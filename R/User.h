//
//  User.h
//  R
//
//  Created by Сергей Ваничкин on 11.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Attach, Issue, Journal, TimeEntry;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSDate * lastLogin;
@property (nonatomic, retain) NSString * skype;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSSet *timeEntriesCreator;
@property (nonatomic, retain) Journal *journalsCreator;
@property (nonatomic, retain) NSSet *issuesCreator;
@property (nonatomic, retain) Issue *issuesAssigner;
@property (nonatomic, retain) Attach *attachCreator;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addTimeEntriesCreatorObject:(TimeEntry *)value;
- (void)removeTimeEntriesCreatorObject:(TimeEntry *)value;
- (void)addTimeEntriesCreator:(NSSet *)values;
- (void)removeTimeEntriesCreator:(NSSet *)values;

- (void)addIssuesCreatorObject:(Issue *)value;
- (void)removeIssuesCreatorObject:(Issue *)value;
- (void)addIssuesCreator:(NSSet *)values;
- (void)removeIssuesCreator:(NSSet *)values;

@end
