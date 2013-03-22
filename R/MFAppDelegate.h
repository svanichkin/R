//
//  MFAppDelegate.h
//  R
//
//  Created by Сергей Ваничкин on 22.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFAppDelegate : NSObject <NSApplicationDelegate>

#pragma mark - Login

@property (assign) IBOutlet NSTextField *login;
@property (assign) IBOutlet NSSecureTextField *password;
@property (assign) IBOutlet NSTextField *apikey;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *progressText;
@property (assign) IBOutlet NSButton *connect;

- (IBAction)connectAction:(id)sender;

#pragma mark - Main

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSSplitView *splitView;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
