//
//  MFConnector.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFConnector.h"

@interface MFConnector ()
{
}
@end

@implementation MFConnector

+ (MFConnector *)sharedInstance
{
	static dispatch_once_t pred;
	static MFConnector *shared = nil;
	
	dispatch_once(&pred, ^
      {
          shared = [[self alloc] init];
      });
	
    return shared;
}

- (void)connectWithLogin:(NSString *)login password:(NSString *)password server:(NSString *)server andApikey:(NSString *)apikey
{
    _connectionProgress = YES;
    
    _redmine = [[RKRedmine alloc] init];
    _redmine.serverAddress = server;
    _redmine.username = login;
    _redmine.password = password;
    _redmine.apiKey = apikey;
    _redmine.delegate = self;
    [_redmine login];
}

- (void) connectionComplete:(NSNumber *)success
{
    _connectionProgress = NO;
    
    if ([success boolValue])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setObject:_redmine.serverAddress forKey:@"serverAddress"];
        [defaults setObject:_redmine.username forKey:@"username"];
        [defaults setObject:_redmine.password forKey:@"password"];
        [defaults setObject:_redmine.apiKey forKey:@"apikey"];
        
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE object:@(YES)];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE object:@(NO)];
    }
}

@end
