//
//  NSStringAdditions.m
//
//  Created by James Montgomerie on 25/04/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THNSStringAdditions.h"
#import <pthread.h>

@implementation NSString (THAdditions)

+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding
{
    NSString *string = [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
    return [string autorelease];
}


static CFAllocatorRef sObjectBackedAllocator = NULL;
typedef struct {
    id object;
    CFIndex objectBackingCount;
} ObjectBackedAllocatorObjectBackingCount;
static CFMutableDictionaryRef sObjectBackedAllocatorPointerToObjectDictionary = NULL;
static pthread_mutex_t sObjectBackedAllocatorMutex = PTHREAD_MUTEX_INITIALIZER;


static void *objectBackedAllocatorAllocate(CFIndex size, CFOptionFlags hint, void *info)
{
    [NSException raise:NSInternalInconsistencyException format:@"Unexpected call to objectBackedAllocatorAllocate"];
    return NULL;
}

static void *objectBackedAllocatorReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
    [NSException raise:NSInternalInconsistencyException format:@"Unexpected call to objectBackedAllocatorReallocate"];
    return NULL;
}

static void objectBackedAllocatorDeallocate(void *ptr, void *info)
{
    pthread_mutex_lock(&sObjectBackedAllocatorMutex);

    ObjectBackedAllocatorObjectBackingCount *backingCount = (ObjectBackedAllocatorObjectBackingCount *)CFDictionaryGetValue(sObjectBackedAllocatorPointerToObjectDictionary, ptr);
    if(--(backingCount->objectBackingCount) == 0) {
        CFDictionaryRemoveValue(sObjectBackedAllocatorPointerToObjectDictionary, ptr);
        pthread_mutex_unlock(&sObjectBackedAllocatorMutex);
        [backingCount->object release];
        free(backingCount);
    } else {
        pthread_mutex_unlock(&sObjectBackedAllocatorMutex);
    }
}

static CFIndex objectBackedAllocatorPreferredSize(CFIndex size, CFOptionFlags hint, void *info)
{
    return 0;
}

static void objectBackedAllocatorRegisterPointerAsBelongingTo(const void *ptr, id object)
{
    pthread_mutex_lock(&sObjectBackedAllocatorMutex);
    if(!sObjectBackedAllocator) {
        CFAllocatorContext context;
        context.version = 0;
        context.info = NULL;
        context.retain = NULL;
        context.release = NULL;
        context.copyDescription = NULL;
        context.allocate = objectBackedAllocatorAllocate;
        context.reallocate = objectBackedAllocatorReallocate;
        context.deallocate = objectBackedAllocatorDeallocate;
        context.preferredSize = objectBackedAllocatorPreferredSize;
        
        sObjectBackedAllocator = CFAllocatorCreate(kCFAllocatorDefault, &context);
        
        sObjectBackedAllocatorPointerToObjectDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                                   0, 
                                                                                   NULL,
                                                                                   NULL);
    }
    
    ObjectBackedAllocatorObjectBackingCount *backingCount = (ObjectBackedAllocatorObjectBackingCount *)CFDictionaryGetValue(sObjectBackedAllocatorPointerToObjectDictionary, ptr);
    if(backingCount) {
        ++(backingCount->objectBackingCount);
    } else {
        backingCount = malloc(sizeof(ObjectBackedAllocatorObjectBackingCount));
        backingCount->object = [object retain];
        backingCount->objectBackingCount = 1;
    
        CFDictionarySetValue(sObjectBackedAllocatorPointerToObjectDictionary, 
                             ptr, backingCount);
    }
    pthread_mutex_unlock(&sObjectBackedAllocatorMutex);    
}

+ (id)stringWithCharacters:(const UniChar *)characters length:(NSUInteger)length backedBy:(id)object
{
    objectBackedAllocatorRegisterPointerAsBelongingTo(characters, object);
    // According to the CFString.h comments, CFStringCreateMutableWithExternalCharactersNoCopy
    // is the only reliable way to create a user-buffer-backed CFString.
    CFStringRef string = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault, 
                                                                           (UniChar *)characters, 
                                                                           length, 
                                                                           length, 
                                                                           sObjectBackedAllocator);
    return [(NSString *)string autorelease];
}


+ (id)stringWithRegMatch:(regmatch_t *)match fromBytes:(const char *)string encoding:(NSStringEncoding)encoding
{
    regoff_t start = match->rm_so;
    if(start == -1) {
        return nil;
    } else {
        regoff_t end = match->rm_eo;
        return [NSString stringWithBytes:string + start length:end - start encoding:encoding];
    }    
}

+ (id)stringWithRegMatch:(regmatch_t *)match fromCString:(const char *)string 
{
    return [self stringWithRegMatch:match fromBytes:string encoding:NSASCIIStringEncoding];
}

+ (id)stringWithByteSize:(long long)byteSize
{
	if(byteSize < 1023) {
		return([NSString stringWithFormat:@"%lld bytes", byteSize]);
    }
    
    double floatSize = (double)byteSize;
    
	floatSize /= 1024;
	if(floatSize < 1023) {
		return([NSString stringWithFormat:@"%1.1f KB", floatSize]);
    }
    
	floatSize /= 1024;
	if(floatSize < 1023) {
		return([NSString stringWithFormat:@"%1.1f MB", floatSize]);
    }
    
	floatSize /= 1024;
	return([NSString stringWithFormat:@"%1.1f GB", floatSize]);
}

- (NSComparisonResult)naturalCompare:(NSString *)aString
{
    return [self compare:aString options:NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch |
                                         NSWidthInsensitiveSearch | NSForcedOrderingSearch];
}

- (NSString *)stringForTitleSorting
{
    NSString *lowerCaseSelf = [self lowercaseString];
    if([lowerCaseSelf hasPrefix:@"the "]) {
        return [[[self substringFromIndex:4] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@", The"];
    } else if([lowerCaseSelf hasPrefix:@"a "]) {
        return [[[self substringFromIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@", A"];
    } else {
        return self;
    }
}

- (NSComparisonResult)titleCompare:(NSString *)aString
{
    return [[self stringForTitleSorting] compare:[aString stringForTitleSorting]
                                         options:NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch |
                                                 NSWidthInsensitiveSearch | NSForcedOrderingSearch];
}

@end
