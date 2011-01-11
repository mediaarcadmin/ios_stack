//
//  BlioProcessingManager.h
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BlioProcessing.h"

static NSString * const BlioProcessingReprocessCoverThumbnailNotification = @"BlioProcessingReprocessCoverThumbnailNotification";

@interface BlioProcessingManager : NSObject <BlioProcessingDelegate> {
    NSOperationQueue *preAvailabilityQueue;
    NSOperationQueue *postAvailabilityQueue;
}

@end


@protocol BlioProcessingManagerOperationProvider
+ (NSArray *)preAvailabilityOperations;

@end