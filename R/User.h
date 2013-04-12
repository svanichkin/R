//
//  User.h
//  R
//
//  Created by Сергей Ваничкин on 12.04.13.
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
@property (nonatomic, retain) NSSet *journalsCreator;
@property (nonatomic, retain) NSSet *issuesCreator;
@property (nonatomic, retain) NSSet *issuesAssigner;
@property (nonatomic, retain) NSSet *attachmentsCreator;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addTimeEntriesCreatorObject:(TimeEntry *)value;
- (void)removeTimeEntriesCreatorObject:(TimeEntry *)value;
- (void)addTimeEntriesCreator:(NSSet *)values;
- (void)removeTimeEntriesCreator:(NSSet *)values;

- (void)addJournalsCreatorObject:(Journal *)value;
- (void)removeJournalsCreatorObject:(Journal *)value;
- (void)addJournalsCreator:(NSSet *)values;
- (void)removeJournalsCreator:(NSSet *)values;

- (void)addIssuesCreatorObject:(Issue *)value;
- (void)removeIssuesCreatorObject:(Issue *)value;
- (void)addIssuesCreator:(NSSet *)values;
- (void)removeIssuesCreator:(NSSet *)values;

- (void)addIssuesAssignerObject:(Issue *)value;
- (void)removeIssuesAssignerObject:(Issue *)value;
- (void)addIssuesAssigner:(NSSet *)values;
- (void)removeIssuesAssigner:(NSSet *)values;

- (void)addAttachmentsCreatorObject:(Attach *)value;
- (void)removeAttachmentsCreatorObject:(Attach *)value;
- (void)addAttachmentsCreator:(NSSet *)values;
- (void)removeAttachmentsCreator:(NSSet *)values;

@end
