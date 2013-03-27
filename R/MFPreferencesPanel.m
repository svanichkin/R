//
//  MFPreferencesPanel.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFPreferencesPanel.h"
#import "MFConnector.h"

@implementation MFPreferencesPanel

-(void)awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"serverAddress"])
    {
        _serverAddress.stringValue = [defaults objectForKey:@"serverAddress"];
        _login.stringValue =         [defaults objectForKey:@"username"];
        _password.stringValue =      [defaults objectForKey:@"password"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionComplete:)
                                                 name:CONNECT_COMPLETE
                                               object:nil];
}

- (IBAction)connectAction:(id)sender
{
    if (_serverAddress.stringValue.length && _login.stringValue.length && _password.stringValue.length && [MFConnector sharedInstance].connectionProgress == NO)
    {
        [_progressIndicator setHidden:NO];
        [_progressIndicator startAnimation:nil];
        
        _progressText.stringValue = @"Authorization...";
        [_progressText setHidden:NO];
        
        [[MFConnector sharedInstance] connectWithLogin:_login.stringValue
                                              password:_password.stringValue
                                                server:_serverAddress.stringValue];
        
    }
}

- (void) connectionComplete:(NSNotification *)notification
{
    [_progressIndicator setHidden:YES];
    [_progressIndicator stopAnimation:nil];
    [_progressText setHidden:NO];
    
    if ([notification.object boolValue])
    {
        _progressText.stringValue = @"Connected";
    }
    else
    {
        _progressText.stringValue = @"Error";
    }
}

@end
