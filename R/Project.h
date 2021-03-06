//
//  Project.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue, Membership, Project, TimeEntry, User;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * sid;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) Project *child;
@property (nonatomic, retain) NSSet *issues;
@property (nonatomic, retain) Project *parent;
@property (nonatomic, retain) NSSet *timeEntries;
@property (nonatomic, retain) User *assigners;
@property (nonatomic, retain) NSSet *memberships;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addIssuesObject:(Issue *)value;
- (void)removeIssuesObject:(Issue *)value;
- (void)addIssues:(NSSet *)values;
- (void)removeIssues:(NSSet *)values;

- (void)addTimeEntriesObject:(TimeEntry *)value;
- (void)removeTimeEntriesObject:(TimeEntry *)value;
- (void)addTimeEntries:(NSSet *)values;
- (void)removeTimeEntries:(NSSet *)values;

- (void)addMembershipsObject:(Membership *)value;
- (void)removeMembershipsObject:(Membership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

@end
