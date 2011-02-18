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

@property (nonatomic, readonly) BOOL paginationIsComplete;

// Array of EucBookNavPoint
@property (nonatomic, readonly) NSArray *navPoints;

@property (nonatomic, copy) EucBookPageIndexPoint *currentPageIndexPoint;

- (NSString *)cacheDirectoryPath;

- (NSString *)etextNumber;
- (NSString *)title;
- (NSString *)author;

- (Class)pageLayoutControllerClass;
- (EucBookIndex *)bookIndex;

- (float)estimatedPercentageForIndexPoint:(EucBookPageIndexPoint *)point;

@optional

- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier;
- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (void)persistCacheableData;

@end