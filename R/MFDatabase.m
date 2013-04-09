//
//  MFDatabase.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFDatabase.h"
#import "MFAppDelegate.h"

#define PROJECT_ENTITY      @"Project"
#define ISSUE_ENTITY        @"Issue"
#define TIME_ENTRY_ENTITY   @"TimeEntry"
#define VERSION_ENTITY      @"Version"
#define USER_ENTITY         @"User"

#define TRACKER_ENTITY      @"Tracker"
#define STATUS_ENTITY       @"Status"
#define PRIORITY_ENTITY     @"Priority"
#define ACTIVITY_ENTITY     @"Activity"

@implementation MFDatabase
{
    NSMutableDictionary *_managedObjectContexts;
}

+ (MFDatabase *)sharedInstance
{
	static dispatch_once_t pred;
	static MFDatabase *shared = nil;
	
	dispatch_once(&pred, ^ { shared = [[self alloc] init]; });
    
    return shared;
}

- (id)init
{
    if ((self = [super init]) != nil)
    {
        _managedObjectContexts = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(threadExit)
                                                     name:NSThreadWillExitNotification
                                                   object:nil];
        
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

#pragma mark - Work With Contexts

- (void)threadExit
{
    NSString *threadKey = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    
    [_managedObjectContexts removeObjectForKey:threadKey];
}

- (NSManagedObjectContext *) managedObjectContext
{
    MFAppDelegate *appController = [[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [appController managedObjectContext];
    
    NSThread *thread = [NSThread currentThread];
    
    if ([thread isMainThread])
    {
        [moc setUndoManager:nil];
        return moc;
    }
    
    // a key to cache the context for the given thread
    NSString *threadKey = [NSString stringWithFormat:@"%p", thread];
    
    if ([_managedObjectContexts objectForKey:threadKey] == nil)
    {
        // create a context for this thread
        NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
        [threadContext setPersistentStoreCoordinator:[moc persistentStoreCoordinator]];
        [threadContext setUndoManager:nil];
        
        // cache the context for this thread
        [_managedObjectContexts setObject:threadContext forKey:threadKey];
    }
    
    return [_managedObjectContexts objectForKey:threadKey];
}

- (void) contextDidSave:(NSNotification*)saveNotification
{
    MFAppDelegate *appController = [[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [appController managedObjectContext];
    
    [moc performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                          withObject:saveNotification
                       waitUntilDone:YES];
}

#pragma mark - Work With All Objects

- (void) resetData
{    
    MFAppDelegate *appController = [[NSApplication sharedApplication] delegate];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [appController persistentStoreCoordinator];
    
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    
    for (NSPersistentStore *store in stores)
    {
        [persistentStoreCoordinator removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    
    _managedObjectContexts = [NSMutableDictionary dictionary];
    [appController createNewCoreData];
}

- (id) newObjectByName:(NSString *)name
{
   return [NSEntityDescription insertNewObjectForEntityForName:name
                                        inManagedObjectContext:[self managedObjectContext]];
}

- (id) objectsByName:(NSString *)name sortingField:(NSString *)field
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:[self managedObjectContext]];
    
    [fetchRequest setEntity:project];
    
    if(field)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:field ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    NSError *error = nil;
    id result = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return result;
}

- (id) objectsByName:(NSString *)name andId:(NSNumber *)nid
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:[self managedObjectContext]];
    
    [fetchRequest setEntity:project];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nid == %@", nid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    id result = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return result;
}

- (BOOL) deleteAllObjects:(NSString *) entityDescription
{
    NSArray *items = [self objectsByName:entityDescription sortingField:nil];
    
    if (items.count)
    {
        for (NSManagedObject *managedObject in items)
        {
            [[self managedObjectContext] deleteObject:managedObject];
        }
        
        return [self save];
    }
    else
    {
        return NO;
    }
}

- (BOOL) deleteObject:(NSManagedObject *)object
{
    [[self managedObjectContext] deleteObject:object];
        
    return [self save];
}

- (BOOL) deleteObjects:(NSArray *)objects
{
    for (NSManagedObject *managedObject in objects)
    {
        [[self managedObjectContext] deleteObject:managedObject];
    }
    
    return [self save];
}

- (BOOL) save
{
    @synchronized (self)
    {
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSThread *thread = [NSThread currentThread];
        
        if ([thread isMainThread] == NO)
        {
            // only observe notifications other than the main thread
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(contextDidSave:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:moc];
        }
        
        NSError *error = nil;
        if (![moc save:&error])
        {
            return NO;
        }
        
        [moc reset];
        
        if ([thread isMainThread] == NO)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:NSManagedObjectContextDidSaveNotification
                                                          object:moc];
        }
        
        return YES;
    }
}

#pragma mark - Project

- (Project *) projectById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:PROJECT_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Project *object = [self newObjectByName:PROJECT_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (Project *) project
{
    return [self newObjectByName:PROJECT_ENTITY];
}

- (NSArray *) projects
{
    return [self objectsByName:PROJECT_ENTITY sortingField:@"name"];
}

#pragma mark - Issue

- (NSArray *) issuesByProjectId:(NSNumber *)nid
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:@"Issue"
                                               inManagedObjectContext:[self managedObjectContext]];
    
    [fetchRequest setEntity:project];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.nid == %@", nid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    id result = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return result;
}

- (Issue *) issueById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:ISSUE_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Issue *object = [self newObjectByName:ISSUE_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (Issue *) issue
{
    return [self newObjectByName:ISSUE_ENTITY];
}

- (NSArray *) issues
{
    return [self objectsByName:ISSUE_ENTITY sortingField:@"name"];
}

#pragma mark - Time Entry

- (NSArray *) timeEntriesByIssueId:(NSNumber *)nid
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *timeEntry = [NSEntityDescription entityForName:@"TimeEntry"
                                                 inManagedObjectContext:[self managedObjectContext]];
    
    [fetchRequest setEntity:timeEntry];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"issue.nid == %@", nid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    id result = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return result;
}

- (TimeEntry *) timeEntryById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:TIME_ENTRY_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        TimeEntry *object = [self newObjectByName:TIME_ENTRY_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (TimeEntry *) timeEntry
{
    return [self newObjectByName:TIME_ENTRY_ENTITY];
}

- (NSArray *) timeEntries
{
    return [self objectsByName:TIME_ENTRY_ENTITY sortingField:@"name"];
}

#pragma mark - Version

- (Version *) versionById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:VERSION_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Version *object = [self newObjectByName:VERSION_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (NSArray *) versions
{
    return [self objectsByName:VERSION_ENTITY sortingField:@"name"];
}

#pragma mark - Users

- (NSArray *) users
{
    return [self objectsByName:USER_ENTITY sortingField:@"name"];
}

- (User *) userById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:USER_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        User *object = [self newObjectByName:USER_ENTITY];
        object.nid = nid;
        return object;
    }
}

#pragma mark - Filters

- (Tracker *) trackerById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:TRACKER_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Tracker *object = [self newObjectByName:TRACKER_ENTITY];
        object.nid = nid;
        return object;
    }
}

#pragma mark - Tracker

- (Tracker *) tracker
{
    return [self newObjectByName:TRACKER_ENTITY];
}

- (NSArray *) trackers
{
    return [self objectsByName:TRACKER_ENTITY sortingField:@"nid"];
}

- (Status *) statusById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:STATUS_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Status *object = [self newObjectByName:STATUS_ENTITY];
        object.nid = nid;
        return object;
    }
}

#pragma mark - Status

- (Status *) status
{
    return [self newObjectByName:STATUS_ENTITY];
}

- (NSArray *) statuses
{
    return [self objectsByName:STATUS_ENTITY sortingField:@"nid"];
}

#pragma mark - Priority

- (Priority *) priorityById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:PRIORITY_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Priority *object = [self newObjectByName:PRIORITY_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (Priority *) priority
{
    return [self newObjectByName:PRIORITY_ENTITY];
}

- (NSArray *) priorities
{
    return [self objectsByName:PRIORITY_ENTITY sortingField:@"nid"];
}

#pragma mark - Activity

- (Activity *) activityById:(NSNumber *)nid
{
    NSArray *objects = [self objectsByName:ACTIVITY_ENTITY andId:nid];
    if (objects.count)
    {
        return [objects objectAtIndex:0];
    }
    else
    {
        Activity *object = [self newObjectByName:ACTIVITY_ENTITY];
        object.nid = nid;
        return object;
    }
}

- (Activity *) activity
{
    return [self newObjectByName:ACTIVITY_ENTITY];
}

- (NSArray *) activities
{
    return [self objectsByName:PRIORITY_ENTITY sortingField:@"nid"];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end