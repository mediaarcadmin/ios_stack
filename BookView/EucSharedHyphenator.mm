//
//  SharedHyphenator.m
//  libEucalyptus
//
//  Created by James Montgomerie on 24/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucSharedHyphenator.h"

using namespace std;
using namespace Hyphenate;

static pthread_once_t once_control = PTHREAD_ONCE_INIT;
static SharedHyphenator *sHyphenator;

void initialise_shared_hyphenator_once() 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    sHyphenator = new SharedHyphenator([[[NSBundle mainBundle] pathForResource:@"en" ofType:@"" inDirectory:@"HyphenationPatterns"] fileSystemRepresentation]);    
    [pool drain];
}

void initialise_shared_hyphenator() 
{
    pthread_once(&once_control, initialise_shared_hyphenator_once);
}

SharedHyphenator* SharedHyphenator::sharedHyphenator()
{
    pthread_once(&once_control, initialise_shared_hyphenator_once);
    return sHyphenator;   
}
