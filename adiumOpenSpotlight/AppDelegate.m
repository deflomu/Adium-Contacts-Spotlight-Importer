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
#import "CommonHeaders.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSURL *modelURL;
@property (nonatomic, strong) NSURL *storeURL;
@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize modelURL = _modelURL;
@synthesize storeURL = _storeURL;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    [[NSApplication sharedApplication] terminate:self];

}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)files
{
    NSString *aPath = [files lastObject]; // just an example to get at one of the paths
    if (aPath && [aPath hasSuffix:EXTERNAL_RECORD_EXTENSION]) {
        
        NSDictionary *pathInfo = [NSPersistentStoreCoordinator elementsDerivedFromExternalRecordURL:[NSURL fileURLWithPath:aPath]];
        
        self.modelURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSModelPathKey]];
        self.storeURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSStorePathKey]];
        
        // decode URI from path
        NSURL *objectURI = [pathInfo valueForKey:NSObjectURIKey];
        
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
                NSString *myScript =   [NSString stringWithFormat:@"tell application \"Adium\"\n"
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
 Returns the managed object model. 
 The last read model is cached in a global variable and reused
 if the URL and modification date are identical
 */
static NSURL				*cachedModelURL = nil;
static NSManagedObjectModel *cachedModel = nil;
static NSDate				*cachedModelModificationDate =nil;

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) return __managedObjectModel;
	
	NSDictionary *modelFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.modelURL path] error:nil];
	NSDate *modelModificationDate =  [modelFileAttributes objectForKey:NSFileModificationDate];
	
	if ([cachedModelURL isEqual:self.modelURL] && [modelModificationDate isEqualToDate:cachedModelModificationDate]) {
		__managedObjectModel = cachedModel;
	} 	
	
	if (!__managedObjectModel) {
		__managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
        
		if (!__managedObjectModel) {
			NSLog(@"%@:%@ unable to load model at URL %@", [self class], NSStringFromSelector(_cmd), self.modelURL);
			return nil;
		}
        
		// Clear out all custom classes used by the model to avoid having to link them
		// with the importer. Remove this code if you need to access your custom logic.
		NSString *managedObjectClassName = [NSManagedObject className];
		for (NSEntityDescription *entity in __managedObjectModel) {
			[entity setManagedObjectClassName:managedObjectClassName];
		}
		
		// cache last loaded model
        
		cachedModelURL = self.modelURL;
		cachedModel = __managedObjectModel;
		cachedModelModificationDate = modelModificationDate;
	}
	
	return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the importer.  
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator) return __persistentStoreCoordinator;
    
    NSError *error = nil;
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:STORE_TYPE configuration:nil URL:self.storeURL options:nil error:&error]) {
        NSLog(@"%@:%@ unable to add persistent store coordinator - %@", [self class], NSStringFromSelector(_cmd), error);
    }    
    
    return __persistentStoreCoordinator;
}

/**
 Returns the managed object context for the importer; already
 bound to the persistent store coordinator. 
 */

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) return __managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (!coordinator) {
        NSLog(@"%@:%@ unable to get persistent store coordinator", [self class], NSStringFromSelector(_cmd));
		return nil;
	}
    
	__managedObjectContext = [[NSManagedObjectContext alloc] init];
	[__managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return __managedObjectContext;
}

@end
