//
//  BlioProcessingManager.m
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingManager.h"
#import "BlioMockBook.h"

@implementation BlioProcessingManager

@synthesize managedObjectContext;

- (void)dealloc {
    self.managedObjectContext = nil;
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext {
    if ((self = [super init])) {
        self.managedObjectContext = aManagedObjectContext;
    }
    return self;
}

#pragma mark -
#pragma mark BlioProcessingDelegate

- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL {
    NSLog(@"book enqueued with title: %@, authors: %@, coverURL: %@, ePurlURL: %@, pdfURL: %@", title, authors, coverURL, ePubURL, pdfURL);
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (nil != moc) {
        BlioMockBook *aBook = [NSEntityDescription insertNewObjectForEntityForName:@"BlioMockBook" inManagedObjectContext:moc];
        [aBook setValue:title forKey:@"title"];
        [aBook setValue:[authors lastObject] forKey:@"author"];
        [aBook setValue:[NSNumber numberWithBool:NO] forKey:@"processingComplete"];
        
        NSError *error;
        if (![moc save:&error]) {
            NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
        }
    }
}

@end
