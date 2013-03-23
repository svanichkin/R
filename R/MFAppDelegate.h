//
//  MFAppDelegate.h
//  R
//
//  Created by Сергей Ваничкин on 22.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFPreferencesPanel.h"

@interface MFAppDelegate : NSObject <NSApplicationDelegate>

#pragma mark - Login

@property (assign) IBOutlet MFPreferencesPanel *preferencesPanel;

#pragma mark - Main

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet NSPopUpButton *projectsSelector;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
