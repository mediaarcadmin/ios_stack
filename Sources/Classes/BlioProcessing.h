//
//  BlioProcessing.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BlioMockBook;

@interface BlioProcessingOperation : NSOperation {
    NSManagedObjectID *bookID;
    NSString *sourceID;
    NSString *sourceSpecificID;
    NSPersistentStoreCoordinator *storeCoordinator;
    BOOL forceReprocess;
    NSUInteger percentageComplete;
    NSString *cacheDirectory;
    NSString *tempDirectory;
    BOOL operationSuccess;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, copy) NSString *sourceID;
@property (nonatomic, copy) NSString *sourceSpecificID;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic) BOOL forceReprocess;
@property (nonatomic) NSUInteger percentageComplete;
@property (nonatomic, retain) NSString *cacheDirectory;
@property (nonatomic, retain) NSString *tempDirectory;
@property (nonatomic) BOOL operationSuccess;

- (void)setBookValue:(id)value forKey:(NSString *)key;
- (id)getBookValueForKey:(NSString *)key;

@end

@protocol BlioProcessingDelegate
@required
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL;
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL sourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
-(void) enqueueBook:(BlioMockBook*)aBook;
-(void) pauseProcessingForBook:(BlioMockBook*) aBook;
- (BlioProcessingOperation *)processingCompleteOperationForSourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (NSArray *)processingOperationsForSourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
@end
