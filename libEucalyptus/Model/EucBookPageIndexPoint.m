//
//  BookPageIndexPoint.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/09/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBookPageIndexPoint.h"
#import "THLog.h"
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>

@implementation EucBookPageIndexPoint

@synthesize source = _source;
@synthesize block = _block;
@synthesize word = _word;
@synthesize element = _element;

+ (off_t)sizeOnDisk
{
    return sizeof(int32_t) * 4;
}

- (BOOL)writeToOpenFD:(int)fd
{
    int32_t data[4];
    data[0] = CFSwapInt32HostToLittle(_source);
    data[1] = CFSwapInt32HostToLittle(_block);
    data[2] = CFSwapInt32HostToLittle(_word);
    data[3] = CFSwapInt32HostToLittle(_element);
    
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
    int32_t data[4];
    size_t size = sizeof(data);
    EucBookPageIndexPoint *ret = nil;
    if(read(fd, data, size) == size) {
        ret = [[[EucBookPageIndexPoint alloc] init] autorelease];
        ret.source = CFSwapInt32LittleToHost(data[0]);
        ret.block = CFSwapInt32LittleToHost(data[1]);
        ret.word = CFSwapInt32LittleToHost(data[2]);
        ret.element = CFSwapInt32LittleToHost(data[3]);
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
    int32_t comparison = self.source - rhs.source;
    if(comparison < 0) {
        return NSOrderedDescending;
    } else if (comparison > 0) {
        return NSOrderedAscending;
    } else {            
        comparison = self.block - rhs.block;
        if(comparison < 0) {
            return NSOrderedDescending;
        } else if (comparison > 0) {
            return NSOrderedAscending;
        } else {
            comparison = self.word - rhs.word;
            if(comparison < 0) {
                return NSOrderedDescending;
            } else if (comparison > 0) {
                return NSOrderedAscending;
            } else {
                comparison = self.element - rhs.element;
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
}


@end

