//
//  BookPageIndex.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <sys/stat.h>
#import <sys/fcntl.h>
#import <unistd.h>
#import <glob.h>
#import "EucBook.h"
#import "EucBookIndex.h"
#import "EucBookPaginator.h"
#import "THLog.h"
#import "THRegex.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookPageIndex.h"


@implementation EucBookPageIndex

@synthesize lastPageNumber = _lastPageNumber;

- (id)_initForIndexAtPath:(NSString *)indexPath
{
    if((self = [super init])) {
        _fd = open([indexPath fileSystemRepresentation], O_RDONLY);
        if(_fd == -1) {
            THWarn(@"Could not turn open index at %@, error %d [\"%s\"]", indexPath, errno, strerror(errno));
            [self release];
            return nil;
        } else {
            THLog(@"Opened index at %@", indexPath);
        }
        
        struct stat stat;
        fstat(_fd, &stat);
        _lastPageNumber = stat.st_size / (sizeof(uint32_t) * 4);   
    }
    return self;
}

+ (id)bookPageIndexAtPath:(NSString *)indexPath
{
    return [[[self alloc] _initForIndexAtPath:(NSString *)indexPath] autorelease];
}

- (void)seekToEnd
{
    lseek(_fd, 0, SEEK_END);
}

- (void)dealloc
{
    if(_fd > 0) {
        close(_fd);
    }
    _fd = 0;

    [super dealloc];
}

- (EucBookPageIndexPoint *)indexPointForPage:(NSUInteger)pageNumber
{       
    EucBookPageIndexPoint *ret = nil;

    NSUInteger lastPageNumber = self.lastPageNumber;
    if(pageNumber <= lastPageNumber) {
        off_t seekTo = (pageNumber - 1) * 4 * sizeof(uint32_t);
        if(lseek(_fd, seekTo, SEEK_SET) == seekTo) {
            return [EucBookPageIndexPoint bookPageIndexPointFromOpenFD:_fd];
        } else {
            THWarn(@"Could not seek to index point for page %lu, error %d [\"%s\"]", (unsigned long)pageNumber, errno, strerror(errno));
        }
    } else if(lastPageNumber == 0) {
        // Book is completly unpaginated.  Fake out the first page.
        ret = [[[EucBookPageIndexPoint alloc] init] autorelease];
    }
    return ret;
}

- (NSUInteger)pageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    uint32_t source = indexPoint.source;
    uint32_t block = indexPoint.block;
    uint32_t word = indexPoint.word;
    uint32_t element = indexPoint.element;

    uint32_t data[4];
    size_t size = sizeof(data);

    uint32_t candidateSource;
    uint32_t candidateBlock;
    uint32_t candidateWord;
    uint32_t candidateElement;
    
    NSUInteger lowerBound = 0;
    NSUInteger upperBound = self.lastPageNumber;
    NSUInteger candidatePage;
    do {
        candidatePage = lowerBound + (upperBound - lowerBound) / 2;
        off_t seekTo = candidatePage * size;
        if(lseek(_fd, seekTo, SEEK_SET) == seekTo) {
            if(read(_fd, data, size) == size) {
                candidateSource = CFSwapInt32LittleToHost(data[0]);
                candidateBlock = CFSwapInt32LittleToHost(data[1]);
                candidateWord = CFSwapInt32LittleToHost(data[2]);
                candidateElement = CFSwapInt32LittleToHost(data[3]);
            } else {
                THWarn(@"Could not read index point for page %lu during search, error %d [\"%s\"]", (unsigned long)candidatePage + 1, errno, strerror(errno));
                break;
            }
        } else {
            THWarn(@"Could not seek to index point for page %lu during search, error %d [\"%s\"]", (unsigned long)candidatePage + 1, errno, strerror(errno));
            break;
        }
        if((candidateSource > source) ||
           (candidateSource == source && candidateBlock > block) ||
           (candidateSource == source && candidateBlock == block && candidateWord > word) ||
           (candidateSource == source && candidateBlock == block && candidateWord == word && candidateElement > element)) {
            upperBound = candidatePage;
        } else {
            lowerBound = candidatePage;
        }
    } while(upperBound - lowerBound > 1);
    
    return lowerBound + 1;
}

@end
