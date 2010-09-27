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

@end
