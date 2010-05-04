//
//  BookPaginator.m
//  libEucalyptus
//
//  Created by James Montgomerie on 06/08/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBookPaginator.h"
#import "EucBook.h"
#import "EucPageLayoutController.h"
#import "EucPageView.h"
#import "EucPageTextView.h"
#import "EucBookIndex.h"
#import "EucBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "THLog.h"
#import "THNSStringAdditions.h"
#import "THTimer.h"
#import "THBackgroundProcessingMediator.h"
#import "THImageFactory.h"

#import <fcntl.h>
#import <sys/stat.h>

NSString * const EucBookBookPaginatorProgressNotification = @"BookPaginationProgressNotification";
NSString * const EucBookPaginatorCompleteNotification = @"BookPaginationCompleteNotification";

NSString * const EucBookPaginatorNotificationBookKey = @"BookPaginationBookKey";
NSString * const EucBookPaginatorNotificationPercentagePaginatedKey = @"BookPaginationBytesPaginated";
NSString * const EucBookPaginatorNotificationPageCountsKey = @"BookPaginatorNotificationPageCounts";

#define kThreadedProgressPollingDelay (1.0 / 5.0)

@interface EucBookPaginator (PRIVATE)

- (void)_paginationThread;
- (void)_paginationThreadComplete;
- (void)_releasePaginationIvars;
- (void)_sendPeriodicPaginationUpdate;

@end

@implementation EucBookPaginator

@synthesize percentagePaginated = _percentagePaginated;
@synthesize isPaginating = _continueParsing;

static void *PaginationThread(void *self) 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [(id)self _paginationThread];
    [pool drain];
    return NULL;
}

static const NSUInteger sDesiredPointSizes[] = { 14, 16, 18, 20, 22 };
static const NSUInteger sDesiredPointSizesCount = (sizeof(sDesiredPointSizes) / sizeof(sDesiredPointSizes[0]));

- (void)_paginationThread
{
    THImageFactory *imageFactory = nil;
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    THTimer *timer = [[THTimer alloc] initWithName:[@"Pagination of " stringByAppendingString:_book.title]];
    BOOL unlocked = NO;
    [_paginationStartedLock lockWhenCondition:0];
    off_t indexPointSize = [EucBookPageIndexPoint sizeOnDisk];
    NSString *indexDirectoryPath = _book.cacheDirectoryPath;
    
    int pageIndexFDs[sDesiredPointSizesCount];
    memset(pageIndexFDs, 0, sizeof(pageIndexFDs));
    EucBookPageIndexPoint *currentPoints[sDesiredPointSizesCount];
    memset(currentPoints, 0, sizeof(currentPoints));
    EucPageView *pageViews[sDesiredPointSizesCount];
    memset(pageViews, 0, sizeof(pageViews));
        
    // Open raw index files.
    for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
        NSString *path = [indexDirectoryPath stringByAppendingPathComponent:[EucBookIndex constructionFilenameForPageIndexForPointSize:sDesiredPointSizes[i]]];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            pageIndexFDs[i] = open([path fileSystemRepresentation], O_RDWR, S_IRUSR | S_IWUSR);
        } else {
            pageIndexFDs[i] = open([path fileSystemRepresentation], O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR);        
        }
        if(pageIndexFDs[i] <= 0) {
            THWarn(@"Error %d attempting to open index file at \"%@\"", errno, path);
            pageIndexFDs[i] = 0;
            goto abandon;
        }
    }
        
    // See if we can read the last index point (i.e. if the files are in-progress).
    for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
        struct stat stat;
        if(fstat(pageIndexFDs[i], &stat) != 0) {
            THWarn(@"Error %d attempting to stat index", errno);
            goto abandon;
        } else {
            off_t currentIndexSize = stat.st_size;
            if((currentIndexSize % indexPointSize) != 0) {
                // Just in case we quit in the middle of writing a point:
                currentIndexSize = currentIndexSize / indexPointSize;
                ftruncate(pageIndexFDs[i], currentIndexSize);            
            }
            if(currentIndexSize > 0) {
                lseek(pageIndexFDs[i], currentIndexSize - indexPointSize, SEEK_SET);
                currentPoints[i] = [[EucBookPageIndexPoint bookPageIndexPointFromOpenFD:pageIndexFDs[i]] retain];
                lseek(pageIndexFDs[i], currentIndexSize - indexPointSize, SEEK_SET);
                // We'll overwrite this point, below.
                
                _pageCounts[i] = (currentIndexSize / indexPointSize) - 1;
            } else {
                currentPoints[i] = [[EucBookPageIndexPoint alloc] init];
            }
        }
    }    
    
    [_paginationStartedLock unlockWithCondition:1];
    unlocked = YES;
        
    // Create the text views we'll use for layout.
    for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
        pageViews[i] = [[_book.pageLayoutControllerClass blankPageViewForPointSize:sDesiredPointSizes[i] withPageTexture:nil] retain];
        if(!pageViews[i]) {
            THWarn(@"Could not create book text view for point size %lu", (unsigned long)sDesiredPointSizes[i]);
            goto abandon;
        }
    }    
    
    long pageCount = 0;
    EucBookPageIndexPoint *nextPoint = nil;
    while(_continueParsing) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [THBackgroundProcessingMediator sleepIfBackgroundProcessingCurtailed];

        
        // Work out which is the furthest behind index.
        NSInteger currentPointIndex = -1;
        for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
            if(currentPoints[i]) {
                if(currentPointIndex == -1) {
                    currentPointIndex = i;
                } else {
                    if([currentPoints[currentPointIndex] compare:currentPoints[i]] == NSOrderedAscending) {
                        currentPointIndex = i;
                    }
                }
            }
        }
        
        if(currentPointIndex == -1) {
            // We're done, all the indexes are finished.
            break;
        }
                
#if TARGET_IPHONE_SIMULATOR
//         usleep(100000);
#endif            
        
        nextPoint = [pageViews[currentPointIndex].bookTextView layoutPageFromPoint:currentPoints[currentPointIndex] 
                                                                            inBook:_book];
        
        if(THWillLogVerbose()) {
            if(nextPoint) {
                THLogVerbose(@"%f: [%ld, %ld, %ld, %ld] -> [%ld, %ld, %ld, %ld]", 
                             pageViews[currentPointIndex].bookTextView.pointSize,
                             (long)currentPoints[currentPointIndex].source, 
                             (long)currentPoints[currentPointIndex].block, 
                             (long)currentPoints[currentPointIndex].word, 
                             (long)currentPoints[currentPointIndex].element, 
                             (long)nextPoint.source, 
                             (long)nextPoint.block, 
                             (long)nextPoint.word, 
                             (long)nextPoint.element);
            } else {
                THLogVerbose(@"%f: [%ld, %ld, %ld, %ld] -> NULL", 
                             pageViews[currentPointIndex].bookTextView.pointSize,
                             (long)currentPoints[currentPointIndex].source, 
                             (long)currentPoints[currentPointIndex].block, 
                             (long)currentPoints[currentPointIndex].word, 
                             (long)currentPoints[currentPointIndex].element);
            }
        }
              
        
        //NSParameterAssert(nextPoint.startOfParagraphByteOffset >= currentPoints[currentPointIndex].startOfParagraphByteOffset || !nextPoint);
        
        [currentPoints[currentPointIndex] writeToOpenFD:pageIndexFDs[currentPointIndex]];
        
        pthread_mutex_lock(&_countMutationMutex);
        ++_pageCounts[currentPointIndex];
        if((pageCount % 16) == 0) {
            _percentagePaginated = [_book estimatedPercentageForIndexPoint:currentPoints[currentPointIndex]];
        }        
        pthread_mutex_unlock(&_countMutationMutex);

        [currentPoints[currentPointIndex] release];
        currentPoints[currentPointIndex] = [nextPoint retain];
        
        if(_saveImagesTo) {
            if(!imageFactory) {
                imageFactory = [[THImageFactory alloc] initWithSize:pageViews[currentPointIndex].frame.size];
            }
            CGContextRef context = imageFactory.CGContext;
            CGContextSaveGState(context);
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, pageViews[currentPointIndex].bounds.size.height);
            CGContextConcatCTM(context, flipVertical);            
            [pageViews[currentPointIndex] drawRect:pageViews[currentPointIndex].bounds inContext:context];
            NSString *imageName = [NSString stringWithFormat:@"%f-%5d.png", pageViews[currentPointIndex].bookTextView.pointSize, pageCount];
            [UIImageJPEGRepresentation(imageFactory.snapshotUIImage, 0.25) writeToFile:[_saveImagesTo stringByAppendingPathComponent:imageName] atomically:NO];
            CGContextRestoreGState(context);
        }
        
        [pageViews[currentPointIndex].bookTextView clear];
        ++pageCount;
                         
        [pool drain];
    }
        
    // Let the book save any data it's collected.
    THTimer *cacheableDataSaveTimer = [THTimer timerWithName:@"Saving cachable data"];
    [_book persistCacheableData];
    [cacheableDataSaveTimer report];
    
    if(_continueParsing) {
        _percentagePaginated = 100.0f;
        [self performSelectorOnMainThread:@selector(_paginationThreadComplete) withObject:nil  waitUntilDone:NO];
    }
    
abandon:
    if(!unlocked) {
        [_paginationStartedLock unlockWithCondition:1];
    }

    for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
        [currentPoints[i] release]; 
        [pageViews[i] release];
        close(pageIndexFDs[i]);
    }
    
    [timer report];
    [timer release]; 
    
    [imageFactory release];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)_paginateBook:(id<EucBook>)book inBackground:(BOOL)inBackground saveImagesTo:(NSString *)saveImagesTo
{
    THLog(@"Pagination of %@ beginning!", _book.title);

    _book = [book retain];
    _saveImagesTo = [[saveImagesTo stringByAppendingPathComponent:@"PageImages"] retain];
    _continueParsing = YES;
    
    _pageCounts = calloc(sizeof(NSUInteger), sDesiredPointSizesCount);
    pthread_mutex_init(&_countMutationMutex, NULL);
    
    if(_saveImagesTo) {
        [[NSFileManager defaultManager] removeItemAtPath:_saveImagesTo error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:_saveImagesTo withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if(inBackground) {
        _paginationStartedLock = [[NSConditionLock alloc] initWithCondition:0];
        pthread_create(&_paginationThread, NULL, PaginationThread, (void *)self);
        _monitoringTimer = [[NSTimer scheduledTimerWithTimeInterval:kThreadedProgressPollingDelay
                                                             target:self 
                                                           selector:@selector(_sendPeriodicPaginationUpdate) 
                                                       userInfo:nil 
                                                        repeats:YES] retain];
        // Callers of this expect the indexes to be in aa usable state after return,
        // even if the paginator's running in the background, so we wait for the 
        // pagination thread to sigmal that it has created the indexes before 
        // returning.
        [_paginationStartedLock lockWhenCondition:1];
        [_paginationStartedLock unlock];
        [_paginationStartedLock release];
        _paginationStartedLock = nil;
    } else {
        [self _paginationThread];
    }
}


- (void)paginateBookInBackground:(id<EucBook>)book saveImagesTo:(NSString *)saveImagesTo
{
    [self _paginateBook:book inBackground:YES saveImagesTo:saveImagesTo];
}

- (void)testPaginateBook:(id<EucBook>)book
{
    [self _paginateBook:book inBackground:NO saveImagesTo:nil];
}


- (void)_sendPeriodicPaginationUpdate
{
    pthread_mutex_lock(&_countMutationMutex);
    if(_percentagePaginated) {
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  _book, EucBookPaginatorNotificationBookKey,
                                  [NSNumber numberWithFloat:_percentagePaginated], EucBookPaginatorNotificationPercentagePaginatedKey, 
                                  nil];    
        [[NSNotificationCenter defaultCenter] postNotificationName:EucBookBookPaginatorProgressNotification
                                                            object:self
                                                          userInfo:userInfo];
        [userInfo release];
    }
    pthread_mutex_unlock(&_countMutationMutex);
}

    
- (void)_releasePaginationIvars
{
    [_paginationStartedLock release];
    _paginationStartedLock = nil;
    [_monitoringTimer invalidate];
    [_monitoringTimer release];
    _monitoringTimer = nil;
    [_book release];
    _book = nil;
    [_saveImagesTo release];
    _saveImagesTo = nil;
    free(_pageCounts);
    _pageCounts = nil;
    _percentagePaginated = 0.0f;
    _continueParsing = NO;
    pthread_mutex_destroy(&_countMutationMutex);
}

    
- (void)stop 
{   
    if(_continueParsing) {
        _continueParsing = NO;
        pthread_join(_paginationThread, NULL);
        [self _releasePaginationIvars];
    }
}

    
- (void)_paginationThreadComplete
{
    [self _sendPeriodicPaginationUpdate];
    
    [EucBookIndex markBookBundleAsIndexesConstructed:[_book cacheDirectoryPath]];
    
    // Retain what we need then clear the ivars to support
    // allowing calls to start pagination in the completion
    // callback.
    id<EucBook> book = [_book retain];
    NSMutableDictionary *pageCounts = [[NSMutableDictionary alloc] initWithCapacity:sDesiredPointSizesCount];
    for(NSUInteger i = 0; i < sDesiredPointSizesCount; ++i) {
        [pageCounts setObject:[NSNumber numberWithInteger:_pageCounts[i]]
                       forKey:[NSNumber numberWithInteger:sDesiredPointSizes[i]]];
    }
        
    [self _releasePaginationIvars]; 

    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                              book, EucBookPaginatorNotificationBookKey,
                              [NSNumber numberWithFloat:100.0f], EucBookPaginatorNotificationPercentagePaginatedKey,
                              pageCounts, EucBookPaginatorNotificationPageCountsKey,
                              nil];    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EucBookPaginatorCompleteNotification
                                                        object:self
                                                      userInfo:userInfo];
    
    [userInfo release];
    [pageCounts release];
    [book release];
    
    THLog(@"Pagination of %@ done!", _book.title);
}

@end
