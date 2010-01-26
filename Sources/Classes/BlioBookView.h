/*
 *  BlioBookView.h
 *  BlioApp
 *
 *  Created by James Montgomerie on 05/01/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

@protocol EucBookContentsTableViewControllerDataSource;

@class BlioBookmarkPoint;
@class BlioMockBook;

@protocol BlioBookView <NSObject>

@required

@property (nonatomic, readonly) NSInteger pageCount;

// Page numbers start at 1.
// The EucBookContentsTableViewControllerDataSource protocol defines a way to 
// map from page numbers to 'display' page number strings.
@property (nonatomic, readonly) NSInteger pageNumber;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated;
- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@property (nonatomic, readonly) BlioBookmarkPoint *pageBookmarkPoint;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@property (nonatomic, readonly) CGRect firstPageRect;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;

// Page texture-related properties are readony because
// - (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
// should be used to set them atomically.
@property (nonatomic, retain, readonly) UIImage *pageTexture;
@property (nonatomic, assign, readonly) BOOL pageTextureIsDark;
- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

@end