//
//  MFIssuesList.m
//  R
//
//  Created by Сергей Ваничкин on 28.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFIssuesList.h"
#import "MFFiltersControl.h"
#import "MFIssueCellView.h"

@interface MFIssuesList ()

@property (nonatomic, strong) MFSettings *settings;
@property (nonatomic, strong) NSMutableArray *issues;
@property (nonatomic, assign) NSInteger selectedRow;

@end

@implementation MFIssuesList

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
        
        self.settings = [MFSettings sharedInstance];
        self.delegate = self;
        self.dataSource = self;
        
        self.selectedRow = -1;
        
        self.backgroundColor = [NSColor clearColor];
    }
    return self;
}

- (void) resetData
{
    self.issues = [NSMutableArray array];

    [self reloadData];
}

- (void) selectIssueByRow:(NSInteger)row
{
    [self selectionReset];
    
    MFIssueCellView *selectedCell = [self viewAtColumn:0
                                                   row:row
                                       makeIfNecessary:NO];
    self.selectedRow = row;
    
    [selectedCell setSelected:YES];
    
    [self issueSelected:selectedCell.nid];
}

- (void) selectionReset
{
    if (self.selectedRow > -1)
    {
        MFIssueCellView *selectedCell = [self viewAtColumn:0
                                                       row:self.selectedRow
                                           makeIfNecessary:NO];
    
        // Скрываем нажатую ячейку
        [selectedCell setSelected:NO];
        
        self.selectedRow = -1;
    }
}

- (void) refreshIssues:(NSNotification *) notification
{
    [self selectionReset];
    
    NSArray *issues = [[MFDatabase sharedInstance] issuesByProjectId:self.settings.selectedProjectId];
    
    self.issues = [NSMutableArray array];

    // Фильтруем задачи
    for (Issue *i in issues)
    {
        if ([MFFiltersControl checkIssueWithStatusIndex:[i.status.nid intValue]
                                          priorityIndex:[i.priority.nid intValue]
                                        andTrackerIndex:[i.tracker.nid intValue]])
        {        
            [self.issues addObject:i];
        }
    }
    
    [self reloadData];
}

#pragma mark - Table View Data Source Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.issues.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MFIssueCellView *cell = [tableView makeViewWithIdentifier:NSStringFromClass([MFIssueCellView class])
                                                        owner:self];
    
    [cell setSelected:NO];
    
    if (self.selectedRow == -1)
        if (row == 0)
            self.selectedRow = row;
    
    if (row == self.selectedRow)
        [cell setSelected:YES];
    
    Issue *issue = [self.issues objectAtIndex:row];
    
    NSString *type = [NSString stringWithFormat:@"%@ %@ %@",
                      [issue.status.name lowercaseString],
                      [issue.priority.name  lowercaseString],
                      [issue.tracker.name lowercaseString]];
    
    cell.taskType.stringValue = type;
    
    NSString *number = [NSString stringWithFormat:@"#%@", issue.nid];
    
    cell.taskNumber.stringValue = number;
    
    if (row == 0)
        [self issueSelected:issue.nid];
    
    cell.nid = issue.nid;
    
    cell.issueText.stringValue = issue.name;
    
    return cell;    
}

#pragma mark - Actions

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    MFIssuesList *m = aNotification.object;
    NSIndexSet *s = m.selectedRowIndexes;

    [self selectIssueByRow:s.firstIndex];
}

- (void) issueSelected:(NSNumber *)nid
{
    self.settings.selectedIssueId = nid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUE_SELECTED object:nil];
}

@end
