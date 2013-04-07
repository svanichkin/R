//
//  MFSettings.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//


#define KEY_SERVER          @"server"
#define KEY_LOGIN           @"login"
#define KEY_API_TOKEN       @"apiToken"
#define KEY_PASSWORD        @"password"

#define KEY_STATES          @"states"
#define KEY_SEL_PROJ_ID     @"selectedProjectId"
#define KEY_SEL_ISSUE_ID    @"selectedIssueId"

#define KEY_DATA_LAST_UPD   @"dataLastUpdate"


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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetData)
                                                     name:RESET_DATABASE
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetFull)
                                                     name:RESET_FULL
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetAuthorization)
                                                     name:RESET_AUTHORIZATION
                                                   object:nil];
    }
    return self;
}

- (void) resetData
{
    [self setDataLastUpdate: nil];
    
    [self setFiltersStates:nil];
    [self setSelectedProjectId:nil];
    [self setSelectedIssueId:nil];
}

- (void) resetAuthorization
{
    [self setLogin: nil];
    [self setPassword:nil];
    [self setServer:nil];
    [self setApiToken:nil];
}

- (void) resetFull
{
    [self resetData];
    [self resetAuthorization];
}

#pragma mark - Credentials

- (void)setServer:(NSString *)server
{
    if (server)
    {
        [_defaults setObject:server forKey:KEY_SERVER];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_SERVER];
    }
    [_defaults synchronize];
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
    }
    else
    {
        [_defaults removeObjectForKey:KEY_LOGIN];
    }
    [_defaults synchronize];
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
    }
    else
    {
        [_defaults removeObjectForKey:KEY_LOGIN];
    }
    [_defaults synchronize];
}

- (NSString *)password
{
    return [_defaults objectForKey:KEY_PASSWORD];
}

- (BOOL) credentials
{
    return (self.server && self.login && self.password);
}

- (void) setApiToken:(NSString *)token
{
    if (token)
    {
        [_defaults setObject:token forKey:KEY_API_TOKEN];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_API_TOKEN];
    }
    [_defaults synchronize];
}

- (NSString *)apiToken
{
    return [_defaults objectForKey:KEY_API_TOKEN];
}
#pragma mark - Filters

- (void)setFiltersStates:(NSArray *)filtersStates
{
    if (filtersStates)
    {
        [_defaults setObject:filtersStates forKey:KEY_STATES];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_STATES];
    }
    [_defaults synchronize];
}

- (NSArray *) filtersStates
{
    return [_defaults objectForKey:KEY_STATES];
}

#pragma mark - Projects

- (void) setSelectedProjectId:(NSNumber *)selectedProjectId
{
    if (selectedProjectId)
    {
        [_defaults setObject:selectedProjectId forKey:KEY_SEL_PROJ_ID];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_SEL_PROJ_ID];
    }
    [_defaults synchronize];
}

- (NSNumber *) selectedProjectId
{
    return [_defaults objectForKey:KEY_SEL_PROJ_ID];
}

#pragma mark - Issues

- (void) setSelectedIssueId:(NSNumber *)selectedIssueId
{
    if (selectedIssueId)
    {
        [_defaults setObject:selectedIssueId forKey:KEY_SEL_ISSUE_ID];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_SEL_ISSUE_ID];
    }
    [_defaults synchronize];
}

- (NSNumber *) selectedIssueId
{
    return [_defaults objectForKey:KEY_SEL_ISSUE_ID];
}



- (void) setDataLastUpdate:(NSDate *)lastUpdate
{
    if (lastUpdate)
    {
        [_defaults setObject:lastUpdate forKey:KEY_DATA_LAST_UPD];
    }
    else
    {
        [_defaults removeObjectForKey:KEY_DATA_LAST_UPD];
    }
    [_defaults synchronize];
}

- (NSDate *) dataLastUpdate
{
    return [_defaults objectForKey:KEY_DATA_LAST_UPD];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end