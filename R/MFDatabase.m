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
        MFAppDelegate *app = [[NSApplication sharedApplication] delegate];
        _managedObjectContext = [app managedObjectContext];
    }
    return self;
}

#pragma mark - Work With All Objects

- (id) newObjectByName:(NSString *)name
{
   return [NSEntityDescription insertNewObjectForEntityForName:name
                                        inManagedObjectContext:_managedObjectContext];
}

- (id) objectByName:(NSString *)name sortingField:(NSString *)field
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
    
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid > 1000"];
//    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    return [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (BOOL) deleteAllObjects:(NSString *) entityDescription
{
    NSArray *items = [self objectByName:entityDescription sortingField:nil];
    
    for (NSManagedObject *managedObject in items)
    {
    	[_managedObjectContext deleteObject:managedObject];
    }
    
    return [self save];
}

- (BOOL) deleteObject:(NSManagedObject *)object
{
    [_managedObjectContext deleteObject:object];
    
    return [self save];
}


- (BOOL) deleteObjects:(NSArray *)objects
{
    for (NSManagedObject *managedObject in objects)
    {
    	[_managedObjectContext deleteObject:managedObject];
    }
    
    return [self save];
}

- (BOOL) save
{
    NSError *error = nil;
    return [_managedObjectContext save:&error];
}

#pragma mark - Work With Objects

- (Project *) project
{
    return [self newObjectByName:PROJECT_ENTITY];
}

- (NSArray *) projects
{
    return [self objectByName:PROJECT_ENTITY sortingField:@"name"];
}

#pragma mark - Filters

- (Tracker *) tracker
{
    return [self newObjectByName:TRACKER_ENTITY];
}

- (NSArray *) trackers
{
    return [self objectByName:TRACKER_ENTITY sortingField:@"tid"];
}

- (Status *) status
{
    return [self newObjectByName:STATUS_ENTITY];
}

- (NSArray *) statuses
{
    return [self objectByName:STATUS_ENTITY sortingField:@"sid"];
}

- (Priority *) priority
{
    return [self newObjectByName:PRIORITY_ENTITY];
}

- (NSArray *) priorities
{
    return [self objectByName:PRIORITY_ENTITY sortingField:@"pid"];
}

@end
