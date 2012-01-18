#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <CoreData/CoreData.h>
#include <Cocoa/Cocoa.h>
#include "CommonHeaders.h"
#include "AdiumContactQuicklookViewController.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool *pool;
    NSError *error = nil;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *pathInfo = [NSPersistentStoreCoordinator elementsDerivedFromExternalRecordURL:((__bridge NSURL*)url)];
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[pathInfo valueForKey:NSModelPathKey]]];
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSURL *storeURL = [NSURL fileURLWithPath:[pathInfo valueForKey:NSStorePathKey]];
    
    if (![coordinator addPersistentStoreWithType:STORE_TYPE configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unable to add persistent store coordinator - %@", error);
    }
    
    NSURL *uri = [pathInfo valueForKey:NSObjectURIKey];
    
    NSManagedObjectID *oid = [coordinator managedObjectIDForURIRepresentation:uri];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    
    NSManagedObject *instance = [moc objectWithID:oid];
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    if (instance!=NULL) {
        
        NSBundle *myBundle = [NSBundle bundleWithIdentifier:@"net.skweez.adium.contact.Adium-Contacts-Quicklook"];
        
        AdiumContactQuicklookViewController *acqvc = [[AdiumContactQuicklookViewController alloc] initWithNibName:@"AdiumContactQuicklookViewController" bundle:myBundle];
        
        NSString *nickname = [instance valueForKey:@"ownDisplayName"];
        if (!nickname)
            nickname = [instance valueForKey:@"displayName"];
        if (!nickname)
            return NO;
        acqvc.uiDisplayName.stringValue = nickname;
        
        NSData *imageData = [instance valueForKey:@"userIcon"];
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:imageRep];
        [acqvc.uiUserIcon setImage:image];

        CGSize canvasSize = CGSizeMake(acqvc.view.frame.size.width, acqvc.view.frame.size.height);
        CGContextRef cgContext = QLPreviewRequestCreateContext(preview, canvasSize, true, NULL);
        
        if(cgContext) {
            NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:context];
                [context saveGraphicsState];
                
                [acqvc.view displayRectIgnoringOpacity:acqvc.view.frame inContext:context];
                
                [context restoreGraphicsState];
                [NSGraphicsContext restoreGraphicsState];
            }
            QLPreviewRequestFlushContext(preview, cgContext);
            CFRelease(cgContext);
        }
    }
    
    [pool release];
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
