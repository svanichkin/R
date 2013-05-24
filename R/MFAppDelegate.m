//
//  MFAppDelegate.m
//  R
//
//  Created by Сергей Ваничкин on 22.03.13.
//  Copyright (c) 2013 MacFlash. All rights reserved.
//

#import "MFAppDelegate.h"

@implementation MFAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize managedObjectContext       = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Если есть креды, делаем автоконнект к серверу
    if ([MFSettings sharedInstance].credentials)
    {
        [[MFConnector sharedInstance] connect];
    }
}

// Возвращает директорию которую использует приложение для хранения Core Data файла.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"R"];
}

- (void) createNewCoreData
{
    [self createNewManagedObjectModel];
    [self createNewPersistentStoreCoordinator];
    [self createNewManagerContext];
}

// Создает модель баы данных приложения.
- (void) createNewManagedObjectModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"R" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
    {
        return _managedObjectModel;
    }
    
    [self createNewManagedObjectModel];
    return _managedObjectModel;
}

// Возвращает persistent stor координатор приложения.
- (void) createNewPersistentStoreCoordinator
{
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom)
    {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        _persistentStoreCoordinator = nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties)
    {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError)
        {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok)
        {
            [[NSApplication sharedApplication] presentError:error];
            _persistentStoreCoordinator = nil;
        }
    }
    else
    {
        if (![properties[NSURLIsDirectoryKey] boolValue])
        {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            _persistentStoreCoordinator = nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"R.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        _persistentStoreCoordinator = nil;
    }
    _persistentStoreCoordinator = coordinator;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
    {
        return _persistentStoreCoordinator;
    }
    
    [self createNewPersistentStoreCoordinator];
    return _persistentStoreCoordinator;
}

// Возвращает managed object context приложения (который уже привязан к persistent store coordinator приложения) 
- (void) createNewManagerContext
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        _managedObjectContext = nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
    {
        return _managedObjectContext;
    }
    
    [self createNewManagerContext];
    return _managedObjectContext;
}

// Возвращает NSUndoManager приложения. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    /*
    // Сохраняются изменения приложения в managed object context перед выходом из приложения.

    if (!_managedObjectContext)
    {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges])
    {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error])
    {
        BOOL result = [sender presentError:error];
        if (result)
        {
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
        
        if (answer == NSAlertAlternateReturn) 
        {
            return NSTerminateCancel;
        }
    }*/

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
