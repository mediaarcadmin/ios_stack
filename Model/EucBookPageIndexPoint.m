//
//  BookPageIndexPoint.m
//  Eucalyptus
//
//  Created by James Montgomerie on 04/09/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "EucBookPageIndexPoint.h"
#import "THLog.h"
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>

@implementation EucBookPageIndexPoint

@synthesize startOfParagraphByteOffset = _startOfParagraphByteOffset;
@synthesize startOfPageParagraphWordOffset = _startOfPageParagraphWordOffset;
@synthesize startOfPageWordHyphenOffset = _startOfPageWordHyphenOffset;
@synthesize source = _source;

+ (off_t)sizeOnDisk
{
    return sizeof(int32_t) * 3;
}

- (BOOL)writeToOpenFD:(int)fd
{
    int32_t data[3];
    data[0] = CFSwapInt32HostToLittle(_startOfParagraphByteOffset);
    data[1] = CFSwapInt32HostToLittle(_startOfPageParagraphWordOffset);
    
    // These are packed into one 32-bit int for backward compatibility.
    data[2] = CFSwapInt32HostToLittle(((uint32_t)_startOfPageWordHyphenOffset) | ((uint32_t)_source) << 16);
    size_t size = sizeof(data);
    if(write(fd, data, size) == size) {
        return YES;
    } else {
        THWarn(@"Could not write index point to file, error %d [\"%s\"]", errno, strerror(errno));
        return NO;
    }
}

+ (EucBookPageIndexPoint *)bookPageIndexPointFromOpenFD:(int)fd
{
    int32_t data[3];
    size_t size = sizeof(data);
    EucBookPageIndexPoint *ret = nil;
    if(read(fd, data, size) == size) {
        ret = [[[EucBookPageIndexPoint alloc] init] autorelease];
        ret.startOfParagraphByteOffset = CFSwapInt32LittleToHost(data[0]);
        ret.startOfPageParagraphWordOffset = CFSwapInt32LittleToHost(data[1]);
        
        // These are packed into one 32-bit int for backward compatibility.
        uint32_t hyphenOffsetAndSource = CFSwapInt32LittleToHost(data[2]);
        ret.startOfPageWordHyphenOffset = (hyphenOffsetAndSource & 0xffff);
        ret.source = (hyphenOffsetAndSource & 0xffff0000) >> 16;
    } else {
        THWarn(@"Could not read index point from file, error %d [\"%s\"]", errno, strerror(errno));
    }
    return ret;
}

+ (EucBookPageIndexPoint *)bookPageIndexPointFromFile:(NSString *)path 
{
    EucBookPageIndexPoint *ret = nil;
    int fd = open([path fileSystemRepresentation], O_RDONLY);
    if(fd > 0) {
        ret = [EucBookPageIndexPoint bookPageIndexPointFromOpenFD:fd];
        close(fd);
    }
    return ret;
}

+ (EucBookPageIndexPoint *)lastBookPageIndexPointFromFile:(NSString *)path 
{
    EucBookPageIndexPoint *ret = nil;
    int fd = open([path fileSystemRepresentation], O_RDONLY);
    if(fd > 0) {
        struct stat statResult;
        if(fstat(fd, &statResult) != -1) {
            off_t pointSize = [self sizeOnDisk];
            off_t seekTo = statResult.st_size / pointSize;
            seekTo *= pointSize;
            seekTo -= pointSize;
            lseek(fd, seekTo, SEEK_SET);
            ret = [EucBookPageIndexPoint bookPageIndexPointFromOpenFD:fd];
        }
        close(fd);
    }
    return ret;
}

- (NSComparisonResult)compare:(EucBookPageIndexPoint *)rhs
{
    int32_t comparison = self.startOfParagraphByteOffset - rhs.startOfParagraphByteOffset;
    if(comparison < 0) {
        return NSOrderedDescending;
    } else if (comparison > 0) {
        return NSOrderedAscending;
    } else {
        comparison = self.startOfPageParagraphWordOffset - rhs.startOfPageParagraphWordOffset;
        if(comparison < 0) {
            return NSOrderedDescending;
        } else if (comparison > 0) {
            return NSOrderedAscending;
        } else {
            comparison = self.startOfPageWordHyphenOffset - rhs.startOfPageWordHyphenOffset;
            if(comparison < 0) {
                return NSOrderedDescending;
            } else if (comparison > 0) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }        
    }
}


@end

