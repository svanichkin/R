//
//  User.h
//  R
//
//  Created by Сергей Ваничкин on 09.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nid;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSDate * lastLogin;
@property (nonatomic, retain) NSString * skype;
@property (nonatomic, retain) NSString * phone;

@end
