//
//  ContactsExportAdiumPlugin.h
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import "CommonHeaders.h"

#define EXPORTED_CONTACTS_DIRECTORY @"Exported Contacts"
#define EXPORTED_CONTACT_EXTENSION @"adiumContact"

@interface ContactsExportAdiumPlugin : NSObject <AIPlugin> {
    NSString *path;
    
    NSBundle *myBundle;
    
    NSString *externalRecordsSupportFolder;
}

@property (retain) NSString *path;
@property (retain) NSBundle *myBundle;
@property (retain) NSString *externalRecordsSupportFolder;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
