//
//  MFIssueCellView.h
//  R
//
//  Created by Сергей Ваничкин on 11.10.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFIssueCellView : NSView

@property (nonatomic, strong) IBOutlet NSTextField *taskNumber;
@property (nonatomic, strong) IBOutlet NSTextField *taskType;
@property (nonatomic, strong) IBOutlet NSTextField *issueText;

@property (nonatomic, strong) NSNumber *nid;

-(void)setSelected:(BOOL)selected;

@end
