//
//  EucBUpeZipDataProvider.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBUpeZipDataProvider.h"
#import <minizip/unzip.h>

@implementation EucBUpeZipDataProvider

- (id)initWithZipFileAtPath:(NSString *)path
{
    if((self = [super init])) {
        _unzfile = unzOpen([path UTF8String]);
        if(!_unzfile) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    if(_unzfile) {
        unzClose(_unzfile);
    }
    [super dealloc];
}

- (NSData *)dataForComponentAtPath:(NSString *)path
{
    NSData *ret = nil;
    if(path.length) {
        const char *pathChars = [path UTF8String];
        size_t pathCharsLen = strlen(pathChars);
        while(pathCharsLen && pathChars[0] == '/') {
            ++pathChars;
            --pathCharsLen;
        }
        if(pathCharsLen) {
            if(unzLocateFile(_unzfile, pathChars, 1) == UNZ_OK) {
                if(unzOpenCurrentFile(_unzfile) == UNZ_OK) {
                    unz_file_info fileInfo;
                    if(unzGetCurrentFileInfo(_unzfile, &fileInfo, NULL, 0, NULL, 0, NULL, 0) == UNZ_OK) {
                        void *bytes = malloc(fileInfo.uncompressed_size);
                        if(unzReadCurrentFile(_unzfile, bytes, fileInfo.uncompressed_size) == fileInfo.uncompressed_size) {
                            ret = [NSData dataWithBytesNoCopy:bytes length:fileInfo.uncompressed_size freeWhenDone:YES];
                        } else {
                            free(bytes);
                        }
                    }
                    unzCloseCurrentFile(_unzfile);
                }
            }
        }
    }
    return ret;
}

@end
