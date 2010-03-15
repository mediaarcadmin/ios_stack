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
#import "EucBookSection.h"
#import "EucBookPaginator.h"
#import "THLog.h"
#import "THRegex.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookPageIndex.h"


@implementation EucBookPageIndex

@synthesize lastPageNumber = _lastPageNumber;

+ (NSUInteger)indexVersion
{
    return 1;
}

+ (NSString *)filenameForPageIndexForPointSize:(NSUInteger)fontSize
{
    return [NSString stringWithFormat:@"%lu.v%luindex", (unsigned long)fontSize, (unsigned long)[EucBookPageIndex indexVersion]];
}

+ (NSString *)constructionFilenameForPageIndexForPointSize:(NSUInteger)fontSize
{
    return [NSString stringWithFormat:@"%lu.v%luindexConstruction", (unsigned long)fontSize, (unsigned long)[EucBookPageIndex indexVersion]];
}

+ (void)markBookBundleAsIndexConstructed:(NSString *)bundlePath
{
    NSString *globPath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"*.v%luindexConstruction", (unsigned long)[EucBookPageIndex indexVersion]]];
    glob_t globValue;
    int err = glob([globPath fileSystemRepresentation],
                   GLOB_NOSORT,
                   NULL,
                   &globValue);
    if(err != 0) {
        THWarn(@"Globbing failed when attempting to find constructed indexes in book bundle %@", bundlePath);
    } else if(globValue.gl_pathc <= 0) {
        THWarn(@"Could not find indexes in book bundle %@", bundlePath);
    } else {
        for(size_t i = 0; i < globValue.gl_pathc; ++i) {
            char *from = globValue.gl_pathv[i];
            int fromLength = strlen(from);
            int toLength = fromLength - 12;
            char to[toLength + 1];
            memcpy(to, from, toLength);
            to[toLength] = 0;
            if(rename(from, to) != 0) {
                THWarn(@"Error moving book index into place, (%s -> %s), error %d [\"%s\"]", from, to, errno, strerror(errno));  
            }
        }
        globfree(&globValue);
    }
}

@synthesize book = _book;
@synthesize pointSize = _pointSize;

@synthesize isFinal = _isFinal;
//@synthesize lastOffset = _lastOffset;

- (id)_initForIndexInBook:(id<EucBook>)book pointSize:(NSUInteger)pointSize
{
    if((self = [super init])) {
        _book = [book retain];
        _pointSize = pointSize;
        
        NSString *path = book.path;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *indexPath = [path stringByAppendingPathComponent:[[self class] filenameForPageIndexForPointSize:pointSize]];
        if(![fileManager fileExistsAtPath:indexPath]) {
            indexPath =  [path stringByAppendingPathComponent:[[self class] constructionFilenameForPageIndexForPointSize:pointSize]];
        } else {
            _isFinal = YES;
        }
        
        _fd = open([indexPath fileSystemRepresentation], O_RDONLY, 0644);
        if(_fd == -1) {
            THWarn(@"Could not turn open index at %@, error %d [\"%s\"]", indexPath, errno, strerror(errno));
            [self dealloc];
            return nil;
        } else {
            THLog(@"Opened index at %@", indexPath);
        }
        
        //if(fcntl(_fd, F_NOCACHE, 1) == -1) {
        //    THWarn(@"Could not turn off caching for index file handle, error %d [\"%s\"]", errno, strerror(errno));
        //}
        
        struct stat stat;
        fstat(_fd, &stat);
        _lastPageNumber = stat.st_size / (sizeof(uint32_t) * 4);   
        
       // if(_isFinal) {
       //     _lastOffset = _book.bookFileSize;
       // } else {
         //   _lastOffset = [self indexPointForPage:self.lastPageNumber].startOfParagraphByteOffset;
       /*     [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_bookPaginationProgress:)
                                                         name:BookPaginationProgressNotification
                                                       object:nil];            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_bookPaginationComplete:)
                                                         name:BookPaginationCompleteNotification
                                                       object:nil];
        }*/
    }
    return self;
}


- (void)_bookPaginationProgress:(NSNotification *)notification
{
 /*   NSDictionary *userInfo = [notification userInfo];
    id<EucBook> book = [userInfo objectForKey:BookPaginationBookKey];
    if(book.etextNumber == _book.etextNumber) {
        struct stat stat;
        fstat(_fd, &stat);
        _lastPageNumber = stat.st_size / (sizeof(uint32_t) * 4);   
        _lastOffset = [self indexPointForPage:_lastPageNumber].startOfParagraphByteOffset;
    }*/
}


- (void)_bookPaginationComplete:(NSNotification *)notification
{
 /*   NSDictionary *userInfo = [notification userInfo];
    id<EucBook> book = [userInfo objectForKey:BookPaginationBookKey];
    if(book.etextNumber == _book.etextNumber) {
        struct stat stat;
        fstat(_fd, &stat);
        _lastPageNumber = stat.st_size / (sizeof(uint32_t) * 4);   
        //_lastOffset = _book.bookFileSize;
        _isFinal = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:BookPaginationProgressNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:BookPaginationCompleteNotification
                                                      object:nil];        
    }*/
}


+ (id)bookPageIndexForIndexInBook:(id<EucBook>)book forPointSize:(NSUInteger)pointSize
{
    return [[[self alloc] _initForIndexInBook:book pointSize:pointSize] autorelease];
}

+ (NSArray *)bookPageIndexesForBook:(id<EucBook>)book
{
    NSMutableArray *indexes = [NSMutableArray array];
    
    NSString *bundlePath = [book path];
    NSString *globPath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"*.v%luindex*", (unsigned long)[EucBookPageIndex indexVersion]]];
    glob_t globValue;
    int err = glob([globPath fileSystemRepresentation],
                   0,
                   NULL,
                   &globValue);
    if(err != 0) {
        THWarn(@"Globbing failed when attempting to find indexes in book bundle %@", bundlePath);
    } else if(globValue.gl_pathc <= 0) {
        THWarn(@"Could not find indexes in book bundle %@", bundlePath);
    } else {
        THRegex *indexRegex = [THRegex regexWithPOSIXRegex:[NSString stringWithFormat:@"([[:digit:]]+).v%luindex(Construction)?$", (unsigned long)[EucBookPageIndex indexVersion]]];
        
        for(size_t i = 0; i < globValue.gl_pathc; ++i) {
            NSString *path = [NSString stringWithUTF8String:globValue.gl_pathv[i]];
            if([indexRegex matchString:path]) {
                NSUInteger pointSize = [[indexRegex match:1] integerValue];
                EucBookPageIndex *index = [self bookPageIndexForIndexInBook:book forPointSize:pointSize];
                if(index) {
                    [indexes addObject:index];
                }
            }
        }
        globfree(&globValue);
    }
    
    [indexes sortUsingSelector:@selector(compare:)];
    
    return indexes;
}

- (void)seekToEnd
{
    lseek(_fd, 0, SEEK_END);
}

- (void)closeIndex
{
    if(_fd > 0) {
        close(_fd);
    }
    _fd = 0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self closeIndex];
    [_book release];
    
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

- (NSComparisonResult)compare:(EucBookPageIndex *)rhs
{
    NSInteger comparison = (NSInteger)self.pointSize - (NSInteger)rhs.pointSize;
    if(comparison > 0) {
        return NSOrderedDescending;
    } else if (comparison < 0) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

@end
