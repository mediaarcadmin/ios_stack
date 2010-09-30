/*
 *  BlioLayoutDataSource.h
 *  BlioApp
 *
 *  Created by matt on 09/07/2010.
 *  Copyright 2010 BitWink. All rights reserved.
 *
 */

@protocol BlioLayoutDataSource
@required

- (NSInteger)pageCount;

- (CGRect)cropRectForPage:(NSInteger)page;
- (CGRect)mediaRectForPage:(NSInteger)page;
- (CGFloat)dpiRatio;

- (void)openDocumentIfRequired;
- (void)closeDocumentIfRequired;
- (void)closeDocument;

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect;
- (UIImage *)thumbnailForPage:(NSInteger)page;

@optional
- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 minSize:(CGSize)size
                              getContext:(id *)context;

@end
