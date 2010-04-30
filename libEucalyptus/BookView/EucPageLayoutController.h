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

@property (nonatomic, readonly) NSArray *availablePointSizes;
@property (nonatomic, assign) CGFloat fontPointSize;

@property (nonatomic, readonly) NSUInteger globalPageCount;

- (id)initWithBook:(id<EucBook>)book fontPointSize:(CGFloat)pointSize;

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber;

- (THPair *)viewAndIndexPointForPageNumber:(NSUInteger)pageNumber withPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

- (BOOL)viewShouldBeRigid:(UIView *)view;

+ (EucPageView *)blankPageViewForPointSize:(CGFloat)pointSize withPageTexture:(UIImage *)pageTexture;

// A full description.
// i.e. page 3 might be "1 of 300", to discount the cover and inner licence page.
// page 1 might be "Cover" etc.
// Used by the page slider.
- (NSString *)pageDescriptionForPageNumber:(NSUInteger)logicalPageNumber;

@end
