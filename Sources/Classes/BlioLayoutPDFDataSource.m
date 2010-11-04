//
//  BlioLayoutPDFDataSource.m
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioLayoutPDFDataSource.h"
#import "BlioLayoutGeometry.h"
#import <libEucalyptus/THUIDeviceAdditions.h>
#import <libEucalyptus/THPair.h>

@implementation BlioLayoutPDFDataSource

@synthesize data;

- (void)dealloc {
    [pdfLock lock];
    if (pdf) CGPDFDocumentRelease(pdf);
    self.data = nil;
    [pdfLock unlock];
    [pdfLock release];
    [super dealloc];
}

- (id)initWithPath:(NSString *)aPath {
    if ((self = [super init])) {
        NSData *aData = [[NSData alloc] initWithContentsOfMappedFile:aPath];
        CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)aData);
        CGPDFDocumentRef aPdf = CGPDFDocumentCreateWithProvider(pdfProvider);
        pageCount = CGPDFDocumentGetNumberOfPages(aPdf);
        CGPDFDocumentRelease(aPdf);
        CGDataProviderRelease(pdfProvider);
        self.data = aData;
        [aData release];
        
        pdfLock = [[NSLock alloc] init];
    }
    return self;
}

- (NSInteger)pageCount {
    return pageCount;
}

- (void)openDocumentWithoutLock {
    if (self.data) {
        CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)self.data);
        pdf = CGPDFDocumentCreateWithProvider(pdfProvider);
        CGDataProviderRelease(pdfProvider);
    }
}

- (CGRect)cropRectForPage:(NSInteger)page {
    [pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return CGRectZero;
        }
    }
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGRect cropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    [pdfLock unlock];
    
    return cropRect;
}

- (CGRect)mediaRectForPage:(NSInteger)page {    
    [pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return CGRectZero;
        }
    }
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGRect mediaRect = CGPDFPageGetBoxRect(aPage, kCGPDFMediaBox);
    [pdfLock unlock];
    
    return mediaRect;
}

- (CGFloat)dpiRatio {
    return 72/96.0f;
}


- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 minSize:(CGSize)size 
                              getContext:(id *)context {
	
//	NSLog(@"Requested rect %@ of size %@", NSStringFromCGRect(rect), NSStringFromCGSize(size));
	
	[self openDocumentIfRequired];
    
    if (nil == pdf) return nil;
    
    size_t width  = size.width;
    size_t height = size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
    
    size_t bytesPerRow = 4 * width;
    size_t totalBytes = bytesPerRow * height;
    
    NSMutableData *bitmapData = [[NSMutableData alloc] initWithCapacity:totalBytes];
    [bitmapData setLength:totalBytes];
    
    CGContextRef bitmapContext = CGBitmapContextCreate([bitmapData mutableBytes], width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);        
    CGColorSpaceRelease(colorSpace);
	
    // Store the default state because libEucalyptus expexts the context to
    // be in the default state - it may write into it.  We'll restore it
    // before returning the context.
	CGContextSaveGState(bitmapContext);
    
	CGRect pageCropRect = [self cropRectForPage:page];
	
    CGFloat pageZoomScaleWidth  = size.width / CGRectGetWidth(rect);
    CGFloat pageZoomScaleHeight = size.height / CGRectGetHeight(rect);
	
	CGRect pageRect = CGRectMake(0, 0, pageCropRect.size.width * pageZoomScaleWidth, pageCropRect.size.height * pageZoomScaleHeight);
   	
    CGAffineTransform fitTransform = transformRectToFitRect(pageCropRect, pageRect, YES);
    CGContextConcatCTM(bitmapContext, fitTransform);
	CGContextTranslateCTM(bitmapContext, -(rect.origin.x - pageCropRect.origin.x) , (rect.origin.y - pageCropRect.origin.y) - (CGRectGetHeight(pageCropRect) - CGRectGetHeight(rect)));
	
	CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
	CGContextFillRect(bitmapContext, pageCropRect);
	CGContextClipToRect(bitmapContext, pageCropRect);
    
    [pdfLock lock];
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGContextDrawPDFPage(bitmapContext, aPage);
    [pdfLock unlock];
    
	CGContextRestoreGState(bitmapContext);
    
	[self closeDocumentIfRequired];

    *context = [bitmapData autorelease];
    
    return (CGContextRef)[(id)bitmapContext autorelease];
}

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect {
    //NSLog(@"drawPage %d inContext %@ inRect: %@ withTransform %@ andBounds %@", page, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)), NSStringFromCGRect(rect), NSStringFromCGAffineTransform(transform), NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);    
    CGContextFillRect(ctx, rect);
    CGContextClipToRect(ctx, rect);
    
    CGContextConcatCTM(ctx, transform);
    [pdfLock lock];
    if (nil == pdf) return;
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGPDFPageRetain(aPage);
    CGContextDrawPDFPage(ctx, aPage);
    CGPDFPageRelease(aPage);
    [pdfLock unlock];
}

- (void)openDocumentIfRequired {
    [pdfLock lock];
    [self openDocumentWithoutLock];
    [pdfLock unlock];
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
    return nil;
}

- (NSArray *)hyperlinksForPage:(NSInteger)page {
    return nil;
}

- (void)closeDocument {
    [pdfLock lock];
    if (pdf) CGPDFDocumentRelease(pdf);
    pdf = NULL;
    [pdfLock unlock];
}

- (void)closeDocumentIfRequired {
	// Apple fixed PDF bitmap graphics footprint on 4.0+
	if (!([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame)) {
		[self closeDocument];
	}
}

@end
