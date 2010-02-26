//
//  BlioProcessing.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessing.h"


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
    
    NSError *error;
    if (![moc save:&error]) {
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
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
        NSLog(@"Failed to retrieve book");
        return;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"processingComplete == %@", [NSNumber numberWithBool:YES]]];
    
    // Block whilst we calculate the position so that other threads don't perform the same
    // check at the same time
    NSError *error;
    @synchronized (self.storeCoordinator) {
        NSUInteger count = [moc countForFetchRequest:request error:&error];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", error, [error userInfo]);
        } else {
            [book setValue:[NSNumber numberWithInt:count] forKey:@"position"];
            [book setValue:[NSNumber numberWithBool:YES] forKey:@"processingComplete"];
        }
        
        NSError *error;
        if (![moc save:&error]) {
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
        }
    }
    
    [moc release];
    
    [pool drain];
}

@end
