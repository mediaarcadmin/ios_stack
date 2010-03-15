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

@property (nonatomic, readonly) NSArray *sectionUuids;

@property (nonatomic, readonly) NSUInteger globalPageCount;

- (id)initWithBook:(id<EucBook>)book fontPointSize:(CGFloat)pointSize;

// A full description for display with the page slider.
// i.e. page 3 might be "page 1 of 300", to discount the cover and inner licence page
- (NSString *)pageDescriptionForPageNumber:(NSUInteger)logicalPageNumber;

// A "display number" i.e. cover -> nil, 2 -> @"1" etc;
// Could also do things like convert to roman numerals when appropriate.
- (NSString *)displayPageNumberForPageNumber:(NSUInteger)pageNumber;

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page;
- (NSString *)nameForSectionUuid:(NSString *)sectionUuid;
- (NSUInteger)pageNumberForSectionUuid:(NSString *)sectionUuid;
- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)uuid;

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber;

- (THPair *)viewAndIndexPointForPageNumber:(NSUInteger)pageNumber withPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

- (BOOL)viewShouldBeRigid:(UIView *)view;

+ (EucPageView *)blankPageViewForPointSize:(CGFloat)pointSize withPageTexture:(UIImage *)pageTexture;

@end
