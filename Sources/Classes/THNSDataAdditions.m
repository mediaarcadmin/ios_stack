//
//  THNSDataAdditions.m
//  Eucalyptus
//
//  Created by James Montgomerie on 03/11/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "THNSDataAdditions.h"

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

@implementation NSData (THNSDataAdditions)

- (BOOL)writeToMappedFile:(NSString *)path
{
    BOOL ret = NO;
    const char *pathFileSystemRepresentation = [path fileSystemRepresentation];
    
    int fd = open(pathFileSystemRepresentation, O_RDWR | O_CREAT , S_IRUSR | S_IWUSR);
    if(fd) {
        off_t size = [self length];
        if(ftruncate(fd, size) == 0) {
            void *mappedFile = mmap(NULL, size, PROT_WRITE, MAP_FILE | MAP_SHARED, fd, 0);
            close(fd);
            if(mappedFile) {
                memcpy(mappedFile, [self bytes], size);
                ret = (munmap(mappedFile, size) == 0);
            }
        } else {
            close(fd);
        }
        if(!ret) {
            unlink(pathFileSystemRepresentation);
        }
    }
    
    return ret;
}


@end
