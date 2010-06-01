//
//  EucBookIndex.m
//  libEucalyptus
//
//  Created by James Montgomerie on 27/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBookIndex.h"
#import "EucBook.h"
#import "EucBookPageIndex.h"
#import "EucFilteredBookPageIndex.h"
#import "THPair.h"
#import "THRegex.h"
#import "THLog.h"

#import <sys/stat.h>
#import <sys/fcntl.h>
#import <unistd.h>
#import <glob.h>

@implementation EucBookIndex

+ (NSUInteger)indexVersion
{
    return 1;
}

+ (NSString *)filenameForPageIndexForPointSize:(NSUInteger)fontSize
{
    return [NSString stringWithFormat:@"%lu.v%luPageIndex", (unsigned long)fontSize, (unsigned long)[self indexVersion]];
}

+ (NSString *)constructionFilenameForPageIndexForPointSize:(NSUInteger)fontSize
{
    return [NSString stringWithFormat:@"%lu.v%luPageIndexConstruction", (unsigned long)fontSize, (unsigned long)[self indexVersion]];
}

+ (NSString *)constructionFlagFilename
{
    return [NSString stringWithFormat:@"v%luIndexConstructed.flag", (unsigned long)[EucBookIndex indexVersion]];
}

+ (void)markBookBundleAsIndexesConstructed:(NSString *)bundlePath
{
    NSString *globPath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"*.v%luPageIndexConstruction", (unsigned long)[self indexVersion]]];
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
    
    int flagFd = open([[bundlePath stringByAppendingPathComponent:[[self class] constructionFlagFilename]] fileSystemRepresentation],
                      O_WRONLY | O_TRUNC | O_CREAT, 
                      S_IRUSR | S_IWUSR);
    if(flagFd != -1) {
        close(flagFd);
    } else {
        THWarn(@"Error marking indexes in %@ as constructed, error %d [\"%s\"]", bundlePath, errno, strerror(errno));  
    }
}

+ (BOOL)indexesAreConstructedForBookBundle:(NSString *)bundlePath
{
    return access([[bundlePath stringByAppendingPathComponent:[[self class] constructionFlagFilename]] fileSystemRepresentation],
                  F_OK) == 0;
}

@synthesize pageIndexPointSizes = _pageIndexPointSizes;
@synthesize pageIndexes = _pageIndexes;

- (id)initForBook:(id<EucBook>)book
{
    if((self = [super init])) {
        NSMutableArray *buildPageIndexes = [[NSMutableArray alloc] init];
        
        NSString *indexDirectoryPath = [book cacheDirectoryPath];
        NSString *globPath = [indexDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"*.v%luPageIndex*", (unsigned long)[[self class] indexVersion]]];
        glob_t globValue;
        int err = glob([globPath fileSystemRepresentation],
                       0,
                       NULL,
                       &globValue);
        if(err != 0) {
            THWarn(@"Globbing failed when attempting to find indexes in book bundle %@", indexDirectoryPath);
        } else if(globValue.gl_pathc <= 0) {
            THWarn(@"Could not find indexes in book bundle %@", indexDirectoryPath);
        } else {
            THRegex *indexRegex = [THRegex regexWithPOSIXRegex:[NSString stringWithFormat:@"([[:digit:]]+).v%luPageIndex(Construction)?$", (unsigned long)[[self class] indexVersion]]];
            
            _pageIndexPointSizes = malloc(globValue.gl_pathc * sizeof(NSUInteger));
            for(size_t i = 0; i < globValue.gl_pathc; ++i) {
                NSString *path = [NSString stringWithUTF8String:globValue.gl_pathv[i]];
                if([indexRegex matchString:path]) {
                    NSUInteger pointSize = [[indexRegex match:1] integerValue];
                    
                    EucFilteredBookPageIndex *index = [EucFilteredBookPageIndex bookPageIndexAtPath:path];
                    if(index) {
                        [buildPageIndexes addPairWithFirst:[NSNumber numberWithUnsignedInteger:pointSize]
                                                    second:index];
                    }
                }
            }
            globfree(&globValue);
        }
        
        if(buildPageIndexes.count) {
            [buildPageIndexes sortUsingSelector:@selector(compare:)];
            
            NSUInteger count = buildPageIndexes.count;
            _pageIndexPointSizes = [[NSMutableArray alloc] initWithCapacity:count];
            _pageIndexes = [[NSMutableArray alloc] initWithCapacity:count];
            for(THPair *sizeAndIndex in buildPageIndexes) {
                [(NSMutableArray *)_pageIndexPointSizes addObject:sizeAndIndex.first];
                [(NSMutableArray *)_pageIndexes addObject:sizeAndIndex.second];
            }
        } else {
            [self release];
            self = nil;
        }
        [buildPageIndexes release];
    }
    return self;
}

- (void)dealloc
{
    [_pageIndexes release];
    [_pageIndexPointSizes release];
    
    [super dealloc];
}


+ (EucBookIndex *)bookIndexForBook:(id<EucBook>)book
{
    return [[[self alloc] initForBook:book] autorelease];
}

@end
