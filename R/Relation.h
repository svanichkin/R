//
//  Relation.h
//  R
//
//  Created by Сергей Ваничкин on 11.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Relation : NSManagedObject

@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) UNKNOWN_TYPE delay;
@property (nonatomic, retain) NSNumber * issueId;
@property (nonatomic, retain) NSNumber * issueToId;
@property (nonatomic, retain) Issue *issue;

@end
