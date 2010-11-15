/*
 *  EucPageLayoutController.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 29/07/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "EucBookContentsTableViewController.h"

@class EucGutenbergBook, EucBookPageIndex, EucBookPageIndexPoint, EucPageView, THPair;
@protocol EucBook, EucBookReader;

@protocol EucPageLayoutController <EucBookContentsTableViewControllerDataSource>

@property (nonatomic, readonly) id<EucBook> book;

@property (nonatomic, assign) CGSize pageSize;

@property (nonatomic, readonly) NSArray *availablePointSizes;
@property (nonatomic, assign) CGFloat fontPointSize;

@property (nonatomic, readonly) NSUInteger globalPageCount;

- (id)initWithBook:(id<EucBook>)book 
          pageSize:(CGSize)pageSize
     fontPointSize:(CGFloat)pointSize;

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber;

- (THPair *)viewAndIndexPointRangeForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (EucBookPageIndexPoint *)indexPointForPageNumber:(NSUInteger)pageNumber;

- (BOOL)viewEdgeIsRigid:(UIView *)view;
- (CGFloat)tapTurnMarginForView:(UIView *)view;

+ (EucPageView *)blankPageViewWithFrame:(CGRect)frame
                           forPointSize:(CGFloat)pointSize;

// A full description.
// i.e. page 3 might be "1 of 300", to discount the cover and inner licence page.
// page 1 might be "Cover" etc.
// Used by the page slider.
- (NSString *)pageDescriptionForPageNumber:(NSUInteger)logicalPageNumber;

@end
