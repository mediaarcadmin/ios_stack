/*
 *  EucCSSLayoutRun_Package.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 25/02/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

// 'Package scope' accessors for EucCSSLayoutRun.

@interface EucCSSLayoutRun ()

@property (nonatomic, assign, readonly) size_t componentsCount;
@property (nonatomic, assign, readonly) EucCSSLayoutRunComponentInfo *componentInfos;
@property (nonatomic, assign, readonly) uint32_t *wordToComponent;

@property (nonatomic, retain, readonly) NSArray *sizeDependentComponentIndexes;
@property (nonatomic, retain, readonly) NSArray *floatComponentIndexes;

- (uint32_t)pointToComponentOffset:(EucCSSLayoutRunPoint)point;

@end