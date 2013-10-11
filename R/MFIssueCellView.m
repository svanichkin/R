//
//  MFIssueCellView.m
//  R
//
//  Created by Сергей Ваничкин on 11.10.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssueCellView.h"

@interface MFIssueCellView ()

@property (nonatomic, strong) IBOutlet NSImageView *selectedImageView;

@end

@implementation MFIssueCellView

-(void)setSelected:(BOOL)selected
{
    self.selectedImageView.hidden = !selected;
}

@end
