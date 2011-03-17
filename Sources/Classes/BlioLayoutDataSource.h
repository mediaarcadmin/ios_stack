/*
 *  BlioLayoutDataSource.h
 *  BlioApp
 *
 *  Created by matt on 09/07/2010.
 *  Copyright 2010 BitWink. All rights reserved.
 *
 */

@class THPair;

@protocol BlioLayoutDataSource

#if OVERLAY_CODE_AVAILABLE
@optional

- (NSString *)enhancedContentRootPath;
- (NSData *)enhancedContentDataAtPath:(NSString *)path;
- (NSURL *)temporaryURLForEnhancedContentVideoAtPath:(NSString *)path;
#endif

@required

- (NSInteger)pageCount;

- (CGRect)cropRectForPage:(NSInteger)page;
- (CGRect)mediaRectForPage:(NSInteger)page;

- (void)openDocumentIfRequired;
- (void)closeDocumentIfRequired;
- (void)closeDocument;

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect;
- (UIImage *)thumbnailForPage:(NSInteger)page;
- (NSArray *)hyperlinksForPage:(NSInteger)page;
#if OVERLAY_CODE_AVAILABLE
- (NSArray *)enhancedContentForPage:(NSInteger)page;
#endif

- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 atSize:(CGSize)size
                              getBacking:(id *)context;

@end