/*
 *  BlioBookView.h
 *  BlioApp
 *
 *  Created by James Montgomerie on 05/01/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

@protocol BlioBookView <NSObject>

@required
- (void)jumpToUuid:(NSString *)uuid;
- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;

// Page texture-related properties are readony because
// - (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
// should be used to set them atomically.
@property (nonatomic, retain, readonly) UIImage *pageTexture;
@property (nonatomic, assign, readonly) BOOL pageTextureIsDark;
- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

@end