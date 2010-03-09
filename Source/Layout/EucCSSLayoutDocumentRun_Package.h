/*
 *  EucCSSLayoutDocumentRun_Package.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 25/02/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

// 'Package scope' accessors for EucCSSLayoutDocumentRun.

@interface EucCSSLayoutDocumentRun ()

@property (nonatomic, readonly) size_t componentsCount;
@property (nonatomic, readonly) id *components;
@property (nonatomic, readonly) EucCSSLayoutDocumentRunComponentInfo *componentInfos;
@property (nonatomic, readonly) uint32_t *wordToComponent;

@end