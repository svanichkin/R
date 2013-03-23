//
//  MFPreferencesPanel.m
//  R
//
//  Created by Сергей Ваничкин on 23.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFPreferencesPanel.h"
#import "MFConnector.h"

@interface MFPreferencesPanel()
{
}

@end

@implementation MFPreferencesPanel

-(void)awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _serverAddress.stringValue = [defaults objectForKey:@"serverAddress"];
    _login.stringValue = [defaults objectForKey:@"username"];
    _password.stringValue = [defaults objectForKey:@"password"];
    _apikey.stringValue = [defaults objectForKey:@"apikey"];

}

- (IBAction)connectAction:(id)sender
{
    if (_serverAddress.stringValue.length &&
        _login.stringValue.length &&
        _password.stringValue.length &&
        _apikey.stringValue.length &&
        [MFConnector sharedInstance].connectionProgress == NO)
    {
        [_progressIndicator setHidden:NO];
        [_progressIndicator startAnimation:nil];
        
        _progressText.stringValue = @"Authorization...";
        [_progressText setHidden:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(connectionComplete:)
                                                     name:CONNECT_COMPLETE
                                                   object:nil];
        
        [[MFConnector sharedInstance] connectWithLogin:_login.stringValue password:_password.stringValue server:_serverAddress.stringValue andApikey:_apikey.stringValue];
        
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
        [[NSNotificationCenter defaultCenter] postNotificationName:CONNECT_COMPLETE object:self];
    }
    else
    {
        _progressText.stringValue = @"Error";
    }
}

@end
