//
//  THCache.m
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCache.h"
#import "THLog.h"

@implementation NSObject (THCacheObjectInUse)

- (BOOL)thCacheObjectInUse
{
    return self.retainCount > 1;
}

@end

@implementation THCache

typedef struct THCacheItem {
    THCache *self;
    id key;
    id value;
} THCacheItem;

- (id)init
{
    if((self = [super init])) {
        self.conserveItemsInUse = YES;
    }
    return self;
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THCacheItem *)item)->value thCacheObjectInUse];
}

@synthesize conserveItemsInUse = _conserveItemsInUse;

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

- (void)cacheObject:(id)value forKey:(id)key
{    
    pthread_mutex_lock(&_cacheMutex);

    THCacheItem item = { self, key, value };
    [self cacheItem:&item];
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForKey:(id)key
{
    id ret;
    
    pthread_mutex_lock(&_cacheMutex);
    THCacheItem probeItem = { self, key };
    const THCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);
    
    return ret;
}

@end

@implementation THIntegerToObjectCache

typedef struct THIntegerToObjectCacheItem {
    THIntegerToObjectCache *self;
    id value;
    uint32_t key;
} THIntegerToObjectCacheItem;

- (id)init
{
    if((self = [super init])) {
        self.conserveItemsInUse = YES;
    }
    return self;
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THIntegerToObjectCacheItem *)item)->value thCacheObjectInUse];
}

@synthesize conserveItemsInUse = _conserveItemsInUse;

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

- (NSString *)describeItem:(const void *)item
{
    return [NSString stringWithFormat:@"%ld -> { %@ }", (long)(((THIntegerToObjectCacheItem *)item)->key), [((THIntegerToObjectCacheItem *)item)->value description]]; 
}

- (void)cacheObject:(id)value forKey:(uint32_t)key
{    
    pthread_mutex_lock(&_cacheMutex);
    
    THIntegerToObjectCacheItem item = { self, value, key };
    [self cacheItem:&item];
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForKey:(uint32_t)key
{
    id ret;
    
    pthread_mutex_lock(&_cacheMutex);
    THIntegerToObjectCacheItem probeItem = { self, NULL, key};
    const THIntegerToObjectCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);

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

- (id)init
{
    if((self = [super init])) {
        self.conserveItemsInUse = YES;
    }
    return self;
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THStringAndIntegerToObjectCacheItem *)item)->value thCacheObjectInUse];
}

@synthesize conserveItemsInUse = _conserveItemsInUse;

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
    
    return item1->integerKey == item2->integerKey && [item1->stringKey isEqualToString:item2->stringKey];
}

- (CFHashCode)hashItem:(const void *)item
{
    return [((THStringAndIntegerToObjectCacheItem *)item)->stringKey hash] ^ (((THStringAndIntegerToObjectCacheItem *)item)->integerKey * 2654435761);
}

- (void)cacheObject:(id)value forStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey
{    
    pthread_mutex_lock(&_cacheMutex);
    
    THStringAndIntegerToObjectCacheItem item = { self, stringKey, integerKey, value };
    [self cacheItem:&item];
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey
{
    id ret;
    
    pthread_mutex_lock(&_cacheMutex);
    THStringAndIntegerToObjectCacheItem probeItem = { self, stringKey, integerKey } ;
    const THStringAndIntegerToObjectCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);
    
    return ret;
}

@end

@implementation THObjectAndCGFloatToObjectCache

typedef struct THObjectAndCGFloatToObjectCacheItem {
    THObjectAndCGFloatToObjectCache *self;
    id objectKey;
    union {
        CGFloat cgFloatKey;
        NSUInteger integerKey;
    } numberKey;
    id value;
} THObjectAndCGFloatToObjectCacheItem;

- (id)init
{
    if((self = [super init])) {
        self.conserveItemsInUse = YES;
    }
    return self;
}

- (BOOL)isItemInUse:(const void *)item
{
    return [((THObjectAndCGFloatToObjectCacheItem *)item)->value thCacheObjectInUse];
}

@synthesize conserveItemsInUse = _conserveItemsInUse;

- (CFIndex)itemSize
{
    return sizeof(THObjectAndCGFloatToObjectCacheItem);
}

- (void)copyItemContents:(const void *)item1In intoEmptyItem:(void *)item2In
{
    THObjectAndCGFloatToObjectCacheItem *item1 = (THObjectAndCGFloatToObjectCacheItem *)item1In;
    THObjectAndCGFloatToObjectCacheItem *item2 = (THObjectAndCGFloatToObjectCacheItem *)item2In;
    
    memcpy(item2, item1, sizeof(THObjectAndCGFloatToObjectCacheItem));
    [item2->objectKey retain];
    [item2->value retain];
}

- (void)releaseItemContents:(void *)itemIn
{
    THObjectAndCGFloatToObjectCacheItem *item = (THObjectAndCGFloatToObjectCacheItem *)itemIn;
    [item->objectKey release];
    [item->value release];
}

- (Boolean)item:(const void *)item1In isEqualToItem:(const void *)item2In
{
    THObjectAndCGFloatToObjectCacheItem *item1 = (THObjectAndCGFloatToObjectCacheItem *)item1In;
    THObjectAndCGFloatToObjectCacheItem *item2 = (THObjectAndCGFloatToObjectCacheItem *)item2In;
    
    return item1->numberKey.integerKey == item2->numberKey.integerKey && [item1->objectKey isEqual:item2->objectKey];
}

- (CFHashCode)hashItem:(const void *)item
{
    return [((THObjectAndCGFloatToObjectCacheItem *)item)->objectKey hash] ^ (((THObjectAndCGFloatToObjectCacheItem *)item)->numberKey.integerKey * 2654435761);
}

- (void)cacheObject:(id)value forObjectKey:(id)objectKey cgFloatKey:(CGFloat)cgFloatKey;
{    
    pthread_mutex_lock(&_cacheMutex);
    
    THObjectAndCGFloatToObjectCacheItem item = { self, objectKey, { cgFloatKey }, value };
    [self cacheItem:&item];
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForObjectKey:(id)objectKey cgFloatKey:(CGFloat)cgFloatKey;
{
    id ret;
    
    pthread_mutex_lock(&_cacheMutex);
    THObjectAndCGFloatToObjectCacheItem probeItem = { self, objectKey, { cgFloatKey } } ;
    const THObjectAndCGFloatToObjectCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = [[item->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);
    
    return ret;
}

@end



@implementation THStringAndCGFloatToCGFloatCache

typedef struct THStringAndFloatToCGFloatCacheItem {
    THStringAndCGFloatToCGFloatCache *self;
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

- (void)cacheCGFloat:(CGFloat)value forStringKey:(NSString *)stringKey cgFloatKey:(CGFloat)cgFloatKey
{    
    pthread_mutex_lock(&_cacheMutex);
    
    THStringAndFloatToCGFloatCacheItem item = { self, stringKey, { cgFloatKey }, value };
    [self cacheItem:&item];
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (CGFloat)cgFloatForStringKey:(NSString *)stringKey cgFloatKey:(CGFloat)cgFloatKey
{
    CGFloat ret;
    
    pthread_mutex_lock(&_cacheMutex);
    THStringAndFloatToCGFloatCacheItem probeItem = { self, stringKey, { cgFloatKey } } ;
    const THStringAndFloatToCGFloatCacheItem *item = [self retrieveItem:&probeItem];
    if(item) {
        ret = item->value;
    } else {
        ret = 0.0f;
    }
    pthread_mutex_unlock(&_cacheMutex);
    
    return ret;
}

@end

