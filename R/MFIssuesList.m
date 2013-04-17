//
//  MFIssuesList.m
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssuesList.h"
#import "MFFiltersControl.h"

@implementation MFIssuesList
{
    MFSettings *_settings;
    NSMutableArray *_issues;
    NSInteger _selectedRow;
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
                                                 selector:@selector(refreshIssues:)
                                                     name:PROJECT_SELECTED
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshIssues:)
                                                     name:FILTERS_CHANGED
                                                   object:nil];
        
        _settings = [MFSettings sharedInstance];
        self.delegate = self;
        self.dataSource = self;
        
        _selectedRow = -1;
        
        self.backgroundColor = [NSColor clearColor];
    }
    return self;
}

- (void) resetData
{
    _issues = [NSMutableArray array];

    [self reloadData];
}

- (void) selectIssueByRow:(NSInteger)row
{
    [self selectionReset];
    
    NSTableCellView *selectedCell = [self viewAtColumn:0 row:row makeIfNecessary:NO];
    _selectedRow = row;
    
    [[selectedCell viewWithTag:1] setHidden:YES];
    [[selectedCell viewWithTag:2] setHidden:NO];
    
    [self issueSelected:[selectedCell.objectValue objectForKey:@"nid"]];
}

- (void) selectionReset
{
    if (_selectedRow > -1)
    {
        NSTableCellView *selectedCell = [self viewAtColumn:0 row:_selectedRow makeIfNecessary:NO];
    
        // Скрываем нажатую ячейку
        [[selectedCell viewWithTag:1] setHidden:NO];
        [[selectedCell viewWithTag:2] setHidden:YES];
    }
}

- (void) refreshIssues:(NSNotification *) notification
{
    [self selectionReset];
    
    NSArray *issues = [[MFDatabase sharedInstance] issuesByProjectId:_settings.selectedProjectId];
    
    _issues = [NSMutableArray array];

    // Фильтруем задачи
    for (Issue *i in issues)
    {
        if ([MFFiltersControl checkIssueWithStatusIndex:[i.status.nid intValue]
                                          priorityIndex:[i.priority.nid intValue]
                                        andTrackerIndex:[i.tracker.nid intValue]])
        {        
            [_issues addObject:i];
        }
    }
    
    [self reloadData];
}

// Создаем массив ячеек
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    [[cell viewWithTag:1] setHidden:NO];
    [[cell viewWithTag:2] setHidden:YES];
    
    if (_selectedRow == -1)
    {
        if (row == 0)
        {
            _selectedRow = row;
        }
    }
    
    if (row == _selectedRow)
    {
        [[cell viewWithTag:1] setHidden:YES];
        [[cell viewWithTag:2] setHidden:NO];
    }
    
    return cell;    
}

// Генерим данные
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _issues.count;
}

// Сетим данные
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Issue *issue = [_issues objectAtIndex:row];
    
    NSString *type = [NSString stringWithFormat:@"%@ %@ %@", [issue.status.name lowercaseString], [issue.priority.name  lowercaseString], [issue.tracker.name lowercaseString]];
    
    NSString *number = [NSString stringWithFormat:@"#%@", issue.nid];
    
    if (row == 0)
    {
        [self issueSelected:issue.nid];
    }
    
    return @{@"type":type, @"text":issue.name, @"number":number, @"nid":issue.nid};
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self selectIssueByRow:self.selectedRow];
}

- (void) issueSelected:(NSNumber *)nid
{
    _settings.selectedIssueId = nid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUE_SELECTED object:nil];
}

@end
