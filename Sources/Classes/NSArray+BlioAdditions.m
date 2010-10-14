//
//  NSArray+BlioAdditions.m
//  BlioApp
//
//  Created by James Montgomerie on 21/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "NSArray+BlioAdditions.h"

@implementation NSArray (BlioAdditions)

- (NSArray *)blioStableSortedArrayUsingFunction:(int (*)(id *arg1, id *arg2))function
{   
    NSUInteger count = self.count;
    id *objects = malloc(count * sizeof(id));
    [self getObjects:objects range:NSMakeRange(0, count)];
    
    mergesort(objects, count, sizeof(id), (int (*)(const void *arg1, const void *arg2))function);
    
    return [NSArray arrayWithObjects:objects count:count];
}   

- (id)longestComponentizedMatch:(NSString *)match componentsSeperatedByString:(NSString *)separator forKeyPath:(NSString *)keyPath {
    id matchedObject = nil;
    NSUInteger matchLength = 0;
    
    NSArray *matchComponents = [match componentsSeparatedByString:separator];
    
    for (int i = 1; i <= [matchComponents count]; i++) {
        NSRange componentsRange = NSMakeRange([matchComponents count] - i, i);
        NSArray *subComponents = [matchComponents subarrayWithRange:componentsRange];
        NSString *partMatch = [subComponents componentsJoinedByString:separator];
        NSUInteger partMatchLength = [partMatch length];
        
        for (id candidate in [self objectEnumerator]) {
            if ([[candidate valueForKeyPath:keyPath] hasSuffix:partMatch]) {
                if (partMatchLength > matchLength) {
                    matchedObject = candidate;
                    matchLength = partMatchLength;
                }
            }
        }
    }
    
    return matchedObject;
}

@end