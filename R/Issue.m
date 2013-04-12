//
//  Issue.m
//  R
//
//  Created by Сергей Ваничкин on 12.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "Issue.h"
#import "Activity.h"
#import "Attach.h"
#import "Issue.h"
#import "Journal.h"
#import "Priority.h"
#import "Project.h"
#import "Relation.h"
#import "Status.h"
#import "TimeEntry.h"
#import "Tracker.h"
#import "User.h"
#import "Version.h"


@implementation Issue

@dynamic create;
@dynamic done;
@dynamic estimated;
@dynamic finish;
@dynamic name;
@dynamic nid;
@dynamic start;
@dynamic text;
@dynamic update;
@dynamic spent;
@dynamic activity;
@dynamic assigner;
@dynamic children;
@dynamic creator;
@dynamic parent;
@dynamic priority;
@dynamic project;
@dynamic status;
@dynamic tracker;
@dynamic version;
@dynamic timeEntries;
@dynamic journals;
@dynamic attachments;
@dynamic relations;

@end
