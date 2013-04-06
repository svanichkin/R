//
//  MFIssuesList.m
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssuesList.h"
#import "MFSettings.h"
#import "MFDatabase.h"
#import "MFFiltersControl.h"

@implementation MFIssuesList
{
    MFSettings *_settings;
    NSArray *_issues;
    id _oldSelectedCell;
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
                                                 selector:@selector(projectSelected:)
                                                     name:PROJECT_SELECTED
                                                   object:nil];
        _settings = [MFSettings sharedInstance];
        self.delegate = self;
    }
    return self;
}

- (void) resetData
{
    [self clearArrayController];
    [self reloadData];
}

- (void) clearArrayController
{
    // Загрузка задач по проекту
    NSUInteger count = [_issuesArrayController.arrangedObjects count];
    [_issuesArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
}

- (void) selectIssueByRow:(NSInteger)row
{
    // Скрываем нажатую ячейку
    if (_oldSelectedCell)
    {
        [[_oldSelectedCell viewWithTag:1] setHidden:NO];
        [[_oldSelectedCell viewWithTag:2] setHidden:YES];
    }

    NSTableCellView *selectedCell = [self viewAtColumn:0 row:row makeIfNecessary:NO];
    _oldSelectedCell = selectedCell;
    
    [[selectedCell viewWithTag:1] setHidden:YES];
    [[selectedCell viewWithTag:2] setHidden:NO];
}

- (void) projectSelected:(NSNotification *) notification
{
    _issues = [[MFDatabase sharedInstance] issuesByProjectId:_settings.selectedProjectId];

    [self clearArrayController];
    
    for (Issue *i in _issues)
    {
        if ([MFFiltersControl checkIssueWithStatusIndex:[i.status.nid intValue]
                                          priorityIndex:[i.priority.nid intValue]
                                        andTrackerIndex:[i.tracker.nid intValue]])
        {
        
            NSString *type = [NSString stringWithFormat:@"%@ %@ %@", [i.status.name lowercaseString], [i.priority.name  lowercaseString], [i.tracker.name lowercaseString]];
            
            [_issuesArrayController addObject:@{
             @"text":[NSString stringWithFormat:@"%@", i.name],
             @"type":type,
             @"number":[NSString stringWithFormat:@"#%@", i.nid]}];
        }
    }
    
    [self reloadData];
    [self selectIssueByRow:1];
}

- (void) issueSelected
{
    //_settings.selectedIssueId = sender.tag;
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:PROJECT_SELECTED object:nil];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self selectIssueByRow:self.selectedRow];
}

@end
