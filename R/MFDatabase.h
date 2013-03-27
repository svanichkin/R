//
//  MFDatabase.h
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFDatabase : NSObject

+ (MFDatabase *)sharedInstance;

- (id) newObjectByName:(NSString *)name;
- (id) objectByName:(NSString *)name;
- (BOOL) save;

@end
