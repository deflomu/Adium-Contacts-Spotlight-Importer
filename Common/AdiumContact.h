//
//  AdiumContact.h
//  Adium Contacts Spotlight Importer
//
//  Created by Leif Middelschulte on 04.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AdiumContact : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * ownDisplayName;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) id userIcon;

@end
