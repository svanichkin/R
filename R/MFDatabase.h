//
//  MFDatabase.h
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Project.h"

#import "Tracker.h"
#import "Status.h"
#import "Priority.h"

@interface MFDatabase : NSObject

+ (MFDatabase *)sharedInstance;

- (BOOL) deleteAllObjects:(NSString *) entityDescription;
- (BOOL) deleteObject:(NSManagedObject *)object;
- (BOOL) deleteObjects:(NSArray *)objects;
- (BOOL) save;

- (Project *) project;
- (NSArray *) projects;

- (Tracker *) tracker;
- (NSArray *) trackers;
- (Status *) status;
- (NSArray *) statuses;
- (Priority *) priority;
- (NSArray *) priorities;

@end
