//
//  MFAuthorizationKey.m
//  R
//
//  Created by Сергей Ваничкин on 03.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFAuthorization.h"
#import "TFHpple.h"

@interface MFAuthorization ()

@property (nonatomic, strong) NSArray *trustedHosts;
@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, strong) MFSettings *settings;

@property (nonatomic, strong) NSURLConnection *loginTokenConnection;
@property (nonatomic, strong) NSURLConnection *authorizationConnection;
@property (nonatomic, strong) NSURLConnection *apiTokenConnection;

@property (nonatomic, strong) NSString *loginString;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *authenticityToken;
@property (nonatomic, strong) NSString *apiToken;

@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL stop;

@end

@implementation MFAuthorization

- (void) authorizationWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server
{
    self.settings = [MFSettings sharedInstance];
    
    self.server         = server;
    self.loginString    = login;
    self.password       = password;
    
    self.stop = NO;
    self.finished = NO;
    
    [self login];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetData)
                                                 name:RESET_DATABASE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetData)
                                                 name:RESET_FULL
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetData)
                                                 name:RESET_AUTHORIZATION
                                               object:nil];
    
    // Цикл позволяет не закрывать поток, пока выполняется пустой цикл
    while(!self.finished)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
}

- (void) resetData
{
    self.stop = YES;
    self.finished = YES;
}

- (void) login
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_START
                                                        object:nil];
    
    NSString *urlString          = [NSString stringWithFormat:@"%@/login", self.server];
    NSURL *url                   = [NSURL URLWithString:urlString];
    
    self.trustedHosts                = [NSArray arrayWithObject:url.host];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    self.loginTokenConnection        = [NSURLConnection connectionWithRequest:request
                                                                 delegate:self];
}

- (void) authorization
{
    NSString *urlString          = [NSString stringWithFormat:@"%@/login", self.server];
    NSURL *url                   = [NSURL URLWithString:urlString];
    
    NSMutableString *postString  = [[NSMutableString alloc] init];
    [postString appendFormat:@"authenticity_token=%@", self.authenticityToken];
    [postString appendFormat:@"&username=%@", self.loginString];
    [postString appendFormat:@"&password=%@", self.password];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    self.authorizationConnection     = [NSURLConnection connectionWithRequest:request
                                                                 delegate:self];
}

- (void) api
{
    NSString *urlString = [NSString stringWithFormat:@"%@/my/account", self.server];
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.trustedHosts = [NSArray arrayWithObject:url.host];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    self.apiTokenConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - Connection Events

- (BOOL) connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([self.trustedHosts containsObject:challenge.protectionSpace.host])
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.receivedData = [[NSMutableData alloc] init];
    [self.receivedData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.stop)
    {
        return;
    }
    
    if ([connection isEqual:self.loginTokenConnection])
    {
        TFHpple *doc              = [[TFHpple alloc] initWithHTMLData:self.receivedData];
        NSArray *elements         = [doc searchWithXPathQuery:@"//input[@name='authenticity_token']"];
        
        if (elements.count > 0)
        {
            TFHppleElement *input = [elements objectAtIndex:0];
            self.authenticityToken    = [[input objectForKey:@"value"] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        }
        
        [self authorization];
    }
    else if ([connection isEqual:self.authorizationConnection])
    {
        [self api];
    }
    else if ([connection isEqual:self.apiTokenConnection])
    {
        TFHpple *doc              = [[TFHpple alloc] initWithHTMLData:self.receivedData];
        NSArray *elements         = [doc searchWithXPathQuery:@"//pre[@id='api-access-key']"];
        
        if (elements.count > 0)
        {
            TFHppleElement *input = [elements objectAtIndex:0];
            
            self.settings.apiToken    = [input content];
        }
        
        self.settings.server      = self.server;
        self.settings.login       = self.loginString;
        self.settings.password    = self.password;

        dispatch_async(dispatch_get_main_queue(), ^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE
                                                                object:@(YES)];
        });
        
        self.finished = YES;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.stop)
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE
                                                           object:@(NO)];
    });
    
    self.finished = YES;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end