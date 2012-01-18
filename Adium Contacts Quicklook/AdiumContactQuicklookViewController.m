//
//  AdiumContactQuicklookViewController.m
//  Adium Contacts Spotlight Importer
//
//  Created by Florian Mutter on 18.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AdiumContactQuicklookViewController.h"

@implementation AdiumContactQuicklookViewController

@synthesize uiDisplayName, uiUserIcon;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self loadView];
    }
    
    return self;
}

@end
