//
//  SharedHyphenator.h
//  Eucalyptus
//
//  Created by James Montgomerie on 24/07/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

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

void initialise_shared_hyphenator();

#endif