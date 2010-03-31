//
//  THCache.h
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pthread.h"

@interface THTreeCache : NSObject {
    void *_cacheTree;
    size_t _count;
    pthread_mutex_t _cacheMutex;
    
    void **_deletionAccumulator;
    size_t _deletionAccumulatorCount;
}

- (void)flushCache:(BOOL)force;
- (void)cacheObject:(id)value forKey:(id)key;
- (id)objectForKey:(id)key;

@end


@interface THIntegerKeyedTreeCache : THTreeCache {}

- (void)cacheObject:(id)value forKey:(uint32_t)key;
- (id)objectForKey:(uint32_t)key;

@end