//
//  Journal.h
//  R
//
//  Created by Сергей Ваничкин on 12.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Detail, Issue, User;

@interface Journal : NSManagedObject

@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) NSSet *details;
@property (nonatomic, retain) Issue *issue;
@end

@interface Journal (CoreDataGeneratedAccessors)

- (void)addDetailsObject:(Detail *)value;
- (void)removeDetailsObject:(Detail *)value;
- (void)addDetails:(NSSet *)values;
- (void)removeDetails:(NSSet *)values;

@end
