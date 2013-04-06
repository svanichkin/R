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
#import "MFIssueCell.h"

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
        //self.dataSource = self;
        //self.delegate = self;
    }
    return self;
}

- (void) resetData
{
    
}

- (void) projectSelected:(NSNotification *) notification
{
    _issues = [[MFDatabase sharedInstance] issuesByProjectId:_settings.selectedProjectId];

    
    
    
    // Загрузка задач по проекту
    NSUInteger count = [_issuesArrayController.arrangedObjects count];
    [_issuesArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
    
    for (Issue *i in _issues)
    {
//        if ([_filtersControl checkIssueWithStatusIndex:[i.status.index intValue]
//                                         priorityIndex:[i.priority.index intValue]
//                                       andTrackerIndex:[i.tracker.index intValue]])
//        {
        
            NSString *type = [NSString stringWithFormat:@"%@ %@ %@", [i.status.name lowercaseString], [i.priority.name  lowercaseString], [i.tracker.name lowercaseString]];
            
            [_issuesArrayController addObject:@{@"text":[NSString stringWithFormat:@"%@", i.text],
             @"type":type,
             @"number":[NSString stringWithFormat:@"#%@", i.nid]}];
//        }
    }
    [self reloadData];
//    [self deselectAll:nil];
    
    
    
    
    
    
    /*[self deselectAll:nil];
    [self reloadData];
    
    if (_issues)
    {
//    [self selectCell:<#(NSCell *)#>]
    }*/
}

/*- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _issues.count;
}*/

/*- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Issue *issue = [_issues objectAtIndex:row];
    
    NSString *type = [NSString stringWithFormat:@"%@ %@ %@", [issue.status.name lowercaseString], [issue.priority.name  lowercaseString], [issue.tracker.name lowercaseString]];
    
    NSString *number = [NSString stringWithFormat:@"#%@", issue.nid];
    
    return @{@"type":type, @"text":issue.text, @"number":number};
}*/

- (void) redrawIssues
{
    
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    // Скрываем нажатую ячейку
    if (_oldSelectedCell)
    {
        [[_oldSelectedCell viewWithTag:1] setHidden:NO];
        [[_oldSelectedCell viewWithTag:2] setHidden:YES];
    }
    
    NSTableCellView *selectedCell = [self viewAtColumn:0 row:self.selectedRow makeIfNecessary:YES];
    
    _oldSelectedCell = selectedCell;
    
    [[selectedCell viewWithTag:1] setHidden:YES];
    [[selectedCell viewWithTag:2] setHidden:NO];
}

- (void) issueSelected:(NSMenuItem *)sender
{
    /*if ([_settings.selectedProjectId intValue] != sender.tag)
    {
        // Сохраним значения сегментов, что бы восстановить при следующем входе
        _settings.selectedProjectId = @(sender.tag);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PROJECT_SELECTED object:nil];
    }*/
}

@end
