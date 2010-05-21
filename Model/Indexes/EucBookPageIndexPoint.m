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

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%ld, %ld, %ld, %ld]", (long)_source, (long)_block, (long)_word, (long)_element];
}

- (id)copyWithZone:(NSZone *)zone
{
    EucBookPageIndexPoint *ret = [[EucBookPageIndexPoint alloc] init];
    ret.source = self.source;
    ret.block = self.block;
    ret.word = self.word;
    ret.element = self.element;
    return ret;
}

- (NSComparisonResult)compare:(EucBookPageIndexPoint *)rhs
{
    int32_t comparison = self.source - rhs.source;
    if(comparison < 0) {
        return NSOrderedAscending;
    } else if (comparison > 0) {
        return NSOrderedDescending;
    } else {            
        comparison = self.block - rhs.block;
        if(comparison < 0) {
            return NSOrderedAscending;
        } else if (comparison > 0) {
            return NSOrderedDescending;
        } else {
            comparison = self.word - rhs.word;
            if(comparison < 0) {
                return NSOrderedAscending;
            } else if (comparison > 0) {
                return NSOrderedDescending;
            } else {
                comparison = self.element - rhs.element;
                if(comparison < 0) {
                    return NSOrderedAscending;
                } else if (comparison > 0) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            }        
        }
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt32:(int32_t)_source forKey:@"source"];
    [aCoder encodeInt32:(int32_t)_block forKey:@"block"];
    [aCoder encodeInt32:(int32_t)_word forKey:@"word"];
    [aCoder encodeInt32:(int32_t)_element forKey:@"element"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super init])) {
        _source = (uint32_t)[aDecoder decodeInt32ForKey:@"source"];
        _block = (uint32_t)[aDecoder decodeInt32ForKey:@"block"];
        _word = (uint32_t)[aDecoder decodeInt32ForKey:@"word"];
        _element = (uint32_t)[aDecoder decodeInt32ForKey:@"element"];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[EucBookPageIndexPoint class]]) {
        return [self compare:(EucBookPageIndexPoint *)object] == NSOrderedSame; 
    }
    return NO;
}

- (NSUInteger)hash
{
    return (_source * 2654435761) | (_block * 2654435761) | (_word * 2654435761) | (_element * 2654435761);
}

@end

