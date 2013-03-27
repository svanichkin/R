//
//  MFDatabase.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFDatabase.h"
#import "MFAppDelegate.h"

@implementation MFDatabase
{
    NSManagedObjectContext *_contextCoreData;
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
        _contextCoreData = [app managedObjectContext];
    }
    return self;
}

- (id) newObjectByName:(NSString *)name
{
   return [NSEntityDescription insertNewObjectForEntityForName:name
                                        inManagedObjectContext:_contextCoreData];
}

- (id) objectByName:(NSString *)name
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *project = [NSEntityDescription entityForName:name
                                               inManagedObjectContext:_contextCoreData];
    
    [fetchRequest setEntity:project];
    
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid > 1000"];
//    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    return [_contextCoreData executeFetchRequest:fetchRequest error:&error];
}

- (BOOL) save
{
    NSError *error = nil;
    return [_contextCoreData save:&error];
}
@end
