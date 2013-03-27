//
//  MFConnector.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFConnector.h"
#import "MFSettings.h"

@implementation MFConnector
{
    MFSettings *_settings;
}

+ (MFConnector *)sharedInstance
{
	static dispatch_once_t pred;
	static MFConnector *shared = nil;
	
	dispatch_once(&pred, ^ { shared = [[self alloc] init]; });

    return shared;
}

- (id)init
{
    if ((self = [super init]) != nil)
    {
        _settings = [MFSettings sharedInstance];

        _redmine = [[RKRedmine alloc] init];
        _redmine.delegate = self;
    }
    return self;
}

#pragma mark - Connection

- (void)connect
{
    [self connectWithLogin:_settings.login password:_settings.password andServer:_settings.server];
}

- (void) connectWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server
{
    if (_connectionProgress == NO)
    {
        _connectionProgress = YES;
        
        _redmine.username = login;
        _redmine.password = password;
        _redmine.serverAddress = server;
        
        [_redmine login];
    }
}

- (void) connectionComplete:(NSNumber *)success
{
    _connectionProgress = NO;
    
    if ([success boolValue])
    {
        [MFSettings sharedInstance].server = _redmine.serverAddress;
        [MFSettings sharedInstance].login = _redmine.username;
        [MFSettings sharedInstance].password = _redmine.password;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE object:@(YES)];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE object:@(NO)];
    }
}

#pragma mark - Load settings

- (void) loadFilters
{
    _settings.filtersStatuses =   [[self loadFilterByPath:@"issue_statuses.json"] objectForKey:@"issue_statuses"];
    _settings.filtersTrackers =   [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
    _settings.filtersPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FILTERS_LOADED object:@((_settings.filters))];
}

- (NSDictionary *) loadFilterByPath:(NSString *)path
{
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MFSettings sharedInstance].server, path]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    if (error)
    {
        return nil;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error)
    {
        return nil;
    }
    
    return result;
}

@end
