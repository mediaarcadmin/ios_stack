/*
 *  EucPageLayoutController.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 29/07/2009.
 *  Copyright 2009 James Montgomerie. All rights reserved.
 *
 */
#import <UIKit/UIKit.h>

@class EucGutenbergBook, EucBookTextView, EucBookPageIndex, EucBookPageIndexPoint, THPair;
@protocol EucBook, EucBookReader;

@protocol EucPageLayoutController <NSObject>

@property (nonatomic, readonly) id<EucBook> book;
@property (nonatomic, assign) CGFloat fontPointSize;
@property (nonatomic, readonly) NSArray *availablePointSizes;
@property (nonatomic, readonly) NSUInteger globalPageCount;

- (id)initWithBook:(id<EucBook>)book fontPointSize:(CGFloat)pointSize;

// A full description for display with the page slider.
// i.e. page 3 might be "page 1 of 300", to discount the cover and inner licence page
- (NSString *)pageDescriptionForPageNumber:(NSUInteger)logicalPageNumber;

// A "display number" i.e. cover -> nil, 2 -> @"1" etc;
// Could also do things like convert to roman numerals when appropriate.
- (NSString *)displayPageNumberForPageNumber:(NSUInteger)pageNumber;

- (NSString *)sectionNameForPageNumber:(NSUInteger)logicalPageNumber;
- (NSString *)sectionUuidForPageNumber:(NSUInteger)page;
- (NSUInteger)pageNumberForUuid:(NSString *)sectionUuid;

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber;
- (NSArray *)sections;

- (THPair *)viewAndIndexPointForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

+ (EucBookPageIndexPoint *)layoutPageFromBookReader:(id <EucBookReader>)reader
                                 startingAtPoint:(EucBookPageIndexPoint *)indexPoint
                                        intoView:(EucBookTextView *)view;

- (BOOL)viewShouldBeRigid:(UIView *)view;

@end
