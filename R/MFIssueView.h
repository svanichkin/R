//
//  MFIssueView.h
//  R
//
//  Created by Сергей Ваничкин on 07.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFIssueView : NSView

@property (assign) IBOutlet NSTextField *smallHeader;
@property (assign) IBOutlet NSTextField *bigHeader;
@property (assign) IBOutlet NSTextField *infoHeader;
@property (assign) IBOutlet NSScrollView *parentScrollView;

@end
