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
@private
    CFMutableSetRef _currentCacheSet;
    CFMutableSetRef _lastGenerationCacheSet;
    
    NSUInteger _generationLifetime;
    NSUInteger _insertionsThisGeneration;

@protected
    pthread_mutex_t _cacheMutex;
}

@property (nonatomic, assign) NSUInteger generationLifetime;

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

@optional
@property (nonatomic, assign) BOOL conserveItemsInUse;  // Treated as YES if not implemented.

@end