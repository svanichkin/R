//
//  MFSettings.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFSettings.h"

#define KEY_SERVER          @"server"
#define KEY_LOGIN           @"login"
#define KEY_PASSWORD        @"password"

#define KEY_PRIORITIES      @"priorities"
#define KEY_TRACKERS        @"trackers"
#define KEY_STATUSES        @"statuses"
#define KEY_STATES          @"states"
#define KEY_SEL_PROJ_ID     @"selectedProjectId"

@implementation MFSettings
{
    NSUserDefaults *_defaults;
}

+ (MFSettings *)sharedInstance
{
	static dispatch_once_t pred;
	static MFSettings *shared = nil;
	
	dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}

- (id)init
{
    if ((self = [super init]) != nil)
    {
        _defaults = [NSUserDefaults standardUserDefaults];   
    }
    return self;
}

#pragma mark - Credentials

- (void)setServer:(NSString *)server
{
    if (server)
    {
        [_defaults setObject:server forKey:KEY_SERVER];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_SERVER];
    }
}

-(NSString *)server
{
    return [_defaults objectForKey:KEY_SERVER];
}

- (void) setLogin:(NSString *)login
{
    if (login)
    {
        [_defaults setObject:login forKey:KEY_LOGIN];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_LOGIN];
    }
}

- (NSString *)login
{
    return [_defaults objectForKey:KEY_LOGIN];
}

- (void) setPassword:(NSString *)password
{
    if (password)
    {
        [_defaults setObject:password forKey:KEY_PASSWORD];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_LOGIN];
    }
}

- (NSString *)password
{
    return [_defaults objectForKey:KEY_PASSWORD];
}

- (BOOL) credentials
{
    return (self.server && self.login && self.password);
}

#pragma mark - Filters

- (void)setFiltersPriorities:(NSArray *)filtersPriorities
{
    if (filtersPriorities)
    {
        [_defaults setObject:filtersPriorities forKey:KEY_PRIORITIES];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_PRIORITIES];
    }
}

- (NSArray *)filtersPriorities
{
    return [_defaults objectForKey:KEY_PRIORITIES];
}

- (void)setFiltersStatuses:(NSArray *)filtersStatuses
{
    if (filtersStatuses)
    {
        [_defaults setObject:filtersStatuses forKey:KEY_STATUSES];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_STATUSES];
    }
}

- (NSArray *)filtersStatuses
{
    return [_defaults objectForKey:KEY_STATUSES];
}

- (void)setFiltersTrackers:(NSArray *)filtersTrackers
{
    if (filtersTrackers)
    {
        [_defaults setObject:filtersTrackers forKey:KEY_TRACKERS];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_TRACKERS];
    }
}

- (NSArray *)filtersTrackers
{
    return [_defaults objectForKey:KEY_TRACKERS];
}

- (BOOL) filters
{
    return (self.filtersPriorities && self.filtersStatuses && self.filtersTrackers);
}

- (void)setFiltersStates:(NSArray *)filtersStates
{
    if (filtersStates)
    {
        [_defaults setObject:filtersStates forKey:KEY_STATES];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_STATES];
    }
}

- (NSArray *)filtersStates
{
    return [_defaults objectForKey:KEY_STATES];
}

#pragma mark - Projects

- (void)setSelectedProjectId:(NSNumber *)selectedProjectId
{
    if (selectedProjectId)
    {
        [_defaults setObject:selectedProjectId forKey:KEY_SEL_PROJ_ID];
        [_defaults synchronize];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_SEL_PROJ_ID];
    }
}

- (NSNumber *)selectedProjectId
{
    return [_defaults objectForKey:KEY_SEL_PROJ_ID];
}

@end
