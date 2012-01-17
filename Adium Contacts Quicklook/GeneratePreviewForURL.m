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
    NSAutoreleasePool *pool;
    NSMutableDictionary *props;
    NSMutableString *html;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *pathInfo = [NSPersistentStoreCoordinator elementsDerivedFromExternalRecordURL:((__bridge NSURL*)url)];
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[pathInfo valueForKey:NSModelPathKey]]];
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSError *error = nil;
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
    if (instance!=NULL)
    {
        props=[[[NSMutableDictionary alloc] init] autorelease];
        [props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
        [props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
        
        html=[[[NSMutableString alloc] init] autorelease];
        [html appendString:@"<html><body>"];
        
        NSString *nickname = [instance valueForKey:@"ownDisplayName"];
        if (!nickname)
            nickname = [instance valueForKey:@"displayName"];
        if (!nickname)
            return NO;
        
        [html appendFormat:@"<h1>%@</h1>", nickname];
        
        [html appendString:@"</body></html>"];
        
        QLPreviewRequestSetDataRepresentation(preview,(CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML,(CFDictionaryRef)props);
    }
    
    [pool release];
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
