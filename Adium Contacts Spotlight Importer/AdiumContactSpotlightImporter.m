//
//  AdiumContactSpotlightImporter.m
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#define STORE_TYPE NSXMLStoreType
#define ENTITY_CONTACT_NAME @"Contact"

#import "AdiumContactSpotlightImporter.h"
#import "AdiumContact.h"

@interface AdiumContactSpotlightImporter ()
@property (nonatomic, strong) NSURL *modelURL;
@property (nonatomic, strong) NSURL *storeURL;
@end

@implementation AdiumContactSpotlightImporter

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize modelURL = _modelURL;
@synthesize storeURL = _storeURL;

- (BOOL)importFileAtPath:(NSString *)filePath attributes:(NSMutableDictionary *)spotlightData error:(NSError **)error
{
        
    NSDictionary *pathInfo = [NSPersistentStoreCoordinator elementsDerivedFromExternalRecordURL:[NSURL fileURLWithPath:filePath]];
            
    self.modelURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSModelPathKey]];
    self.storeURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSStorePathKey]];


    NSURL *objectURI = [pathInfo valueForKey:NSObjectURIKey];
    NSManagedObjectID *oid = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURI];

    if (!oid) {
        NSLog(@"%@:%@ to find object id from path %@", [self class], NSStringFromSelector(_cmd), filePath);
        return NO;
    }

    NSManagedObject *instance = [[self managedObjectContext] objectWithID:oid];

    // how you process each instance will depend on the entity that the instance belongs to

    if ([[[instance entity] name] isEqualToString:ENTITY_CONTACT_NAME]) {

        // set the display name for Spotlight search result
        NSString *nickname = [instance valueForKey:@"ownDisplayName"];
        if (!nickname)
            nickname = [instance valueForKey:@"displayName"];
        if (!nickname)
            return NO;

        [spotlightData setObject:nickname forKey:(NSString *)kMDItemDisplayName];
        
         /*
            Determine how you want to store the instance information in 'spotlightData' dictionary.
            For each property, pick the key kMDItem... from MDItem.h that best fits its content.  
            If appropriate, aggregate the values of multiple properties before setting them in the dictionary.
            For relationships, you may want to flatten values. 

            id YOUR_FIELD_VALUE = [instance valueForKey:ATTRIBUTE_NAME];
            [spotlightData setObject:YOUR_FIELD_VALUE forKey:(NSString *) kMDItem...];
            ... more property values; 
            To determine if a property should be indexed, call isIndexedBySpotlight

         */

    }

    return YES;
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
