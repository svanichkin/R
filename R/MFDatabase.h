//
//  MFDatabase.h
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Project.h"

#import "Issue.h"
#import "TimeEntry.h"
#import "Version.h"
#import "User.h"
#import "Attach.h"
#import "Journal.h"
#import "Detail.h"

#import "Tracker.h"
#import "Status.h"
#import "Priority.h"
#import "Activity.h"

@interface MFDatabase : NSObject

+ (MFDatabase *) sharedInstance;

- (BOOL) deleteAllObjects:(NSString *) entityDescription;
- (BOOL) deleteObject:(NSManagedObject *)object;
- (BOOL) deleteObjects:(NSArray *)objects;

- (BOOL) save;

- (Project *) projectById:(NSNumber *)nid;
- (Project *) project;
- (NSArray *) projects;

- (Issue *) issueById:(NSNumber *)nid;
- (Issue *) issue;
- (NSArray *) issues;
- (NSArray *) issuesByProjectId:(NSNumber *)nid;
- (Attach *) attach;
- (void) deleteAttachmentsByIssueId:(NSNumber *)nid;
- (Journal *) journal;
- (void) deleteJournalsByIssueId:(NSNumber *)nid;
- (Detail *) detail;

- (TimeEntry *) timeEntryById:(NSNumber *)nid;
- (TimeEntry *) timeEntry;
- (NSArray *) timeEntries;

- (Version *) versionById:(NSNumber *)nid;
- (NSArray *) versions;

- (User *) userById:(NSNumber *)nid;
- (NSArray *) users;

- (Tracker *) trackerById:(NSNumber *)nid;
- (Tracker *) tracker;
- (NSArray *) trackers;

- (Status *) statusById:(NSNumber *)nid;
- (Status *) status;
- (NSArray *) statuses;

- (Priority *) priorityById:(NSNumber *)nid;
- (Priority *) priority;
- (NSArray *) priorities;

- (Activity *) activityById:(NSNumber *)nid;
- (Activity *) activity;
- (NSArray *) activities;

@end
