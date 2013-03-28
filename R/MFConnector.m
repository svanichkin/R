//
//  MFConnector.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFConnector.h"
#import "MFSettings.h"
#import "Project.h"
#import "Issue.h"
#import "MFDatabase.h"

@implementation MFConnector
{
    MFSettings *_settings;
    MFDatabase *_database;

    NSMutableArray *_newProjects;
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
        
        _redmine = [[RKRedmine alloc] init];
        _redmine.delegate = self;
    }
    return self;
}

- (void) sendEvent:(NSString *)event success:(BOOL)boolean
{
    [[NSNotificationCenter defaultCenter] postNotificationName:event object:@(boolean)];
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
    }
    
    [self sendEvent:CONNECT_COMPLETE success:[success boolValue]];
}

#pragma mark - Load settings

- (void) loadFilters
{
    [self sendEvent:FILTERS_LOADED success:YES];
    
    _settings.filtersStatuses =   [[self loadFilterByPath:@"issue_statuses.json"] objectForKey:@"issue_statuses"];
    _settings.filtersTrackers =   [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
    _settings.filtersPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
    
    [self sendEvent:FILTERS_LOADED success:_settings.filters];
}

- (NSDictionary *) loadFilterByPath:(NSString *)path
{
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MFSettings sharedInstance].server, path]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    if (error)
    {
        return nil;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        return nil;
    }
    
    return result;
}

#pragma mark - Load Projects

- (void) loadProjects
{
    if (_settings.projectsLastUpdate)
    {
        [self sendEvent:PROJECTS_LOADED success:YES];
    }

    _settings.projectsLastUpdate = [NSDate date];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        // В этом массиве будут абсолютно все загруженные проекты
        _newProjects = [NSMutableArray array];
        
        // Начинаем рекурсивную загрузку, если она успешна продолжим
        if ([self loadProjectsWithOffset:0])
        {
            // Если длина массива хранимых значений больше чем длина пришедших данных,
            // значит, у нас какие то значения нужно удалить (проекты были удалены)
            NSMutableArray *oldProjects = [NSMutableArray arrayWithArray:[_database projects]];
            if (oldProjects.count > _newProjects.count)
            {
                for (int i = 0; i < oldProjects.count; i ++)
                {
                    Project *op = [oldProjects objectAtIndex:i];
                    for (int j = 0; j < _newProjects.count; j ++)
                    {
                        NSDictionary *np = [_newProjects objectAtIndex:j];
                        if ([[np objectForKey:@"id"] isEqualToNumber:op.pid])
                        {
                            // Затем удаляем объект новых
                            [_newProjects removeObjectAtIndex:j --];
                            [oldProjects removeObjectAtIndex:i --];
                            break;
                        }
                    }
                    continue;
                }
                
                // Удаляем из базы проекты которые были удалены на серваке
                if (oldProjects.count)
                {
                    [_database deleteObjects:oldProjects];
                    [self sendEvent:PROJECTS_LOADED success:YES];
                }
            }
        }
    });
}

- (BOOL) loadProjectsWithOffset:(int)offset
{
    // Грузим проекты рекурсивно
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/projects.json?limit=100&offset=%i", [MFSettings sharedInstance].server, offset]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEvent:PROJECTS_LOADED success:NO];
        });
        return NO;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEvent:PROJECTS_LOADED success:NO];
        });
        return NO;
    }
    
    // Добавляем все новые проекты в один массив, что бы потом про сравнении двух массивов понять, какие из проектов были удалены
    [_newProjects addObjectsFromArray:[result objectForKey:@"projects"]];
    
    // Проверим, возможно такие проекты уже существуют, если существуют выкинем их, а если существуют и изменялись на сервере, то обновим
    BOOL changed = NO;
    NSMutableArray *newProjects = [result objectForKey:@"projects"];
    NSArray *oldProjects = [_database projects];
    for (int i = 0; i < newProjects.count; i ++)
    {
        NSDictionary *p = [newProjects objectAtIndex:i];
        NSNumber *pid = [p objectForKey:@"id"];
        for (Project *op in oldProjects)
        {
            if ([pid isEqualToNumber:op.pid])
            {
                // Проверям если пришел измененный объект, то обновим
                NSDate *tmpd = [self dateFromString:[p objectForKey:@"updated_on"]];
                if(!([op.update compare:tmpd] == NSOrderedSame))
                {
                    op.text = [p objectForKey:@"description"];
                    op.name = [p objectForKey:@"name"];
                    op.update = tmpd;
                    changed = YES;
                }
                
                // Затем удаляем объект из новых, т.к. он нам теперь не нужен
                [newProjects removeObjectAtIndex:i --];
                break;
            }
        }
        continue;
    }
    
    // Сохраняем в базу новые объекты
    if (newProjects.count)
    {
        for (NSDictionary *p in newProjects)
        {
            Project *project = [_database project];
            project.name   = [p objectForKey:@"name"];
            project.text   = [p objectForKey:@"description"];
            project.pid    = [p objectForKey:@"id"];
            project.create = [self dateFromString:[p objectForKey:@"created_on"]];
            project.update = [self dateFromString:[p objectForKey:@"updated_on"]];
        }
    }
    
    // Save
    if (newProjects.count || changed)
    {
        if (![_database save])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendEvent:PROJECTS_LOADED success:NO];
            });
            return NO;
        }
    }
    
    // Если у нас total меньше чем offsef, то делаем рекурсивно вызов на загрузку сл. offseta
    if (offset < [[result objectForKey:@"total_count"] intValue])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEvent:PROJECTS_LOADED success:YES];
        });
        
        offset += 100;
        return [self loadProjectsWithOffset:offset];
    }
    
    return YES;
}

- (NSDate *) dateFromString:(NSString *)dateString
{
    dateString = [dateString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    dateString = [dateString stringByReplacingOccurrencesOfString:@"Z" withString:@""];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setTimeStyle:NSDateFormatterFullStyle];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [dateFormat dateFromString:dateString];
}

#pragma mark - Load Issues

- (void) loadIssues
{
    if (_settings.projectsLastUpdate)
    {
        [self sendEvent:ISSUES_LOADED success:YES];
    }
    
    _settings.projectsLastUpdate = [NSDate date];
    
}

#pragma mark - Load Time Entries

- (void) loadTimeEntries
{
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/time_entries.json?limit=1000", [MFSettings sharedInstance].server]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    if (error)
    {
        return;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error)
    {
        return;
    }
    
}



@end
