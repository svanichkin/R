//
//  Membership.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, Role, User;

@interface Membership : NSManagedObject

@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSSet *roles;
@property (nonatomic, retain) User *user;
@end

@interface Membership (CoreDataGeneratedAccessors)

- (void)addRolesObject:(Role *)value;
- (void)removeRolesObject:(Role *)value;
- (void)addRoles:(NSSet *)values;
- (void)removeRoles:(NSSet *)values;

@end
