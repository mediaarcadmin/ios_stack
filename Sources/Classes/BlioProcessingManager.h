//
//  BlioProcessingManager.h
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>

@protocol BlioProcessingDelegate
@optional
- (void)pauseProcessing;
- (void)resumeProcessing;

- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL;
@end

@interface BlioProcessingManager : NSObject <BlioProcessingDelegate> {
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;

@end
