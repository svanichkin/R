//
//  MFAppDelegate.m
//  R
//
//  Created by Сергей Ваничкин on 22.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFAppDelegate.h"
#import "MFConnector.h"
#import "RKIssue.h"
#import "MFSettings.h"

@implementation MFAppDelegate
{
    NSArray *_projects;
    NSMenuItem *_projectSelected;
    NSArray *_issues;
    NSTableCellView *_oldCellSelected;
    
    MFSettings *_settings;
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize managedObjectContext       = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionComplete:)
                                                 name:CONNECT_COMPLETE
                                               object:nil];
    
    _settings = [MFSettings sharedInstance];
    
    // Если есть креды, делаем автоконнект к серверу
    if (_settings.credentials)
    {
        [[MFConnector sharedInstance] connect];
    }
    
    //[_issuesTable setAction:@selector(issuesCellSelected:)];
}

- (void) connectionComplete:(NSNotification *) notification
{
    if ([notification.object boolValue])
    {
        /*NSArray *operationsArray = @[
        [NSBlockOperation blockOperationWithBlock:^
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                // Загрузка значений с сервера для генерации количества и названий сегментов
                [[MFConnector sharedInstance] loadFilters];
            });
        }],
    
        [NSBlockOperation blockOperationWithBlock:^
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                // Загрузка списка проектов
                [[MFConnector sharedInstance] loadProjects];
            });
        }],
        
        [NSBlockOperation blockOperationWithBlock:^
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                // Загрузка списка задач
                [[MFConnector sharedInstance] loadIssues];
            });
        }]];
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue addOperations:operationsArray waitUntilFinished:YES];*/
        
        // Загрузка значений с сервера для генерации количества и названий сегментов
//        [[MFConnector sharedInstance] loadFilters];
        
        // Загрузка списка проектов
//        [[MFConnector sharedInstance] loadProjects];
        
        // Загрузка списка задач
//        [[MFConnector sharedInstance] loadIssues];
    }
}

#pragma mark - Table view callbacks

// Если выбрали задачу в левом окне
- (void) issuesCellSelected:(NSTableView *)sender
{
    /*if (_oldCellSelected)
    {
        [[_oldCellSelected viewWithTag:1] setHidden:NO];
        [[_oldCellSelected viewWithTag:2] setHidden:YES];
    }
    
    NSInteger row = [_issuesTable clickedRow];
    
    if (row != -1)
    {
        NSTableCellView *cellView = [_issuesTable viewAtColumn:0 row:row makeIfNecessary:YES];
        [[cellView viewWithTag:1] setHidden:YES];
        [[cellView viewWithTag:2] setHidden:NO];
        [_mainPageScroll setHidden:NO];
        _oldCellSelected = cellView;
        
        RKIssue *issue = [_issues objectAtIndex:row];
        
        NSString *smallHeader = [NSString stringWithFormat:@"#%@ – %@ %@", issue.index, [issue.priority.name lowercaseString], [issue.tracker.name lowercaseString]];
        
        if (issue.fixedVersion.name)
        {
            smallHeader = [NSString stringWithFormat:@"%@ for version %@, %@", smallHeader, issue.fixedVersion.name, [issue.status.name lowercaseString]];
        }
        else
        {
            smallHeader = [NSString stringWithFormat:@"%@, %@", smallHeader, [issue.status.name lowercaseString]];
        }
        
        if ([issue.doneRatio intValue] > 0)
        {
            smallHeader = [NSString stringWithFormat:@"%@ %@%%.", smallHeader, issue.doneRatio];
        }
        else
        {
            smallHeader = [NSString stringWithFormat:@"%@.", smallHeader];
        }
        
        RKValue *h = issue.spentHours;
        if (issue.spentHours)
        {
            smallHeader = [NSString stringWithFormat:@"%@ Spent time %@ hour.", smallHeader, issue.spentHours.value];
        }
        _smallHeader.stringValue = smallHeader;
        
        //#30000 – immediate question for version 2.4.11, in progress 50%. Spent time 0.9 hour.
    }
    else
    {
        [_mainPageScroll setHidden:YES];
    }*/
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "ru.macflash.R" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"ru.macflash.R"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"R" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"R.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

// Если окно закрыли, покажем обратно при нажатии на иконку программы
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (flag)
    {
        return NO;
    }
    else
    {
        [_window makeKeyAndOrderFront:self];
        return YES;
    }
}

@end
