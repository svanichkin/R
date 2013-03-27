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
            
            for (int i = 0; i < projects.count; i ++)
            {
                Project *p = [projects objectAtIndex:i];
                
                // !!!!!!!!! проверить, есть ли событие у самого селектора и подрубить его через интерфейс билдер
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:p.name
                                                              action:@selector (projectSelected:)
                                                       keyEquivalent:@""];
                item.tag = [p.pid intValue];
                [self.menu addItem:item];
            }
            
            //!!!!!!!!!! проверить, если ноль и айдиеник значит не найден
            [self selectItemWithTag:[_settings.selectedProjectId intValue]];
        }
    
        [self setEnabled:projects.count];
    }
}

- (void) projectSelected:(NSMenuItem *)sender
{
    // Сохраним значения сегментов, что бы восстановить при следующем входе
    _settings.selectedProjectId = @(sender.tag);

    // Передаем дальше событие
    /*if (_mainTarget && _mainAction)
    {
        if ([_mainTarget respondsToSelector:_mainAction])
        {
            [_mainTarget performSelector:_mainAction withObject:sender afterDelay:0];
        }
    }*/
}

@end