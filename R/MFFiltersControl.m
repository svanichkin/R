//
//  MFFiltersControl.m
//  R
//
//  Created by Сергей Ваничкин on 27.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFFiltersControl.h"

@interface MFFiltersControl ()

@property (nonatomic, strong) MFSettings *settings;

@property (nonatomic, assign) SEL mainAction;
@property (nonatomic, strong) id mainTarget;

@property (nonatomic, assign) NSInteger statusesCount;
@property (nonatomic, assign) NSInteger trackersCount;

@end

@implementation MFFiltersControl

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
                                                 selector:@selector(filtersLoaded:)
                                                     name:DATABASE_UPDATING_COMPLETE
                                                   object:nil];
        
        self.settings = [MFSettings sharedInstance];
    }
    return self;
}

- (void) resetData
{
    self.hidden = YES;
}

- (void) filtersLoaded:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        if (self.settings.dataLastUpdate)
        {
            self.hidden = NO;
            self.target = self;
            [self setAction:@selector(segmentChanged:)];
            
            MFDatabase *database = [MFDatabase sharedInstance];
            
            // Генерация кнопок с названиями фильтров
            NSArray *statuses   = database.statuses;
            NSArray *trackers   = database.trackers;
            NSArray *priorities = database.priorities;
            
            self.statusesCount = statuses.count;
            self.trackersCount = trackers.count;
            
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
            NSArray *states = self.settings.filtersStates;
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
                
                [self setStates];
            }
        
            [[NSNotificationCenter defaultCenter] postNotificationName:FILTERS_INITED object:nil];
        }
        else
        {
            self.hidden = YES;
        }
    }
}

// Проверяем, проходит ли задача через фильтр или нет
+ (BOOL) checkIssueWithStatusIndex:(int)status priorityIndex:(int)priority andTrackerIndex:(int)tracker
{
    MFSettings *settings = [MFSettings sharedInstance];
    MFDatabase *database = [MFDatabase sharedInstance];
    
    NSArray *statuses   = database.statuses;
    NSArray *trackers   = database.trackers;
    NSArray *priorities = database.priorities;

    BOOL statusSegmentPressed = NO;
    BOOL trackerSegmentPressed = NO;
    BOOL prioritySegmentPressed = NO;
    
    NSArray *states = settings.filtersStates;
    
    NSInteger i = 0;
    for (Status *s in statuses)
    {
        if ([s.nid isEqualToNumber:@(status)] && [[states objectAtIndex:i] boolValue] == YES)
        {
            statusSegmentPressed = YES;
            break;
        }
        i ++;
    }
    
    i = statuses.count;
    for (Tracker *t in trackers)
    {
        if ([t.nid isEqualToNumber:@(tracker)] && [[states objectAtIndex:i] boolValue] == YES)
        {
            trackerSegmentPressed = YES;
            break;
        }
        i ++;
    }
    
    i = trackers.count;
    for (Priority *p in priorities)
    {
        if ([p.nid isEqualToNumber:@(priority)] && [[states objectAtIndex:i] boolValue] == YES)
        {
            prioritySegmentPressed = YES;
            break;
        }
        i ++;
    }

    return (statusSegmentPressed && trackerSegmentPressed && prioritySegmentPressed);
}

- (void) setStates
{
    // Сохраним значения сегментов, что бы восстановить при следующем входе
    NSInteger count = self.segmentCount;
    NSMutableArray *states = [NSMutableArray array];
    for (int i = 0; i < count; i ++)
    {
        [states addObject:@([self isSelectedForSegment:i])];
    }
    self.settings.filtersStates = states;
}

- (void) segmentChanged:(id)sender
{
    [self setStates];

    [[NSNotificationCenter defaultCenter] postNotificationName:FILTERS_CHANGED object:nil];
}

@end
