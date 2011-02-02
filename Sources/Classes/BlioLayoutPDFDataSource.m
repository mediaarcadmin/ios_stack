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
#import "BlioLayoutHyperlink.h"

@interface BlioLayoutPDFDataSource()

@property (nonatomic, retain) NSArray *tableOfContents;
@property (nonatomic, retain) NSDictionary *namesDictionary;

@end

@implementation BlioLayoutPDFDataSource

@synthesize data;
@synthesize tableOfContents; // Lazily loaded - see -(NSArray *)tableOfContents
@synthesize namesDictionary; // Lazily loaded - see -(NSDictionary *)namesDictionary

- (void)dealloc {
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

/*
void dictionaryInfoFunction ( const char *key,CGPDFObjectRef object, void *info ) { 
	NSLog(@"Processing Dictionary Info");
	
	NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
	CGPDFDictionaryRef contentDict = (CGPDFDictionaryRef)info;
	
	CGPDFObjectType objectType = CGPDFObjectGetType(object);
	if(objectType == kCGPDFObjectTypeDictionary)
	{
		CGPDFDictionaryRef value  = NULL;
		CGPDFDictionaryGetDictionary(contentDict, key, &value);
		NSLog(@"Value for key %@ is dictionary of size %d",keyStr,CGPDFDictionaryGetCount(value));
		CGPDFDictionaryApplyFunction(value, dictionaryInfoFunction, value);
	}
	else if(objectType == kCGPDFObjectTypeArray)
	{
		CGPDFArrayRef value  = NULL;
		CGPDFDictionaryGetArray(contentDict, key, &value);
		NSLog(@"Value for key %@ is array of size %d",keyStr,CGPDFArrayGetCount(value));
	}
	else if(objectType == kCGPDFObjectTypeStream)
	{
		CGPDFStreamRef value  = NULL;
		CGPDFDictionaryGetStream(contentDict, key, &value);
		NSLog(@"Processing for key %@ is stream",keyStr);
		CGPDFDataFormat dataFormat;
		CFDataRef streamData = CGPDFStreamCopyData(value, &dataFormat);
		CFShow(streamData);
		NSString *contentString = [[NSString alloc]initWithBytes:[(NSData*)streamData bytes] length:[(NSData*)streamData length] encoding:NSUTF8StringEncoding];
		NSLog(@"%@",contentString);
		
	}
	else if(objectType == kCGPDFObjectTypeInteger)
	{
		CGPDFInteger integerValue;
		CGPDFDictionaryGetInteger(contentDict, key, &integerValue);
		NSLog(@"Processing for Key %@ is int value %d",keyStr,integerValue);
		
	}
	else if(objectType == kCGPDFObjectTypeName)
	{
		const char *name;
		CGPDFDictionaryGetName(contentDict, key, &name);
		NSLog(@"Processing for key %@ name value %@",keyStr,[NSString stringWithCString:name encoding:NSUTF8StringEncoding]);
	}
	else if(objectType == kCGPDFObjectTypeString)
	{
		CGPDFStringRef string;
		NSString *title = nil;
		
		CGPDFDictionaryGetString(contentDict, key, &string);
		title = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
		NSLog(@"Processing for key %@ string value %@",keyStr,title);
	}
}

void arrayInfoFunction ( size_t index,CGPDFObjectRef object, void *info ) { 
	NSLog(@"Processing Array Info");
	
	NSString *keyStr = [NSString stringWithFormat:@"%d", index];
	CGPDFArrayRef contentArray = (CGPDFArrayRef)info;
	
	CGPDFObjectType objectType = CGPDFObjectGetType(object);
	if(objectType == kCGPDFObjectTypeDictionary)
	{
		CGPDFDictionaryRef value  = NULL;
		CGPDFArrayGetDictionary(contentArray, index, &value);
		NSLog(@"Value for array entry %@ is dictionary of size %d",keyStr,CGPDFDictionaryGetCount(value));
		CGPDFDictionaryApplyFunction(value, dictionaryInfoFunction, value);
	}
	else if(objectType == kCGPDFObjectTypeArray)
	{
		CGPDFArrayRef value  = NULL;
		CGPDFArrayGetArray(contentArray, index, &value);
		NSLog(@"Value for array entry %@ is array of size %d",keyStr,CGPDFArrayGetCount(value));
	}
	else if(objectType == kCGPDFObjectTypeStream)
	{
		CGPDFStreamRef value  = NULL;
		CGPDFArrayGetStream(contentArray, index, &value);
		NSLog(@"Processing for array entry %@ is stream ",keyStr);
		CGPDFDataFormat dataFormat;
		CFDataRef streamData = CGPDFStreamCopyData(value, &dataFormat);
		CFShow(streamData);
		NSString *contentString = [[NSString alloc]initWithBytes:[(NSData*)streamData bytes] length:[(NSData*)streamData length] encoding:NSUTF8StringEncoding];
		NSLog(@"%@",contentString);
		
	}
	else if(objectType == kCGPDFObjectTypeInteger)
	{
		CGPDFInteger integerValue;
		CGPDFArrayGetInteger(contentArray, index, &integerValue);
		NSLog(@"Processing for array entry %@ is int value %d",keyStr,integerValue);
		
	}
	else if(objectType == kCGPDFObjectTypeName)
	{
		const char *name;
		CGPDFArrayGetName(contentArray, index, &name);
		NSLog(@"Processing for array entry %@ is name value %@",keyStr,[NSString stringWithCString:name encoding:NSUTF8StringEncoding]);
	}
	else if(objectType == kCGPDFObjectTypeString)
	{
		CGPDFStringRef string;
		NSString *title = nil;
		
		CGPDFArrayGetString(contentArray, index, &string);
		title = [(NSString *)CGPDFStringCopyTextString(string) autorelease];
		NSLog(@"Processing for array entry %@ is string value %@",keyStr,title);
	}
}
*/

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

- (NSArray *)enhancedContentForPage:(NSInteger)page {
	return nil;
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
