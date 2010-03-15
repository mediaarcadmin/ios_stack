/*
 *  EucBook.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 29/07/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

@class EucBookPageIndexPoint, EucBookSection;

@protocol EucBook <NSObject>

// Pairs of string, uuid
@property (nonatomic, readonly) NSArray *navPoints;

@property (nonatomic, copy) EucBookPageIndexPoint *currentPageIndexPoint;

- (NSString *)etextNumber;
- (NSString *)title;
- (NSString *)author;
- (NSString *)path;

- (Class)pageLayoutControllerClass;
- (NSArray *)bookPageIndexes;

@end