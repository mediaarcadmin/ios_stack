//
//  BookPaginator.h
//  Eucalyptus
//
//  Created by James Montgomerie on 06/08/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pthread.h>
#import "EucBook.h"

extern NSString * const BookPaginationProgressNotification;
extern NSString * const BookPaginationCompleteNotification;

extern NSString * const BookPaginationBookKey;
extern NSString * const BookPaginationBytesPaginatedKey;

@interface EucBookPaginator : NSObject {
    size_t _bytesProcessed;
    
    id<EucBook> _book;
    NSString *_fontFamilyName;
    
    pthread_t _paginationThread;
    NSConditionLock *_paginationStartedLock;
    BOOL _continueParsing;
    
    NSTimer *_monitoringTimer;
}

@property (nonatomic, readonly) size_t bytesProcessed;
@property (nonatomic, readonly) BOOL isPaginating;

- (void)paginateBookInBackground:(id<EucBook>)book forForFontFamily:(NSString *)fontFamilyName;
- (void)stop;

- (void)testPaginateBook:(id<EucBook>)book forForFontFamily:(NSString *)fontFamilyName;

@end
