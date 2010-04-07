//
//  SharedHyphenator.h
//  libEucalyptus
//
//  Created by James Montgomerie on 24/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THCache.h"

#import <sys/types.h>

#ifdef __cplusplus

#import "Hyphenator.h"
#import "HyphenationRule.h"

class SharedHyphenator : public Hyphenate::Hyphenator
{
private:
    SharedHyphenator(const char *filename) : Hyphenate::Hyphenator(filename) {};
    friend void initialise_shared_hyphenator_once();

public:
    static SharedHyphenator* sharedHyphenator();
};

extern "C" void initialise_shared_hyphenator();

#else

typedef void * SharedHyphenator;

void initialise_shared_hyphenator();

#endif

@interface EucSharedHyphenator : NSObject {
    SharedHyphenator *_hyphenator;
    THCache *_cache;
}

+ (EucSharedHyphenator *)sharedHyphenator;
- (NSArray *)hyphenationsForWord:(NSString *)word;

@end