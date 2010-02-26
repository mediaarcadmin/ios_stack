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
}

@property (nonatomic, retain) NSURL* url;

- (id)initWithUrl:(NSURL *)aURL;

@end

@interface BlioProcessingDownloadCoverOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadEPubOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadPdfOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadTextFlowOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadAudiobookOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingGenerateCoverThumbsOperation : BlioProcessingOperation
@end

