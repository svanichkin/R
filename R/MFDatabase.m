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

- (id) objectByName:(NSString *)name
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:_managedObjectContext];
    
    [fetchRequest setEntity:project];
    
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid > 1000"];
//    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    return [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (BOOL) deleteAllObjects:(NSString *) entityDescription
{
    NSArray *items = [self objectByName:entityDescription];    
    
    for (NSManagedObject *managedObject in items)
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
    return [self objectByName:PROJECT_ENTITY];
}

@end
