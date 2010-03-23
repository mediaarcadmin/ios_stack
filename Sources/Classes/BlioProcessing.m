//
//  BlioProcessing.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessing.h"
#import "BlioMockBook.h"


@implementation BlioProcessingOperation

@synthesize bookID, storeCoordinator, forceReprocess, percentageComplete, cacheDirectory;

- (void)dealloc {
    self.bookID = nil;
    self.storeCoordinator = nil;
    self.cacheDirectory = nil;
    [super dealloc];
}

- (void)setBookValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    NSManagedObject *book = [moc objectWithID:self.bookID];
    if (nil == book) 
        NSLog(@"Failed to retrieve book");
    else
        [book setValue:value forKey:key];
    
    NSError *anError;
    if (![moc save:&anError]) {
        NSLog(@"Save failed with error: %@, %@", anError, [anError userInfo]);
    }
    
    [moc release];
    
    [pool drain];
}

- (id)getBookValueForKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    NSManagedObject *book = [moc objectWithID:self.bookID];
    
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        [moc release];
        [pool drain];
        return nil;
    } 
    
    id value = [book valueForKey:key];
    [moc release];
    [pool drain];

    return value;
}

- (void)setBookProcessingComplete {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator];
    NSManagedObject *book = [moc objectWithID:self.bookID];
    
    if (nil == book) {
        [moc release];
        NSLog(@"Failed to retrieve book");
        return;
    }
    
    NSFetchRequest *aRequest = [[NSFetchRequest alloc] init];
    [aRequest setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [aRequest setPredicate:[NSPredicate predicateWithFormat:@"processingComplete == %@", [NSNumber numberWithBool:YES]]];
    
    // Block whilst we calculate the position so that other threads don't perform the same
    // check at the same time
    NSError *anError;
    @synchronized (self.storeCoordinator) {
        NSUInteger count = [moc countForFetchRequest:aRequest error:&anError];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", anError, [anError userInfo]);
        } else {
            [book setValue:[NSNumber numberWithInt:count] forKey:@"position"];
            [book setValue:[NSNumber numberWithBool:YES] forKey:@"processingComplete"];
        }
        
        NSError *anError;
        if (![moc save:&anError]) {
            NSLog(@"Save failed with error: %@, %@", anError, [anError userInfo]);
        }
    }
    
    [aRequest release];
    [moc release];
    
    [pool drain];
}

@end
