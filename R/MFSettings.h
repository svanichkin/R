//
//  MFSettings.h
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFSettings : NSObject

@property (nonatomic, weak) NSString *server;
@property (nonatomic, weak) NSString *login;
@property (nonatomic, weak) NSString *password;
@property (nonatomic, readonly) BOOL credentials;

@property (nonatomic, weak) NSArray *filtersPriorities;
@property (nonatomic, weak) NSArray *filtersStatuses;
@property (nonatomic, weak) NSArray *filtersTrackers;
@property (nonatomic, readonly) BOOL filters;
@property (nonatomic, weak) NSArray *filtersStates;

@property (nonatomic, weak) NSNumber *selectedProjectId;

+ (MFSettings *)sharedInstance;

@end
