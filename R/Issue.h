//
//  Issue.h
//  R
//
//  Created by Сергей Ваничкин on 11.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Attach, Issue, Journal, Priority, Project, Status, TimeEntry, Tracker, User, Version;

@interface Issue : NSManagedObject

@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSNumber * estimated;
@property (nonatomic, retain) NSDate * finish;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSNumber * spent;
@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) User *assigner;
@property (nonatomic, retain) Issue *children;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) Issue *parent;
@property (nonatomic, retain) Priority *priority;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Status *status;
@property (nonatomic, retain) Tracker *tracker;
@property (nonatomic, retain) Version *version;
@property (nonatomic, retain) NSSet *timeEntries;
@property (nonatomic, retain) Journal *journals;
@property (nonatomic, retain) Attach *attachments;
@end

@interface Issue (CoreDataGeneratedAccessors)

- (void)addTimeEntriesObject:(TimeEntry *)value;
- (void)removeTimeEntriesObject:(TimeEntry *)value;
- (void)addTimeEntries:(NSSet *)values;
- (void)removeTimeEntries:(NSSet *)values;

@end
