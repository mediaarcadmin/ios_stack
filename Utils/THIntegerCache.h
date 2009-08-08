//
//  IntegerCache.h
//  Eucalyptus
//
//  Created by James Montgomerie on 02/04/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pthread.h"

@interface THIntegerCache : NSObject {
    CFMutableDictionaryRef _cacheDictionary;
    pthread_mutex_t _cacheMutex;
}


- (void)cacheInteger:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;

@end
