#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <CoreData/CoreData.h>
#include <Cocoa/Cocoa.h>
#include "CommonHeaders.h"

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
    
    NSRect  viewRect  ;
    NSTextField *uiDisplayName;
    
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
        
        viewRect = NSMakeRect( 0, 0, 500.0,  500.0 );
        NSView *view = [[NSView alloc] initWithFrame:viewRect];
        
        NSString *nickname = [instance valueForKey:@"ownDisplayName"];
        if (!nickname)
            nickname = [instance valueForKey:@"displayName"];
        if (!nickname)
            return NO;
        uiDisplayName   = [ [ NSTextField alloc ] init];
        [uiDisplayName setStringValue:nickname];
        [uiDisplayName setDrawsBackground:NO];
        [view addSubview:uiDisplayName];
        
        NSData *imageData = [instance valueForKey:@"userIcon"];
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:imageData];
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:imageRep];
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImage:image];
        [view addSubview:imageView];

        CGSize canvasSize = CGSizeMake(500.0, 500.0);
        CGContextRef cgContext = QLPreviewRequestCreateContext(preview, canvasSize, true, NULL);
        
        if(cgContext) {
            NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:context];
                [context saveGraphicsState];
                
                [view displayRectIgnoringOpacity:viewRect inContext:context];
                
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
