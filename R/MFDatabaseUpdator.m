//
//  MFDatabaseUpdator.m
//  R
//
//  Created by Сергей Ваничкин on 04.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFDatabaseUpdator.h"

@interface MFDatabaseUpdator ()

@property (assign, nonatomic) CGFloat deltaProgress;
@property (assign, nonatomic) CGFloat globalProgress;

@property (assign, nonatomic) BOOL stop;
@property (assign, nonatomic) BOOL finished;

@property (assign, nonatomic) BOOL error;

@property (assign, nonatomic) NSInteger projectsTotal;
@property (assign, nonatomic) NSInteger issuesTotal;
@property (assign, nonatomic) NSInteger timeEntriesTotal;
@property (assign, nonatomic) NSInteger usersTotal;
@property (assign, nonatomic) NSInteger rolesTotal;

@property (strong, nonatomic) NSArray *tasks;
@property (assign, nonatomic) NSInteger indexOfTask;

@property (assign, nonatomic) MFDatabase *database;
@property (assign, nonatomic) MFSettings *settings;

@end

@implementation MFDatabaseUpdator

- (void) update
{
    self.database = [MFDatabase sharedInstance];
    self.settings = [MFSettings sharedInstance];
    
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
    
    self.stop = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_START
                                                        object:nil];
    
    self.tasks = @[@"loadFilters",
                   @"loadProjects",
                   @"loadIssues",
                   @"loadIssuesDetail",
                   @"loadTimeEntries",
                   @"loadRoles",
                   @"loadUsers"];
    
    [self next];
}

- (void) resetData
{
    self.stop = YES;
    self.finished = YES;
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
    if (![self checkForCancel])
    {
        if (self.indexOfTask < self.tasks.count)
        {
            self.indexOfTask ++;
            [self performSelector:NSSelectorFromString([self.tasks objectAtIndex:self.indexOfTask - 1])];
        }
        else
        {
            self.settings.dataLastUpdate = [NSDate date];
            [self sendNotificationComplete:YES];
        }
    }
}

- (BOOL) checkForCancel
{
    if (self.stop)
    {
        return YES;
    }
    
    if (self.error)
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
    
    self.deltaProgress = (100.0/numSteps)/self.tasks.count;
}

- (void) sendNotificationProgress
{
    self.globalProgress += self.deltaProgress;
    
    if (self.globalProgress > 100)
    {
        self.globalProgress = 100;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATING_PROGRESS
                                                            object:@(self.globalProgress)];
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
    if ([self checkForCancel])
    {
        return;
    }
    [self sendNotificationProgress];
    if (self.stop)
    {
        return;
    }
    
    NSArray *newTrackers   = [[self loadFilterByPath:@"trackers.json"] objectForKey:@"trackers"];
    if ([self checkForCancel])
    {
        return;
    }
    [self sendNotificationProgress];
    if (self.stop)
    {
        return;
    }
    
    NSArray *newPriorities = [[self loadFilterByPath:@"enumerations/issue_priorities.json"] objectForKey:@"issue_priorities"];
    if (self.error)
    {
        self.error = NO;
    }
    [self sendNotificationProgress];
    if (self.stop)
    {
        return;
    }
            
    if (newStatuses)
    {
        for (NSDictionary *ns in newStatuses)
        {
            Status *status = self.database.status;
            status.name = [ns objectForKey:@"name"];
            status.nid  = [ns objectForKey:@"id"];
        }
    }
    
    if (newTrackers)
    {
        for (NSDictionary *t in newTrackers)
        {
            Tracker *tracker = self.database.tracker;
            tracker.name = [t objectForKey:@"name"];
            tracker.nid  = [t objectForKey:@"id"];
        }
    }
    
    if (newPriorities)
    {
        for (NSDictionary *p in newPriorities)
        {
            Priority *priority = self.database.priority;
            priority.name = [p objectForKey:@"name"];
            priority.nid  = [p objectForKey:@"id"];
        }
    }
    
    if (newStatuses || newTrackers || newPriorities)
    {
        [self.database save];
    }
 
    [self sendNotificationProgress];
    
    [self next];
}

- (NSDictionary *) loadFilterByPath:(NSString *)path
{
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?key=%@", [MFSettings sharedInstance].server, path, self.settings.apiToken]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    if (error)
    {
        self.error = YES;
        return nil;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error)
    {
        self.error = YES;
        return nil;
    }
    
    return result;
}

#pragma mark - Load Projects

- (void) loadProjects
{
    if ([self checkForCancel])
    {
        return;
    }
    
    // Начинаем загрузку и получаем сколько всего проектов
    if ([self loadProjectsWithOffset:0])
    {
        if ([self checkForCancel])
        {
            return;
        }
        
        if (self.projectsTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < self.projectsTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if ([self checkForCancel])
                    {
                        return;
                    }
                    
                    [self loadProjectsWithOffset:i];
                    
                    if (i + 100 > self.projectsTotal)
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
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/projects.json?limit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, self.settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        // Наполняем базу
        NSArray *newProjects = [result objectForKey:@"projects"];
        for (NSDictionary *newProject in newProjects)
        {
            if (self.error)
            {
                return NO;
            }
            Project *oldProject = [self.database projectById:[newProject objectForKey:@"id"]];
            [self refreshProject:oldProject withDictionaryProject:newProject];
        }
        
        if (![self.database save])
        {
            self.error = YES;
            return NO;
        }
        
        if (!self.projectsTotal)
        {
            self.projectsTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:self.projectsTotal/100];
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
            project.parent = [self.database projectById:[object objectForKey:@"id"]];
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
        if (![self.database save])
        {
            self.error = YES;
        }
    }
}

#pragma mark - Load Issues

- (void) loadIssues
{
    if ([self checkForCancel])
    {
        return;
    }
    
    // Начинаем рекурсивную загрузку, если она успешна продолжим
    if ([self loadIssuesWithOffset:0])
    {
        if ([self checkForCancel])
        {
            return;
        }
        
        if (self.issuesTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < self.issuesTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if ([self checkForCancel])
                    {
                        return;
                    }
                    
                    [self loadIssuesWithOffset:i];
                    
                    if (i + 100 > self.issuesTotal)
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
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/issues.json?status_id=*&ilimit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, self.settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            self.error = YES;
            return NO;
        }
                
        // Наполняем базу
        NSArray *newArray = [result objectForKey:@"issues"];
        for (NSDictionary *newIssue in newArray)
        {
            if (self.error)
            {
                return NO;
            }
            Issue *oldIssue = [self.database issueById:[newIssue objectForKey:@"id"]];
            [self refreshIssue:oldIssue withDictionaryIssue:newIssue];
        }
        
        if (![self.database save])
        {
            self.error = YES;
            return NO;
        }
        
        self.issuesTotal = [[result objectForKey:@"total_count"] intValue];
        
        if (!self.issuesTotal)
        {
            self.issuesTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:self.issuesTotal/100];
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
            issue.version = [self.database versionById:[object objectForKey:@"id"]];
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
            issue.tracker = [self.database trackerById:[object objectForKey:@"id"]];
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
            issue.status = [self.database statusById:[object objectForKey:@"id"]];
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
            issue.priority = [self.database priorityById:[object objectForKey:@"id"]];
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
        issue.creator = [self.database userById:[object objectForKey:@"id"]];
        
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
            issue.assigner = [self.database userById:[object objectForKey:@"id"]];
            
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
            issue.parent = [self.database issueById:[object objectForKey:@"id"]];
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
            issue.project = [self.database projectById:[object objectForKey:@"id"]];
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
        if(![self.database save])
        {
            self.error = YES;
        }
    }
}

- (void) loadIssuesDetail
{
    if ([self checkForCancel])
    {
        return;
    }
    
    self.issuesTotal = self.database.issues.count;
    if (_issuesTotal)
    {
        [self setDeltaProgressWithNumSteps:self.issuesTotal];
        
        if ([self checkForCancel])
        {
            return;
        }
        
        NSMutableArray *operationsArray = [NSMutableArray array];
        
        int i = 0;
        for (Issue *issue in self.database.issues)
        {
            i ++;
            
            [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
            {
                if ([self checkForCancel])
                {
                    return;
                }
                
                [self loadIssueDetailWithIssue:issue];
                
                if (i == self.issuesTotal)
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
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/issues/%@.json?include=children,attachments,relations,changesets,journals,watchers&key=%@", [MFSettings sharedInstance].server, issue.nid, self.settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        // Наполняем базу
        [self refreshIssue:issue withDictionaryIssueDetail:[result objectForKey:@"issue"]];
        
        if (self.error)
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
    
    Issue *i = [self.database issueById:issue.nid];
    
    // Journals
    NSArray *journals = [dictionary objectForKey:@"journals"];
    if (journals.count)
    {
        for (NSDictionary *journal in journals)
        {
            [i addJournalsObject:[self newJournalByDictionary:journal]];
        }
        needSave = YES;
    }
    
    // Attachments
    NSArray *attachments = [dictionary objectForKey:@"attachments"];
    if (attachments.count)
    {
        for (NSDictionary *attach in attachments)
        {
            [i addAttachmentsObject:[self newAttachByDictionary:attach]];
        }
        needSave = YES;
    }
    
    // Relations
    NSArray *relations = [dictionary objectForKey:@"relations"];
    if (relations.count)
    {
        for (NSDictionary *relation in relations)
        {
            [i addRelationsObject:[self newRelationByDictionary:relation]];
        }
        needSave = YES;
    }
    
    if (needSave == YES)
    {
        if(![_database save])
        {
            self.error = YES;
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
        attach.creator = [self.database userById:[object objectForKey:@"id"]];
        
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
    Journal *journal = self.database.journal;
    journal.nid    = [dictionary objectForKey:@"id"];
    journal.text   = [dictionary objectForKey:@"notes"];
    journal.create = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    
    // Details
    NSArray *details = [dictionary objectForKey:@"details"];
    for (NSDictionary *detail in details)
    {
        Detail *newDetail = self.database.detail;
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
    Relation *relation = self.database.relation;
    relation.nid     = [dictionary objectForKey:@"id"];
    relation.type    = [dictionary objectForKey:@"relation_type"];
    if ([dictionary objectForKey:@"delay"] != [NSNull null])
    {
        relation.delay = [dictionary objectForKey:@"delay"];
    }
    relation.issueId = [dictionary objectForKey:@"issue_id"];
    relation.text    = [dictionary objectForKey:@"notes"];
    relation.create  = [self dateFromString:[dictionary objectForKey:@"created_on"]];
    
    return relation;
}

#pragma mark - Load Time Entries

- (void) loadTimeEntries
{
    if ([self checkForCancel])
    {
        return;
    }
    
    // Начинаем рекурсивную загрузку, если она успешна продолжим
    if ([self loadTimeEntryWithOffset:0])
    {
        if ([self checkForCancel])
        {
            return;
        }
            
        if (self.timeEntriesTotal > 100)
        {
            NSMutableArray *operationsArray = [NSMutableArray array];
            
            for (int i = 100; i < self.timeEntriesTotal; i += 100)
            {
                [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
                {
                    if (self.stop)
                    {
                        return;
                    }
                    
                    [self loadTimeEntryWithOffset:i];
                    
                    if (i + 100 > self.timeEntriesTotal)
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
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/time_entries.json?ilimit=100&offset=%i&key=%@", [MFSettings sharedInstance].server, offset, self.settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        // Наполняем базу
        NSArray *newArray = [result objectForKey:@"time_entries"];
        for (NSDictionary *newTimeEntry in newArray)
        {
            if (self.error)
            {
                return NO;
            }
            TimeEntry *oldTimeEntry = [self.database timeEntryById:[newTimeEntry objectForKey:@"id"]];
            [self refreshTimeEntry:oldTimeEntry withDictionaryTimeEntry:newTimeEntry];
        }
        
        if (![self.database save])
        {
            self.error = YES;
            return NO;
        }
        
        self.timeEntriesTotal = [[result objectForKey:@"total_count"] intValue];
        
        if (!self.timeEntriesTotal)
        {
            self.timeEntriesTotal = [[result objectForKey:@"total_count"] intValue];
            [self setDeltaProgressWithNumSteps:self.timeEntriesTotal/100];
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
            timeEntry.project = [self.database projectById:[object objectForKey:@"id"]];
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
            timeEntry.issue = [self.database issueById:[object objectForKey:@"id"]];
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
            timeEntry.activity = [self.database activityById:[object objectForKey:@"id"]];
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
        timeEntry.creator = [self.database userById:[object objectForKey:@"id"]];
        
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
        if(![self.database save])
        {
            self.error = YES;
        }
    }
}

#pragma mark - Load Users

- (void) loadUsers
{
    if ([self checkForCancel])
    {
        return;
    }
    
    self.usersTotal = self.database.users.count;
    if (self.usersTotal)
    {
        [self setDeltaProgressWithNumSteps:self.usersTotal];
        
        if ([self checkForCancel])
        {
            return;
        }
        
        NSMutableArray *operationsArray = [NSMutableArray array];
        
        int i = 0;
        for (User *user in self.database.users)
        {
            i ++;
            
            [operationsArray addObject:[NSBlockOperation blockOperationWithBlock: ^
            {
                if ([self checkForCancel])
                {
                    return;
                }
                
                [self loadUserWithUserEntity:user];
                
                if (i == self.usersTotal)
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
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json?include=memberships,groups&key=%@", [MFSettings sharedInstance].server, user.nid, self.settings.apiToken]];
        NSData *jsonData = [NSData dataWithContentsOfURL:url
                                                 options:NSDataReadingUncached
                                                   error:&error];
        
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error)
        {
            self.error = YES;
            return NO;
        }
        
        // Наполняем базу
        [self refreshUser:user withDictionaryUser:[result objectForKey:@"user"]];
        
        if (self.error)
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
        Membership *membership = self.database.membership;
        membership.nid = [object objectForKey:@"id"];

        membership.project = [self.database projectById:[[object objectForKey:@"project"]objectForKey:@"id"]];
        
        NSArray *roles = [object objectForKey:@"roles"];
        for (NSDictionary *nr in roles)
        {
            Role *role = [self.database roleById:[nr objectForKey:@"id"]];
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
    
    if(![self.database save])
    {
        self.error = YES;
    }
}

#pragma mark - Load Roles

- (void) loadRoles
{
    // Всего 4 шага, ставим вручную
    [self setDeltaProgressWithNumSteps:2];
    
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/roles.json?key=%@", [MFSettings sharedInstance].server, self.settings.apiToken]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];
    if (error)
    {
        self.error = YES;
        [self checkForCancel];
        return;
    }
    
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    NSArray *roles = [result objectForKey:@"roles"];
    
    if (error)
    {
        self.error = YES;
        [self checkForCancel];
        return;
    }
    
    [self sendNotificationProgress];
    
    if (roles)
    {
        for (NSDictionary *nr in roles)
        {
            Role *role = self.database.role;
            role.name = [nr objectForKey:@"name"];
            role.nid  = [nr objectForKey:@"id"];
        }
        
        if(![self.database save])
        {
            self.error = YES;
            [self checkForCancel];
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