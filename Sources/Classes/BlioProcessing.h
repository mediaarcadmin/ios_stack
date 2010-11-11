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
@class BlioProcessingDownloadOperation;

typedef enum {
	BlioBookSourceNotSpecified = 0,
	BlioBookSourceFileSharing = 1,
	BlioBookSourceLocalBundle = 2,
	BlioBookSourceOnlineStore = 3,
	BlioBookSourceOtherApplications = 4,
	BlioBookSourceFeedbooks = 5,
	BlioBookSourceGoogleBooks = 6
} BlioBookSourceID;

static NSString * const BlioProcessingOperationStartNotification = @"BlioProcessingOperationStartNotification";
static NSString * const BlioProcessingOperationProgressNotification = @"BlioProcessingOperationProgressNotification";
static NSString * const BlioProcessingOperationCompleteNotification = @"BlioProcessingOperationCompleteNotification";
static NSString * const BlioProcessingOperationFailedNotification = @"BlioProcessingOperationFailedNotification";

@interface BlioProcessingOperation : NSOperation {
    NSManagedObjectID *bookID;
    BlioBookSourceID sourceID;
    NSString *sourceSpecificID;
    BOOL forceReprocess;
    NSUInteger percentageComplete;
    NSString *cacheDirectory;
    NSString *tempDirectory;
    BOOL operationSuccess;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIBackgroundTaskIdentifier backgroundTaskIdentifier;
#endif
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, assign) BlioBookSourceID sourceID;
@property (nonatomic, copy) NSString *sourceSpecificID;
@property (nonatomic) BOOL forceReprocess;
@property (nonatomic) NSUInteger percentageComplete;
@property (nonatomic, retain) NSString *cacheDirectory;
@property (nonatomic, retain) NSString *tempDirectory;
@property (nonatomic) BOOL operationSuccess;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
#endif

- (NSData *)getBookTextFlowDataWithPath:(NSString *)path;
- (BOOL)bookManifestPath:(NSString *)path existsForLocation:(NSString *)location;
- (void)setBookManifestValue:(id)value forKey:(NSString *)key;
- (BOOL)hasBookManifestValueForKey:(NSString *)key;
- (NSData *)getBookManifestDataForKey:(NSString *)key;
- (NSString *)getBookManifestPathForKey:(NSString *)key;

- (void)setBookValue:(id)value forKey:(NSString *)key;
- (id)getBookValueForKey:(NSString *)key;

- (void)reportBookReadingIfRequired;

@end

@protocol BlioProcessingDelegate
@required
//- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
//					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
//			   audiobookPath:(NSString *)audiobookPath;
//- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
//					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
//			   audiobookPath:(NSString *)audiobookPath sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
			   audiobookPath:(NSString *)audiobookPath sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID placeholderOnly:(BOOL)placeholderOnly;
-(void) enqueueBook:(BlioBook*)aBook;
-(void) enqueueBook:(BlioBook*)aBook placeholderOnly:(BOOL)placeholderOnly;
- (void) resumeProcessing;
-(BlioBook*)bookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
-(void) reprocessCoverThumbnailsForBook:(BlioBook*)aBook;
- (void) resumeProcessingForSourceID:(BlioBookSourceID)bookSource;
- (BlioProcessingCompleteOperation *)processingCompleteOperationForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (NSArray *)processingOperationsForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
-(void) resumeSuspendedProcessingForSourceID:(BlioBookSourceID)bookSource;
	-(void) suspendProcessingForSourceID:(BlioBookSourceID)bookSource;
- (void)pauseProcessingForBook:(BlioBook*)aBook;
- (void)suspendProcessingForBook:(BlioBook*)aBook;
- (void)stopProcessingForBook:(BlioBook*)aBook;
-(void) deletePaidBooksForUserNum:(NSInteger)user siteNum:(NSInteger)site;
-(void) deleteBook:(BlioBook*)aBook shouldSave:(BOOL)shouldSave;
- (void)stopInternetOperations;
- (NSArray *)internetOperations;
- (BlioProcessingOperation*) operationByClass:(Class)targetClass forSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
- (BlioProcessingDownloadOperation*) incompleteDownloadOperationForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
@end
