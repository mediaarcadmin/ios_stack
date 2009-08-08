//
//  THNSFileManagerAdditions.m
//  Eucalyptus
//
//  Created by James Montgomerie on 27/11/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "THNSFileManagerAdditions.h"
#import "THLog.h"
#import <sys/xattr.h>
#import <sys/stat.h>
#import <unistd.h>
#import <fcntl.h>

@implementation NSFileManager (THAdditions)

struct getattrret {
    void *value;
    size_t size;
};

static int setxattr_and_backup(NSString *path, NSString *name, const void *value, size_t size)
{
    const char *pathFsrep = [path fileSystemRepresentation];
    int ret = setxattr(pathFsrep, 
                       [name UTF8String],
                       value,
                       size, 
                       0, 0);
    if(ret == 0) {
        struct stat statResult;
        if((stat(pathFsrep, &statResult) == 0) && ((statResult.st_mode | S_IFDIR) != 0)) {
            NSString *backupXattrFilePath = [path stringByAppendingPathComponent:[@".(o.O).ea." stringByAppendingString:name]];
            unlink([backupXattrFilePath fileSystemRepresentation]);
            int fd = open([backupXattrFilePath fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
            if(fd > 0) {
                if(write(fd, value, size) != size) {
                    THWarn(@"Error setting backup xattr file.");
                }
            } else {
                THWarn(@"Error opening backup xattr file for writing.");
            }
        }
    }
    return ret;
}


static struct getattrret get_xattr_from_backup_if_necessary(NSString *path, NSString *name)
{
    struct getattrret ret = { 0, 0 };
    
    const char *pathFsrep = [path fileSystemRepresentation];
    const char *utf8Name = [name UTF8String];
    
    ssize_t attributeSize = getxattr(pathFsrep, utf8Name, NULL, 0, 0, 0);
    if(attributeSize > 0) {
        ret.value = malloc(attributeSize);
        ret.size = attributeSize;
        getxattr(pathFsrep, utf8Name, ret.value, ret.size, 0, 0);
    } else {
        struct stat statResult;
        if(stat(pathFsrep, &statResult) == 0 && (statResult.st_mode | S_IFDIR) != 0) {
            NSString *backupXattrFilePath = [path stringByAppendingPathComponent:[@".(o.O).ea." stringByAppendingString:name]];
            int fd = open([backupXattrFilePath fileSystemRepresentation], O_RDONLY);
            if(fd <= 0) {
                // Fallback for older versions.
                // I was using a ._ prefix, forgetting it would collide with 
                // resource fork usage...
                backupXattrFilePath = [path stringByAppendingPathComponent:[@"._ea." stringByAppendingString:name]];
                fd = open([backupXattrFilePath fileSystemRepresentation], O_RDONLY);
            } 
            if(fd > 0) {
                if(fstat(fd, &statResult) == 0) {
                    if(statResult.st_size > 0) {
                        ret.value = malloc(statResult.st_size);
                        ret.size = statResult.st_size;
                        read(fd, ret.value, ret.size);
                        
                        THLog(@"Read xattr %@ for %@ from backup %@", name, path, [backupXattrFilePath lastPathComponent]);
                        
                        setxattr(pathFsrep, 
                                 utf8Name,
                                 ret.value,
                                 ret.size, 
                                 0, 0);
                    }
                }
            }
        }
    }

    return ret;
}

- (NSString *)stringExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path
{
    NSString *ret = nil;
    struct getattrret result = get_xattr_from_backup_if_necessary(path, name);
    if(result.size) {
        ret = [[[NSString alloc] initWithBytes:result.value length:result.size encoding:NSUTF8StringEncoding] autorelease];
        free(result.value);
    }    
    return ret;
}

- (BOOL)setStringExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path to:(NSString *)value
{
    const char *utf8Value = [value UTF8String];
    return setxattr_and_backup(path, name,
                               utf8Value,
                               strlen(utf8Value)) == 0;
}

- (uint64_t)uint64ExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path
{
    uint64_t attribute = 0;
    
    struct getattrret result = get_xattr_from_backup_if_necessary(path, name);
    if(result.size) {
        attribute = CFSwapInt64LittleToHost(*((uint64_t *)result.value));
        free(result.value);
    }
    return attribute;
}

- (BOOL)setUint64ExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path to:(uint64_t)value
{
    value = CFSwapInt64HostToLittle(value);
    return setxattr_and_backup(path,
                               name,
                               &value,
                               sizeof(uint64_t)) == 0;
}

@end
