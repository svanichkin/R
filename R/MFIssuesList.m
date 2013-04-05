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

@implementation MFIssuesList
{
    MFSettings *_settings;
    NSArray *_issues;
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
        self.dataSource = self;
    }
    return self;
}

- (void) resetData
{
    
}

- (void) projectSelected:(NSNotification *) notification
{
    _issues = [[MFDatabase sharedInstance] issuesByProjectId:_settings.selectedProjectId];
        
    // Генерация таблицы
    if (_issues)
    {
//            self.m
            
            /*[self.menu removeAllItems];
            
            for (Issue *p in _issues)
            {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:p.name
                                                              action:nil//@selector (projectSelected:)
                                                       keyEquivalent:@""];
                item.target = self;
                item.tag = [p.nid intValue];
                [self.menu addItem:item];
            }*/
            
            // Сетим выбранный проект
            //[self selectItemWithTag:[_settings.selectedProjectId intValue]];
//            self sele
        }
        
//        [self setEnabled:_issues.count];
        [self setEnabled:YES];
    [self reloadData];
        
//        selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:
//        - (NSTableViewSelectionHighlightStyle)selectionHighlightStyle NS_AVAILABLE_MAC(10_5);
//       - (void)setSelectionHighlightStyle:(NSTableViewSelectionHighlightStyle)selectionHighlightStyle NS_AVAILABLE_MAC(10_5);

}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _issues.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSButtonCell *cell = [[NSButtonCell alloc] init];
    [cell setAllowsMixedState:YES];
    [(NSButtonCell *)cell setButtonType:NSSwitchButton];
    [cell setTitle:@"Test"];
    
    return cell;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
}

// Выбрали один из проектов
//- (void) projectSelected:(NSNotification *) notification
//{
    // Скрываем правый фрейм
    /*[_mainPageScroll setHidden:YES];
     
     // Скрываем нажатую ячейку
     if (_oldCellSelected)
     {
     [[_oldCellSelected viewWithTag:1] setHidden:NO];
     [[_oldCellSelected viewWithTag:2] setHidden:YES];
     }
     
     _projectSelected = item;
     
     // Загрузка задач по проекту
     RKProject *projects = [_projects objectAtIndex:item.tag];
     _issues = projects.issues;
     
     NSUInteger count = [_issuesArrayController.arrangedObjects count];
     [_issuesArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,count)]];
     
     for (RKIssue *i in _issues)
     {
     if ([_filtersControl checkIssueWithStatusIndex:[i.status.index intValue]
     priorityIndex:[i.priority.index intValue]
     andTrackerIndex:[i.tracker.index intValue]])
     {
     
     NSString *type = [NSString stringWithFormat:@"%@ %@ %@", [i.status.name lowercaseString], [i.priority.name  lowercaseString], [i.tracker.name lowercaseString]];
     
     [_issuesArrayController addObject:@{@"text":[NSString stringWithFormat:@"%@", i.subject],
     @"type":type,
     @"number":[NSString stringWithFormat:@"#%@", i.index]}];
     }
     }
     [_issuesTable reloadData];
     [_issuesTable deselectAll:nil];
     */
//}

- (void) redrawIssues
{
    
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
