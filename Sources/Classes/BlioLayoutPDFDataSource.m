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
#import "BlioTOCEntry.h"
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/EucChapterNameFormatting.h>
#import "NSArray+BlioAdditions.h"

@interface BlioLayoutPDFDataSource()

@property (nonatomic, retain) NSArray *tableOfContents;

@end

@implementation BlioLayoutPDFDataSource

@synthesize data;
@synthesize tableOfContents; // Lazily loaded - see -(NSArray *)tableOfContents

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
    CGRect cropRect = CGRectZero;
    
    [pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return CGRectZero;
        }
    }
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    if(aPage) {
        cropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    }
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
   	
    // Don't preserve the aspect ratio here - libEucalyptus sometimes /deliberately/
    // asks for slightly different X and Y scle factors in order to have the 
    // scaled rect fit to pixels.
    CGAffineTransform fitTransform = transformRectToFitRect(pageCropRect, pageRect, NO);
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
    if (nil == pdf) {
		[pdfLock unlock];
		return;
	}
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

static NSInteger pageNumberFromPageDictionary(CGPDFDictionaryRef target) {
	// there's nothing in the page dictionary to identify page number
	// so we have to work it out by counting our elder siblings
	// and the descendents of elder siblings of each ancestor
	
	NSInteger pageNumber = 0;
	CGPDFDictionaryRef parent;
	while (CGPDFDictionaryGetDictionary(target, "Parent", &parent))
	{
		CGPDFArrayRef kids;
		if (CGPDFDictionaryGetArray(parent, "Kids", &kids))
		{
			size_t numKids = CGPDFArrayGetCount(kids);
			size_t kidNum;
			for (kidNum = 0; kidNum < numKids; ++kidNum)
			{
				CGPDFDictionaryRef kid;
				if (CGPDFArrayGetDictionary(kids, kidNum, &kid))
				{
					if (kid == target)
						break;
					CGPDFInteger count;
					if (CGPDFDictionaryGetInteger(kid, "Count", &count))
						pageNumber += count;
					else
						pageNumber += 1;
				}
			}
		}
		target = parent;
	}
	return pageNumber + 1;
}

static NSInteger pageNumberFromDestArray(CGPDFArrayRef array) {
	
	CGPDFDictionaryRef page;
	if (CGPDFArrayGetDictionary(array, 0, &page)) {		
		return pageNumberFromPageDictionary(page);
	}
	
	return -1;
}

static NSInteger pageNumberFromAction(CGPDFDictionaryRef action) {
	const char *name;
	CGPDFArrayRef dest;
	
	if (CGPDFDictionaryGetName(action, "S", &name)) {
		if (strcmp(name, "GoTo") == 0) {
			if (CGPDFDictionaryGetArray(action, "D", &dest)) {
				return pageNumberFromDestArray(dest);
			}
		}
	}
	
	return -1;
}

static void
parse_outline_items(int indent, CGPDFDocumentRef document,
					CGPDFDictionaryRef outline, void* context)
{
    bool isOpen;

    CGPDFStringRef string;
    CGPDFDictionaryRef first, action;
	CGPDFArrayRef dest;
    CGPDFInteger count;
    NSString *title = nil;
	
	NSInteger num = -1;
	
    if (document == NULL || outline == NULL)
		return;
	
	NSMutableArray *toc = (NSMutableArray *)context;
	
    do {
		title = NULL;
		if (CGPDFDictionaryGetString(outline, "Title", &string)) {
			title = (NSString *)CGPDFStringCopyTextString(string);
		}
		
		if (CGPDFDictionaryGetDictionary(outline, "A", &action)) {
			num = pageNumberFromAction(action);
		} else if (CGPDFDictionaryGetArray(outline, "Dest", &dest)) {
			num = pageNumberFromDestArray(dest);
		}
		
		isOpen = true;
		if (CGPDFDictionaryGetInteger(outline, "Count", &count)) {
			isOpen = (count < 0) ? false : true;
		}
				
		
		if (title && (num > -1)) {
			BlioTOCEntry *tocEntry = [[BlioTOCEntry alloc] init];
			tocEntry.level = indent;
			tocEntry.name = [NSString stringWithString:(NSString *)title];
			tocEntry.startPage = num - 1;
	
			[toc addObject:tocEntry];
			[tocEntry release];		
		}
		
		if (CGPDFDictionaryGetDictionary(outline, "First", &first))
			parse_outline_items(indent + 1, document, first, context);
		
    } while (CGPDFDictionaryGetDictionary(outline, "Next", &outline));
}

- (NSArray *)parseTOC {
	NSMutableArray *toc = [NSMutableArray array];
	
	[pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
    }
	
    if(pdf) {
        // Section 8.2.2 Document Outline in the 1.6 PDF spec:
        // http://www.adobe.com/content/dam/Adobe/en/devnet/pdf/pdfs/pdf_reference_archives/PDFReference16.pdf
        
        CGPDFDictionaryRef catalog, outline, first;
        catalog = CGPDFDocumentGetCatalog(pdf);
        if (CGPDFDictionaryGetDictionary(catalog, "Outlines", &outline)) {
            if (CGPDFDictionaryGetDictionary(outline, "First", &first)) {
                parse_outline_items(0, pdf, first, toc);
            }
        }
    }
    [pdfLock unlock];
	
    // If there are no TOC entries for page index 0, add an artificial one.
    BOOL makeArtificialFrontEnrty = YES;
    for(BlioTOCEntry *entry in toc) {
        if(entry.startPage == 0) {
            makeArtificialFrontEnrty = NO;
        }
    }
    if(makeArtificialFrontEnrty) {
        BlioTOCEntry *tocEntry = [[BlioTOCEntry alloc] init];
        tocEntry.name = NSLocalizedString(@"Front of book", @"Name for the single table-of-contents entry for the front page of a book that does not specify a TOC entry for the front page");
        [toc addObject:tocEntry];
        [tocEntry release];
    }
    
	return toc;
}

- (NSArray *)tableOfContents {
    if(!tableOfContents) {
		self.tableOfContents = [self parseTOC];
    }
    return tableOfContents;
}

#pragma mark -
#pragma mark EucBookContentsTableViewControllerDataSource

- (NSUInteger)levelForSectionUuid:(NSString *)sectionUuid {
	NSUInteger sectionIndex = [sectionUuid integerValue];
    return [[self.tableOfContents objectAtIndex:sectionIndex] level];
}

- (NSArray *)sectionUuids {
	NSUInteger sectionCount = self.tableOfContents.count;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:sectionCount];
    for(NSUInteger i = 0; i < sectionCount; ++i) {
        [array addObject:[[NSNumber numberWithUnsignedInteger:i] stringValue]];
    }
    return [array autorelease];
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page {
	NSUInteger pageIndex = page - 1;
    NSUInteger sectionIndex = 0;
    NSUInteger nextSectionIndex = 0;
    for(BlioTOCEntry *section in self.tableOfContents) {
        if(section.startPage <= pageIndex) {
            sectionIndex = nextSectionIndex;
            ++nextSectionIndex;
        } else {
            break;
        }
    }
    return [[NSNumber numberWithUnsignedInteger:sectionIndex] stringValue];
}

- (NSString *)displayPageNumberForPageNumber:(NSUInteger)aPageNumber {
	return [NSString stringWithFormat:@"%ld", (long)aPageNumber];
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid {
	NSUInteger sectionIndex = [sectionUuid integerValue];
    NSString *sectionName = [[self.tableOfContents objectAtIndex:sectionIndex] name];
    if (sectionName) {
        return [sectionName splitAndFormattedChapterName];
    } else {
        NSString *sectionString;
        NSUInteger startPage = [[self.tableOfContents objectAtIndex:sectionIndex] startPage];
        if (startPage < 1) {
            sectionString = NSLocalizedString(@"Front of Book", @"TOC section string for missing section name without page");
        } else {
            sectionString = [NSString stringWithFormat:NSLocalizedString(@"Page %@", @"TOC section string for missing section name with page number"), [self displayPageNumberForPageNumber:startPage]];
        }
        return [sectionString splitAndFormattedChapterName];
    }
}

- (NSUInteger)pageNumberForSectionUuid:(NSString *)sectionUuid {
	NSUInteger sectionIndex = [sectionUuid integerValue];
    return [[self.tableOfContents objectAtIndex:sectionIndex] startPage] + 1;
}

@end
