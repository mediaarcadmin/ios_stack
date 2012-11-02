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
static NSString * const BlioProcessingLicenseAcquisitionTokenRequiredNotification = @"BlioProcessingLicenseAcquisitionTokenRequiredNotification";
static NSString * const BlioProcessingDownloadPaidBookTokenRequiredNotification = @"BlioProcessingDownloadPaidBookTokenRequiredNotification";
static NSString * const BlioProcessingDownloadPaidBookNonMatchingUserNotification = @"BlioProcessingDownloadPaidBookNonMatchingUserNotification";
static NSString * const BlioProcessingLicenseAcquisitionNonMatchingUserNotification = @"BlioProcessingLicenseAcquisitionNonMatchingUserNotification";
static NSString * const BlioProcessingWillDeleteBookNotification = @"BlioProcessingWillDeleteBookNotification";

@interface BlioProcessingManager : NSObject <BlioProcessingDelegate> {
    NSOperationQueue *preAvailabilityQueue;
    NSUInteger _queuedCompleteOperations;
    BOOL _notifyProcessingComplete;
}

@end


@protocol BlioProcessingManagerOperationProvider
+ (NSArray *)preAvailabilityOperations;

@end