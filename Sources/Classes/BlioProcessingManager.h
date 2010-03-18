//
//  BlioProcessingManager.h
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BlioProcessing.h"

@interface BlioProcessingManager : NSObject <BlioProcessingDelegate> {
    NSManagedObjectContext *managedObjectContext;
    
    NSOperationQueue *preAvailabilityQueue;
    NSOperationQueue *postAvailabilityQueue;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;

@end


@protocol BlioProcessingManagerOperationProvider
+ (NSArray *)preAvailabilityOperations;
@end