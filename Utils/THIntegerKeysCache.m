//
//  THIntegerKeysCache.m
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THIntegerKeysCache.h"
#import "THLog.h"

@implementation THIntegerKeysCache

- (id)init
{
    if((self = [super init])) {
        _cacheDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                     0, 
                                                     NULL, 
                                                     &kCFTypeDictionaryValueCallBacks);   
        pthread_mutex_init(&_cacheMutex, NULL);
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];        
    }
    return self;
}

- (void)dealloc
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];
    pthread_mutex_destroy(&_cacheMutex);
    CFRelease(_cacheDictionary);
    
    [super dealloc];
}

static void UsedCacheItemsAccumulator(const void *key, const void *value, void *context)
{
    if(CFGetRetainCount(value) > 1) {
        CFDictionarySetValue(context, key, value);
    }
}

- (void)_didReceiveMemoryWarning
{
    pthread_mutex_lock(&_cacheMutex);
    
    THLog(@"Cache had %ld items - emptying...", (long)CFDictionaryGetCount(_cacheDictionary));
    
    // Create a new dictionary containing only the items that are used 
    // elsewhere, and switch it out for the full dictionary.
    CFMutableDictionaryRef newDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                                     0, 
                                                                     NULL, 
                                                                     &kCFTypeDictionaryValueCallBacks);
    CFDictionaryApplyFunction(_cacheDictionary, UsedCacheItemsAccumulator, newDictionary);
    CFRelease(_cacheDictionary);
    _cacheDictionary = newDictionary;
    
    THLog(@"Cache has %ld items.", (long)CFDictionaryGetCount(_cacheDictionary));
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (void)cacheObject:(id)value forKey:(uint32_t)key
{
    pthread_mutex_lock(&_cacheMutex);
    CFDictionarySetValue(_cacheDictionary, (void *)((intptr_t)key), value);
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForKey:(uint32_t)key
{
    id value = nil;
    
    pthread_mutex_lock(&_cacheMutex);
    value = (id)CFDictionaryGetValue(_cacheDictionary, ((intptr_t)key));
    [[value retain] autorelease];
    pthread_mutex_unlock(&_cacheMutex);
    
    return value;
}

@end
