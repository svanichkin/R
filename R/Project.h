//
//  Project.h
//  R
//
//  Created by Сергей Ваничкин on 09.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * sid;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * update;
@property (nonatomic, retain) Project *parent;

@end
