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
#define VERSION_ENTITY      @"Version"
#define USER_ENTITY         @"User"

#define TRACKER_ENTITY      @"Tracker"
#define STATUS_ENTITY       @"Status"
#define PRIORITY_ENTITY     @"Priority"

@implementation MFDatabase
{
    NSManagedObjectContext *_managedObjectContext;
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
        MFAppDelegate *appController = [[NSApplication sharedApplication] delegate];
        //_managedObjectContext = [app managedObjectContext];
        
        NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] init];
        [ctx setUndoManager:nil];
        [ctx setPersistentStoreCoordinator: [appController persistentStoreCoordinator]];
        
    }
    return self;
}

#pragma mark - Work With All Objects

- (id) newObjectByName:(NSString *)name
{
   return [NSEntityDescription insertNewObjectForEntityForName:name
                                        inManagedObjectContext:_managedObjectContext];
}

- (id) objectsByName:(NSString *)name sortingField:(NSString *)field
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:_managedObjectContext];
    
    [fetchRequest setEntity:project];
    
    if(field)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:field ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    [_managedObjectContext lock];
    
    NSError *error = nil;
    id result = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    [_managedObjectContext unlock];
    
    return result;
}

- (id) objectsByName:(NSString *)name andId:(NSNumber *)nid
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:_managedObjectContext];
    
    [fetchRequest setEntity:project];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nid == %@", nid];
    [fetchRequest setPredicate:predicate];
    
    [_managedObjectContext lock];
    
    NSError *error = nil;
    id result = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    [_managedObjectContext unlock];
    
    return result;
}

- (BOOL) deleteAllObjects:(NSString *) entityDescription
{
    NSArray *items = [self objectsByName:entityDescription sortingField:nil];
    
    [_managedObjectContext lock];
    
    for (NSManagedObject *managedObject in items)
    {
        [_managedObjectContext deleteObject:managedObject];
    }
    
    [_managedObjectContext unlock];
    
    return [self save];
}

- (BOOL) deleteObject:(NSManagedObject *)object
{
    [_managedObjectContext lock];
    
    [_managedObjectContext deleteObject:object];
    
    [_managedObjectContext unlock];
        
    return [self save];
}


- (BOOL) deleteObjects:(NSArray *)objects
{
    [_managedObjectContext lock];
    
    for (NSManagedObject *managedObject in objects)
    {
        [_managedObjectContext deleteObject:managedObject];
    }
    
    [_managedObjectContext unlock];
    
    return [self save];
}

- (BOOL) save
{
    [_managedObjectContext lock];
    
    NSError *error = nil;
    BOOL result = [_managedObjectContext save:&error];
    
    [_managedObjectContext unlock];
    
    return result;
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

- (Status *) status
{
    return [self newObjectByName:STATUS_ENTITY];
}

- (NSArray *) statuses
{
    return [self objectsByName:STATUS_ENTITY sortingField:@"nid"];
}

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

@end
