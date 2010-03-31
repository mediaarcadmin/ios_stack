//
//  THIntegerKeysCache.h
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pthread.h>

@interface THIntegerKeysCache : NSObject {
    CFMutableDictionaryRef _cacheDictionary;
    pthread_mutex_t _cacheMutex;
}

- (void)cacheObject:(id)value forKey:(uint32_t)key;
- (id)objectForKey:(uint32_t)key;

@end
