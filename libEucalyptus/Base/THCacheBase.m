//
//  THCacheBase.m
//  libEucalyptus
//
//  Created by James Montgomerie on 01/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCacheBase.h"
#import "THLog.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@implementation THCacheBase

@synthesize generationLifetime = _generationLifetime;

static const void *THCacheItemRetain(CFAllocatorRef allocator, const void *item)
{
    THCacheBase *cache = *((THCacheBase **)item);
    
    void *newItem = CFAllocatorAllocate(allocator, [cache itemSize], 0);
    [cache copyItemContents:item intoEmptyItem:newItem];
    
    return newItem; 
}

static void THCacheItemRelease(CFAllocatorRef allocator, const void *item)
{    
    [*((THCacheBase **)item) releaseItemContents:(void *)item];
    CFAllocatorDeallocate(allocator, (void *)item);
}

static Boolean THCacheItemEqual(const void *item1, const void *item2)
{    
    return [*((THCacheBase **)item1) item:item1 isEqualToItem:item2];
}

CFHashCode THCacheItemHash(const void *item)
{
    return [*((THCacheBase **)item) hashItem:item];    
}

static const CFSetCallBacks THCacheSetCallBacks = {
    0,
    THCacheItemRetain,
    THCacheItemRelease,
    NULL,
    THCacheItemEqual,
    THCacheItemHash
};

- (id)init
{
    if((self = [super init])) {
        pthread_mutex_init(&_cacheMutex, NULL);
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
#endif        
        _currentCacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
    }
    return self;
}

- (void)dealloc
{    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];
#endif
    
    if(_lastGenerationCacheSet) {
        CFRelease(_lastGenerationCacheSet);
    }
    CFRelease(_currentCacheSet);
    
    pthread_mutex_destroy(&_cacheMutex);
    
    [super dealloc];
}

- (CFIndex)itemSize
{
    return 0;
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In {}

- (void)releaseItemContents:(void *)itemIn {}

- (Boolean)item:(const void *)item1In isEqualToItem:(const void *)item2In { return YES; }

- (CFHashCode)hashItem:(const void *)item { return 0; }

- (void)_cycleGenerations
{
    if([self respondsToSelector:@selector(isItemInUse:)] &&
       (![self respondsToSelector:@selector(conserveItemsInUse)] || [(id<THCacheItemInUse>)self conserveItemsInUse])) {
        // Save all the still-in-use values from the old generation.
        CFIndex setCount = CFSetGetCount(_lastGenerationCacheSet);
        const void **items = malloc(sizeof(void *) * setCount);
        CFSetGetValues(_lastGenerationCacheSet, items);
        for(CFIndex i = 0; i < setCount; ++i) { 
            if([(id<THCacheItemInUse>)self isItemInUse:items[i]]) {
                CFSetSetValue(_currentCacheSet, items[i]);
            }
        }
        free(items);
    } 
    
    // Get rid of the old generation, and 
    CFRelease(_lastGenerationCacheSet);
    _lastGenerationCacheSet = _currentCacheSet;
    _currentCacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
    
    if(CFSetGetCount(_lastGenerationCacheSet) > _generationLifetime) {
        THWarn(@"Cache has more items in use from last generation (%ld) than generation lifetime (%ld)", (long)CFSetGetCount(_lastGenerationCacheSet), (long)_generationLifetime);
    }
    
    _insertionsThisGeneration = 0;
}

- (void)_didReceiveMemoryWarning
{
    pthread_mutex_lock(&_cacheMutex);
    
    if(_lastGenerationCacheSet) {
        THLog(@"Cache had %ld items - emptying...", (long)CFSetGetCount(_currentCacheSet) +  (long)CFSetGetCount(_lastGenerationCacheSet));
    } else {
        THLog(@"Cache had %ld items - emptying...", (long)CFSetGetCount(_currentCacheSet));
    }
    
    if([self respondsToSelector:@selector(isItemInUse:)] &&
       (![self respondsToSelector:@selector(conserveItemsInUse)] || [(id<THCacheItemInUse>)self conserveItemsInUse])) {
        THLog(@"Conserving items in use in current cache set...");
        CFIndex setCount = CFSetGetCount(_currentCacheSet);
        const void **items = malloc(sizeof(void *) * setCount);
        CFSetGetValues(_currentCacheSet, items);
        for(CFIndex i = 0; i < setCount; ++i) { 
            if(![(id<THCacheItemInUse>)self isItemInUse:items[i]]) {
                CFSetRemoveValue(_currentCacheSet, items[i]);
            }
        }
        free(items);
    } else {
        CFRelease(_currentCacheSet);
        _currentCacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
    }

    if(_generationLifetime) {
        [self _cycleGenerations];
    }

    THLog(@"Cache has %ld items.", (long)CFSetGetCount(_lastGenerationCacheSet ?: _currentCacheSet));

    pthread_mutex_unlock(&_cacheMutex);
}

- (void)setGenerationLifetime:(NSUInteger)generationLifetime
{
    pthread_mutex_lock(&_cacheMutex);
    if(generationLifetime > 0) {
        _generationLifetime = generationLifetime;
        if(!_lastGenerationCacheSet) {
            _lastGenerationCacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
        }
    } else {
        if(_generationLifetime) {
            [self _cycleGenerations];
            CFRelease(_currentCacheSet);
            _currentCacheSet = _lastGenerationCacheSet;
            _lastGenerationCacheSet = nil;
            _generationLifetime = 0;
        }
    }
    pthread_mutex_unlock(&_cacheMutex);
}

- (void)cacheItem:(void *)item
{
    if(_lastGenerationCacheSet) {
        CFSetRemoveValue(_lastGenerationCacheSet, item);
    }
    CFSetSetValue(_currentCacheSet, item);
    if(_generationLifetime) {
        if(++_insertionsThisGeneration > _generationLifetime) {
            [self _cycleGenerations];
        }
    }
}

- (const void *)retrieveItem:(void *)probeItem
{
    const void *ret = CFSetGetValue(_currentCacheSet, probeItem);
    if(!ret && _lastGenerationCacheSet) {
        ret = CFSetGetValue(_lastGenerationCacheSet, probeItem);
        if(ret) {
            CFSetSetValue(_currentCacheSet, ret);
            CFSetRemoveValue(_lastGenerationCacheSet, ret);
        }
    }
    return ret;
}

@end
