//
//  Role.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Membership;

@interface Role : NSManagedObject

@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *memberships;
@end

@interface Role (CoreDataGeneratedAccessors)

- (void)addMembershipsObject:(Membership *)value;
- (void)removeMembershipsObject:(Membership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

@end
