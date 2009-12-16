//
//  LowMemoryDictionaryEmptier.m
//  libEucalyptus
//
//  Created by James Montgomerie on 03/04/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THLowMemoryDictionaryEmptier.h"
#import "THLog.h"

@implementation THLowMemoryDictionaryEmptier

- (id)initWithDictionary:(CFMutableDictionaryRef)dictionary mutex:(pthread_mutex_t *)mutex
{
    
    if((self = [super init])) {
        CFRetain(dictionary);
        _dictionary = dictionary;
        _pMutex = mutex;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(_didReceiveMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:[UIApplication sharedApplication]];         
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];    
    if(_pMutex) {
        pthread_mutex_lock(_pMutex);
    }
    CFRelease(_dictionary);
    if(_pMutex) {
        pthread_mutex_unlock(_pMutex);
    }
    [super dealloc];
}

- (void)_didReceiveMemoryWarning
{
    THLog(@"Emptying Dictionary!");
    if(_pMutex) {
        pthread_mutex_lock(_pMutex);
    }
    CFDictionaryRemoveAllValues(_dictionary);
    if(_pMutex) {
        pthread_mutex_unlock(_pMutex);
    }
}

@end
