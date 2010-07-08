//
//  BlioProcessing.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BlioBook;
@class BlioProcessingCompleteOperation;

typedef enum {
	BlioBookSourceNotSpecified = 0,
	BlioBookSourceOnlineStore = 1,
	BlioBookSourceFeedbooks = 2,
	BlioBookSourceGoogleBooks = 3
} BlioBookSourceID;

extern NSString * const BlioProcessingOperationStartNotification;
extern NSString * const BlioProcessingOperationProgressNotification;
extern NSString * const BlioProcessingOperationCompleteNotification;
extern NSString * const BlioProcessingOperationFailedNotification;

@interface BlioProcessingOperation : NSOperation {
    NSManagedObjectID *bookID;
    BlioBookSourceID sourceID;
    NSString *sourceSpecificID;
    BOOL forceReprocess;
    NSUInteger percentageComplete;
    NSString *cacheDirectory;
    NSString *tempDirectory;
    BOOL operationSuccess;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, assign) BlioBookSourceID sourceID;
@property (nonatomic, copy) NSString *sourceSpecificID;
@property (nonatomic) BOOL forceReprocess;
@property (nonatomic) NSUInteger percentageComplete;
@property (nonatomic, retain) NSString *cacheDirectory;
@property (nonatomic, retain) NSString *tempDirectory;
@property (nonatomic) BOOL operationSuccess;

- (void)setBookManifestValue:(id)value forKey:(NSString *)key;
- (NSData *)getBookManifestDataForKey:(NSString *)key;
- (NSString *)getBookManifestPathForKey:(NSString *)key;

- (void)setBookValue:(id)value forKey:(NSString *)key;
- (id)getBookValueForKey:(NSString *)key;

@end

@protocol BlioProcessingDelegate
@required
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL xpsURL:(NSURL *)xpsURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL;
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL xpsURL:(NSURL *)xpsURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL xpsURL:(NSURL *)xpsURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID placeholderOnly:(BOOL)placeholderOnly;
-(void) enqueueBook:(BlioBook*)aBook;
-(void) enqueueBook:(BlioBook*)aBook placeholderOnly:(BOOL)placeholderOnly;
- (void) resumeProcessing;
-(BlioBook*)bookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (void) resumeProcessingForSourceID:(BlioBookSourceID)bookSource;
- (BlioProcessingCompleteOperation *)processingCompleteOperationForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (NSArray *)processingOperationsForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (void)pauseProcessingForBook:(BlioBook*)aBook;
- (void)stopProcessingForBook:(BlioBook*)aBook;
-(void) deleteBook:(BlioBook*)aBook shouldSave:(BOOL)shouldSave;
- (void)stopDownloadingOperations;
- (NSArray *)downloadOperations;
- (BlioProcessingOperation*) operationByClass:(Class)targetClass forSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;

@end
