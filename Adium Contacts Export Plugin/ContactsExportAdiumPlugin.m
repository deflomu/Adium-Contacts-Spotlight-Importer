//
//  ContactsExportAdiumPlugin.m
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactsExportAdiumPlugin.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIDebugControllerProtocol.h>
#import <Adium/AIContactList.h>
#import <Adium/AIPathUtilities.h>

@implementation ContactsExportAdiumPlugin

- (void) installPlugin
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsConnected:) name:ACCOUNT_CONNECTED object:nil];
    
    path = [adium createResourcePathForName:EXPORTED_CONTACTS_DIRECTORY];
    
}

- (void) uninstallPlugin
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) accountsConnected:(NSNotification *)aNotification {
    NSArray *allContacts = nil;
    NSString *contactFile = nil;
    allContacts = [[adium contactController] allContacts];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
        
    for (AIListContact *contact in allContacts) {
        contactFile = [NSString stringWithFormat:@"%@/%@.%@", path, contact.UID, EXPORTED_CONTACT_EXTENSION];
        
        if ( ![mgr createFileAtPath:contactFile contents:nil attributes:nil] )
            NSLog(@"Could not create file: %@", contactFile);
    }
}

@end
