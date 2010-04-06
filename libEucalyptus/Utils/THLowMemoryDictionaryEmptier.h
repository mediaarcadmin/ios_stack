//
//  LowMemoryDictionaryEmptier.h
//  libEucalyptus
//
//  Created by James Montgomerie on 03/04/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

@interface THLowMemoryDictionaryEmptier : NSObject {
    CFMutableDictionaryRef _dictionary;
    pthread_mutex_t *_pMutex;
}

- (id)initWithDictionary:(CFMutableDictionaryRef)dictionary mutex:(pthread_mutex_t *)mutex;

@end
