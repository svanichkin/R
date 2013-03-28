//
//  Project.h
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * pid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSString * sid;
@property (nonatomic, retain) NSSet *issue;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addIssueObject:(Issue *)value;
- (void)removeIssueObject:(Issue *)value;
- (void)addIssue:(NSSet *)values;
- (void)removeIssue:(NSSet *)values;

@end
