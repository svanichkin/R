//
//  Priority.h
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Priority : NSManagedObject

@property (nonatomic, retain) NSNumber * pid;
@property (nonatomic, retain) NSString * name;

@end
