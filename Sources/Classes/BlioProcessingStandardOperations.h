//
//  BlioProcessingOperations.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"
#import "BlioBook.h"


@interface BlioProcessingAggregateOperation : BlioProcessingOperation {
	NSUInteger alreadyCompletedOperations;
}
@property (nonatomic, assign) NSUInteger alreadyCompletedOperations;
-(void) calculateProgress;
@end

@interface BlioProcessingCompleteOperation : BlioProcessingAggregateOperation {
}

@end
@interface BlioProcessingDeleteBookOperation : BlioProcessingOperation {
    id<BlioProcessingDelegate> _processingDelegate;
    BOOL attemptArchive;
    BOOL shouldSave;
}
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, assign) BOOL attemptArchive;
@property (nonatomic, assign) BOOL shouldSave;
@end


@interface BlioProcessingPreAvailabilityCompleteOperation : BlioProcessingAggregateOperation {
    NSString *filenameKey;
}
@property (nonatomic, copy) NSString *filenameKey;
@end

@interface BlioProcessingDownloadOperation : BlioProcessingOperation {
    NSURL *url;
    NSString *filenameKey;
    NSString *localFilename;
    NSString *tempFilename;
    
    NSString *serverFilename;
    NSString *serverMimetype;
    
    NSURLConnection *connection;
    NSURLConnection *headConnection;
    NSFileHandle *downloadFile;
    
    BOOL executing;
    BOOL finished;
	BOOL resume;
	
	long long expectedContentLength;	
	NSData * requestHTTPBody;
    
    NSInteger statusCode;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, copy) NSString *filenameKey;
@property (nonatomic, copy) NSString *localFilename;
@property (nonatomic, copy) NSString *tempFilename;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLConnection *headConnection;
@property (nonatomic, retain) NSFileHandle *downloadFile;
@property (nonatomic, assign) long long expectedContentLength;
@property (nonatomic, assign) BOOL resume;
@property (nonatomic, retain) NSData * requestHTTPBody;

@property (nonatomic, copy) NSString *serverFilename;
@property (nonatomic, copy) NSString *serverMimetype;

@property (nonatomic, assign) NSInteger statusCode;

- (id)initWithUrl:(NSURL *)aURL;
- (void)downloadDidFinishSuccessfully:(BOOL)success;
-(void)startDownload;
-(void)headDownload;
-(NSString*)temporaryPath;
-(BOOL)shouldBackupDownload;
@end

@interface BlioProcessingLicenseAcquisitionOperation : BlioProcessingOperation {
	NSUInteger attemptsMade;
	NSUInteger attemptsMaximum;
}
	
@property (nonatomic, assign) NSUInteger attemptsMade;
@property (nonatomic, assign) NSUInteger attemptsMaximum;

@end

@interface BlioProcessingDownloadAndUnzipOperation : BlioProcessingDownloadOperation

- (void)unzipDidFinishSuccessfully:(BOOL)success;

@end

@interface BlioProcessingDownloadAndUnzipVoiceOperation : BlioProcessingDownloadAndUnzipOperation {
	NSString * voice;
}
@property (nonatomic, copy) NSString *voice;

@end

@interface BlioProcessingDownloadPaidBookOperation : BlioProcessingDownloadOperation 

@end

@interface BlioProcessingXPSManifestOperation : BlioProcessingOperation <NSXMLParserDelegate> {

	NSXMLParser * audiobookReferencesParser;	
	NSXMLParser * rightsParser;	
	NSXMLParser * metadataParser;	
	NSXMLParser * textflowParser;		
	NSMutableArray * audioFiles;
	NSMutableArray * timingFiles;
	NSDictionary * featureCompatibilityDictionary;
	BOOL hasAudiobook;
	BOOL hasReflowRightOverride;
}
@property (nonatomic, retain) NSMutableArray * audioFiles;
@property (nonatomic, retain) NSMutableArray * timingFiles;
@property (nonatomic, retain) NSDictionary * featureCompatibilityDictionary;

@end

@interface BlioProcessingDownloadCoverOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadEPubOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadPdfOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadXPSOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadTextFlowOperation : BlioProcessingDownloadAndUnzipOperation
@end

@interface BlioProcessingDownloadAudiobookOperation : BlioProcessingDownloadAndUnzipOperation
@end

@interface BlioProcessingGenerateCoverThumbsOperation : BlioProcessingOperation {
    BOOL maintainAspectRatio;
}
@property (nonatomic, assign) BOOL maintainAspectRatio;

@end


