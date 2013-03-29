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
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSString * sid;
@property (nonatomic, retain) NSSet *issues;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addIssuesObject:(Issue *)value;
- (void)removeIssuesObject:(Issue *)value;
- (void)addIssues:(NSSet *)values;
- (void)removeIssues:(NSSet *)values;

@end
