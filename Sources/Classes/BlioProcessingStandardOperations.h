//
//  BlioProcessingOperations.h
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"

@interface BlioProcessingCompleteOperation : BlioProcessingOperation
@end

@interface BlioProcessingDownloadOperation : BlioProcessingOperation {
    NSURL *url;
    NSString *localFilename;
    NSString *tempFilename;
    
    NSURLConnection *connection;
    NSFileHandle *downloadFile;
    
    BOOL executing;
    BOOL finished;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *localFilename;
@property (nonatomic, retain) NSString *tempFilename;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSFileHandle *downloadFile;

- (id)initWithUrl:(NSURL *)aURL;
- (void)downloadDidFinishSuccessfully:(BOOL)success;

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

