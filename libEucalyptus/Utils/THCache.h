//
//  THCache.h
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pthread.h"

@interface THCache : NSObject {
    CFMutableDictionaryRef _cacheDictionary;
    pthread_mutex_t _cacheMutex;
}

- (void)cacheObject:(id)value forKey:(id)key;
- (id)objectForKey:(id)key;

@end
