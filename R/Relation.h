//
//  Relation.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Relation : NSManagedObject

@property (nonatomic, retain) NSNumber * delay;
@property (nonatomic, retain) NSNumber * issueId;
@property (nonatomic, retain) NSNumber * issueToId;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) Issue *issue;

@end
