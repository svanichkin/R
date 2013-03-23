//
//  MFConnector.h
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRedmine.h"

@interface MFConnector : NSObject

@property (nonatomic, assign) BOOL connectionProgress;
@property (nonatomic, readonly) RKRedmine *redmine;


+ (MFConnector *)sharedInstance;
- (void)connectWithLogin:(NSString *)login password:(NSString *)password server:(NSString *)server andApikey:(NSString *)apikey;
@end
