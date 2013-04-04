//
//  MFAuthorizationKey.m
//  R
//
//  Created by Сергей Ваничкин on 03.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFAuthorization.h"
#import "MFSettings.h"
#import "TFHpple.h"

@implementation MFAuthorization
{
    NSArray *_trustedHosts;
    NSMutableData *_receivedData;

    MFSettings *_settings;
    
    NSURLConnection *_loginTokenConnection, *_authorizationConnection, *_apiTokenConnection;
    NSString *_login, *_password, *_server, *_authenticityToken, *_apiToken;
    
    BOOL _finished;
    BOOL _stop;
}

- (void) authorizationWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server
{
    _settings = [MFSettings sharedInstance];
    
    _server   = server;
    _login    = login;
    _password = password;
    
    _stop = NO;
    _finished = NO;
    
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
    while(!_finished)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
}

- (void) resetData
{
    _stop = YES;
    _finished = YES;
}

- (void) login
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_START
                                                        object:nil];
    
    NSString *urlString          = [NSString stringWithFormat:@"%@/login", _settings.server];
    NSURL *url                   = [NSURL URLWithString:urlString];
    
    _trustedHosts                = [NSArray arrayWithObject:url.host];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    _loginTokenConnection        = [NSURLConnection connectionWithRequest:request
                                                                 delegate:self];
}

- (void) authorization
{
    NSString *urlString          = [NSString stringWithFormat:@"%@/login", _server];
    NSURL *url                   = [NSURL URLWithString:urlString];
    
    NSMutableString *postString  = [[NSMutableString alloc] init];
    [postString appendFormat:@"authenticity_token=%@", _authenticityToken];
    [postString appendFormat:@"&username=%@", _login];
    [postString appendFormat:@"&password=%@", _password];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    _authorizationConnection     = [NSURLConnection connectionWithRequest:request
                                                                 delegate:self];
}

- (void) api
{
    NSString *urlString = [NSString stringWithFormat:@"%@/my/account", _settings.server];
    NSURL *url = [NSURL URLWithString:urlString];
    
    _trustedHosts = [NSArray arrayWithObject:url.host];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    _apiTokenConnection = [NSURLConnection connectionWithRequest:request delegate:self];    
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
        if ([_trustedHosts containsObject:challenge.protectionSpace.host])
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _receivedData = [[NSMutableData alloc] init];
    [_receivedData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_stop)
    {
        return;
    }
    
    if ([connection isEqual:_loginTokenConnection])
    {
        TFHpple *doc              = [[TFHpple alloc] initWithHTMLData:_receivedData];
        NSArray *elements         = [doc searchWithXPathQuery:@"//input[@name='authenticity_token']"];
        
        if (elements.count > 0)
        {
            TFHppleElement *input = [elements objectAtIndex:0];
            _authenticityToken    = [[input objectForKey:@"value"] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        }
        
        [self authorization];
    }
    else if ([connection isEqual:_authorizationConnection])
    {
        [self api];
    }
    else if ([connection isEqual:_apiTokenConnection])
    {
        TFHpple *doc              = [[TFHpple alloc] initWithHTMLData:_receivedData];
        NSArray *elements         = [doc searchWithXPathQuery:@"//pre[@id='api-access-key']"];
        
        if (elements.count > 0)
        {
            TFHppleElement *input = [elements objectAtIndex:0];
            
            _settings.apiToken    = [input content];
            _settings.server      = _server;
            _settings.login       = _login;
            _settings.password    = _password;
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE
                                                                object:@(elements.count)];
        });
        
        _finished = YES;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_stop)
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE
                                                           object:@(NO)];
    });
    
    _finished = YES;
}

@end