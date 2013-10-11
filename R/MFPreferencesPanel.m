//
//  MFPreferencesPanel.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFPreferencesPanel.h"

@interface MFPreferencesPanel ()

// Ключ включается, при первом коннекте или коннекте с другими кредами к другому серверу
@property (nonatomic, assign) BOOL newLoginData;

@property (nonatomic, assign) NSInteger projectsProgress;
@property (nonatomic, assign) NSInteger filtersProgress;
@property (nonatomic, assign) NSInteger issuesProgress;

@end

@implementation MFPreferencesPanel

-(void) awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"serverAddress"])
    {
        self.serverAddress.stringValue = [defaults objectForKey:@"serverAddress"];
        self.login.stringValue         = [defaults objectForKey:@"username"];
        self.password.stringValue      = [defaults objectForKey:@"password"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStart:)
                                                 name:CONNECT_START
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionComplete:)
                                                 name:CONNECT_COMPLETE
                                               object:nil];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseUpdatingStart:)
                                                 name:DATABASE_UPDATING_START
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseUpdatingProgress:)
                                                 name:DATABASE_UPDATING_PROGRESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseUpdatingComplete:)
                                                 name:DATABASE_UPDATING_COMPLETE
                                               object:nil];
}

#pragma mark - Connection

- (IBAction) connectAction:(id)sender
{
    if (self.serverAddress.stringValue.length &&
        self.login.stringValue.length &&
        self.password.stringValue.length &&
        [MFConnector sharedInstance].connectionProgress == NO)
    {
        MFSettings *settings = [MFSettings sharedInstance];
        
        // Если данных по коннекту нет или данные отличаются от тех что сохранены в настройках
        if ([self.serverAddress.stringValue isEqualToString:settings.server] == NO ||
            [self.login.stringValue isEqualToString:settings.login] == NO ||
            [self.password.stringValue isEqualToString:settings.password] == NO)
        {
            self.newLoginData = YES;
        }
        else
        {
            return;
        }
                
        // Начнём конект
        [[MFConnector sharedInstance] connectWithLogin:self.login.stringValue
                                              password:self.password.stringValue
                                             andServer:self.serverAddress.stringValue];
    }
}

- (void) connectionStart:(NSNotification *)notification
{
    // Скрываем текст
    self.progressText.hidden = YES;
    
    // Покажем прогресс индикатор
    self.progressLogin.hidden = NO;
    [self.progressLogin startAnimation:nil];
    
    // Скрываем обновление данных
    self.progressDatabaseUpdate.hidden = YES;
}

- (void) connectionComplete:(NSNotification *)notification
{
    // Скрываем прогресс бар логина
    self.progressLogin.hidden = NO;
    [self.progressLogin stopAnimation:nil];
    
    if ([notification.object boolValue])
    {        
        if ([MFSettings sharedInstance].dataLastUpdate == nil || self.newLoginData == YES)
        {
            self.newLoginData = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RESET_DATABASE object:nil];
            
            self.progressDatabaseUpdate.hidden = NO;
         
            // Загрузка значений с сервера для генерации количества и названий сегментов
            [[MFConnector sharedInstance] databaseUpdate];
        }
        else
        {
            self.progressText.hidden = NO;
            self.progressText.stringValue = @"Connected";
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_COMPLETE object:(@YES)];
        }
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESET_AUTHORIZATION object:nil];
        [self loadingError];
    }
}

#pragma mark - Database

- (void) databaseUpdatingStart:(NSNotification *)notification
{
    // Скрываем текст
    self.progressText.hidden = YES;
    
    // Скрываем прогресс бар логина
    self.progressLogin.hidden = NO;
    [self.progressLogin stopAnimation:nil];
    
    // Показываем обновление данных
    self.progressDatabaseUpdate.hidden = NO;
}

- (void) databaseUpdatingProgress:(NSNotification *)notification
{
    [self.progressDatabaseUpdate setDoubleValue:[notification.object floatValue]];
}

- (void) databaseUpdatingComplete:(NSNotification *)notification
{
    if ([notification.object boolValue])
    {
        self.progressText.hidden = NO;
        self.progressText.stringValue = @"Connected";
        
        self.progressDatabaseUpdate.hidden = YES;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESET_DATABASE object:nil];
        [self loadingError];
    }
}

- (void) loadingError
{
    self.progressText.hidden = NO;
    self.progressText.stringValue = @"Error";
    
    self.progressDatabaseUpdate.hidden = YES;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
