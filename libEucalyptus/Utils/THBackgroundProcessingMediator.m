//
//  THBackgroundProcessingMediator.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/12/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THBackgroundProcessingMediator.h"
#import "THLog.h"
#import <pthread.h>

static pthread_rwlock_t rw_lock = PTHREAD_RWLOCK_INITIALIZER;
static NSInteger sCurtailationCount = 0;

@implementation THBackgroundProcessingMediator

+ (void)sleepIfBackgroundProcessingCurtailed
{
    if(pthread_rwlock_trywrlock(&rw_lock) == EBUSY) {
        THLog(@"Sleeping - Background Processing is curtailed");
        pthread_rwlock_wrlock(&rw_lock);
        THLog(@"Woken up - Background Processing is not curtailed");
    }
    pthread_rwlock_unlock(&rw_lock);
}

+ (void)curtailBackgroundProcessing
{
    if(sCurtailationCount == 0) {
        pthread_rwlock_rdlock(&rw_lock);
    } 
    ++sCurtailationCount;
}

+ (void)allowBackgroundProcessing
{
    if(sCurtailationCount == 1) {
        pthread_rwlock_unlock(&rw_lock);
    }
    --sCurtailationCount;
    if(sCurtailationCount < 1) {
        THWarn(@"Background processing allowed more than curtailed!");
    }
}

@end
