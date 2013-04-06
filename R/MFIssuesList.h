//
//  MFIssuesList.h
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFIssuesList : NSTableView //<NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSArrayController *issuesArrayController;

@end
