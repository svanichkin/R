//
//  MFDatabase.h
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"

@interface MFDatabase : NSObject

+ (MFDatabase *)sharedInstance;

- (BOOL) deleteAllObjects:(NSString *) entityDescription;
- (BOOL) deleteObject:(NSManagedObject *)object;
- (BOOL) deleteObjects:(NSArray *)objects;
- (BOOL) save;

- (Project *) project;
- (NSArray *) projects;

@end
