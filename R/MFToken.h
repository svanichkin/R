//
//  MFAuthorizationKey.h
//  R
//
//  Created by Сергей Ваничкин on 03.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFToken : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (void) tokenWithDelegate:(id)delegate andFunction:(SEL)function;

@end
