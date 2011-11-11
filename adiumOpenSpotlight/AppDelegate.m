//
//  AppDelegate.m
//  adiumOpenSpotlight
//
//  Created by Leif Middelschulte on 11.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#define EXTERNAL_RECORD_EXTENSION @"adiumContact"

#import "AppDelegate.h"
#import "AdiumContact.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)files
{
    NSString *aPath = [files lastObject]; // just an example to get at one of 
    the paths
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

                AdiumContact *contact = mo;
                
                
                
            }
        }
    }
}
@end
