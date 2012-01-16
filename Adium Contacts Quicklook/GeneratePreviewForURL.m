#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <CoreData/CoreData.h>
#include "CommonHeaders.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{

    NSDictionary *pathInfo = [NSPersistentStoreCoordinator elementsDerivedFromExternalRecordURL:url];
    
    NSURL *modelURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSModelPathKey]];
    NSURL *storeURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSStorePathKey]];
    
    
    NSURL *objectURI = [pathInfo valueForKey:NSObjectURIKey];
    NSManagedObjectID *oid = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURI];
    
    if (!oid) {
        NSLog(@"%@:%@ to find object id from path %@", [self class], NSStringFromSelector(_cmd), filePath);
        return 255;
    }
    
    NSManagedObject *instance = [[self managedObjectContext] objectWithID:oid];
    
    // how you process each instance will depend on the entity that the instance belongs to
    
    if ([[[instance entity] name] isEqualToString:ENTITY_CONTACT_NAME]) {
        
    }
    
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
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
    
    