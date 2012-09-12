//
//  BlioLayoutPDFDataSource.m
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioLayoutPDFDataSource.h"
#import "BlioLayoutGeometry.h"
#import "BlioTOCEntry.h"
#import <libEucalyptus/THUIDeviceAdditions.h>
#import <libEucalyptus/EucChapterNameFormatting.h>
#import <libEucalyptus/THPair.h>
#import "NSArray+BlioAdditions.h"
#import "BlioLayoutHyperlink.h"
#import "BlioPDFFont.h"
#import "BlioPDFPageParser.h"
#import "KNFBTextFlowPositionedWord.h"
#import "KNFBTextFlowBlock.h"

@interface BlioLayoutPDFDataSource()

@property (nonatomic, retain) NSArray *tableOfContents;
@property (nonatomic, retain) NSDictionary *namesDictionary;
@property (nonatomic, retain) NSCache *pageToFontMappings;
@property (nonatomic, retain) NSCache *documentFonts;

- (id)mappedFont:(NSValue *)fontPointer forPageRef:(CGPDFPageRef)pageRef;
- (NSDictionary *)mappedFontsForPageRef:(CGPDFPageRef)pageRef;
- (NSArray *)calculateBlocksForPageAtIndex:(NSInteger)pageIndex;

@end

static void mapPageFont(const char *key, CGPDFObjectRef object, void *info);

@implementation BlioLayoutPDFDataSource

@synthesize data;
@synthesize tableOfContents;
@synthesize namesDictionary;
@synthesize pageToFontMappings;
@synthesize documentFonts;

- (void)dealloc {
    [pageToFontMappings release], pageToFontMappings = nil;
    [documentFonts release], documentFonts = nil;
    
    [pdfLock lock];
    if (pdf) CGPDFDocumentRelease(pdf);
    self.data = nil;
    [pdfLock unlock];
    [pdfLock release];
	
	[tableOfContents release], tableOfContents = nil;
	[namesDictionary release], namesDictionary = nil;
	
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
    if (self.data && !pdf) {
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

- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 atSize:(CGSize)size 
                              getBacking:(id *)context {
	
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

//- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect {
//    //NSLog(@"drawPage %d inContext %@ inRect: %@ withTransform %@ andBounds %@", page, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)), NSStringFromCGRect(rect), NSStringFromCGAffineTransform(transform), NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
//    
//    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);    
//    CGContextFillRect(ctx, rect);
//    CGContextClipToRect(ctx, rect);
//    
//    CGContextConcatCTM(ctx, transform);
//    [pdfLock lock];
//    if (nil == pdf) {
//		[pdfLock unlock];
//		return;
//	}
//    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
//    CGPDFPageRetain(aPage);
//    CGContextDrawPDFPage(ctx, aPage);
//    CGPDFPageRelease(aPage);
//    [pdfLock unlock];
//}

- (void)openDocumentIfRequired {
    [pdfLock lock];
    [self openDocumentWithoutLock];
    [pdfLock unlock];
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
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

static NSInteger pageNumberFromDestinationString(NSString *dest, void *context) {	
	
	NSDictionary *names = (NSDictionary *)context;
	
	id match = nil;
	
	if (dest) {
		match = [names objectForKey:dest];
	}
	
	if (match) {
		return [match integerValue];
	} else {
		return -1;
	}
}

static NSInteger pageNumberFromAction(CGPDFDictionaryRef action, void *context) {
	const char *name;
	CGPDFArrayRef dest;
	
	CGPDFStringRef string;
	NSString *destString = nil;
		
	if (CGPDFDictionaryGetName(action, "S", &name)) {
		if (strcmp(name, "GoTo") == 0) {
			if (CGPDFDictionaryGetArray(action, "D", &dest)) {
				return pageNumberFromDestArray(dest);
			} else if (CGPDFDictionaryGetString(action, "D", &string)) {
				destString = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
				return pageNumberFromDestinationString(destString, context);
			}
		} else if (strcmp(name, "URI") == 0) {
			// Do nothing as we don't yet support URI actions
			//if (CGPDFDictionaryGetString(action, "URI", &string)) {
//				destString = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
//				NSLog(@"Skipping Link annotation with URI %@", destString);
//			}
		}
	}
	
	return -1;
}

static void parse_names_array(CGPDFArrayRef names, void* context) {
	NSMutableDictionary *namesDict = (NSMutableDictionary *)context;
	
	size_t numNames = CGPDFArrayGetCount(names);
	size_t nameNum;

	NSInteger pageNum = -1;
	NSString *nameString = nil;
	
	for (nameNum = 0; nameNum < numNames; ++nameNum) {
		CGPDFObjectRef arrayObj;
		if (CGPDFArrayGetObject(names, nameNum, &arrayObj)) {
			//arrayInfoFunction(nameNum, arrayObj, names);
			
			CGPDFObjectType objectType = CGPDFObjectGetType(arrayObj);
			if(objectType == kCGPDFObjectTypeString)
			{
				CGPDFStringRef string;
				CGPDFArrayGetString(names, nameNum, &string);
				nameString = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
			}
			else if (objectType == kCGPDFObjectTypeDictionary)
			{
				CGPDFDictionaryRef dict;
				CGPDFArrayRef dest;
				
				CGPDFArrayGetDictionary(names, nameNum, &dict);
				if (CGPDFDictionaryGetArray(dict, "D", &dest)) {
					pageNum = pageNumberFromDestArray(dest);
				}
				else 
				{
					// Could be a GoTo action according to 8.2.1 of PDF 1.7 spec
					//NSLog(@"Unhandled names array dictionary type");
				}

			}
			else if (objectType == kCGPDFObjectTypeArray)
			{
				CGPDFArrayRef dest;
				if (CGPDFArrayGetArray(names, nameNum, &dest)) {
					pageNum = pageNumberFromDestArray(dest);
				}
				

			}
			else 
			{
				//NSLog(@"Unhandled names array object");
			}
					
			if ((pageNum > -1) && (nameString != nil)) {
				//NSLog(@"Adding page %d destination named %@", pageNum, nameString);
				[namesDict setObject:[NSNumber numberWithInt:pageNum] forKey:nameString];
				pageNum = -1;
				nameString = nil;
			}
		}
	}

	
}

static void
parse_names_node(CGPDFDictionaryRef node, void* context)
{
	
    if (node == NULL) {
		return;
	}
	
	//CGPDFDictionaryApplyFunction(node, dictionaryInfoFunction, node);
	
	CGPDFArrayRef kids, names;
	CGPDFDictionaryRef dests;
	
		if (CGPDFDictionaryGetArray(node, "Kids", &kids)) {
			size_t numKids = CGPDFArrayGetCount(kids);
			size_t kidNum;
			for (kidNum = 0; kidNum < numKids; ++kidNum) {
				CGPDFDictionaryRef kid;
				if (CGPDFArrayGetDictionary(kids, kidNum, &kid))
				{
					parse_names_node(kid, context);
				}
			}
		} else if (CGPDFDictionaryGetArray(node, "Names", &names)) {
			parse_names_array(names, context);
		} else if (CGPDFDictionaryGetDictionary(node, "Dests", &dests)) {
			parse_names_node(dests, context);
		}

}

static void
parse_outline_items(int indent, CGPDFDocumentRef document,
					CGPDFDictionaryRef outline, void* context, void* names)
{
    CGPDFStringRef string;
	CGPDFArrayRef destArray;
	const char *destName;
	NSString *destString = nil;
    CGPDFDictionaryRef first, action;
    NSString *title = nil;
	
	NSInteger num = -1;
	
    if (document == NULL || outline == NULL)
		return;
	
	
	NSMutableArray *toc = (NSMutableArray *)context;
	NSDictionary *namesDict = (NSDictionary *)names;
	
    do {
		title = NULL;
		if (CGPDFDictionaryGetString(outline, "Title", &string)) {
			title = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
		}
				
		if (CGPDFDictionaryGetDictionary(outline, "A", &action)) {
			num = pageNumberFromAction(action, namesDict);
		}  else if (CGPDFDictionaryGetName(outline, "Dest", &destName)) {
			destString = [[[NSString alloc] initWithCString:destName encoding:NSUTF8StringEncoding] autorelease];
			num = pageNumberFromDestinationString(destString, namesDict);
		}  else if (CGPDFDictionaryGetString(outline, "Dest", &string)) {
			destString = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
			num = pageNumberFromDestinationString(destString, namesDict);
		} else if (CGPDFDictionaryGetArray(outline, "Dest", &destArray)) {
			num = pageNumberFromDestArray(destArray);
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
			parse_outline_items(indent + 1, document, first, context, names);
		
    } while (CGPDFDictionaryGetDictionary(outline, "Next", &outline));
}

- (NSDictionary *)parseNames {
	
	NSMutableDictionary *namesDict = [NSMutableDictionary dictionary];
	
	[pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
    }
	
    if(pdf) {
		
        CGPDFDictionaryRef catalog, names;
        catalog = CGPDFDocumentGetCatalog(pdf);
		
		if (CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
			parse_names_node(names, namesDict);
		}
		
	}
	[pdfLock unlock];
	
	
	return namesDict;
	
}

- (NSArray *)parseTOC {
	
	// Construct the names dictionary before applying the lock
	if (!namesDictionary) {
		self.namesDictionary = [self parseNames];
	}
	
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
                parse_outline_items(0, pdf, first, toc, self.namesDictionary);
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
        [toc insertObject:tocEntry atIndex:0];
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

- (KNFBTOCEntry *)tocEntryForSectionUuid:(NSString *)sectionUuid
{
	NSUInteger sectionIndex = [sectionUuid integerValue];
    return [self.tableOfContents objectAtIndex:sectionIndex];
}

- (NSDictionary *)namesDictionary {
	if (!namesDictionary) {
		self.namesDictionary = [self parseNames];
	}
	
	return namesDictionary;
}

- (NSArray *)hyperlinksForPage:(NSInteger)pageNumber {
    NSMutableArray *hyperlinks = [NSMutableArray array];
	
	// Construct the names dictionary before applying the lock
	if (!namesDictionary) {
		self.namesDictionary = [self parseNames];
	}
	
	[pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return hyperlinks;
        }
    }
	
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, pageNumber);
    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
	
	CGPDFInteger pageRotate = 0;
	CGPDFDictionaryGetInteger( pageDictionary, "Rotate", &pageRotate ); 
	CGRect pageRect = CGRectIntegral( CGPDFPageGetBoxRect( page, kCGPDFMediaBox ));
	if( pageRotate == 90 || pageRotate == 270 ) {
		CGFloat temp = pageRect.size.width;
		pageRect.size.width = pageRect.size.height;
		pageRect.size.height = temp;
	}
	
	CGAffineTransform trans = CGAffineTransformIdentity;
	trans = CGAffineTransformTranslate(trans, 0, pageRect.size.height);
	trans = CGAffineTransformScale(trans, 1.0, -1.0);
	
    CGPDFArrayRef outputArray;
	//CGPDFDictionaryApplyFunction(pageDictionary, dictionaryInfoFunction, pageDictionary);
    if(!CGPDFDictionaryGetArray(pageDictionary, "Annots", &outputArray)) {
		[pdfLock unlock];
        return hyperlinks;
    }
	
    int arrayCount = CGPDFArrayGetCount( outputArray );
    if(!arrayCount) {
		[pdfLock unlock];
        return hyperlinks;
    }
	
    for( int j = 0; j < arrayCount; ++j ) {
		
        CGPDFObjectRef aDictObj;
        if(!CGPDFArrayGetObject(outputArray, j, &aDictObj)) {
            [pdfLock unlock];
			return hyperlinks;
        }
		
        CGPDFDictionaryRef annotDict;
        if(!CGPDFObjectGetValue(aDictObj, kCGPDFObjectTypeDictionary, &annotDict)) {
            [pdfLock unlock];
			return hyperlinks;
        }
		
		int num = -1;
		int arrayCount = 0;
		const char *name;
		
		if (!(CGPDFDictionaryGetName(annotDict, "Subtype", &name) && (strcmp(name, "Link") == 0))) {
			continue;
		}
		
		CGPDFArrayRef rectArray;
        if(CGPDFDictionaryGetArray(annotDict, "Rect", &rectArray)) {
            arrayCount = CGPDFArrayGetCount( rectArray );
        }
		
		CGPDFDictionaryRef action;
		CGPDFArrayRef destArray;
		const char *destName;
		CGPDFStringRef string;
		NSString *destString = nil;
		
		if (CGPDFDictionaryGetDictionary(annotDict, "A", &action)) {
			num = pageNumberFromAction(action, self.namesDictionary);
		}  else if (CGPDFDictionaryGetName(annotDict, "Dest", &destName)) {
			destString = [[[NSString alloc] initWithCString:destName encoding:NSUTF8StringEncoding] autorelease];
			num = pageNumberFromDestinationString(destString, self.namesDictionary);
		}  else if (CGPDFDictionaryGetString(annotDict, "Dest", &string)) {
			destString = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
			num = pageNumberFromDestinationString(destString, self.namesDictionary);
		} else if (CGPDFDictionaryGetArray(annotDict, "Dest", &destArray)) {
			num = pageNumberFromDestArray(destArray);
		}
		
		if ((arrayCount == 4) && (num > -1)) {
			CGPDFReal coords[4];
			for( int k = 0; k < arrayCount; ++k ) {
				
				coords[k] = 0;
				
				CGPDFObjectRef rectObj;
				CGPDFReal coord;
				
				if (CGPDFArrayGetObject(rectArray, k, &rectObj)) {
					if (CGPDFObjectGetValue(rectObj, kCGPDFObjectTypeReal, &coord)) {
						coords[k] = coord;
					}
				}
			}      
			
			CGRect hyperlinkRect = CGRectMake(coords[0],coords[1],coords[2],coords[3]);
			
			if (!CGRectEqualToRect(hyperlinkRect, CGRectNull)) {
				hyperlinkRect.size.width -= hyperlinkRect.origin.x;
				hyperlinkRect.size.height -= hyperlinkRect.origin.y;
				hyperlinkRect = CGRectApplyAffineTransform(hyperlinkRect, trans);
				
				BlioLayoutHyperlink *blioHyperlink = [[BlioLayoutHyperlink alloc] initWithLink:[NSString stringWithFormat:@"%d", num] rect:hyperlinkRect];
				[hyperlinks addObject:blioHyperlink];
				[blioHyperlink release];
			}
		}
		
	}
	
	[pdfLock unlock];
		
    return hyperlinks;
}

#pragma mark -
#pragma mark EucBookContentsTableViewControllerDataSource

- (NSArray *)contentsTableViewControllerSectionIdentifiers:(EucBookContentsTableViewController *)contentsTableViewController {
	NSUInteger sectionCount = self.tableOfContents.count;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:sectionCount];
    for(NSUInteger i = 0; i < sectionCount; ++i) {
        [array addObject:[NSNumber numberWithUnsignedInteger:i]];
    }
    return [array autorelease];
}

- (NSString *)sectionUuidForPageIndex:(NSUInteger)pageIndex {
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

- (NSString *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
            displayPageNumberForPageIndex:(NSUInteger)pageNumber {
	return [NSString stringWithFormat:@"%ld", (long)pageNumber + 1];
}

- (THPair *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
presentationNameAndSubTitleForSectionIdentifier:(id)sectionIdentifier {
	NSInteger sectionIndex = [sectionIdentifier integerValue];
    NSString *sectionName = [[self.tableOfContents objectAtIndex:sectionIndex] name];
    if (sectionName) {
        return [sectionName splitAndFormattedChapterName];
    } else {
        NSString *sectionString;
        NSUInteger startPage = [[self.tableOfContents objectAtIndex:sectionIndex] startPage];
        if (startPage < 1) {
            sectionString = NSLocalizedString(@"Front of Book", @"PDF TOC section string for missing section name without page");
        } else {
            sectionString = [NSString stringWithFormat:NSLocalizedString(@"Page %@", @"PDF TOC section string for missing section name with page number"), [self contentsTableViewController:contentsTableViewController displayPageNumberForPageIndex:startPage - 1]];
        }
        return [THPair pairWithFirst:sectionString second:nil];
    }
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
                  pageIndexForSectionIdentifier:(id)sectionIdentifier {
	NSInteger sectionIndex = [sectionIdentifier integerValue];
    return [[self.tableOfContents objectAtIndex:sectionIndex] startPage];
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
                      levelForSectionIdentifier:(id)sectionIdentifier {
	NSInteger sectionIndex = [sectionIdentifier integerValue];
    return [[self.tableOfContents objectAtIndex:sectionIndex] level];
}

#pragma mark - Positioned Strings

- (NSAttributedString *)attributedStringForPageIndex:(NSUInteger)aPageIndex
{
    NSAttributedString *aString = nil;
    
    [self openDocumentIfRequired];
    
    if (nil == pdf) {
        return aString;
    }
    
    [pdfLock lock];
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, aPageIndex + 1);
    BlioPDFPageParser *parser = [[BlioPDFPageParser alloc] initWithPageRef:aPage resourceDataSource:self];
    [parser parse];
    aString = [parser attributedString];
    [parser release];
    [pdfLock unlock];    

    return aString;
}

- (NSArray *)calculateBlocksForPageAtIndex:(NSInteger)pageIndex 
{    
    CGRect cropRect = [self cropRectForPage:pageIndex + 1];
    CGRect mediaRect = [self mediaRectForPage:pageIndex + 1];
    
    CGAffineTransform flip = CGAffineTransformMakeScale(1, -1);
    flip = CGAffineTransformTranslate(flip, 0, -mediaRect.size.height);
                                                
    __block NSMutableArray *pageBlocks = nil;    
    NSAttributedString *attString = [self attributedStringForPageIndex:pageIndex];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    
    if (attString) {
        pageBlocks = [NSMutableArray array];
        [[attString string] enumerateSubstringsInRange:NSMakeRange(0, [attString length]) 
                                               options:NSStringEnumerationByParagraphs 
                                            usingBlock:^(NSString *paragraph, NSRange paraRange, NSRange paraEnclosingRange, BOOL *stop) {
                                                
                                                __block NSMutableArray *wordsArray = [NSMutableArray array];
                                                __block BOOL firstWord = YES;
                                                __block CGRect blockRect;

                                                NSIndexPath *blockID = [NSIndexPath indexPathForRow:[pageBlocks count] inSection:pageIndex];

                                                [paragraph enumerateSubstringsInRange:NSMakeRange(0, [paragraph length]) 
                                                                              options:NSStringEnumerationByWords
                                                                           usingBlock:^(NSString *word, NSRange wordRange, NSRange wordEnclosingRange, BOOL *stop) {
                                                                               
                                                                               NSString *wordWithPunctuationAndWhitespace = [paragraph substringWithRange:wordEnclosingRange];
                                                                               NSString *wordWithPunctuation = [wordWithPunctuationAndWhitespace stringByTrimmingCharactersInSet:whitespaceSet];
                                                                               
                                                                               NSRange wordWithPunctuationRange = [wordWithPunctuationAndWhitespace rangeOfString:wordWithPunctuation];
                                                                               
                                                                               __block BOOL firstCharacter = YES;
                                                                               __block CGRect wordRect;
                                                                               
                                                                               [attString enumerateAttribute:kBlioPDFPositionAttribute 
                                                                                                     inRange:NSMakeRange(paraRange.location + wordEnclosingRange.location + wordWithPunctuationRange.location, wordWithPunctuationRange.length) 
                                                                                                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired 
                                                                                                  usingBlock:^(id position, NSRange attrRange, BOOL *stop) {
                                                                                                      if (position) {
                                                                                                          if (firstCharacter) {
                                                                                                              firstCharacter = NO;
                                                                                                              wordRect = [position CGRectValue];
                                                                                                          } else {
                                                                                                              wordRect = CGRectUnion(wordRect, [position CGRectValue]);
                                                                                                          }
                                                                                                      }
                                                                                                  }];
                                                                               
                                                                               if (CGRectContainsRect(cropRect, wordRect)) {
                                                                                   wordRect = CGRectApplyAffineTransform(wordRect, flip);
                                                                                   
                                                                                   if (firstWord) {
                                                                                       firstWord = NO;
                                                                                       blockRect = wordRect;
                                                                                   } else {
                                                                                       blockRect = CGRectUnion(blockRect, wordRect);
                                                                                   }
                                                                                   
                                                                                   KNFBTextFlowPositionedWord *newWord = [[KNFBTextFlowPositionedWord alloc] init];
                                                                                   [newWord setString:wordWithPunctuation];
                                                                                   [newWord setRect:wordRect];
                                                                                   [newWord setBlockID:blockID];
                                                                                   [newWord setWordIndex:[wordsArray count]];
                                                                                   [wordsArray addObject:newWord];
                                                                                   [newWord release];
                                                                               }
                                                                           }];
                                                
                                                KNFBTextFlowBlock *newBlock = [[KNFBTextFlowBlock alloc] init];
                                                newBlock.pageIndex = pageIndex;
                                                newBlock.blockIndex = [pageBlocks count];
                                                newBlock.blockID = blockID;
                                                newBlock.words = wordsArray;
                                                newBlock.folio = NO;
                                                [pageBlocks addObject:newBlock];
                                                [newBlock release];
                                            }];
        
    }

    return pageBlocks;
}

// This is a direct port of the equivalent method in KNFBTextFlow

- (NSArray *)blocksForPageAtIndex:(NSInteger)pageIndex includingFolioBlocks:(BOOL)includingFolioBlocks {
    NSArray *ret = nil;
    
    [pageBlocksCacheLock lock];
    {
        NSUInteger cacheIndex = NSUIntegerMax;
        for(NSUInteger i = 0; i < kPDFPageBlocksCacheCapacity; ++i) {
            if(pageIndexCache[i] == pageIndex) {
                cacheIndex = i;
                break;
            }
        }
        
        if(cacheIndex != NSUIntegerMax) {
            ret = [pageBlocksCache[cacheIndex] autorelease];
            if(ret) {
                size_t toMove = kPDFPageBlocksCacheCapacity - cacheIndex - 1;
                if(toMove) {
                    memmove(pageIndexCache + cacheIndex, pageIndexCache + cacheIndex + 1, toMove * sizeof(NSInteger));
                    memmove(pageBlocksCache + cacheIndex, pageBlocksCache + cacheIndex + 1, toMove * sizeof(NSArray *));
                } 
            }
        } 
        
        if(!ret) {
            //if(pageBlocksCache[0]) {
            //    NSLog(@"Discarding cached blocks for layout page %ld", (long)pageIndexCache[0]);
            //}
            [pageBlocksCache[0] release];
            memmove(pageIndexCache, pageIndexCache + 1, sizeof(NSInteger) * (kPDFPageBlocksCacheCapacity - 1));
            memmove(pageBlocksCache, pageBlocksCache + 1, sizeof(NSArray *) * (kPDFPageBlocksCacheCapacity - 1));
            
            ret = [self calculateBlocksForPageAtIndex:pageIndex];
            //NSLog(@"Generating blocks for layout page %ld", (long)pageIndex);
        } //else {
        //NSLog(@"Using cached blocks for layout page %ld", (long)pageIndex);
        //}
        
        pageBlocksCache[kPDFPageBlocksCacheCapacity - 1] = [ret retain];
        pageIndexCache[kPDFPageBlocksCacheCapacity - 1] = pageIndex;
        
    }
    [pageBlocksCacheLock unlock];
    
    if(!includingFolioBlocks) {
        return [ret filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isFolio == NO"]];
    } else {
        return ret;
    }
}

#pragma mark - BlioPDFResourceDataSource

- (id)fontWithName:(NSString *)name onPageRef:(CGPDFPageRef)pageRef
{
    id font = nil;
    
    NSDictionary *pageFonts = [self mappedFontsForPageRef:pageRef];
    NSValue *fontPointer = [pageFonts valueForKey:name];
    
    if (fontPointer) {
        font = [self mappedFont:fontPointer forPageRef:pageRef];
    }
    
    return font;
}

- (NSCache *)pageToFontMappings
{
    if (!pageToFontMappings) {
        pageToFontMappings = [[NSCache alloc] init];
    }
    
    return pageToFontMappings;
}

- (NSCache *)documentFonts
{
    if (!documentFonts) {
        documentFonts = [[NSCache alloc] init];
    }
    
    return documentFonts;
}

static void mapPageFont(const char *key, CGPDFObjectRef object, void *info) 
{
    NSMutableDictionary *pageFonts = info;
    CGPDFDictionaryRef dict;
    
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)) {
        return;
    }
    
    NSString *fontId = [NSString stringWithCString:key encoding:NSASCIIStringEncoding];
    NSValue *uniqueFont = [NSValue valueWithPointer:dict];
    [pageFonts setObject:uniqueFont forKey:fontId];
}

static void parseFont(const char *key, CGPDFObjectRef object, void *info) {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    const char *name;
    CGPDFDictionaryRef dict;
    NSString *baseFont, *fontType;
    
    NSMutableDictionary *fonts = info;
    
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)) {
        return;
    }
    
    NSValue *uniqueFont = [NSValue valueWithPointer:dict];
    
    if ([fonts objectForKey:uniqueFont]) {
        return;
    }
    
    if (CGPDFDictionaryGetName(dict, "BaseFont", &name)) {
        baseFont = [NSString stringWithString:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    } else {
        return;
    }
    
    if (CGPDFDictionaryGetName(dict, "Subtype", &name)) {
        fontType = [NSString stringWithCString: name encoding:NSASCIIStringEncoding];
    } else {
        return;
    }
    
    BlioPDFFont *font = [[BlioPDFFont alloc] initWithKey:[NSString stringWithUTF8String:key]];
    [font setBaseFont:baseFont];
    [font setType:fontType];
	
    CGPDFDictionaryRef descriptorDict;
    
    NSUInteger firstWidthChar = 0;
    CGPDFInteger firstChar;
    if (CGPDFDictionaryGetInteger(dict, "FirstChar", &firstChar)) {
        firstWidthChar = (NSUInteger)firstChar;
    }
    
    NSInteger defaultWidth = 0;
    CGPDFArrayRef widths;
    if (CGPDFDictionaryGetArray(dict, "Widths", &widths)) {
        NSInteger widthsTotal = 0;
        int arraySize = CGPDFArrayGetCount(widths);        
        NSMutableDictionary *widthsDict = [font widths];
        
        for(int n = 0; n < arraySize; n++) {
            if (n >= arraySize) continue;
            CGPDFInteger width;
            if (CGPDFArrayGetInteger(widths, n, &width)) {
                [widthsDict setObject:[NSNumber numberWithInteger:(NSInteger)width] forKey:[NSNumber numberWithInteger:(firstWidthChar + n)]];
                widthsTotal += width;
            }
        }
        defaultWidth = (NSInteger)(round(widthsTotal/(float)arraySize));
    }
    
    
    if (CGPDFDictionaryGetDictionary(dict, "FontDescriptor", &descriptorDict)) {        
        CGPDFReal missingWidth;
        CGPDFReal averageWidth;
        CGPDFReal maxWidth;
        CGPDFArrayRef fontBBox;
            
        if (CGPDFDictionaryGetNumber(descriptorDict, "MissingWidth", &missingWidth)) {
            defaultWidth = (NSInteger)missingWidth;
        } else if (CGPDFDictionaryGetNumber(descriptorDict, "AverageWidth", &averageWidth)) {
            defaultWidth = (NSInteger)averageWidth;
        } 
        
        // Use the maxWidths if we have nothing better
        if (defaultWidth == 0) {
            if (CGPDFDictionaryGetNumber(descriptorDict, "MaxWidth", &maxWidth)) {
                defaultWidth = (NSInteger)maxWidth;
            } else if (CGPDFDictionaryGetArray(descriptorDict, "FontBBox", &fontBBox)) {
                CGPDFReal x1, x2;
                if (CGPDFArrayGetNumber(fontBBox, 0, &x1) && CGPDFArrayGetNumber(fontBBox, 2, &x2)) {
                    CGFloat boxWidth = fabs(x2 - x1);
                    defaultWidth = (NSInteger)boxWidth;
                }
            }
        }
    }
    [font setMissingWidth:defaultWidth];
    
    CGPDFStreamRef unicodeStream;
    if (CGPDFDictionaryGetStream(dict, "ToUnicode", &unicodeStream)) {
        [font setHasUnicodeMapping:YES];
    }
    
    [fonts setObject:font forKey:uniqueFont];
    [font release];
    [pool drain];
}

- (id)mappedFont:(NSValue *)fontPointer forPageRef:(CGPDFPageRef)pageRef 
{    
    id font = [self.documentFonts objectForKey:fontPointer];
    
    if (!font) {        
        CGPDFDictionaryRef dict, resources, pageFonts;
        
        dict = CGPDFPageGetDictionary(pageRef);
        if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
            return nil;
        if (!CGPDFDictionaryGetDictionary(resources, "Font", &pageFonts))
            return nil;
        CGPDFDictionaryApplyFunction(pageFonts, &parseFont, self.documentFonts);
                
        font = [self.documentFonts objectForKey:fontPointer];
    }
    
    return font;
}

- (NSDictionary *)mappedFontsForPageRef:(CGPDFPageRef)pageRef
{
    size_t pageNumber = CGPDFPageGetPageNumber(pageRef);
    
    NSDictionary *pageFonts = [self.pageToFontMappings objectForKey:[NSNumber numberWithInt:pageNumber]];
    
    if (!pageFonts) {
        
        NSMutableDictionary *newPageFonts = [NSMutableDictionary dictionary];
        
        CGPDFDictionaryRef dict = CGPDFPageGetDictionary(pageRef);        
        CGPDFDictionaryRef resourcesDict, pageFontsDict;
        
        if (CGPDFDictionaryGetDictionary(dict, "Resources", &resourcesDict)) {
            if (CGPDFDictionaryGetDictionary(resourcesDict, "Font", &pageFontsDict))
                CGPDFDictionaryApplyFunction(pageFontsDict, &mapPageFont, newPageFonts);
        }
        
        [self.pageToFontMappings setObject:newPageFonts forKey:[NSNumber numberWithInt:pageNumber]];
        
        pageFonts = newPageFonts;
    }
    
    return pageFonts;
}

@end
