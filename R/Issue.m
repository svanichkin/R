//
//  Issue.m
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "Issue.h"
#import "Priority.h"
#import "Project.h"
#import "Status.h"
#import "Tracker.h"
#import "User.h"
#import "Version.h"


@implementation Issue

@dynamic name;
@dynamic iid;
@dynamic text;
@dynamic start;
@dynamic finish;
@dynamic create;
@dynamic update;
@dynamic done;
@dynamic estimated;
@dynamic spent;
@dynamic project;
@dynamic tracker;
@dynamic priority;
@dynamic status;
@dynamic creator;
@dynamic assigner;
@dynamic version;

@end
