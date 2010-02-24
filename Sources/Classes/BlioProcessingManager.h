//
//  BlioProcessingManager.h
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface BlioProcessingBookOperation : NSOperation {
    NSManagedObjectID *bookID;
    NSPersistentStoreCoordinator *storeCoordinator;
    BOOL forceReprocess;
    NSUInteger percentageComplete;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic) BOOL forceReprocess;
@property (nonatomic) NSUInteger percentageComplete;

@end

@protocol BlioProcessingDelegate
@optional
- (void)pauseProcessing;
- (void)resumeProcessing;

- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL;
@end

@interface BlioProcessingManager : NSObject <BlioProcessingDelegate> {
    NSManagedObjectContext *managedObjectContext;
    
    NSOperationQueue *preAvailabilityQueue;
    NSOperationQueue *postAvailabilityQueue;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;

@end
