//
//  TimeEntry.h
//  R
//
//  Created by Сергей Ваничкин on 12.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Issue, Project, User;

@interface TimeEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * spent;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Issue *issue;
@property (nonatomic, retain) Activity *activity;

@end
