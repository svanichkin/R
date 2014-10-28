//
//  MFIssueView.m
//  R
//
//  Created by Сергей Ваничкин on 07.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssueView.h"
#import <WebKit/WebKit.h>

@interface MFIssueView ()

@property (nonatomic, strong) MFSettings *settings;
@property (nonatomic, strong) MFDatabase *database;
@property (nonatomic, strong) Issue *issue;

@end

@implementation MFIssueView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetData)
                                                     name:RESET_DATABASE
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetData)
                                                     name:RESET_FULL
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(issueSelected:)
                                                     name:ISSUE_SELECTED
                                                   object:nil];
        self.settings = [MFSettings sharedInstance];
        self.database = [MFDatabase sharedInstance];
    }
    return self;
}

- (void) resetData
{
    self.hidden = YES;
    self.issue = nil;
}

// Если выбрали задачу в левом окне
- (void) issueSelected:(NSNotification *)notification
{
    self.hidden = NO;
        
    self.scrollView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"linen.tiff"]];
    
    self.issue = [self.database issueById:self.settings.selectedIssueId];
    
    NSString *smallHeader = [NSString stringWithFormat:@"#%@ – %@ %@", self.issue.nid, [self.issue.priority.name lowercaseString], [self.issue.tracker.name lowercaseString]];
    
    if (self.issue.version.name)
    {
        smallHeader = [NSString stringWithFormat:@"%@ for version %@, %@", smallHeader, self.issue.version.name, [self.issue.status.name lowercaseString]];
    }
    else
    {
        smallHeader = [NSString stringWithFormat:@"%@, %@", smallHeader, [self.issue.status.name lowercaseString]];
    }
    
    if ([self.issue.done intValue] > 0)
    {
        smallHeader = [NSString stringWithFormat:@"%@ %@%%.", smallHeader, self.issue.done];
    }
    else
    {
        smallHeader = [NSString stringWithFormat:@"%@.", smallHeader];
    }
    
    if ([self.issue.spent intValue] > 0)
    {
        NSNumber *t = self.issue.spent;
        
        int hour = [t intValue]%10;
        int min = 60*([t floatValue] - hour);
        if (hour > 0 && min == 0)
        {
            smallHeader = [NSString stringWithFormat:@"%@ Spent time %i hour.", smallHeader, hour];
        }
        else if (hour > 0 && min > 0)
        {
            smallHeader = [NSString stringWithFormat:@"%@ Spent time %ih %im.", smallHeader, hour, min];
        }
        else if (hour == 0 && min > 0)
        {
            smallHeader = [NSString stringWithFormat:@"%@ Spent time %i minutes.", smallHeader, min];
        }
    }
    self.smallHeader.stringValue = smallHeader;
    
    self.bigHeader.stringValue = self.issue.name;
    
    
    NSString *infoHeader = [NSString stringWithFormat:@"From %@", self.issue.creator.name];
    
    if (self.issue.create)
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] initWithDateFormat:@"%0d %B %Y" allowNaturalLanguage:NO];
        NSString *dateString = [dateFormat stringFromDate:self.issue.create];
        
        infoHeader = [NSString stringWithFormat:@"%@, %@.", infoHeader, dateString];
    }
    
    if ([self.issue.estimated floatValue] > 0)
    {
        NSNumber *t = self.issue.estimated;
        
        int hour = [t intValue]%10;
        int min = 60*([t floatValue] - hour);
        if (hour > 0 && min == 0)
        {
            infoHeader = [NSString stringWithFormat:@"%@ Estimated time %i hour.", infoHeader, hour];
        }
        else if (hour > 0 && min > 0)
        {
            infoHeader = [NSString stringWithFormat:@"%@ Estimated time %ih %im.", infoHeader, hour, min];
        }
        else if (hour == 0 && min > 0)
        {
            infoHeader = [NSString stringWithFormat:@"%@ Estimated time %i minutes.", infoHeader, min];
        }
    }
    
    if (self.issue.finish)
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] initWithDateFormat:@"%0d %B %Y" allowNaturalLanguage:NO];
        NSString *dateString = [dateFormat stringFromDate:self.issue.finish];
        
        infoHeader = [NSString stringWithFormat:@"%@ Due date %@.", infoHeader, dateString];
    }
    
    self.infoHeader.stringValue = infoHeader;
}

@end
