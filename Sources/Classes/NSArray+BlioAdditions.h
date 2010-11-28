//
//  NSArray+BlioAdditions.h
//  BlioApp
//
//  Created by James Montgomerie on 21/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (BlioAdditions)

- (NSArray *)blioStableSortedArrayUsingFunction:(int (*)(id *arg1, id *arg2))function;
- (id)longestComponentizedMatch:(NSString *)match componentsSeperatedByString:(NSString *)separator forKeyPath:(NSString *)keyPath;

@end
