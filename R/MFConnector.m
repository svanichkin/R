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

- (void) loadAllProjects
{
    //[_database deleteAllObjects:@"Project"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self loadProjectsWithOffset:0];
    });
}

- (void) loadProjectsWithOffset:(int)offset
{
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
        return;
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
        return;
    }
    
    // Проверим, возможно такие проекты уже существуют
    NSMutableArray *projects = [result objectForKey:@"projects"];
    NSArray *oldProjects = [_database projects];
    for (int i = 0; i < projects.count; i ++)
    {
        NSNumber *pid = [[projects objectAtIndex:i] objectForKey:@"id"];
        for (Project *op in oldProjects)
        {
            if ([pid isEqualToNumber:op.pid])
            {
                // Проверка на предмет изменений полей, если такое случилось, требуется обновить объект
                project.name   = [p objectForKey:@"name"];
                project.text   = [p objectForKey:@"description"];
                project.pid    = [p objectForKey:@"id"];
                project.create = [self dateFromString:[p objectForKey:@"created_on"]];
                project.update = [self dateFromString:[p objectForKey:@"updated_on"]];
                
                // Если никакие поля не изменились, удаляем объект
                [projects removeObjectAtIndex:i --];
                break;
            }
        }
        continue;
    }
    
    if (projects.count)
    {
        for (NSDictionary *p in projects)
        {
            Project *project = [_database project];
            project.name   = [p objectForKey:@"name"];
            project.text   = [p objectForKey:@"description"];
            project.pid    = [p objectForKey:@"id"];
            project.create = [self dateFromString:[p objectForKey:@"created_on"]];
            project.update = [self dateFromString:[p objectForKey:@"updated_on"]];
        }
        
        if (![_database save])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendEvent:PROJECTS_LOADED success:NO];
            });
            return;
        }
    }
    
    if (offset < [[result objectForKey:@"total_count"] intValue])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEvent:PROJECTS_LOADED success:YES];
        });
        
        offset += 100;
        [self loadProjectsWithOffset:offset];
    }
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
