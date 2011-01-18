//
//  SharedHyphenator.m
//  libEucalyptus
//
//  Created by James Montgomerie on 24/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucSharedHyphenator.h"
#import "THPair.h"

#import "Hyphenator.h"
#import "HyphenationRule.h"

#include <vector>
#include <memory>

using namespace std;
using namespace Hyphenate;

class SharedHyphenator : public Hyphenate::Hyphenator
{
private:
    SharedHyphenator(const char *filename) : Hyphenate::Hyphenator(filename) {};
    friend void initialise_shared_hyphenator_once();
    
public:
    static SharedHyphenator* sharedHyphenator();
};

static pthread_once_t sHyphenatorOnceControl = PTHREAD_ONCE_INIT;
static SharedHyphenator *sHyphenator;

void initialise_shared_hyphenator_once() 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    sHyphenator = new SharedHyphenator([[[NSBundle mainBundle] pathForResource:@"en" ofType:@"" inDirectory:@"HyphenationPatterns"] fileSystemRepresentation]);    
    [pool drain];
}

void initialise_shared_hyphenator() 
{
    pthread_once(&sHyphenatorOnceControl, initialise_shared_hyphenator_once);
}

SharedHyphenator* SharedHyphenator::sharedHyphenator()
{
    pthread_once(&sHyphenatorOnceControl, initialise_shared_hyphenator_once);
    return sHyphenator;   
}


@implementation EucSharedHyphenator

static pthread_once_t sSharedHyphenatorOnceControl = PTHREAD_ONCE_INIT;
static EucSharedHyphenator *sSharedHyphenator;

- (id)init
{
    if((self = [super init])) {
        _hyphenator = SharedHyphenator::sharedHyphenator();
        _cache = [[THCache alloc] init];
        _cache.conserveItemsInUse = NO;
    }
    return self;
}

static void EucSharedHyphenatorSetup() 
{
    sSharedHyphenator = [[EucSharedHyphenator alloc] init];
}

+ (EucSharedHyphenator *)sharedHyphenator
{
    pthread_once(&sSharedHyphenatorOnceControl, EucSharedHyphenatorSetup);
    return sSharedHyphenator;
}

- (NSArray *)hyphenationsForWord:(NSString *)word
{
    NSArray *ret = [_cache objectForKey:word];
    if(!ret) {
        THPair *items[word.length];
        auto_ptr< vector< const HyphenationRule *> > hyphenationPoints = _hyphenator->applyHyphenationRules((CFStringRef)word);
        
        NSUInteger ruleCount = 0;
        NSUInteger strPos = 0;
        vector<const HyphenationRule*>::const_iterator it = hyphenationPoints->begin();
        vector<const HyphenationRule*>::const_iterator endAt = hyphenationPoints->end();
        for(;
            it != endAt;
            ++it, ++strPos) {
            const HyphenationRule *rule = *it;
            if(rule != NULL) {
                NSString *beforeBreak = (NSString *)rule->create_applied_string_first((CFStringRef)[word substringToIndex:strPos], CFSTR("-"));
                
                std::pair<CFStringRef, int> applied = rule->create_applied_string_second(NULL);
                NSUInteger skip = applied.second;
                NSString *afterBreak;
                if(applied.first) {
                    NSString *afterBreakStart = (NSString *)applied.first;
                    afterBreak = [afterBreakStart stringByAppendingString:[word substringFromIndex:strPos + skip]];
                    [afterBreakStart release];
                } else {
                    afterBreak = [word substringFromIndex:strPos + skip];
                }
                
                items[ruleCount++] = [THPair pairWithFirst:beforeBreak second:afterBreak];
                
                [beforeBreak release];                
            }
        }
        ret = [NSArray arrayWithObjects:items count:ruleCount];
        [_cache cacheObject:ret forKey:word];
    }
    return ret;
}

@end