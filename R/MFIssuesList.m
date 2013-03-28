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
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(issuesLoaded:)
                                                     name:ISSUES_LOADED
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(projectSelected:)
                                                     name:PROJECT_SELECTED
                                                   object:nil];
        _settings = [MFSettings sharedInstance];
    }
    return self;
}

- (void) issuesLoaded:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        NSArray *projects = [[MFDatabase sharedInstance] projects];
        
        // Генерация таблицы
        if (projects)
        {
            [self.menu removeAllItems];
            
            for (Project *p in projects)
            {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:p.name
                                                              action:@selector (projectSelected:)
                                                       keyEquivalent:@""];
                item.target = self;
                item.tag = [p.pid intValue];
                [self.menu addItem:item];
            }
            
            // Сетим выбранный проект
            [self selectItemWithTag:[_settings.selectedProjectId intValue]];
        }
        
        [self setEnabled:projects.count];
    }
}

// Выбрали один из проектов
- (IBAction) projectSelected:(MFProjectSelector *)selector
{
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
}

- (void) redrawIssues
{
    
}


@end
