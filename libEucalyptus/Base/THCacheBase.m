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

static BOOL sDontReallyCache;
static pthread_once_t sDontReallyCacheOnceControl = PTHREAD_ONCE_INIT;

@implementation THCacheBase

static void readDontReallyCacheDefault()
{
    sDontReallyCache = [[NSUserDefaults standardUserDefaults] boolForKey:@"THCacheDontReallyCache"];
}

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
        pthread_once(&sDontReallyCacheOnceControl, readDontReallyCacheDefault);
        pthread_rwlock_init(&_cacheRWLock, NULL);
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
#endif        
        _cacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
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
    
    CFRelease(_cacheSet);
    
    pthread_rwlock_destroy(&_cacheRWLock);
    
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

- (void)_didReceiveMemoryWarning
{
    THLog(@"Cache had %ld items - emptying...", (long)CFSetGetCount(_cacheSet));
    
    pthread_rwlock_wrlock(&_cacheRWLock);
    
    if([self respondsToSelector:@selector(isItemInUse:)]) {
        CFIndex setCount = CFSetGetCount(_cacheSet);
        const void **items = malloc(sizeof(void *) * setCount);
        CFSetGetValues(_cacheSet, items);
        for(CFIndex i = 0; i < setCount; ++i) { 
            if(![(id<THCacheItemInUse>)self isItemInUse:items[i]]) {
                CFSetRemoveValue(_cacheSet, items[i]);
            }
        }
        free(items);
    } else {
        CFRelease(_cacheSet);
        _cacheSet = CFSetCreateMutable(kCFAllocatorDefault, 0, &THCacheSetCallBacks);
    }

    pthread_rwlock_unlock(&_cacheRWLock);
    THLog(@"Cache has %ld items.", (long)CFSetGetCount(_cacheSet));
}

- (void)cacheItem:(void *)item
{
    if(!sDontReallyCache) {
        CFSetSetValue(_cacheSet, item);
    }
}

- (const void *)retrieveItem:(void *)probeItem
{
    return CFSetGetValue(_cacheSet, probeItem);
}

@end
