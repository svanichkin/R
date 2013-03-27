//
//  MFFiltersControl.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFFiltersControl.h"
#import "MFConnector.h"
#import "MFSettings.h"

@implementation MFFiltersControl
{
    MFSettings *_settings;
    SEL _mainAction;
    id _mainTarget;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(filtersLoaded:)
                                                     name:FILTERS_LOADED
                                                   object:nil];
        
        _settings = [MFSettings sharedInstance];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

- (void) filtersLoaded:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        if (_settings.filters)
        {
            self.hidden = NO;
            
            _mainAction = self.action;
            _mainTarget = self.target;
            
            self.target = self;
            [self setAction:@selector(segmentChanged:)];
            
            // Генерация кнопок с названиями фильтров
            NSArray *statuses = _settings.filtersStatuses;
            NSArray *trackers = _settings.filtersTrackers;
            NSArray *priorities = _settings.filtersPriorities;
            
            NSInteger segmentsCount = statuses.count + trackers.count + priorities.count;
            [self setSegmentCount:segmentsCount];
            
            int i = 0;
            for (NSDictionary *status in statuses)
            {
                
                [self setLabel:[status objectForKey:@"name"] forSegment:i ++];
            }
            
            for (NSDictionary *tracker in trackers)
            {
                [self setLabel:[tracker objectForKey:@"name"] forSegment:i ++];
            }
            
            for (NSDictionary *prioritie in priorities)
            {
                [self setLabel:[prioritie objectForKey:@"name"] forSegment:i ++];
            }

            // Загрузка сохраненных значений, если имеются и подходят
            NSArray *states = _settings.filtersStates;
            if (states.count > 0 && states.count == segmentsCount)
            {
                for (int i = 0; i < segmentsCount; i ++)
                {
                    [self setSelected:[[states objectAtIndex:i] boolValue] forSegment:i];
                }
            }
            // Если у нас приложение запущено первый раз, то выключим все фильтры
            else
            {
                for (int i = 0; i < segmentsCount; i ++)
                {
                    [self setSelected:YES forSegment:i];
                }
            }
        }
        else
        {
            self.hidden = YES;
        }
    }
}

// Проверяем, проходит ли задача через фильтр или нет
- (BOOL) checkIssueWithStatusIndex:(int)status priorityIndex:(int)priority andTrackerIndex:(int)tracker
{
    NSInteger statusesCount = _settings.filtersStatuses.count - 1;
    NSInteger trackersCount = _settings.filtersTrackers.count - 1;
    
    BOOL statusSegmentPressed =   [self isSelectedForSegment:status - 1];
    BOOL trackerSegmentPressed =  [self isSelectedForSegment:statusesCount + tracker];
    BOOL prioritySegmentPressed = [self isSelectedForSegment:statusesCount + trackersCount + priority - 1];
    
    return (statusSegmentPressed && trackerSegmentPressed && prioritySegmentPressed);
}


- (void) segmentChanged:(id)sender
{
    // Сохраним значения сегментов, что бы восстановить при следующем входе
    NSInteger count = self.segmentCount;
    NSMutableArray *states = [NSMutableArray array];
    for (int i = 0; i < count; i ++)
    {
        [states addObject:@([self isSelectedForSegment:i])];
    }
    _settings.filtersStates = states;
    
    // Передаем дальше событие
    if (_mainTarget && _mainAction)
    {
        if ([_mainTarget respondsToSelector:_mainAction])
        {
            [_mainTarget performSelector:_mainAction withObject:sender afterDelay:0];
        }
    }
}

@end
