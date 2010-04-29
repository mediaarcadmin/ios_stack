/*
 *  EucBook.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 29/07/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

@class EucBookIndex, EucBookPageIndexPoint;

@protocol EucBook <NSObject>

// Pairs of string, uuid
@property (nonatomic, readonly) NSArray *navPoints;

@property (nonatomic, copy) EucBookPageIndexPoint *currentPageIndexPoint;

- (NSString *)etextNumber;
- (NSString *)title;
- (NSString *)author;
- (NSString *)path;
- (NSString *)cacheDirectoryPath;

- (Class)pageLayoutControllerClass;
- (EucBookIndex *)bookIndex;

- (float)estimatedPercentageForIndexPoint:(EucBookPageIndexPoint *)point;

@optional

- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (void)persistCacheableData;

@end