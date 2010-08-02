//
//  BlioTimeOrderedCache.h
//  BlioApp
//
//  Created by matt on 30/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlioTimeOrderedCache : NSObject {
    NSMutableDictionary *objectStore;
    NSMutableDictionary *accessStore;
    NSMutableDictionary *costStore;
    NSUInteger totalCostLimit;
    NSUInteger countLimit;
    NSUInteger totalCost;
}

@property (nonatomic, assign) NSUInteger totalCostLimit;
@property (nonatomic, assign) NSUInteger countLimit;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end