//
//  MFConnector.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "Project.h"
#import "Issue.h"
#import "Version.h"
#import "User.h"
#import "MFAppDelegate.h"
#import "MFAuthorization.h"
#import "MFDatabaseUpdator.h"

@implementation MFConnector
{
    MFSettings *_settings;
    MFDatabase *_database;
    
    MFAuthorization *token;
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
        _database = [MFDatabase sharedInstance];
        
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
    }
    return self;
}

- (void) sendEvent:(NSString *)event success:(BOOL)boolean
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:event object:@(boolean)];
    });
}

- (void) sendEvent:(NSString *)event progress:(int)procent
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:event object:@(procent)];
    });
}

- (void) resetData
{
    _connectionProgress = NO;
    _databaseUpdatingProgress = NO;
}

#pragma mark - Authorization

- (void)connect
{
    [self connectWithLogin:_settings.login password:_settings.password andServer:_settings.server];
}

- (void) connectWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server
{
    if (_connectionProgress == NO)
    {
        _connectionProgress = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(connectionComplete:)
                                                     name:CONNECT_COMPLETE
                                                   object:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
        {
            // Получаем токен авторизации
            [[[MFAuthorization alloc] init] authorizationWithLogin:login password:password andServer:server];
        });
    }
}

- (void) connectionComplete:(NSNumber *)success
{
    _connectionProgress = NO;
}

#pragma mark - Database Updating

- (void) databaseUpdate
{
    if (_databaseUpdatingProgress == NO)
    {
        _databaseUpdatingProgress = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(databaseUpdatingComplete:)
                                                     name:DATABASE_UPDATING_COMPLETE
                                                   object:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
        {
            // Загружаем данные
            [[[MFDatabaseUpdator alloc] init] update];
        });
    }
}

- (void) databaseUpdatingComplete:(NSNumber *)success
{
    _databaseUpdatingProgress = NO;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
