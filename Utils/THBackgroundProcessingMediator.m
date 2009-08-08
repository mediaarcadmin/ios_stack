//
//  THBackgroundProcessingMediator.m
//  Eucalyptus
//
//  Created by James Montgomerie on 05/12/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "THBackgroundProcessingMediator.h"
#import "THLog.h"
#import <pthread.h>

static pthread_rwlock_t rw_lock = PTHREAD_RWLOCK_INITIALIZER;


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
    pthread_rwlock_rdlock(&rw_lock);
}

+ (void)allowBackgroundProcessing
{
    pthread_rwlock_unlock(&rw_lock);
}

@end
