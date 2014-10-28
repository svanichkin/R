//
//  MFAuthorizationKey.h
//  R
//
//  Created by Сергей Ваничкин on 03.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFAuthorization : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (void) authorizationWithLogin:(NSString *)login password:(NSString *)password andServer:(NSString *)server;

@end
