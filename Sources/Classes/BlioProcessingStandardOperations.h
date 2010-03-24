//
//  BlioProcessingOperations.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"

extern NSString * const BlioProcessingCompleteOperationFinishedNotification;
@interface BlioProcessingCompleteOperation : BlioProcessingOperation
@end

@interface BlioProcessingDownloadOperation : BlioProcessingOperation {
    NSURL *url;
    NSString *filenameKey;
    NSString *localFilename;
    NSString *tempFilename;
    
    NSURLConnection *connection;
    NSURLConnection *headConnection;
    NSFileHandle *downloadFile;
    
    BOOL executing;
    BOOL finished;
	BOOL resume;
	
	long expectedContentLength;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, copy) NSString *filenameKey;
@property (nonatomic, retain) NSString *localFilename;
@property (nonatomic, retain) NSString *tempFilename;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLConnection *headConnection;
@property (nonatomic, retain) NSFileHandle *downloadFile;
@property (nonatomic, assign) long expectedContentLength;
@property (nonatomic, assign) BOOL resume;

- (id)initWithUrl:(NSURL *)aURL;
- (void)downloadDidFinishSuccessfully:(BOOL)success;
-(void)startDownload;
-(void)headDownload;

@end

@interface BlioProcessingDownloadAndUnzipOperation : BlioProcessingDownloadOperation

- (void)unzipDidFinishSuccessfully:(BOOL)success;

@end

@interface BlioProcessingDownloadCoverOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadEPubOperation : BlioProcessingDownloadAndUnzipOperation
@end

@interface BlioProcessingDownloadPdfOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadTextFlowOperation : BlioProcessingDownloadAndUnzipOperation
@end

@interface BlioProcessingDownloadAudiobookOperation : BlioProcessingDownloadAndUnzipOperation
@end

@interface BlioProcessingGenerateCoverThumbsOperation : BlioProcessingOperation
@end


