//
//  MFIssueView.m
//  R
//
//  Created by Сергей Ваничкин on 07.04.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssueView.h"


@implementation MFIssueView
{
    MFSettings *_settings;
    MFDatabase *_database;
    Issue *_issue;
}

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
        _settings = [MFSettings sharedInstance];
        _database = [MFDatabase sharedInstance];
    }
    return self;
}

- (void) resetData
{
    _parentScrollView.hidden = YES;
    _issue = nil;
}

// Если выбрали задачу в левом окне
- (void) issueSelected:(NSNotification *)notification
{
    _parentScrollView.hidden = NO;
    
    _issue = [_database issueById:_settings.selectedIssueId];
    
    NSString *smallHeader = [NSString stringWithFormat:@"#%@ – %@ %@", _issue.nid, [_issue.priority.name lowercaseString], [_issue.tracker.name lowercaseString]];
    
    if (_issue.version.name)
    {
        smallHeader = [NSString stringWithFormat:@"%@ for version %@, %@", smallHeader, _issue.version.name, [_issue.status.name lowercaseString]];
    }
    else
    {
        smallHeader = [NSString stringWithFormat:@"%@, %@", smallHeader, [_issue.status.name lowercaseString]];
    }
    
    if ([_issue.done intValue] > 0)
    {
        smallHeader = [NSString stringWithFormat:@"%@ %@%%.", smallHeader, _issue.done];
    }
    else
    {
        smallHeader = [NSString stringWithFormat:@"%@.", smallHeader];
    }
    
    if ([_issue.spent intValue] > 0)
    {
        NSNumber *t = _issue.spent;
        
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
    _smallHeader.stringValue = smallHeader;
    
    _bigHeader.stringValue = _issue.name;
    
    
    NSString *infoHeader = [NSString stringWithFormat:@"From %@", _issue.creator.name];
    
    if (_issue.create)
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] initWithDateFormat:@"%0d %B %Y" allowNaturalLanguage:NO];
        NSString *dateString = [dateFormat stringFromDate:_issue.create];
        
        infoHeader = [NSString stringWithFormat:@"%@, %@.", infoHeader, dateString];
    }
    
    if ([_issue.estimated floatValue] > 0)
    {
        NSNumber *t = _issue.estimated;
        
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
    
    if (_issue.finish)
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] initWithDateFormat:@"%0d %B %Y" allowNaturalLanguage:NO];
        NSString *dateString = [dateFormat stringFromDate:_issue.finish];
        
        infoHeader = [NSString stringWithFormat:@"%@ Due date %@.", infoHeader, dateString];
    }
    
    _infoHeader.stringValue = infoHeader;
}

@end
