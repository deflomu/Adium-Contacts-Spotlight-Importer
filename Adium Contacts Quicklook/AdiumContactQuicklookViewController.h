//
//  AdiumContactQuicklookViewController.h
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 18.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AdiumContactQuicklookViewController : NSViewController {
    IBOutlet NSTextField *uiDisplayName;
    IBOutlet NSImageView *uiUserIcon;
}

@property (retain) NSTextField *uiDisplayName;
@property (retain) NSImageView *uiUserIcon;

@end
