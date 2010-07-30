//
//  BlioTimeOrderedCache.m
//  BlioApp
//
//  Created by matt on 30/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTimeOrderedCache.h"

@interface BlioTimeOrderedCache()

@property (nonatomic, retain) NSMutableDictionary *objectStore;
@property (nonatomic, retain) NSMutableDictionary *accessStore;
@property (nonatomic, retain) NSMutableDictionary *costStore;

- (void)removeOldestObject;

@end


@implementation BlioTimeOrderedCache

@synthesize totalCostLimit, countLimit;
@synthesize objectStore, accessStore, costStore;

- (id)init {
    if ((self = [super init])) {
        self.objectStore = [NSMutableDictionary dictionary];
        self.accessStore = [NSMutableDictionary dictionary];
        self.costStore = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAllObjects];
    self.objectStore = nil;
    self.accessStore = nil;
    self.costStore = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self removeAllObjects];
}

- (id)objectForKey:(id)key {
    id cacheObject = [self.objectStore objectForKey:key];
    
    if (cacheObject) {
        [self.accessStore setValue:[NSDate date] forKey:key];
    }
    
    return cacheObject;
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [self.objectStore setObject:obj forKey:key];
    [self.accessStore setValue:[NSDate date] forKey:key];
    [self.costStore setValue:[NSNumber numberWithInteger:g] forKey:key];
    
    totalCost += g;
    
    if (countLimit) {
        while ([self.accessStore count] > countLimit) {
            [self removeOldestObject];
        }
    }
    
    if (totalCostLimit) {
        while ((totalCost > totalCostLimit) && ([self.accessStore count] >= 1)) {
            [self removeOldestObject];
        }
    }
}

- (void)removeObjectForKey:(id)key {
    [self.objectStore removeObjectForKey:key];
    [self.accessStore removeObjectForKey:key];
    
    NSNumber *cost = [self.costStore valueForKey:key];
    if (cost) {
        totalCost -= [cost integerValue];
        [self.costStore removeObjectForKey:key];
    }
}

- (void)removeAllObjects {
    [self.objectStore removeAllObjects];
    [self.accessStore removeAllObjects];
    [self.costStore removeAllObjects];
    totalCost = 0;
}

- (void)removeOldestObject {
    NSArray *sortedKeys = [self.accessStore keysSortedByValueUsingSelector:@selector(compare:)];
    if ([sortedKeys count]) {
        [self removeObjectForKey:[sortedKeys objectAtIndex:0]];
    }
}

@end
