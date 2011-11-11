//
//  ContactsExportAdiumPlugin.m
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactsExportAdiumPlugin.h"
#import "AdiumContact.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIDebugControllerProtocol.h>
#import <Adium/AIContactList.h>
#import <Adium/AIPathUtilities.h>

@implementation ContactsExportAdiumPlugin

@synthesize path;

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

/**
 Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
    
    NSArray *pluginsPaths = AISearchPathForDirectories(AIPluginsDirectory);
    
    NSBundle *myBundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Adium Contacts Export Plugin.AdiumPlugin", [pluginsPaths objectAtIndex:0]]];
    
    NSURL *modelURL = [myBundle URLForResource:@"Adium" withExtension:@"mom"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [NSURL fileURLWithPath:self.path];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"AdiumContacts.storedata"];
    
    NSString *externalRecordsSupportFolder = [@"~/Library/Caches/Metadata/CoreData/AdiumContacts/" stringByExpandingTildeInPath];
    
    [fileManager createDirectoryAtPath:externalRecordsSupportFolder withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        [[NSApplication sharedApplication] presentError:error];
    }
    
    NSMutableDictionary *storeOptions = [[NSMutableDictionary alloc] init];
    [storeOptions setObject:@"adiumContact" forKey:NSExternalRecordExtensionOption];
    [storeOptions setObject:externalRecordsSupportFolder forKey:NSExternalRecordsDirectoryOption];
    [storeOptions setObject:NSBinaryExternalRecordType forKey:NSExternalRecordsFileFormatOption];
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:storeOptions error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;
    
    return __persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
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
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return __managedObjectContext;
}

- (void)saveData {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)installPlugin
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsConnected:) name:ACCOUNT_CONNECTED object:nil];
    
    self.path = [adium createResourcePathForName:EXPORTED_CONTACTS_DIRECTORY];
}

- (void)uninstallPlugin
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) accountsConnected:(NSNotification *)aNotification {
    NSArray *allContacts = nil;
    AdiumContact *contactToSave = nil;
    allContacts = [[adium contactController] allContacts];
    
    for (AIListContact *contact in allContacts) {
        NSLog(@"%@", contact.UID);
        
        contactToSave = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
        contactToSave.uid = contact.UID;
        contactToSave.ownDisplayName = contact.ownDisplayName;
        contactToSave.displayName = contact.displayName;
        contactToSave.userIcon = contact.userIconData;
        contactToSave.accountName = contact.account.UID;
    }
    
    [self saveData];
}


@end
