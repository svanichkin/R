//
//  Detail.h
//  R
//
//  Created by Сергей Ваничкин on 15.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Journal;

@interface Detail : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * newValue;
@property (nonatomic, retain) NSString * oldValue;
@property (nonatomic, retain) NSString * property;
@property (nonatomic, retain) Journal *journal;

@end
