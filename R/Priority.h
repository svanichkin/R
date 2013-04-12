//
//  Priority.h
//  R
//
//  Created by Сергей Ваничкин on 12.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Priority : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSSet *issues;
@end

@interface Priority (CoreDataGeneratedAccessors)

- (void)addIssuesObject:(Issue *)value;
- (void)removeIssuesObject:(Issue *)value;
- (void)addIssues:(NSSet *)values;
- (void)removeIssues:(NSSet *)values;

@end
