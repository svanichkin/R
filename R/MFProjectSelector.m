//
//  MFProjectSelector.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFProjectSelector.h"
#import "MFDatabase.h"
#import "MFSettings.h"

@implementation MFProjectSelector
{
    MFSettings *_settings;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(projectsLoaded:)
                                                     name:PROJECTS_LOADED
                                                   object:nil];
        _settings = [MFSettings sharedInstance];
    }
    return self;
}

- (void) projectsLoaded:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        NSArray *projects = [[MFDatabase sharedInstance] projects];
        
        // Генерация выпадающего меню
        if (projects)
        {
            [self.menu removeAllItems];
            
            for (Project *p in projects)
            {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:p.name
                                                              action:@selector (projectSelected:)
                                                       keyEquivalent:@""];
                item.target = self;
                item.tag = [p.nid intValue];
                [self.menu addItem:item];
            }
            
            // Сетим выбранный проект
            [self selectItemWithTag:[_settings.selectedProjectId intValue]];
        }
    
        [self setEnabled:projects.count];
    }
}

- (void) projectSelected:(NSMenuItem *)sender
{
    if ([_settings.selectedProjectId intValue] != sender.tag)
    {
        // Сохраним значения сегментов, что бы восстановить при следующем входе
        _settings.selectedProjectId = @(sender.tag);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PROJECT_SELECTED object:nil];
    }
}

@end