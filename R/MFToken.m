//
//  MFAuthorizationKey.m
//  R
//
//  Created by Сергей Ваничкин on 03.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFToken.h"
#import "Base64.h"
#import "MFSettings.h"
#import "TFHpple.h"

@implementation MFToken
{
    id _delegate;
    NSArray *_trustedHosts;
    NSMutableData *_receivedData;
    SEL _function;
    MFSettings *_settings;
    NSURLConnection *_getTokenConnection;
}

- (void) tokenWithDelegate:(id)delegate andFunction:(SEL)function
{
    _delegate = delegate;
    _function = function;
    
    _settings = [MFSettings sharedInstance];
    
    //NSString *urlString     = [NSString stringWithFormat:@"https://spo.avaya.com", _settings.server];
    NSString *urlString     = @"https://spo.avaya.com";
    NSURL *url              = [NSURL URLWithString:urlString];
    
    _trustedHosts = [NSArray arrayWithObject:url.host];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    _getTokenConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - Connection Events

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSLog(@"authorization");
    
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"trust - %@",challenge.protectionSpace.host);

    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([_trustedHosts containsObject:challenge.protectionSpace.host])
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"responce %@",[(NSHTTPURLResponse*)response allHeaderFields]);
    _receivedData = [[NSMutableData alloc] init];
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"complete %@", [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding]);
    TFHpple *doc            = [[TFHpple alloc] initWithHTMLData:_receivedData];
    NSArray *elements       = [doc searchWithXPathQuery:@"//input[@name='authenticity_token']"];
    NSString *auth_key      = nil;
    
    if ([elements count] > 0)
    {
        TFHppleElement *input   = [elements objectAtIndex:0];
        auth_key      = [input objectForKey:@"value"];
    }

    if (auth_key)
    {
        _settings.token = auth_key;
    }

    [_delegate performSelector:_function withObject:nil afterDelay:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
     NSLog(@"error %@", error.localizedDescription);
    [_delegate performSelector:_function withObject:nil afterDelay:0];
}

/*
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    return  request;
}

*/
/*
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
}
*/

/*
-(BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}
*/
-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    return  nil;
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
}

@end