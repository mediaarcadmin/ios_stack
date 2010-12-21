//
//  THCache.m
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCache.h"
#import "THLog.h"

@implementation THCache

typedef struct THCacheItem {
    THCache *self;
    id key;
    id value;
} THCacheItem;

- (CFIndex)itemSize
{
    return sizeof(THCacheItem);
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In
{
    THCacheItem *item1 = (THCacheItem *)item1In;
    THCacheItem *item2 = (THCacheItem *)item2In;
    
    memcpy(item2, item1, sizeof(THCacheItem));
    [item2->key retain];
    [item2->value retain];
}

- (void)releaseItemContents:(void *)itemIn
{
    THCacheItem *item = (THCacheItem *)itemIn;
    [item->key release];
    [item->value release];
}

- (Boolean)item:(const void *)item1In isEqualToItem:(const void *)item2In
{
    THCacheItem *item1 = (THCacheItem *)item1In;
    THCacheItem *item2 = (THCacheItem *)item2In;
    
    return [item1->key isEqual:item2->key];
}

- (CFHashCode)hashItem:(const void *)item
{
    return [((THCacheItem *)item)->key hash];
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THCacheItem *)item)->value thCacheObjectInUse];
}

- (void)cacheObject:(id)value forKey:(id)key
{    
    pthread_rwlock_wrlock(&_cacheRWLock);

    THCacheItem item = { self, key, value };
    [self cacheItem:&item];
    
    pthread_rwlock_unlock(&_cacheRWLock);
}

- (id)objectForKey:(id)key
{
    id ret;
    
    pthread_rwlock_rdlock(&_cacheRWLock);
    THCacheItem probeItem = { self, key };
    const THCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_rwlock_unlock(&_cacheRWLock);
    
    return ret;
}

@end

@implementation NSObject (THCacheObjectInUse)

- (BOOL)thCacheObjectInUse
{
    return self.retainCount > 1;
}

@end



@implementation THIntegerToObjectCache

typedef struct THIntegerToObjectCacheItem {
    THIntegerToObjectCache *self;
    uint32_t key;
    id value;
} THIntegerToObjectCacheItem;

- (CFIndex)itemSize
{
    return sizeof(THIntegerToObjectCacheItem);
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In
{
    THIntegerToObjectCacheItem *item1 = (THIntegerToObjectCacheItem *)item1In;
    THIntegerToObjectCacheItem *item2 = (THIntegerToObjectCacheItem *)item2In;
    
    memcpy(item2, item1, sizeof(THIntegerToObjectCacheItem));
    [item2->value retain];
}

- (void)releaseItemContents:(void *)item;
{
    [((THIntegerToObjectCacheItem *)item)->value release];
}

- (Boolean)item:(const void *)item1 isEqualToItem:(const void *)item2
{
    return ((THIntegerToObjectCacheItem *)item1)->key == ((THIntegerToObjectCacheItem *)item2)->key;
}

- (CFHashCode)hashItem:(const void *)item
{
    return ((THIntegerToObjectCacheItem *)item)->key * 2654435761;
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THCacheItem *)item)->value retainCount] > 1;
}

- (void)cacheObject:(id)value forKey:(uint32_t)key
{    
    pthread_rwlock_wrlock(&_cacheRWLock);
    
    THIntegerToObjectCacheItem item = { self, key, value};
    [self cacheItem:&item];
    
    pthread_rwlock_unlock(&_cacheRWLock);
}

- (id)objectForKey:(uint32_t)key
{
    id ret;
    
    pthread_rwlock_rdlock(&_cacheRWLock);
    THIntegerToObjectCacheItem probeItem = { self, key, 0 };
    const THCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_rwlock_unlock(&_cacheRWLock);

    return ret;
}

@end



@implementation THStringAndIntegerToObjectCache

typedef struct THStringAndIntegerToObjectCacheItem {
    THStringAndIntegerToObjectCache *self;
    NSString *stringKey;
    uint32_t integerKey;
    id value;
} THStringAndIntegerToObjectCacheItem;

- (CFIndex)itemSize
{
    return sizeof(THStringAndIntegerToObjectCacheItem);
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In
{
    THStringAndIntegerToObjectCacheItem *item1 = (THStringAndIntegerToObjectCacheItem *)item1In;
    THStringAndIntegerToObjectCacheItem *item2 = (THStringAndIntegerToObjectCacheItem *)item2In;
    
    memcpy(item2, item1, sizeof(THStringAndIntegerToObjectCacheItem));
    [item2->stringKey retain];
    [item2->value retain];
}

- (void)releaseItemContents:(void *)itemIn
{
    THStringAndIntegerToObjectCacheItem *item = (THStringAndIntegerToObjectCacheItem *)itemIn;
    [item->stringKey release];
    [item->value release];
}

- (Boolean)item:(const void *)item1In isEqualToItem:(const void *)item2In
{
    THStringAndIntegerToObjectCacheItem *item1 = (THStringAndIntegerToObjectCacheItem *)item1In;
    THStringAndIntegerToObjectCacheItem *item2 = (THStringAndIntegerToObjectCacheItem *)item2In;
    
    return item1->integerKey == item2->integerKey && [item1->stringKey isEqual:item2->stringKey];
}

- (CFHashCode)hashItem:(const void *)item
{
    return [((THStringAndIntegerToObjectCacheItem *)item)->stringKey hash] ^ (((THStringAndIntegerToObjectCacheItem *)item)->integerKey * 2654435761);
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THStringAndIntegerToObjectCacheItem *)item)->value retainCount] > 1;
}

- (void)cacheObject:(id)value forStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey
{    
    pthread_rwlock_wrlock(&_cacheRWLock);
    
    THStringAndIntegerToObjectCacheItem item = { self, stringKey, integerKey, value };
    [self cacheItem:&item];
    
    pthread_rwlock_unlock(&_cacheRWLock);
}

- (id)objectForStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey
{
    id ret;
    
    pthread_rwlock_rdlock(&_cacheRWLock);
    THStringAndIntegerToObjectCacheItem probeItem = { self, stringKey, integerKey } ;
    const THStringAndIntegerToObjectCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_rwlock_unlock(&_cacheRWLock);
    
    return ret;
}

@end

@implementation THStringAndFloatToCGFloatCache

typedef struct THStringAndFloatToCGFloatCacheItem {
    THStringAndFloatToCGFloatCache *self;
    NSString *stringKey;
    union {
        CGFloat cgFloatKey;
        NSUInteger integerKey;
    } numberKey;
    CGFloat value;
} THStringAndFloatToCGFloatCacheItem;

- (CFIndex)itemSize
{
    return sizeof(THStringAndFloatToCGFloatCacheItem);
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In
{
    THStringAndFloatToCGFloatCacheItem *item1 = (THStringAndFloatToCGFloatCacheItem *)item1In;
    THStringAndFloatToCGFloatCacheItem *item2 = (THStringAndFloatToCGFloatCacheItem *)item2In;
    
    memcpy(item2, item1, sizeof(THStringAndFloatToCGFloatCacheItem));
    [item2->stringKey retain];
}

- (void)releaseItemContents:(void *)itemIn
{
    THStringAndFloatToCGFloatCacheItem *item = (THStringAndFloatToCGFloatCacheItem *)itemIn;
    [item->stringKey release];
}

- (Boolean)item:(const void *)item1In isEqualToItem:(const void *)item2In
{
    THStringAndFloatToCGFloatCacheItem *item1 = (THStringAndFloatToCGFloatCacheItem *)item1In;
    THStringAndFloatToCGFloatCacheItem *item2 = (THStringAndFloatToCGFloatCacheItem *)item2In;
    
    return item1->numberKey.cgFloatKey == item2->numberKey.cgFloatKey && [item1->stringKey isEqual:item2->stringKey];
}

- (CFHashCode)hashItem:(const void *)item
{
    return [((THStringAndFloatToCGFloatCacheItem *)item)->stringKey hash] ^ (((THStringAndFloatToCGFloatCacheItem *)item)->numberKey.integerKey * 2654435761);
}

- (void)cacheCGFloat:(CGFloat)value forStringKey:(NSString *)stringKey cgFloatKet:(CGFloat)cgFloatKey
{    
    pthread_rwlock_wrlock(&_cacheRWLock);
    
    THStringAndFloatToCGFloatCacheItem item = { self, stringKey, { cgFloatKey }, value };
    [self cacheItem:&item];
    
    pthread_rwlock_unlock(&_cacheRWLock);
}

- (CGFloat)cgFloatForStringKey:(NSString *)stringKey cgFloatKet:(CGFloat)cgFloatKey
{
    CGFloat ret;
    
    pthread_rwlock_rdlock(&_cacheRWLock);
    THStringAndFloatToCGFloatCacheItem probeItem = { self, stringKey, { cgFloatKey } } ;
    const THStringAndFloatToCGFloatCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = item->value;
    } else {
        ret = 0.0f;
    }
    pthread_rwlock_unlock(&_cacheRWLock);
    
    return ret;
}

@end

