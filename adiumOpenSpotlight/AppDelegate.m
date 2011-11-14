//
//  AppDelegate.m
//  adiumOpenSpotlight
//
//  Created by Leif Middelschulte on 11.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#define EXTERNAL_RECORD_EXTENSION @"adiumContact"

#import "AdiumContact.h"
#import "AppDelegate.h"


@implementation AppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)files
{
    NSString *aPath = [files lastObject]; // just an example to get at one of the paths
    if (aPath && [aPath hasSuffix:EXTERNAL_RECORD_EXTENSION]) {
        // decode URI from path
        NSURL *objectURI = [[NSPersistentStoreCoordinator 
                             elementsDerivedFromExternalRecordURL:[NSURL fileURLWithPath:aPath]] 
                            objectForKey:NSObjectURIKey];
        if (objectURI) {
            NSManagedObjectID *moid = [[self persistentStoreCoordinator] 
                                       managedObjectIDForURIRepresentation:objectURI];
            if (moid) {
                NSManagedObject *mo = [[self managedObjectContext] 
                                       objectWithID:moid];
                // your code to select the object in your application's UI

                AdiumContact *contact = (AdiumContact*)mo;
                
                if (!contact.accountName || !contact.uid)
                    return;
                //FIXME add parameters like [NSString stringWithFormat]
                NSString *myScript =   [NSString stringWithFormat:@"tell application \"Adium\""
                                            "tell account \"%@\" to make new chat with contacts {contact \"%@\"} with new chat window\n"
                                            "activate\n"
                                        "end tell", contact.accountName, contact.uid];
                NSAppleScript *script = [[NSAppleScript alloc] initWithSource:myScript];
                
                [script executeAndReturnError:nil];
            }
        }
    }
}

/**
 Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
    
    NSBundle *myBundle = [NSBundle mainBundle];
    
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
    NSURL *applicationFilesDirectory = [[NSBundle mainBundle] bundleURL];
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

@end
