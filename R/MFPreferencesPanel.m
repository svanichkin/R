//
//  MFPreferencesPanel.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFPreferencesPanel.h"

@implementation MFPreferencesPanel
{
    // Ключ включается, при первом коннекте или коннекте с другими кредами к другому серверу
    BOOL _newLoginData;
        
    int _projectsProgress, _filtersProgress, _issuesProgress;
}

-(void) awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"serverAddress"])
    {
        _serverAddress.stringValue = [defaults objectForKey:@"serverAddress"];
        _login.stringValue         = [defaults objectForKey:@"username"];
        _password.stringValue      = [defaults objectForKey:@"password"];
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
    if (_serverAddress.stringValue.length &&
        _login.stringValue.length &&
        _password.stringValue.length &&
        [MFConnector sharedInstance].connectionProgress == NO)
    {
        MFSettings *settings = [MFSettings sharedInstance];
        
        // Если данных по коннекту нет или данные отличаются от тех что сохранены в настройках
        if ([_serverAddress.stringValue isEqualToString:settings.server] == NO ||
            [_login.stringValue isEqualToString:settings.login] == NO ||
            [_password.stringValue isEqualToString:settings.password] == NO)
        {
            _newLoginData = YES;
        }
        else
        {
            return;
        }
                
        // Начнём конект
        [[MFConnector sharedInstance] connectWithLogin:_login.stringValue
                                              password:_password.stringValue
                                             andServer:_serverAddress.stringValue];
    }
}

- (void) connectionStart:(NSNotification *)notification
{
    // Скрываем текст
    _progressText.hidden = YES;
    
    // Покажем прогресс индикатор
    _progressLogin.hidden = NO;
    [_progressLogin startAnimation:nil];
    
    // Скрываем обновление данных
    _progressDatabaseUpdate.hidden = YES;
}

- (void) connectionComplete:(NSNotification *)notification
{
    // Скрываем прогресс бар логина
    _progressLogin.hidden = NO;
    [_progressLogin stopAnimation:nil];
    
    if ([notification.object boolValue])
    {        
        if ([MFSettings sharedInstance].dataLastUpdate == nil || _newLoginData == YES)
        {
            _newLoginData = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RESET_DATABASE object:nil];
            
            _progressDatabaseUpdate.hidden = NO;
         
            // Загрузка значений с сервера для генерации количества и названий сегментов
            [[MFConnector sharedInstance] databaseUpdate];
        }
        else
        {
            _progressText.hidden = NO;
            _progressText.stringValue = @"Connected";
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
    _progressText.hidden = YES;
    
    // Скрываем прогресс бар логина
    _progressLogin.hidden = NO;
    [_progressLogin stopAnimation:nil];
    
    // Показываем обновление данных
    _progressDatabaseUpdate.hidden = NO;
}

- (void) databaseUpdatingProgress:(NSNotification *)notification
{
    [_progressDatabaseUpdate setDoubleValue:[notification.object floatValue]];
}

- (void) databaseUpdatingComplete:(NSNotification *)notification
{
    if ([notification.object boolValue])
    {
        _progressText.hidden = NO;
        _progressText.stringValue = @"Connected";
        
        _progressDatabaseUpdate.hidden = YES;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESET_DATABASE object:nil];
        [self loadingError];
    }
}

- (void) loadingError
{
    _progressText.hidden = NO;
    _progressText.stringValue = @"Error";
    
    _progressDatabaseUpdate.hidden = YES;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
