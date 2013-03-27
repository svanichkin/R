//
//  MFPreferencesPanel.h
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFPreferencesPanel : NSPanel

@property (assign) IBOutlet NSTextField *login;
@property (assign) IBOutlet NSSecureTextField *password;
@property (assign) IBOutlet NSTextField *serverAddress;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *progressText;
@property (assign) IBOutlet NSButton *connect;

- (IBAction)connectAction:(id)sender;

@end
