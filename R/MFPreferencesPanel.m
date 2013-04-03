//
//  MFPreferencesPanel.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFPreferencesPanel.h"
#import "MFConnector.h"
#import "MFSettings.h"
#import "MFDatabase.h"

@implementation MFPreferencesPanel
{
    // Ключ включается, при первом коннекте или коннекте с другими кредами к другому серверу
    BOOL _renewDatabase;
        
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
                                             selector:@selector(connectionComplete:)
                                                 name:CONNECT_COMPLETE
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectsLoadingProgress:)
                                                 name:PROJECTS_LOADING_PROGRESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(projectsLoadingComplete:)
                                                 name:PROJECTS_LOADED
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filtersLoadingProgress:)
                                                 name:FILTERS_LOADING_PROGRESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filtersLoadingComplete:)
                                                 name:FILTERS_LOADED
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(issuesLoadingProgress:)
                                                 name:ISSUES_LOADING_PROGRESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(issuesLoadingComplete:)
                                                 name:ISSUES_LOADED
                                               object:nil];
}

- (IBAction) connectAction:(id)sender
{
    if (_serverAddress.stringValue.length &&
        _login.stringValue.length &&
        _password.stringValue.length &&
        [MFConnector sharedInstance].connectionProgress == NO)
    {
        MFSettings *settings = [MFSettings sharedInstance];
        
        // Если данных по коннекту нет или данные отличаются от тех что сохранены в настройках
        _renewDatabase = ([_serverAddress.stringValue isEqualToString:settings.server] == NO ||
                          [_login.stringValue isEqualToString:settings.login] == NO ||
                          [_password.stringValue isEqualToString:settings.password] == NO);
        
        // Скрываем текст
        _progressText.hidden = YES;
        
        // Покажем прогресс индикатор
        _progressLogin.hidden = NO;
        [_progressLogin startAnimation:nil];
        
        // Скрываем обновление данных
        _progressDatabaseUpdate.hidden = YES;

        // Начнём конект
        [[MFConnector sharedInstance] connectWithLogin:_login.stringValue
                                              password:_password.stringValue
                                             andServer:_serverAddress.stringValue];
    }
}

- (void) connectionComplete:(NSNotification *)notification
{
    // Скрываем прогресс бар логина
    _progressLogin.hidden = NO;
    [_progressLogin stopAnimation:nil];
    
    if ([notification.object boolValue])
    {
        // Если авторизация происходит с другим логином паролем, то всё загруженное удаляем
        if (_renewDatabase == YES)
        {
            _renewDatabase = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RESET_ALL_DATA object:nil];
        }
        
        if ([MFSettings sharedInstance].projectsLastUpdate == nil ||
            [MFSettings sharedInstance].filtersLastUpdate == nil ||
            [MFSettings sharedInstance].issuesLastUpdate == nil)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:RESET_ALL_DATA object:nil];
            
            _progressDatabaseUpdate.hidden = NO;
         
            // Загрузка значений с сервера для генерации количества и названий сегментов
            [[MFConnector sharedInstance] loadFilters];
        }
        else
        {
            _progressText.hidden = NO;
            _progressText.stringValue = @"Connected";
        }
    }
    else
    {
        _progressText.hidden = NO;
        _progressText.stringValue = @"Error";
    }
}

#pragma mark - Loading Events

- (void) projectsLoadingProgress:(NSNotification *)notification
{
    _projectsProgress = [notification.object intValue];
    [self refreshProgress];
}

- (void) projectsLoadingComplete:(NSNotification *)notification
{
    if ([notification.object boolValue])
    {
        _projectsProgress = 100;
        [self refreshProgress];
        
        // Загрузка списка задач
        [[MFConnector sharedInstance] loadIssues];
    }
    else
    {
        [self loadingError];
    }
}

- (void) filtersLoadingProgress:(NSNotification *)notification
{
    _filtersProgress = [notification.object intValue];
    [self refreshProgress];
}

- (void) filtersLoadingComplete:(NSNotification *)notification
{
    if ([notification.object boolValue])
    {
        _filtersProgress = 100;
        [self refreshProgress];
        
        // Загрузка списка проектов
        [[MFConnector sharedInstance] loadProjects];
    }
    else
    {
        [self loadingError];
    }
}

- (void) issuesLoadingProgress:(NSNotification *)notification
{
    if (notification.object)
    {
        _issuesProgress = [notification.object intValue];
        [self refreshProgress];
    }
}

- (void) issuesLoadingComplete:(NSNotification *)notification
{
    if ([notification.object boolValue])
    {
        _issuesProgress = 100;
        [self refreshProgress];
        
        [_progressText setHidden:NO];
        _progressText.stringValue = @"Connected";
        
        _progressDatabaseUpdate.hidden = YES;
    }
    else
    {
        [self loadingError];
    }
}

- (void) loadingError
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RESET_ALL_DATA object:nil];
    
    [_progressText setHidden:NO];
    _progressText.stringValue = @"Error";
    
    _progressDatabaseUpdate.hidden = YES;
}

- (void) refreshProgress
{
    [_progressDatabaseUpdate setDoubleValue: (_projectsProgress + _filtersProgress + _issuesProgress) / 3];
}

@end
