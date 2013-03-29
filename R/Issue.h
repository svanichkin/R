//
//  Issue.h
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue, Priority, Project, Status, Tracker, User, Version;

@interface Issue : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * finish;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSNumber * estimated;
@property (nonatomic, retain) NSNumber * spent;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Tracker *tracker;
@property (nonatomic, retain) Priority *priority;
@property (nonatomic, retain) Status *status;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) User *assigner;
@property (nonatomic, retain) Version *version;
@property (nonatomic, retain) Issue *parent;
@property (nonatomic, retain) Issue *children;

@end
