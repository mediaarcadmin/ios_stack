//
//  THCacheBase.h
//  libEucalyptus
//
//  Created by James Montgomerie on 01/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

@interface THCacheBase : NSObject {
    pthread_rwlock_t _cacheRWLock;
    CFMutableSetRef _cacheSet;
}

// To override:
- (CFIndex)itemSize;
- (void)copyItemContents:(const void *)item1 intoEmptyItem:(void *)item2;
- (void)releaseItemContents:(void *)item;
- (Boolean)item:(const void *)item1 isEqualToItem:(const void *)item2;
- (CFHashCode)hashItem:(const void *)item;

// To call:
- (void)cacheItem:(void *)item;
- (const void *)retrieveItem:(void *)probeItem;

@end

@protocol THCacheItemInUse

- (BOOL)isItemInUse:(const void *)item;

@end