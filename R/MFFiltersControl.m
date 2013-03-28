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
#import "MFDatabase.h"

@implementation MFFiltersControl
{
    MFSettings *_settings;
    SEL _mainAction;
    id _mainTarget;
    NSInteger _statusesCount;
    NSInteger _trackersCount;
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

- (void) filtersLoaded:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        if (_settings.filtersLastUpdate)
        {
            self.hidden = NO;
            self.target = self;
            [self setAction:@selector(segmentChanged:)];
            
            MFDatabase *database = [MFDatabase sharedInstance];
            
            // Генерация кнопок с названиями фильтров
            NSArray *statuses   = database.statuses;
            NSArray *trackers   = database.trackers;
            NSArray *priorities = database.priorities;
            
            _statusesCount = statuses.count;
            _trackersCount = trackers.count;
            
            NSInteger segmentsCount = statuses.count + trackers.count + priorities.count;
            [self setSegmentCount:segmentsCount];
            
            int i = 0;
            for (Status *status in statuses)
            {
                [self setLabel:status.name forSegment:i ++];
            }
            
            for (Tracker *tracker in trackers)
            {
                [self setLabel:tracker.name forSegment:i ++];
            }
            
            for (Priority *priority in priorities)
            {
                [self setLabel:priority.name forSegment:i ++];
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
    NSInteger statusesCount = _statusesCount - 1;
    NSInteger trackersCount = _trackersCount - 1;
    
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FILTERS_CHANGED object:nil];
}

@end
