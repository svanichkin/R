//
//  MFConnector.h
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFConnector : NSObject

@property (nonatomic, assign) BOOL connectionProgress;
@property (nonatomic, assign) BOOL databaseUpdatingProgress;

+ (MFConnector *) sharedInstance;

- (void) connect;
- (void) connectWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server;

- (void) databaseUpdate;

@end
