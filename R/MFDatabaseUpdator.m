//
//  MFDatabaseUpdator.m
//  R
//
//  Created by Сергей Ваничкин on 04.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFDatabaseUpdator.h"

@implementation MFDatabaseUpdator
{
    float _deltaProgress;
    float _globalProgress;
    
    BOOL _stop;
    BOOL _finished;
    
    BOOL _error;
    
    NSInteger _projectsTotal;
    NSInteger _issuesTotal;
    int _timeEntriesTotal;
    NSInteger _usersTotal;
    NSInteger _rolesTotal;

    NSArray *_tasks;
    int _indexOfTask;
        
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
    
    _tasks = @[@"loadFilters",
               @"loadProjects",
               @"loadIssues",
               @"loadIssuesDetail",
               @"loadTimeEntries",
               @"loadRoles",
               @"loadUsers" ];
    
    [self next];
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

- (void) next
{
    if (![self checkErrorOrStop])
    {
        if (_indexOfTask < _tasks.count)
        {
            _indexOfTask ++;
            [self performSelector:NSSelectorFromString([_tasks objectAtIndex:_indexOfTask - 1])];
        }
        else
        {
            _settings.dataLastUpdate = [NSDate date];
            [self sendNotificationComplete:YES];
        }
    }
}

- (BOOL) checkErrorOrStop
{
    if (_stop)
    {
        return YES;
    }
    
    if (_error)
    {
        [self sendNotificationComplete:NO];
        return YES;
    }
    
    return NO;
}

// Подсчитывает необходимый шаг в процентах для прогресс бара
- (void) setDeltaProgressWithNumSteps:(float)numSteps
{
    if (numSteps < 1) numSteps = 1;
    
    _deltaProgress = (100.0/numSteps)/_tasks.count;
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
    if ([self checkErrorOrStop])
    {
        return;
    }
    [self sendNotificationProgress];
    if (_stop)
    {
        return;
    }
    
    NSArray *newTrackers   = [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
    if ([self checkErrorOrStop])
    {
        return;
    }
    [self sendNotificationProgress];
    if (_stop)
    {
        return;
    }
    
    NSArray *newPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
    //if ([self checkErrorOrStop])
    if (_error)
    {
        _error = NO;
    }
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
    
    [self next];
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
        _error = YES;
        return nil;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        _error = YES;
        return nil;
    }
    
    return result;
}

#pragma mark - Load Projects

- (void) loadProjects
{
    if ([self checkErrorOrStop])
    {
        return;
    }
    
    // Начинаем загрузку и получаем сколько всего проектов
    if ([self loadProjectsWithOffset:0])
    {
        if ([self checkErrorOrStop])
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
                    if ([self checkErrorOrStop])
                    {
                        return;
                    }
                    
                    [self loadProjectsWithOffset:i];
                    
                    if (i + 100 > _projectsTotal)
                    {
                        [self next];
                    }
                }]];
            }
            
            NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue addOperations:operationsArray waitUntilFinished:YES];
        }
        else
        {
            [self next];
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
            _error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        // Наполняем базу
        NSArray *newProjects = [result objectForKey:@"projects"];
        for (NSDictionary *newProject in newProjects)
        {
            if (_error)
            {
                return NO;
            }
            Project *oldProject = [_database projectById:[newProject objectForKey:@"id"]];
            [self refreshProject:oldProject withDictionaryProject:newProject];
        }
        
        if (![_database save])
        {
            _error = YES;
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

- (void) refreshProject:(Project *)project withDictionaryProject:(NSDictionary *)dictionary
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
            _error = YES;
        }
    }
}

#pragma mark - Load Issues

- (void) loadIssues
{
    if ([self checkErrorOrStop])
    {
        return;
    }
    
    // Начинаем рекурсивную загрузку, если она успешна продолжим
    if ([self loadIssuesWithOffset:0])
    {
        if ([self checkErrorOrStop])
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
                    if ([self checkErrorOrStop])
                    {
                        return;
                    }
                    
                    [self loadIssuesWithOffset:i];
                    
                    if (i + 100 > _issuesTotal)
                    {
                        [self next];
                    }
                }]];
            }
            
            NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue addOperations:operationsArray waitUntilFinished:YES];
        }
        else
        {
            [self next];
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
            _error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _error = YES;
            return NO;
        }
                
        // Наполняем базу
        NSArray *newArray = [result objectForKey:@"issues"];
        for (NSDictionary *newIssue in newArray)
        {
            if (_error)
            {
                return NO;
            }
            Issue *oldIssue = [_database issueById:[newIssue objectForKey:@"id"]];
            [self refreshIssue:oldIssue withDictionaryIssue:newIssue];
        }
        
        if (![_database save])
        {
            _error = YES;
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

- (void) refreshIssue:(Issue *)issue withDictionaryIssue:(NSDictionary *)dictionary
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
    if (issue.creator == nil)
    {
        issue.creator = [_database userById:[object objectForKey:@"id"]];
        
        NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
        if (n.count == 2)
        {
            [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
        }
        
        issue.creator.name = [n componentsJoinedByString:@" "];
        
        needSave = YES;
    }
    
    // Assigned to
    object = [dictionary objectForKey:@"assigned_to"];
    if (object)
    {
        if (issue.assigner == nil)
        {
            issue.assigner = [_database userById:[object objectForKey:@"id"]];
            
            NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
            if (n.count == 2)
            {
                [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
            }
            
            issue.assigner.name = [n componentsJoinedByString:@" "];
            
            needSave = YES;
        }
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
            _error = YES;
        }
    }
}

- (void) loadIssuesDetail
{
    if ([self checkErrorOrStop])
    {
        return;
    }
    
    _issuesTotal = _database.issues.count;
    if (_issuesTotal)
    {
        [self setDeltaProgressWithNumSteps:_issuesTotal];
        
        if ([self checkErrorOrStop])
        {
            return;
        }
        
        NSMutableArray *operationsArray = [NSMutableArray array];
        
        int i = 0;
        for (Issue *issue in _database.issues)
        {
            i ++;
            
            [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
            {
                if ([self checkErrorOrStop])
                {
                    return;
                }
                
                [self loadIssueDetailWithIssue:issue];
                
                if (i == _issuesTotal)
                {
                    [self next];
                }
            }]];
        }
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue addOperations:operationsArray waitUntilFinished:YES];
    }
    else
    {
        [self next];
    }
}

- (BOOL) loadIssueDetailWithIssue:(Issue *)issue
{
    @autoreleasepool
    {
        // Грузим юзеров рекурсивно
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/issues/%@.json?include=children,attachments,relations,changesets,journals,watchers&key=%@", [MFSettings sharedInstance].server, issue.nid, _settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        // Наполняем базу
        [self refreshIssue:issue withDictionaryIssueDetail:[result objectForKey:@"issue"]];
        
        if (_error)
        {
            return NO;
        }
        
        [self sendNotificationProgress];
        
        return YES;
    }
}

- (void) refreshIssue:(Issue *)issue withDictionaryIssueDetail:(NSDictionary *)dictionary
{
    NSNumber *spent = [dictionary objectForKey:@"spent_hours"];
    if (spent) issue.spent = spent;
    
    BOOL needSave = NO;
    
    // Journals
    NSArray *journals = [dictionary objectForKey:@"journals"];
    if (journals.count)
    {
        for (NSDictionary *journal in journals)
        {
            [issue addJournalsObject:[self newJournalByDictionary:journal]];
        }
        needSave = YES;
    }
    
    // Attachments
    NSArray *attachments = [dictionary objectForKey:@"attachments"];
    if (attachments.count)
    {
        for (NSDictionary *attach in attachments)
        {
            [issue addAttachmentsObject:[self newAttachByDictionary:attach]];
        }
        needSave = YES;
    }
    
    // Relations
    NSArray *relations = [dictionary objectForKey:@"relations"];
    if (relations.count)
    {
        for (NSDictionary *relation in relations)
        {
            [issue addRelationsObject:[self newRelationByDictionary:relation]];
        }
        needSave = YES;
    }
    
    if (needSave == YES)
    {
        if(![_database save])
        {
            _error = YES;
        }
    }
}

- (Attach *) newAttachByDictionary:(NSDictionary *)dictionary
{
    Attach *attach = _database.attach;
    attach.nid    = [dictionary objectForKey:@"id"];
    attach.name   = [dictionary objectForKey:@"filename"];
    attach.size   = [dictionary objectForKey:@"filesize"];
    attach.type   = [dictionary objectForKey:@"content_type"];
    attach.text   = [dictionary objectForKey:@"description"];
    attach.url    = [dictionary objectForKey:@"content_url"];
    attach.create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    
    // Author
    NSDictionary *object = [dictionary objectForKey:@"author"];
    if (attach.creator == nil)
    {
        attach.creator = [_database userById:[object objectForKey:@"id"]];
        
        NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
        if (n.count == 2)
        {
            [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
        }
        
        attach.creator.name = [n componentsJoinedByString:@" "];
    }
    
    return attach;
}

- (Journal *) newJournalByDictionary:(NSDictionary *)dictionary
{
    Journal *journal = _database.journal;
    journal.nid    = [dictionary objectForKey:@"id"];
    journal.text   = [dictionary objectForKey:@"notes"];
    journal.create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    
    // Details
    NSArray *details = [dictionary objectForKey:@"details"];
    for (NSDictionary *detail in details)
    {
        Detail *newDetail = _database.detail;
        newDetail.property = [detail objectForKey:@"property"];
        if ([newDetail.property isEqualToString:@"attr"])
        {
            NSString *name = [detail objectForKey:@"name"];
            if ([name isEqualToString:@"tracker_id"])
            {
                newDetail.name = [detail objectForKey:@"tracker"];
            }
            else if ([name isEqualToString:@"subject"])
            {
                newDetail.name = [detail objectForKey:@"text"];
            }
            else if ([name isEqualToString:@"due_date"])
            {
                newDetail.name = [detail objectForKey:@"finish"];
            }
            else if ([name isEqualToString:@"status_id"])
            {
                newDetail.name = [detail objectForKey:@"status"];
            }
            else if ([name isEqualToString:@"assigned_to_id"])
            {
                newDetail.name = [detail objectForKey:@"assigner"];
            }
            else if ([name isEqualToString:@"priority_id"])
            {
                newDetail.name = [detail objectForKey:@"priority"];
            }
            else if ([name isEqualToString:@"fixed_version_id"])
            {
                newDetail.name = [detail objectForKey:@"version"];
            }
            else if ([name isEqualToString:@"start_date"])
            {
                newDetail.name = [detail objectForKey:@"start"];
            }
            else if ([name isEqualToString:@"done_ratio"])
            {
                newDetail.name = [detail objectForKey:@"done"];
            }
            else if ([name isEqualToString:@"estimated_hours"])
            {
                newDetail.name = [detail objectForKey:@"estimated"];
            }
        }
        newDetail.newValue = [detail objectForKey:@"new_value"];
        newDetail.oldValue = [detail objectForKey:@"old_value"];
        
        [journal addDetailsObject:newDetail];
    }
    
    return journal;
}

- (Relation *) newRelationByDictionary:(NSDictionary *)dictionary
{
    Relation *relation = _database.relation;
    relation.nid     = [dictionary objectForKey:@"id"];
    relation.type    = [dictionary objectForKey:@"relation_type"];
    relation.delay   = [dictionary objectForKey:@"delay"];
    relation.issue   = [dictionary objectForKey:@"issue_id"];
    relation.text    = [dictionary objectForKey:@"notes"];
    relation.create  = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    
    return relation;
}

#pragma mark - Load Time Entries

- (void) loadTimeEntries
{
    if ([self checkErrorOrStop])
    {
        return;
    }
    
    // Начинаем рекурсивную загрузку, если она успешна продолжим
    if ([self loadTimeEntryWithOffset:0])
    {
        if ([self checkErrorOrStop])
        {
            return;
        }
            
        if (_timeEntriesTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < _timeEntriesTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if (_stop)
                    {
                        return;
                    }
                    
                    [self loadTimeEntryWithOffset:i];
                    
                    if (i + 100 > _timeEntriesTotal)
                    {
                        [self next];
                    }
                }]];
            }
            
            NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue addOperations:operationsArray waitUntilFinished:YES];
        }
        else
        {
            [self next];
        }
    }
}

- (BOOL) loadTimeEntryWithOffset:(int)offset
{
    @autoreleasepool
    {
        // Грузим задачи рекурсивно
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/time_entries.json?ilimit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, _settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        // Наполняем базу
        NSArray *newArray = [result objectForKey:@"time_entries"];
        for (NSDictionary *newTimeEntry in newArray)
        {
            if (_error)
            {
                return NO;
            }
            TimeEntry *oldTimeEntry = [_database timeEntryById:[newTimeEntry objectForKey:@"id"]];
            [self refreshTimeEntry:oldTimeEntry withDictionaryTimeEntry:newTimeEntry];
        }
        
        if (![_database save])
        {
            _error = YES;
            return NO;
        }
        
        _timeEntriesTotal = [[result objectForKey:@"total_count"] intValue];
        
        if (!_timeEntriesTotal)
        {
            _timeEntriesTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:_timeEntriesTotal/100];
        }
        
        [self sendNotificationProgress];
        
        return YES;
    }
}

- (void) refreshTimeEntry:(TimeEntry *)timeEntry withDictionaryTimeEntry:(NSDictionary *)dictionary
{
    NSString *text = [dictionary objectForKey:@"comments"];
    if (text) timeEntry.text = text;
    
    NSNumber *hours = [dictionary objectForKey:@"hours"];
    if (hours) timeEntry.hours = hours;
    
    NSDate *update = [self dateFromString:[dictionary objectForKey:@"updated_on"]];
    if (update) timeEntry.update = update;
    
    NSDate *create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    if (create) timeEntry.create = create;
    
    NSDictionary *object;
    BOOL needSave = NO;
    
    // Project
    object = [dictionary objectForKey:@"project"];
    if (object)
    {
        if (timeEntry.project == nil)
        {
            timeEntry.project = [_database projectById:[object objectForKey:@"id"]];
        }
        timeEntry.project.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (timeEntry.project != nil)
    {
        timeEntry.project = nil;
        needSave = YES;
    }

    // Issue
    object = [dictionary objectForKey:@"issue"];
    if (object)
    {
        if (timeEntry.issue == nil)
        {
            timeEntry.issue = [_database issueById:[object objectForKey:@"id"]];
        }
        needSave = YES;
    }
    else if (timeEntry.issue != nil)
    {
        timeEntry.issue = nil;
        needSave = YES;
    }
        
    // Activity
    object = [dictionary objectForKey:@"activity"];
    if (object)
    {
        if (timeEntry.activity == nil)
        {
            timeEntry.activity = [_database activityById:[object objectForKey:@"id"]];
        }
        timeEntry.activity.name = [object objectForKey:@"name"];
        needSave = YES;
    }
    else if (timeEntry.activity != nil)
    {
        timeEntry.activity = nil;
        needSave = YES;
    }
    
    // User
    object = [dictionary objectForKey:@"user"];
    if (timeEntry.creator == nil)
    {
        timeEntry.creator = [_database userById:[object objectForKey:@"id"]];
        
        NSMutableArray *n = [NSMutableArray arrayWithArray:[[object objectForKey:@"name"] componentsSeparatedByString:@","]];
        if (n.count == 2)
        {
            [n exchangeObjectAtIndex:0 withObjectAtIndex:1];
        }
        
        timeEntry.creator.name = [n componentsJoinedByString:@" "];
        
        needSave = YES;
    }
    
    if (needSave == YES)
    {
        if(![_database save])
        {
            _error = YES;
        }
    }
}

#pragma mark - Load Users

- (void) loadUsers
{
    if ([self checkErrorOrStop])
    {
        return;
    }
    
    _usersTotal = _database.users.count;
    if (_usersTotal)
    {
        [self setDeltaProgressWithNumSteps:_usersTotal];
        
        if ([self checkErrorOrStop])
        {
            return;
        }
        
        NSMutableArray *operationsArray = [NSMutableArray array];
        
        int i = 0;
        for (User *user in _database.users)
        {
            i ++;
            
            [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
            {
                if ([self checkErrorOrStop])
                {
                    return;
                }
                
                [self loadUserWithUserEntity:user];
                
                if (i == _usersTotal)
                {
                    [self next];
                }
            }]];
        }
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue addOperations:operationsArray waitUntilFinished:YES];
    }
    else
    {
        [self next];
    }
}

- (BOOL) loadUserWithUserEntity:(User *)user
{
    @autoreleasepool
    {
        // Грузим юзеров рекурсивно
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json?include=memberships,groups&key=%@", [MFSettings sharedInstance].server, user.nid, _settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            _error = YES;
            return NO;
        }
        
        // Наполняем базу
        [self refreshUser:user withDictionaryUser:[result objectForKey:@"user"]];
        
        if (_error)
        {
            return NO;
        }
        
        [self sendNotificationProgress];
        
        return YES;
    }
}

- (void) refreshUser:(User *)user withDictionaryUser:(NSDictionary *)dictionary
{
    NSString *name = [dictionary objectForKey:@"name"];
    if (name) user.name = name;
    
    NSString *firstname = [dictionary objectForKey:@"firstname"];
    if (firstname) user.firstname = firstname;
    
    NSString *lastname = [dictionary objectForKey:@"lastname"];
    if (lastname) user.lastname = lastname;
    
    NSString *mail = [dictionary objectForKey:@"mail"];
    if (mail) user.mail = mail;

    NSDate *lastLogin = [self dateFromString:[dictionary objectForKey:@"last_login_on"]];
    if (lastLogin) user.lastLogin = lastLogin;
    
    NSDate *create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    if (create) user.create = create;
    
    // Custom fields
    NSArray *customFields = [dictionary objectForKey:@"custom_fields"];

    BOOL skypeField;
    BOOL phoneField;
    
    for (NSDictionary *object in customFields)
    {
        if ([[object objectForKey:@"name"] isEqualToString:@"Skype"])
        {
            skypeField = YES;
            user.skype = [object objectForKey:@"value"];
        }
        else if ([[object objectForKey:@"name"] isEqualToString:@"Phone"])
        {
            phoneField = YES;
            user.phone = [object objectForKey:@"value"];
        }
    }
    
    // Memberships
    NSArray *memberships = [dictionary objectForKey:@"memberships"];
    for (NSDictionary *object in memberships)
    {
        Membership *membership = _database.membership;
        membership.nid = [object objectForKey:@"id"];

        membership.project = [_database projectById:[[object objectForKey:@"project"]objectForKey:@"id"]];
        
        NSArray *roles = [object objectForKey:@"roles"];
        for (NSDictionary *nr in roles)
        {
            Role *role = [_database roleById:[nr objectForKey:@"id"]];
            role.name = [nr objectForKey:@"name"];
            [membership addRolesObject:role];
        }
    }
    
    if (!skypeField)
    {
        user.skype = nil;
    }
    
    if (!phoneField)
    {
        user.phone = nil;
    }
    
    if(![_database save])
    {
        _error = YES;
    }
}

#pragma mark - Load Roles

- (void) loadRoles
{
    // Всего 4 шага, ставим вручную
    [self setDeltaProgressWithNumSteps:2];
    
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/roles.json?key=%@", [MFSettings sharedInstance].server, _settings.apiToken]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    if (error)
    {
        _error = YES;
        [self checkErrorOrStop];
        return;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    NSArray *roles = [result objectForKey:@"roles"];
    
    if (error)
    {
        _error = YES;
        [self checkErrorOrStop];
        return;
    }
    
    if (roles)
    {
        for (NSDictionary *nr in roles)
        {
            Role *role = _database.role;
            role.name = [nr objectForKey:@"name"];
            role.nid  = [nr objectForKey:@"id"];
        }
        
        if(![_database save])
        {
            _error = YES;
            [self checkErrorOrStop];
            return;
        }
    }
    
    [self sendNotificationProgress];
    
    [self next];
}

#pragma mark - Memory Management

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end