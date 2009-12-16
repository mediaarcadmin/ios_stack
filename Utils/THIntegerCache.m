//
//  IntegerCache.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/04/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THIntegerCache.h"

@implementation THIntegerCache

- (id)init
{
    if((self = [super init])) {
        _cacheDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                     256, 
                                                     &kCFCopyStringDictionaryKeyCallBacks, 
                                                     NULL);   
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
    [super dealloc];
}

- (void)_didReceiveMemoryWarning
{
    pthread_mutex_lock(&_cacheMutex);
    CFDictionaryRemoveAllValues(_cacheDictionary);
    pthread_mutex_unlock(&_cacheMutex);
}

- (void)cacheInteger:(NSInteger)value forKey:(NSString *)key
{
    pthread_mutex_lock(&_cacheMutex);
    CFDictionarySetValue(_cacheDictionary, key, (void *)((intptr_t)value));
    pthread_mutex_unlock(&_cacheMutex);
}

- (NSInteger)integerForKey:(NSString *)key
{
    const void *value = NULL;
    
    pthread_mutex_lock(&_cacheMutex);
    if(!CFDictionaryGetValueIfPresent(_cacheDictionary, key, &value)) {
        pthread_mutex_unlock(&_cacheMutex);
        return NSNotFound;
    }
    
    pthread_mutex_unlock(&_cacheMutex);
    return (NSInteger)((intptr_t)value);
}


@end
