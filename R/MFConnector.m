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
#import "Version.h"
#import "User.h"
#import "MFDatabase.h"
#import "MFAppDelegate.h"

// Загрузка состоит из двух частей, первая это загрузка из сети
// вторая часть это формирование базы даных
// Этот флаг указывает, сколько процентов уделять на загрузку
// а сколько на формирование. Т.к. скорость загрузки выше
// чем скорость формирования базы, значит прогресс бар
// быстрее проползет по загрузке а затем долго будет ползти по
// формированию базы. Поэтому лучше поставить соотношение 30/70
#define SHIFT_LOADING_PROCENT    10
#define SHIFT_DATABASE_PROCENT   90

@implementation MFConnector
{
    MFSettings *_settings;
    MFDatabase *_database;

    NSMutableArray *_newProjects;
    NSMutableArray *_newIssues;
    
    BOOL _noNeedFilters;
    BOOL _noNeedProjects;
    BOOL _noNeedIssues;
    
    float _shiftLoading;
    float _shiftDatabase;
    
    int _projectsProgress, _filtersProgress, _issuesProgress;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(allStop)
                                                     name:RESET_ALL_DATA
                                                   object:nil];
        
        _shiftLoading  = 100/SHIFT_LOADING_PROCENT;
        _shiftDatabase = 100/SHIFT_DATABASE_PROCENT;
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

- (NSDate *) dateFromString:(NSString *)dateString
{
    if (dateString == nil)
    {
        return nil;
    }
    
    dateString = [dateString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    dateString = [dateString stringByReplacingOccurrencesOfString:@"Z" withString:@""];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setTimeStyle:NSDateFormatterFullStyle];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [dateFormat dateFromString:dateString];
}

- (NSDate *) dateFromString2:(NSString *)dateString
{
    if (dateString == nil)
    {
        return nil;
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setTimeStyle:NSDateFormatterFullStyle];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    return [dateFormat dateFromString:dateString];
}

- (void) allStop
{
    _noNeedFilters  = YES;
    _noNeedProjects = YES;
    _noNeedIssues   = YES;
    
    _settings.projectsLastUpdate = nil;
    _settings.filtersLastUpdate  = nil;
    _settings.issuesLastUpdate   = nil;
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
        
        _redmine.username      = login;
        _redmine.password      = password;
        _redmine.serverAddress = server;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
        {
            [_redmine login];
        });
    }
}

- (void) connectionComplete:(NSNumber *)success
{
    _connectionProgress = NO;
    
    if ([success boolValue])
    {
        [MFSettings sharedInstance].server   = _redmine.serverAddress;
        [MFSettings sharedInstance].login    = _redmine.username;
        [MFSettings sharedInstance].password = _redmine.password;
    }
    
    [self sendEvent:CONNECT_COMPLETE success:[success boolValue]];
}

#pragma mark - Load settings

- (void) loadFilters
{
    _noNeedFilters = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
    {
        NSArray *newStatuses   = [[self loadFilterByPath:@"issue_statuses.json"] objectForKey:@"issue_statuses"];
        [self sendEvent:FILTERS_LOADING_PROGRESS progress:25];
        
        NSArray *newTrackers   = [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
        [self sendEvent:FILTERS_LOADING_PROGRESS progress:50];
        
        NSArray *newPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
        [self sendEvent:FILTERS_LOADING_PROGRESS progress:75];
        
        if (_noNeedFilters)
        {
            return;
        }

        [_database deleteAllObjects:@"Status"];
        [_database deleteAllObjects:@"Tracker"];
        [_database deleteAllObjects:@"Priority"];
        
        if (newStatuses && newTrackers && newPriorities)
        {
            for (NSDictionary *ns in newStatuses)
            {
                Status *status = _database.status;
                status.name = [ns objectForKey:@"name"];
                status.nid  = [ns objectForKey:@"id"];
            }
            
            for (NSDictionary *t in newTrackers)
            {
                Tracker *tracker = _database.tracker;
                tracker.name = [t objectForKey:@"name"];
                tracker.nid  = [t objectForKey:@"id"];
            }
            for (NSDictionary *p in newPriorities)
            {
                Priority *priority = _database.priority;
                priority.name = [p objectForKey:@"name"];
                priority.nid  = [p objectForKey:@"id"];
            }
            
            if ([_database save])
            {
                _settings.projectsLastUpdate = [NSDate date];
                [self sendEvent:FILTERS_LOADING_PROGRESS progress:100];
                [self sendEvent:FILTERS_LOADED success:YES];
                return;
            }
        }
        [self sendEvent:FILTERS_LOADED success:NO];
    });
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
    _noNeedProjects = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
    {
        // В этом массиве будут абсолютно все загруженные проекты
        _newProjects = [NSMutableArray array];
        
        // Начинаем рекурсивную загрузку, если она успешна продолжим
        if ([self loadProjectsWithOffset:0])
        {
            if (_noNeedProjects)
            {
                return;
            }
            
            if (_newProjects.count)
            {
                int index = 0;
                for (NSDictionary *newProject in _newProjects)
                {
                    @autoreleasepool
                    {
                        Project *oldProject = [_database projectById:[newProject objectForKey:@"id"]];
                        [self refreshProject:oldProject withDictionary:newProject];

                        index ++;
                        int progress = ((index * 100)/_newProjects.count);
                        _projectsProgress = progress > 100 ? 100 : progress;
                        [self sendEvent:PROJECTS_LOADING_PROGRESS progress:SHIFT_LOADING_PROCENT + (_projectsProgress/_shiftDatabase)];
                    }
                }
                
                if (![_database save])
                {
                    [self sendEvent:PROJECTS_LOADED success:NO];
                    return;
                }
            }
            
            // Если длина массива хранимых значений больше чем длина пришедших данных,
            // значит, у нас какие то значения нужно удалить (проекты были удалены)
            /*NSMutableArray *oldProjects = [NSMutableArray arrayWithArray:[_database projects]];
            if (oldProjects.count > _newProjects.count)
            {
                for (int i = 0; i < oldProjects.count; i ++)
                {
                    Project *op = [oldProjects objectAtIndex:i];
                    for (int j = 0; j < _newProjects.count; j ++)
                    {
                        NSDictionary *np = [_newProjects objectAtIndex:j];
                        if ([[np objectForKey:@"id"] isEqualToNumber:op.nid])
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
                    [_database deleteObjects:oldIssues];
                    _settings.projectsLastUpdate = [NSDate date];
                    [self sendEvent:PROJECTS_LOADING_PROGRESS progress:100];
                    [self sendEvent:PROJECTS_LOADED success:[_database deleteObjects:oldProjects]];
                }
            }*/
            
            _settings.projectsLastUpdate = [NSDate date];
            [self sendEvent:PROJECTS_LOADING_PROGRESS progress:100];
            [self sendEvent:PROJECTS_LOADED success:YES];
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
        [self sendEvent:PROJECTS_LOADED success:NO];
        return NO;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        [self sendEvent:PROJECTS_LOADED success:NO];
        return NO;
    }
    
    if (_noNeedProjects)
    {
        return NO;
    }
    
    // Добавляем все новые проекты в один массив, что бы потом про сравнении двух массивов понять, какие из проектов были удалены
    [_newProjects addObjectsFromArray:[result objectForKey:@"projects"]];
        
    // Если у нас total меньше чем offsef, то делаем рекурсивно вызов на загрузку сл. offseta
    if (offset < [[result objectForKey:@"total_count"] intValue])
    {
        int progress = ((offset * 100)/[[result objectForKey:@"total_count"] intValue]);
        _projectsProgress = progress > 100 ? 100 : progress;
        [self sendEvent:PROJECTS_LOADING_PROGRESS progress:_projectsProgress/_shiftLoading];
        
        offset += 100;
        return [self loadProjectsWithOffset:offset];
    }
    
    return YES;
}

- (void) refreshProject:(Project *)project withDictionary:(NSDictionary *)dictionary
{
    NSString *name = [dictionary objectForKey:@"name"];
    if (name) project.name = name;
    
    NSString *text = [dictionary objectForKey:@"description"];
    if (text) project.text = text;
    
    NSString *stringId = [dictionary objectForKey:@"identifier"];
    if (text) project.sid = stringId;
    
    NSDate *update = [self dateFromString:[dictionary objectForKey:@"updated_on"]];
    if (update) project.update = update;
    
    NSDate *create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    if (create) project.create = create;
    
    BOOL needSave = NO;
    
    // Parent
    NSDictionary *object = [dictionary objectForKey:@"parent"];
    if (object)
    {
        if (project.parent == nil)
        {
            project.parent = [_database projectById:[object objectForKey:@"id"]];
        }
        project.parent.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (project.parent != nil)
    {
        project.parent = nil;
        needSave = YES;
    }
    
    if (needSave == YES)
    {
        if (![_database save])
        {
            NSLog(@"sdfsdf");
        }
    }
}

#pragma mark - Load Issues

- (void) loadIssues
{
    _noNeedIssues = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
    {
        // В этом массиве будут абсолютно все загруженные задачи
        _newIssues = [NSMutableArray array];
        
        // Начинаем рекурсивную загрузку, если она успешна продолжим
        if ([self loadIssuesWithOffset:0])
        {
            if (_noNeedIssues)
            {
                return;
            }
            
            if (_newProjects.count)
            {
                int index = 0;
                for (NSDictionary *newIssue in _newIssues)
                {
                    @autoreleasepool
                    {
                        Issue *oldIssue = [_database issueById:[newIssue objectForKey:@"id"]];
                        [self refreshIssue:oldIssue withDictionary:newIssue];
                        
                        index ++;
                        int progress = ((index * 100)/_newIssues.count);
                        _issuesProgress = progress > 100 ? 100 : progress;
                        [self sendEvent:ISSUES_LOADING_PROGRESS progress:SHIFT_LOADING_PROCENT + (_issuesProgress / _shiftDatabase)];
                    }
                }
                
                if (![_database save])
                {
                    [self sendEvent:ISSUES_LOADED success:NO];
                    return;
                }
            }
            
            // Если длина массива хранимых значений больше чем длина пришедших данных,
            // значит, у нас какие то значения нужно удалить (проекты были удалены)
            /*NSMutableArray *oldIssues = [NSMutableArray arrayWithArray:[_database issues]];
            if (oldIssues.count > _newIssues.count)
            {
                for (int i = 0; i < oldIssues.count; i ++)
                {
                    Issue *oldIssue = [oldIssues objectAtIndex:i];
                    for (int j = 0; j < _newIssues.count; j ++)
                    {
                        NSDictionary *newIssue = [_newIssues objectAtIndex:j];
                        if ([[newIssue objectForKey:@"id"] isEqualToNumber:oldIssue.nid])
                        {
                            // Затем удаляем объект новых
                            [_newIssues removeObjectAtIndex:j --];
                            [oldIssues removeObjectAtIndex:i --];
                            break;
                        }
                    }
                    continue;
                }
                
                // Удаляем из базы проекты которые были удалены на серваке
                if (oldIssues.count)
                {
                    [_database deleteObjects:oldIssues];
                    _settings.issuesLastUpdate = [NSDate date];
                    [self sendEvent:ISSUES_LOADING_PROGRESS progress:100];
                    [self sendEvent:ISSUES_LOADED success:YES];
                }
            }*/
            
            _settings.issuesLastUpdate = [NSDate date];
            [self sendEvent:ISSUES_LOADING_PROGRESS progress:100];
            [self sendEvent:ISSUES_LOADED success:YES];
        }
    });
}

- (BOOL) loadIssuesWithOffset:(int)offset
{
    // Грузим задачи рекурсивно
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/issues.json?limit=100&offset=%i", [MFSettings sharedInstance].server, offset]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    
    if (error)
    {
        [self sendEvent:ISSUES_LOADED success:NO];
        return NO;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        [self sendEvent:ISSUES_LOADED success:NO];
        return NO;
    }
    
    if (_noNeedIssues)
    {
        return NO;
    }
    
    // Добавляем все новые проекты в один массив, что бы потом про сравнении двух массивов понять, какие из проектов были удалены
    [_newIssues addObjectsFromArray:[result objectForKey:@"issues"]];
    
    // Проверим, возможно такие проекты уже существуют, если существуют выкинем их, а если существуют и изменялись на сервере, то обновим
    /*NSMutableArray *newIssues = [result objectForKey:@"issues"];
    for (NSDictionary *newIssue in newIssues)
    {
        Issue *oldIssue = [_database issueById:[newIssue objectForKey:@"id"]];
        [self refreshIssue:oldIssue withDictionary:newIssue];
        if (![_database save])
        {
            [self sendEvent:ISSUES_LOADED success:NO];
            return NO;
        }
    }*/
        
    // Если у нас total меньше чем offsef, то делаем рекурсивно вызов на загрузку сл. offseta
    if (offset < [[result objectForKey:@"total_count"] intValue])
    {
        int progress = ((offset * 100)/[[result objectForKey:@"total_count"] intValue]);
        _issuesProgress = progress > 100 ? 100 : progress;
        [self sendEvent:ISSUES_LOADING_PROGRESS progress:_issuesProgress / _shiftLoading];

        offset += 100;
        return [self loadIssuesWithOffset:offset];
    }
    
    return YES;
}

- (void) refreshIssue:(Issue *)issue withDictionary:(NSDictionary *)dictionary
{
    NSString *name = [dictionary objectForKey:@"subject"];
    if (name) issue.name = name;
    
    NSString *text = [dictionary objectForKey:@"description"];
    if (text) issue.text = text;
    
    NSNumber *estimated = [dictionary objectForKey:@"estimated_hours"];
    if (estimated) issue.estimated = estimated;
    
    NSNumber *done = [dictionary objectForKey:@"done_ratio"];
    if (done) issue.done = done;
    
    NSDate *start = [self dateFromString2:[dictionary objectForKey:@"start_date"]];
    if (start) issue.start = start;
    
    NSDate *finish = [self dateFromString2:[dictionary objectForKey:@"due_date"]];
    if (finish) issue.finish = finish;
    
    NSDate *update = [self dateFromString:[dictionary objectForKey:@"updated_on"]];
    if (update) issue.update = update;
    
    NSDate *create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    if (create) issue.create = create;
    
    NSDictionary *object;
    BOOL needSave = NO;
    
    // Version
    object = [dictionary objectForKey:@"version"];
    if (object)
    {
        if (issue.version == nil)
        {
            issue.version = [_database versionById:[object objectForKey:@"id"]];
        }
        issue.version.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.version != nil)
    {
        issue.version = nil;
        needSave = YES;
    }
    
    // Tracker
    object = [dictionary objectForKey:@"tracker"];
    if (object)
    {
        if (issue.tracker == nil)
        {
            issue.tracker = [_database trackerById:[object objectForKey:@"id"]];
        }
        issue.tracker.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.tracker != nil)
    {
        issue.tracker = nil;
        needSave = YES;
    }
    
    // Status
    object = [dictionary objectForKey:@"status"];
    if (object)
    {
        if (issue.status == nil)
        {
            issue.status = [_database statusById:[object objectForKey:@"id"]];
        }
        issue.status.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.status != nil)
    {
        issue.status = nil;
        needSave = YES;
    }
    
    // Priority
    object = [dictionary objectForKey:@"priority"];
    if (object)
    {
        if (issue.priority == nil)
        {
            issue.priority = [_database priorityById:[object objectForKey:@"id"]];
        }
        issue.priority.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.priority != nil)
    {
        issue.priority = nil;
        needSave = YES;
    }
    
    // Author
    object = [dictionary objectForKey:@"author"];
    if (object)
    {
        if (issue.creator == nil)
        {
            issue.creator = [_database userById:[object objectForKey:@"id"]];
        }
        issue.creator.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.creator != nil)
    {
        issue.creator = nil;
        needSave = YES;
    }

    // Assigned to
    object = [dictionary objectForKey:@"assigned_to"];
    if (object)
    {
        if (issue.assigner == nil)
        {
            issue.assigner = [_database userById:[object objectForKey:@"id"]];
        }
        issue.assigner.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.assigner != nil)
    {
        issue.assigner = nil;
        needSave = YES;
    }

    // Parent
    object = [dictionary objectForKey:@"parent"];
    if (object)
    {
        if (issue.parent == nil)
        {
            issue.parent = [_database issueById:[object objectForKey:@"id"]];
        }
        issue.parent.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.parent != nil)
    {
        issue.parent = nil;
        needSave = YES;
    }
    
    // Project
    object = [dictionary objectForKey:@"project"];
    if (object)
    {
        if (issue.project == nil)
        {
            issue.project = [_database projectById:[object objectForKey:@"id"]];
        }
        issue.project.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (issue.project != nil)
    {
        issue.project = nil;
        needSave = YES;
    }
    
    if (needSave == YES)
    {
        if (![_database save])
        {
            NSLog(@"sdfsdf222");
        }
    }
}

#pragma mark - Load Time Entries

/*- (void) loadTimeEntries
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
}*/



@end
