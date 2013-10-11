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

@interface MFConnector ()

@property (nonatomic, strong) MFSettings *settings;
@property (nonatomic, strong) MFDatabase *database;

@property (nonatomic, strong) MFAuthorization *token;

@end

@implementation MFConnector

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
        self.settings = [MFSettings sharedInstance];
        self.database = [MFDatabase sharedInstance];
        
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
    self.connectionProgress = NO;
    self.databaseUpdatingProgress = NO;
}

#pragma mark - Authorization

- (void)connect
{
    [self connectWithLogin:self.settings.login
                  password:self.settings.password
                 andServer:self.settings.server];
}

- (void) connectWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server
{
    if (self.connectionProgress == NO)
    {
        self.connectionProgress = YES;
        
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
    self.connectionProgress = NO;
}

#pragma mark - Database Updating

- (void) databaseUpdate
{
    if (self.databaseUpdatingProgress == NO)
    {
        self.databaseUpdatingProgress = YES;
        
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
    self.databaseUpdatingProgress = NO;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
