//
//  TimeEntry.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, Issue, Project, User;

@interface TimeEntry : NSManagedObject

@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * spent;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) Issue *issue;
@property (nonatomic, retain) Project *project;

@end
