//
//  MFDatabaseUpdator.m
//  R
//
//  Created by Сергей Ваничкин on 04.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFDatabaseUpdator.h"

#define NUM_OF_TASKS 3.0

@implementation MFDatabaseUpdator
{
    float _deltaProgress;
    float _globalProgress;
    
    BOOL _stop;
    BOOL _finished;
    
    int _projectsTotal;
    BOOL _projectsError;
    
    int _issuesTotal;
    BOOL _issuesError;
    
    MFDatabase *_database;
    MFSettings *_settings;
}

- (void) update
{
    _database = [MFDatabase sharedInstance];
    _settings = [MFSettings sharedInstance];
    
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
    
    _stop = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_START
                                                        object:nil];
    
    
    [self loadFilters];
}

- (void) resetData
{
    _stop = YES;
    _finished = YES;
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

// Подсчитывает необходимый шаг в процентах для прогресс бара
- (void) setDeltaProgressWithNumSteps:(float)numSteps
{
    if (numSteps < 1) numSteps = 1;
    
    _deltaProgress = (100.0/numSteps)/NUM_OF_TASKS;
}

- (void) sendNotificationProgress
{
    _globalProgress += _deltaProgress;
    
    if (_globalProgress > 100)
    {
        _globalProgress = 100;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_PROGRESS
                                                            object:@(_globalProgress)];
    });
}

- (void) sendNotificationComplete:(BOOL)complete
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_COMPLETE
                                                            object:@(complete)];
    });
}

#pragma mark - Load settings

- (void) loadFilters
{
    // Всего 4 шага, ставим вручную
    [self setDeltaProgressWithNumSteps:4];
    
    NSArray *newStatuses   = [[self loadFilterByPath:@"issue_statuses.json"] objectForKey:@"issue_statuses"];
    [self sendNotificationProgress];
    if (_stop)
    {
        return;
    }
    
    NSArray *newTrackers   = [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
    [self sendNotificationProgress];
    if (_stop)
    {
        return;
    }
    
    NSArray *newPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
    [self sendNotificationProgress];
    if (_stop)
    {
        return;
    }
            
    if (newStatuses)
    {
        for (NSDictionary *ns in newStatuses)
        {
            Status *status = _database.status;
            status.name = [ns objectForKey:@"name"];
            status.nid  = [ns objectForKey:@"id"];
        }
    }
    
    if (newTrackers)
    {
        for (NSDictionary *t in newTrackers)
        {
            Tracker *tracker = _database.tracker;
            tracker.name = [t objectForKey:@"name"];
            tracker.nid  = [t objectForKey:@"id"];
        }
    }
    
    if (newPriorities)
    {
        for (NSDictionary *p in newPriorities)
        {
            Priority *priority = _database.priority;
            priority.name = [p objectForKey:@"name"];
            priority.nid  = [p objectForKey:@"id"];
        }
    }
    
    if (newStatuses || newTrackers || newPriorities)
    {
        [_database save];
    }
 
    [self sendNotificationProgress];
    
    [self loadProjects];
}

- (NSDictionary *) loadFilterByPath:(NSString *)path
{
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?key=%@", [MFSettings sharedInstance].server, path, _settings.apiToken]];
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
    if (_stop)
    {
        return;
    }
    
    // Начинаем загрузку и получаем сколько всего проектов
    if ([self loadProjectsWithOffset:0])
    {
        if (_stop)
        {
            return;
        }
        
        if (_projectsTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < _projectsTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if (_stop)
                    {
                        return;
                    }
                    
                    [self loadProjectsWithOffset:i];
                    
                    if (i + 100 > _projectsTotal)
                    {
                        [self loadIssues];
                    }
                }]];
            }
            
            NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue addOperations:operationsArray waitUntilFinished:YES];
        }
        else
        {
            if (_projectsError)
            {
                [self sendNotificationComplete:NO];
            }
            else
            {
                [self loadIssues];
            }
        }
    }
}

- (BOOL) loadProjectsWithOffset:(int)offset
{
    @autoreleasepool
    {
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/projects.json?limit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, _settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            _projectsError = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _projectsError = YES;
            return NO;
        }
        
        // Наполняем базу
        NSArray *newProjects = [result objectForKey:@"projects"];
        for (NSDictionary *newProject in newProjects)
        {
            if (_projectsError)
            {
                return NO;
            }
            Project *oldProject = [_database projectById:[newProject objectForKey:@"id"]];
            [self refreshProject:oldProject withDictionary:newProject];            
        }
        
        if (![_database save])
        {
            _projectsError = YES;
            return NO;
        }
        
        if (!_projectsTotal)
        {
            _projectsTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:_projectsTotal/100];
        }
        
        [self sendNotificationProgress];
        
        return YES;
    }
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
            _projectsError = YES;
        }
    }
}

#pragma mark - Load Issues

- (void) loadIssues
{
    if (_stop)
    {
        return;
    }
    
    // Начинаем рекурсивную загрузку, если она успешна продолжим
    if ([self loadIssuesWithOffset:0])
    {
        if (_stop)
        {
            return;
        }
        
        if (_issuesTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < _issuesTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if (_stop)
                    {
                        return;
                    }
                    
                    [self loadIssuesWithOffset:i];
                    
                    if (i + 100 > _issuesTotal)
                    {
                        _settings.dataLastUpdate = [NSDate date];
                        [self sendNotificationComplete:YES];
                    }
                }]];
            }
            
            NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue addOperations:operationsArray waitUntilFinished:YES];
        }
        else
        {
            if (_issuesError)
            {
                [self sendNotificationComplete:NO];
            }
            else
            {
                _settings.dataLastUpdate = [NSDate date];
                [self sendNotificationComplete:YES];
            }
        }
    }
}

- (BOOL) loadIssuesWithOffset:(int)offset
{
    @autoreleasepool
    {
        // Грузим задачи рекурсивно
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/issues.json?status_id=*&ilimit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, _settings.apiToken]];        
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            _issuesError = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _issuesError = YES;
            return NO;
        }
                
        // Наполняем базу
        NSArray *newArray = [result objectForKey:@"issues"];
        for (NSDictionary *newIssue in newArray)
        {
            if (_issuesError)
            {
                return NO;
            }
            Issue *oldIssue = [_database issueById:[newIssue objectForKey:@"id"]];
            [self refreshIssue:oldIssue withDictionary:newIssue];
        }
        
        if (![_database save])
        {
            _issuesError = YES;
            return NO;
        }
        
        _issuesTotal = [[result objectForKey:@"total_count"] intValue];
        
        if (!_issuesTotal)
        {
            _issuesTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:_issuesTotal/100];
        }
        
        [self sendNotificationProgress];
        
        return YES;
    }
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
    object = [dictionary objectForKey:@"fixed_version"];
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
        
        NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
        if (n.count == 2)
        {
            [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
        }
        
        issue.creator.name = [n componentsJoinedByString:@" "];
        
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
        
        NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
        if (n.count == 2)
        {
            [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
        }
        
        issue.assigner.name = [n componentsJoinedByString:@" "];
        
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
        if(![_database save])
        {
            _issuesError = YES;
        }
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end