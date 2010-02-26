//
//  BlioProcessing.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface BlioProcessingOperation : NSOperation {
    NSManagedObjectID *bookID;
    NSPersistentStoreCoordinator *storeCoordinator;
    BOOL forceReprocess;
    NSUInteger percentageComplete;
    NSString *cacheDirectory;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic) BOOL forceReprocess;
@property (nonatomic) NSUInteger percentageComplete;
@property (nonatomic, retain) NSString *cacheDirectory;

- (void)setBookValue:(id)value forKey:(NSString *)key;
- (id)getBookValueForKey:(NSString *)key;

@end

@protocol BlioProcessingDelegate
@required
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL;
@end
