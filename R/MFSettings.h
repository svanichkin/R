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
@property (nonatomic, weak) NSString *apiToken;
@property (nonatomic, readonly) BOOL credentials;


@property (nonatomic, weak) NSArray *filtersStates;
@property (nonatomic, weak) NSNumber *selectedProjectId;
@property (nonatomic, weak) NSNumber *selectedIssueId;

@property (nonatomic, weak) NSDate *dataLastUpdate;

+ (MFSettings *)sharedInstance;

@end
