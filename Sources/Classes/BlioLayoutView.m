//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"
#import "BlioBookmarkPoint.h"

/*
static void logDictContents(const char *key, CGPDFObjectRef object, void *info) {
    NSString *dict = info;
    if (dict == nil) dict = @"Dictionary";
    
    switch (CGPDFObjectGetType(object)) {
        case kCGPDFObjectTypeNull:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeNull");
            break;
        case kCGPDFObjectTypeBoolean:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeBoolean");
            break;
        case kCGPDFObjectTypeInteger:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeInteger");
            break;
        case kCGPDFObjectTypeReal:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeReal");
            break;
        case kCGPDFObjectTypeName:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeName");
            break;
        case kCGPDFObjectTypeString:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeString");
            break;
        case kCGPDFObjectTypeArray:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeArray");
            break;
        case kCGPDFObjectTypeDictionary:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeDictionary");
            break;
        case kCGPDFObjectTypeStream:
            printf("%s: %s [%s]\n", [dict UTF8String], key, "kCGPDFObjectTypeStream");
            break;
        default:
            break;
    }
}
*/

static const CGFloat kBlioPDFTextMinLineSpacing = 1.0f;
static const CGFloat kBlioPDFTextMinWordSpaceGlyphRatio = 0.9f; // 0.9 pretty good
static const CGFloat kBlioPDFTextMinWordNonSpaceGlyphRatio = 0.25f; // 0.9 pretty good
static const CGFloat kBlioPDFBlockMinimumWidth = 50;
static const CGFloat kBlioPDFBlockInsetX = 6;
static const CGFloat kBlioPDFBlockInsetY = 10;
static const CGFloat kBlioPDFShadowShrinkScale = 2;
static const CGFloat kBlioPDFGoToZoomScale = 0.7f;

typedef enum {
    kBlioPDFEncodingStandard = 0,
    kBlioPDFEncodingMacRoman = 1,
    kBlioPDFEncodingWin = 2
} BlioPDFEncoding;

@interface BlioPDFPositionedString : NSObject {
    NSString *string;
    CGRect boundingRect;
    CGRect displacementRect;
    NSUInteger lineNumber;
    CGFloat spaceWidth;
    CGFloat lastGlyphWidth;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect boundingRect;
@property (nonatomic) CGRect displacementRect;
@property (nonatomic) NSUInteger lineNumber;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) CGFloat minX;
@property (nonatomic, readonly) CGFloat maxY;
@property (nonatomic, readonly) CGFloat maxX;
@property (nonatomic) CGFloat spaceWidth;
@property (nonatomic) CGFloat lastGlyphWidth;

- (id)initWithString:(NSString *)aString;

@end

@interface BlioPDFFont : NSObject {
    NSString *key;
    NSString *baseFont;
    NSString *type;
    BlioPDFEncoding fontEncoding;
    NSMutableDictionary *glyphs;
    NSMutableDictionary *widths;
    NSMutableDictionary *toUnicode;
    NSMutableDictionary *charEncoding;
    unichar notdef;
    NSInteger missingWidth;
    CGFloat spaceWidth;
}

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *baseFont;
@property (nonatomic, retain) NSString *type;
@property (nonatomic) BlioPDFEncoding fontEncoding;
@property (nonatomic, retain) NSMutableDictionary *glyphs;
@property (nonatomic, retain) NSMutableDictionary *widths;
@property (nonatomic, retain) NSMutableDictionary *toUnicode;
@property (nonatomic, retain) NSMutableDictionary *charEncoding;
@property (nonatomic) unichar notdef;
@property (nonatomic) NSInteger missingWidth;
@property (nonatomic, readonly) CGFloat spaceWidth;

- (id)initWithKey:(NSString *)key;
- (NSInteger)glyphWidthForCharacter:(unichar)character;
- (NSInteger)decodedCharacterForCharacter:(unichar)character;
- (void)createEncoding;
- (NSString *)stringForCharacterCode:(unichar)character withDecode:(unichar)decodedChar;
+ (NSMutableDictionary *)glyphDictionaryForEncoding:(BlioPDFEncoding)pdfEncoding;

@end

@interface BlioPDFFontList : NSObject {
    NSMutableDictionary *dictionary;
}

@property (nonatomic, retain) NSMutableDictionary *dictionary;

- (void)addFontsFromPage:(CGPDFPageRef)pageRef;

@end

@interface BlioPDFParsedPage : NSObject {
    CGRect cropRect;
    //CGRect textRect;
    NSMutableArray *positionedStrings;
    //NSMutableArray *wordRects;
    //NSMutableString *textContent;
    NSMutableDictionary *fontLookup;
    BlioPDFFontList *fontList;
    CGAffineTransform textMatrix;
    CGAffineTransform textLineMatrix;
    CGAffineTransform textStateMatrix;
    CGFloat Tj;
    CGFloat Tl;
    CGFloat Tc;
    CGFloat Tw;
    CGFloat Th;
    CGFloat Ts;
    CGFloat Tfs;
    CGFloat userUnit;
    BlioPDFFont *currentFont;
    NSArray *textBlocks;
    CGFloat lastGlyphWidth;
}

//@property (nonatomic) CGRect textRect;
@property (nonatomic, retain) NSMutableArray *positionedStrings;
//@property (nonatomic, retain) NSMutableArray *wordRects;
//@property (nonatomic, retain) NSMutableString * textContent;
@property (nonatomic, retain) NSMutableDictionary *fontLookup;
@property (nonatomic, retain) BlioPDFFontList *fontList;
@property (nonatomic) CGAffineTransform textMatrix;
@property (nonatomic) CGAffineTransform textLineMatrix;
@property (nonatomic, readonly) CGAffineTransform textStateMatrix;
@property (nonatomic) CGFloat Tj;
@property (nonatomic) CGFloat Tl;
@property (nonatomic) CGFloat Tc;
@property (nonatomic) CGFloat Tw;
@property (nonatomic) CGFloat Th;
@property (nonatomic) CGFloat Ts;
@property (nonatomic) CGFloat Tfs;
@property (nonatomic) CGFloat userUnit;
@property (nonatomic, retain) BlioPDFFont *currentFont;
@property (nonatomic) CGFloat lastGlyphWidth;

- (id)initWithPage:(CGPDFPageRef)pageRef andFontList:(BlioPDFFontList*)newFontList;
- (void)updateTextStateMatrix;
- (void)addCharWithChar:(unichar)characterCode;
- (NSString *)textContent;
- (CGRect)rectForWordAtPosition:(NSInteger)position;
- (NSArray *)textBlocks;
- (NSString *)textContent;

@end

@interface BlioFastCATiledLayer : CATiledLayer
@end

static const CGFloat kBlioLayoutMaxZoom = 54.0f; // That's just showing off!
static const CGFloat kBlioLayoutShadow = 16.0f;
static const NSUInteger kBlioLayoutMaxViews = 6; // Must be at least 6 for the go to animations to look right

@interface BlioPDFTiledLayerDelegate : NSObject {
    CGPDFPageRef page;
    CGAffineTransform fitTransform;
    CGRect pageRect;
    BOOL cover;
}

@property(nonatomic) CGPDFPageRef page;
@property(nonatomic) CGAffineTransform fitTransform;
@property(nonatomic) BOOL cover;

@end

@interface BlioPDFShadowLayerDelegate : NSObject {
    CGRect pageRect;
    CGPDFPageRef page;
    BOOL preloadPage;
}

@property(nonatomic) CGRect pageRect;
@property(nonatomic) CGPDFPageRef page;
@property(nonatomic) BOOL preloadPage;

@end

@interface BlioPDFSharpLayerDelegate : CALayer {
    CGRect pageRect;
    CGPDFPageRef page;
    CGFloat zoomScale;
}

@property(nonatomic) CGRect pageRect;
@property(nonatomic) CGPDFPageRef page;
@property(nonatomic) CGFloat zoomScale;

@end

@interface BlioPDFHighlightLayerDelegate : CALayer {
    CGAffineTransform fitTransform;
    NSArray *highlights;
    CGPDFPageRef page;
    CGAffineTransform highlightsTransform;
}

@property(nonatomic) CGAffineTransform fitTransform;
@property(nonatomic) CGAffineTransform highlightsTransform;
@property(nonatomic, retain) NSArray* highlights;
@property(nonatomic) CGPDFPageRef page;

@end

@interface BlioPDFDrawingView : UIView {
    CGPDFDocumentRef document;
    CGPDFPageRef page;
    id layoutView;
    BlioFastCATiledLayer *tiledLayer;
    CALayer *shadowLayer;
    CALayer *sharpLayer;
    CALayer *highlightLayer;
    BlioPDFTiledLayerDelegate *tiledLayerDelegate;
    BlioPDFShadowLayerDelegate *shadowLayerDelegate;
    BlioPDFSharpLayerDelegate *sharpLayerDelegate;
    BlioPDFHighlightLayerDelegate *highlightLayerDelegate;
    CGAffineTransform textFlowTransform;
}

@property (nonatomic, assign) id layoutView;
@property (nonatomic, retain) BlioFastCATiledLayer *tiledLayer;
@property (nonatomic, retain) CALayer *shadowLayer;
@property (nonatomic, retain) CALayer *sharpLayer;
@property (nonatomic, retain) CALayer *highlightLayer;
@property (nonatomic, retain) BlioPDFTiledLayerDelegate *tiledLayerDelegate;
@property (nonatomic, retain) BlioPDFShadowLayerDelegate *shadowLayerDelegate;
@property (nonatomic, retain) BlioPDFSharpLayerDelegate *sharpLayerDelegate;
@property (nonatomic, retain) BlioPDFHighlightLayerDelegate *highlightLayerDelegate;
@property (nonatomic, readonly) CGAffineTransform textFlowTransform;

- (id)initWithFrame:(CGRect)frame document:(CGPDFDocumentRef)aDocument page:(NSInteger)aPageNumber;
- (void)setPageNumber:(NSInteger)pageNumber;
- (CGPDFPageRef)page;

@end

@interface BlioPDFDebugView : UIView {
    CGAffineTransform fitTransform;
    CGMutablePathRef interestPath;
    CGRect interestRect, mediaRect, cropRect;
}

@property (nonatomic) CGAffineTransform fitTransform;
@property (nonatomic) CGRect interestRect, mediaRect, cropRect;

- (void)clearAreasOfInterest;

@end


@interface BlioLayoutView(private)

- (BlioPDFPageView *)loadPage:(int)newPageNumber current:(BOOL)current preload:(BOOL)preload;
- (BlioPDFPageView *)loadPage:(int)newPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload;
- (BlioPDFPageView *)loadPage:(int)aPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload preserve:(NSArray *)preservedPages;
- (BlioPDFDebugView *)debugView;
- (void)setDebugView:(BlioPDFDebugView *)newView;
- (void)parsePage:(NSInteger)aPageNumber;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) CGFloat lastZoomScale;

@end

@interface BlioPDFContainerScrollView : UIScrollView {
    NSInteger pageCount;
}

@property (nonatomic) NSInteger pageCount;

@end

@interface BlioPDFPageView : UIView {
    BlioPDFDrawingView *view;
    CGPDFPageRef page;
    BOOL valid;
}

@property (nonatomic, retain) BlioPDFDrawingView *view;
@property (nonatomic) CGPDFPageRef page;
@property (nonatomic, getter=isValid) BOOL valid;

- (id)initWithView:(BlioPDFDrawingView *)view andPageRef:(CGPDFPageRef)newPage;
- (void)setPreload:(BOOL)preload;
- (void)setCover:(BOOL)cover;
- (CGPoint)convertPointToPDFPage:(CGPoint)point;
- (CGRect)convertRectFromPDFPage:(CGRect)rect;
- (void)renderSharpPageAtScale:(CGFloat)scale;
- (void)hideSharpPage;
//- (void)zoomToContents;

@end

@implementation BlioLayoutView


@synthesize book, scrollView, containerView, pageViews, navigationController, currentPageView, tiltScroller, fonts, parsedPage, scrollToPageInProgress, disableScrollUpdating, pageNumber, pageCount, highlighter;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    self.book = nil;
    self.scrollView = nil;
    self.containerView = nil;
    self.pageViews = nil;
    self.navigationController = nil;
    self.debugView = nil;
    self.currentPageView = nil;
    self.fonts = nil;
    [self.highlighter removeObserver:self forKeyPath:@"tracking"];
    [self.highlighter detatchFromView];
    self.highlighter = nil;
    [super dealloc];
}

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
//- (id)initWithPath:(NSString *)path page:(NSUInteger)page animated:(BOOL)animated {
    NSURL *pdfURL = [NSURL fileURLWithPath:[aBook pdfPath]];
    pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    
    if (NULL == pdf) return nil;
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        // Initialization code
        self.book = aBook;
        self.clearsContextBeforeDrawing = NO; // Performance optimisation;
        self.scrollToPageInProgress = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];    
        self.autoresizesSubviews = YES;
        
        pageCount = CGPDFDocumentGetNumberOfPages(pdf);
        
        BlioPDFContainerScrollView *aScrollView = [[BlioPDFContainerScrollView alloc] initWithFrame:self.bounds];
        aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width * pageCount, aScrollView.frame.size.height);
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.minimumZoomScale = 1.0f;
        aScrollView.maximumZoomScale = kBlioLayoutMaxZoom;
        aScrollView.showsHorizontalScrollIndicator = NO;
        aScrollView.showsVerticalScrollIndicator = NO;
        aScrollView.clearsContextBeforeDrawing = NO;
        aScrollView.directionalLockEnabled = YES;
        aScrollView.bounces = YES;
        aScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        aScrollView.autoresizesSubviews = YES;
        //aScrollView.bouncesZoom = YES;
        aScrollView.scrollsToTop = NO;
        aScrollView.delegate = self;
        aScrollView.pageCount = pageCount;
        [self addSubview:aScrollView];
        self.scrollView = aScrollView;
        [aScrollView release];
        
        UIView *aView = [[UIView alloc] initWithFrame:self.bounds];
        [self.scrollView addSubview:aView];
        aView.backgroundColor = [UIColor clearColor];
        aView.autoresizesSubviews = YES;
        
        self.containerView = aView;
        self.containerView.clipsToBounds = NO;
        [aView release];
        
        EucHighlighter *aHighlighter = [[EucHighlighter alloc] init];
        [aHighlighter attachToView:self];
        [aHighlighter addObserver:self
                       forKeyPath:@"tracking"
                          options:0
                          context:NULL];
        aHighlighter.dataSource = self;
        self.highlighter = aHighlighter;
        [aHighlighter release];
        
        NSMutableArray *pageViewArray = [[NSMutableArray alloc] initWithCapacity:kBlioLayoutMaxViews];
        self.pageViews = pageViewArray;
        [pageViewArray release];
        
        NSNumber *savedPage = [aBook layoutPageNumber];
        NSInteger page = (nil != savedPage) ? [savedPage intValue] : 1;
        
        if (page > self.pageCount) page = self.pageCount;
        self.pageNumber = page;
        
        if (animated) {
            [self loadPage:1 current:YES preload:YES];
            [self loadPage:2 current:NO preload:YES];
            if (page == 1) {
                for (int i = 2; i < kBlioLayoutMaxViews; i++) {
                    [self loadPage:i+1 current:NO preload:NO];
                }
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blioCoverPageDidFinishRender:) name:@"blioCoverPageDidFinishRender" object:nil];
            }
        } else {
            [self loadPage:self.pageNumber current:YES preload:YES];
            for (int i = 0; i < kBlioLayoutMaxViews; i++) {
                if (i != 1) [self loadPage:(self.pageNumber - 1 + i) current:NO preload:NO];
            }
            
            [self goToPageNumber:self.pageNumber animated:NO];
        }
        
        //[self performSelectorInBackground:@selector(parseFonts) withObject:nil];
        [self performSelector:@selector(parseFonts)]; 
        /*
        CGPDFDictionaryRef dict = CGPDFDocumentGetInfo(pdf);
        CGPDFDictionaryApplyFunction(dict, &logDictContents, @"documentDict");
        */
//        NSEnumerator *enumerator = [[fonts dictionary] objectEnumerator];
//        BlioPDFFont *font;
//        
//        while ((font = [enumerator nextObject])) {
//            NSLog(@"%@", [font baseFont]);
//            NSLog(@"%@", [font key]);
//        }
         
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomInProgress:) name:@"BlioLayoutZoomInProgress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomEnded:) name:@"BlioLayoutZoomEnded" object:nil];
        
    }
    return self;
}

- (void)parseFonts {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BlioPDFFontList *aFontsList = [[BlioPDFFontList alloc] init];
    self.fonts = aFontsList;
    [aFontsList release];
    
    for (int k = 0; k < CGPDFDocumentGetNumberOfPages(pdf); k++)
        [self.fonts addFontsFromPage:CGPDFDocumentGetPage(pdf, k)];
    
    [pool drain];
}

- (void)setTiltScroller:(MSTiltScroller*)ts {
    tiltScroller = ts;
    [tiltScroller setScrollView:self.scrollView];
}

- (BlioPDFDebugView *)debugView {
    return debugView;
}

- (void)setDebugView:(BlioPDFDebugView *)newView {
    [newView retain];
    [debugView release];
    debugView = newView;
}

- (void)displayDebugRect:(CGRect)rect forPage:(NSInteger)aPageNumber {
    if (nil == self.debugView) {
        BlioPDFDebugView *aView  = [[BlioPDFDebugView alloc] initWithFrame:CGRectZero];
        aView.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:aView];
        self.debugView = aView;
        [aView release];
    }
    CGRect frame = self.scrollView.frame;
    
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdf, aPageNumber);
    //CGRect cropRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    //CGRect mediaRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    frame.origin = CGPointZero;
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(pageRef, kCGPDFCropBox, insetBounds, 0, true);
    
    frame.origin.x = frame.size.width * ([self pageNumber] - 1);
    frame.origin.y = 0;
    [self.debugView setFrame:frame];
    [self.debugView setFitTransform:fitTransform];
    //[self.debugView setCropRect:cropRect];
    //[self.debugView setMediaRect:mediaRect];
    [self.debugView clearAreasOfInterest];
    [self.debugView setInterestRect:rect];
    [self.debugView setNeedsDisplay];
    [self.scrollView bringSubviewToFront:self.debugView];
}

- (void)displayDebug {
    [self displayDebugRect:CGRectZero forPage:pageNumber];
}

#pragma mark -
#pragma mark Highlighter

- (NSArray *)blockIdentifiersForEucHighlighter:(EucHighlighter *)highlighter {
    NSInteger pageIndex = self.pageNumber - 1;
    return [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
}

- (CGRect)eucHighlighter:(EucHighlighter *)highlighter frameOfBlockWithIdentifier:(id)id {
    CGRect blockRect = [(BlioTextFlowParagraph *)id rect];
    //CGAffineTransform [self.currentPageView textFlowTransform];
    return blockRect;
}

- (NSArray *)eucHighlighter:(EucHighlighter *)highlighter identifiersForElementsOfBlockWithIdentifier:(id)id; {
    return [(BlioTextFlowParagraph *)id words];
}

- (NSArray *)eucHighlighter:(EucHighlighter *)highlighter rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId {    
    CGRect wordRect = [(BlioTextFlowPositionedWord *)elementId rect];
    return [NSArray arrayWithObject:[NSValue valueWithCGRect:wordRect]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(object == self.highlighter &&
       [keyPath isEqualToString:@"tracking"]) {
        self.scrollView.scrollEnabled = !((EucHighlighter *)object).isTracking;
    }
}

#pragma mark -
#pragma mark TTS

- (id)getCurrentParagraphId {
    NSArray *pages = [[self.book textFlow] pages];
    NSInteger pageIndex = self.pageNumber - 1;
    if (pageIndex >= [pages count]) return nil;
        
    NSArray *page = [pages objectAtIndex:pageIndex];
    if (![page count])
        return nil;
    else
        return [page objectAtIndex:0];
}

- (NSUInteger)getCurrentWordOffset {
    return 0;
}

- (id)paragraphIdForParagraphAfterParagraphWithId:(id)paragraphID {
    BlioTextFlowParagraph *currentParagraph = (BlioTextFlowParagraph *)paragraphID;
    NSArray *pages = [[self.book textFlow] pages];
    if (![pages count]) return nil;    
    
    if (!currentParagraph) {
        NSArray *page = [pages objectAtIndex:0];
        if (![page count])
            return nil;
        else
            return [page objectAtIndex:0];
    } else {
        NSInteger pageIndex = [currentParagraph pageIndex];
        if (pageIndex < [pages count]) {
            NSArray *page = [pages objectAtIndex:pageIndex];
            NSUInteger currentIndex = [page indexOfObject:currentParagraph];
            if (++currentIndex < [page count]) {
                return [page objectAtIndex:currentIndex];
            } else {
                while (++pageIndex < ([pages count])) {
                    NSArray *page = [pages objectAtIndex:pageIndex];
                    if ([page count])
                        return [page objectAtIndex:0];
                }
            }
        }
    }
    return nil;
}

- (NSArray *)paragraphWordsForParagraphWithId:(id)paragraphId {
    return [(BlioTextFlowParagraph *)paragraphId wordsArray];
}

- (void)highlightWordAtParagraphId:(uint32_t)paragraphId wordOffset:(uint32_t)wordOffset {
    BlioTextFlowParagraph *currentParagraph = (BlioTextFlowParagraph *)paragraphId;
    NSInteger pageIndex = [currentParagraph pageIndex];
    NSInteger targetPageNumber = ++pageIndex;
    if ((self.pageNumber != targetPageNumber) && !self.disableScrollUpdating) {
        [self goToPageNumber:targetPageNumber animated:YES];
    }
}

#pragma mark -
#pragma mark BlioBookView Protocol Methods

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {

}

- (void)gotoCurrentPageAnimated {
    [self goToPageNumber:self.pageNumber animated:YES];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
    
    if (targetPage < 1 )
        targetPage = 1;
    else if (targetPage > pageCount)
        targetPage = pageCount;
    
    [self willChangeValueForKey:@"pageNumber"];
    
    if (animated) {
        // Animation steps:
        // 1. Move the current page and its adjacent pages next to the target page's adjacent pages
        // 2. Load the target page and its adjacent pages
        // 3. Zoom out the current page
        // 4. Scroll to the target page
        // 5. Zoom in the target page
        
        // 1. Move the current page and its adjacent pages next to the target page's adjacent pages
        CGFloat pageWidth = self.scrollView.contentSize.width / pageCount;
        NSInteger startPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 2;
        if (startPage == targetPage) return;
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        self.pageNumber = targetPage;
        NSInteger pagesToGo = targetPage - startPage;
        NSInteger pagesToOffset = 0;
        
        self.disableScrollUpdating = YES;
        [self.scrollView setPagingEnabled:NO]; // Paging affects the animations
        
        CGPoint currentOffset = self.scrollView.contentOffset;
        NSMutableArray *pagesToPreserve = [NSMutableArray array];
        
        if (abs(pagesToGo) > 3) {
            pagesToOffset = pagesToGo - (3 * (pagesToGo/abs(pagesToGo)));
            CGFloat frameOffset = pagesToOffset * self.scrollView.frame.size.width;
            CGRect firstFrame = CGRectMake((startPage - 2) * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
            CGRect lastFrame = CGRectMake((startPage - 2 + 2) * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
            CGRect pagesToOffsetRect = CGRectUnion(firstFrame, lastFrame);
            
            for (BlioPDFPageView *page in self.pageViews) {
                if (!CGRectIsNull(CGRectIntersection(page.frame, pagesToOffsetRect))) {
                    NSInteger preservePageNum = CGPDFPageGetPageNumber([page.view page]);
                    if (NSLocationInRange(preservePageNum, NSMakeRange(startPage - 1, 3))) {
                        CGRect newFrame = page.frame;
                        newFrame.origin.x += frameOffset;
                        page.frame = newFrame;
                        [page setValid:NO];
                        BlioPDFPageView *existingPage = nil;
                        for (BlioPDFPageView *preservedPage in pagesToPreserve) {
                            if ((CGRectEqualToRect(page.frame, preservedPage.frame)) &&
                                (preservePageNum == CGPDFPageGetPageNumber([preservedPage.view page]))) {
                                    existingPage = page;
                                    break;
                                }
                        }
                        if (nil == existingPage) [pagesToPreserve addObject:page];
                    } //else {
//                        NSLog(@"Page in position but wrong page number");
//                    }
                }
            }
            currentOffset = CGPointMake(currentOffset.x + frameOffset*self.scrollView.zoomScale, currentOffset.y);
            [self.scrollView setContentOffset:currentOffset animated:NO];
        }
        
        if ([pagesToPreserve count] > 3) {
            NSLog(@"WARNING: more than 3 pages found to preserve duing go to animation: %@", [pagesToPreserve description]); 
        }
        
        // 2. Load the target page and its adjacent pages
        BlioPDFPageView *preservePage = [self loadPage:targetPage current:YES preload:YES forceReload:NO preserve:pagesToPreserve];
        if (preservePage) [pagesToPreserve addObject:preservePage];
        preservePage = [self loadPage:targetPage - 1 current:NO preload:YES forceReload:NO preserve:pagesToPreserve];
        if (preservePage) [pagesToPreserve addObject:preservePage];
        [self loadPage:targetPage + 1 current:NO preload:YES forceReload:NO preserve:pagesToPreserve];
        
        // The rest of the steps are performed after the animation thread has been run
        NSInteger fromPage = startPage + pagesToOffset;

        NSMethodSignature * mySignature = [BlioLayoutView instanceMethodSignatureForSelector:@selector(performGoToPageStep1FromPage:)];
        NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
        [myInvocation setTarget:self];    
        [myInvocation setSelector:@selector(performGoToPageStep1FromPage:)];
        [myInvocation setArgument:&fromPage atIndex:2];
        [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:0.1f];
    } else {
        [self loadPage:targetPage current:YES preload:YES];
        [self loadPage:targetPage - 1 current:NO preload:NO];
        [self loadPage:targetPage + 1 current:NO preload:NO];
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake((targetPage - 1) * self.scrollView.frame.size.width * self.scrollView.zoomScale, 0)];
        self.pageNumber = targetPage;
        [self didChangeValueForKey:@"pageNumber"];
    }
}

- (void)performGoToPageStep1FromPage:(NSInteger)fromPage {

    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    
    CFTimeInterval shrinkDuration = 0.25f + (0.5f * (self.scrollView.zoomScale / self.scrollView.maximumZoomScale));
    [UIView beginAnimations:@"BlioLayoutGoToPageStep1" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:shrinkDuration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.scrollView setMinimumZoomScale:kBlioPDFGoToZoomScale];
    [self.scrollView setZoomScale:kBlioPDFGoToZoomScale];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    [UIView commitAnimations];
}
    
- (void)performGoToPageStep2 {   
    CFTimeInterval scrollDuration = 0.75f;
    [UIView beginAnimations:@"BlioLayoutGoToPageStep2" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:scrollDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self.scrollView setContentOffset:CGPointMake(((self.pageNumber - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    [UIView commitAnimations];
}

- (void)performGoToPageStep3 {  
    
    CFTimeInterval zoomDuration = 0.25f;
    [UIView beginAnimations:@"BlioLayoutGoToPageStep3" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:zoomDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setZoomScale:1];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * self.scrollView.frame.size.width, 0)];
    [UIView commitAnimations];
    [self didChangeValueForKey:@"pageNumber"];
}

- (BlioBookmarkPoint *)pageBookmarkPoint
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    [self goToPageNumber:bookmarkPoint.layoutPage animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return bookmarkPoint.layoutPage;
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
    return self;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (finished) {
        //NSLog(@"Animation: %@ did finish", animationID);
        if ([animationID isEqualToString:@"BlioLayoutGoToPageStep1"]) {
            [self performSelector:@selector(performGoToPageStep2)];
        } else if ([animationID isEqualToString:@"BlioLayoutGoToPageStep2"]) {
            [self performSelector:@selector(performGoToPageStep3)];
        } else if ([animationID isEqualToString:@"BlioLayoutGoToPageStep3"]) {
            [self scrollViewDidEndScrollingAnimation:self.scrollView];
            [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else if ([animationID isEqualToString:@"BlioZoomPage"]) {
            [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
            [self performSelector:@selector(enableInteractions) withObject:nil afterDelay:0.1f];
        }
    }
} 

#pragma mark -
#pragma mark Contents Data Source protocol methods

- (NSArray *)sectionUuids
{
  return [NSArray arrayWithObject:@"dummy-uuid"];
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page
{
  return @"dummy-uuid";
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid
{
  return NULL;
}

- (NSInteger)pageNumberForSectionUuid:(NSString *)sectionUuid
{
  return 1; // only one section, very easy
}

- (NSString *)displayPageNumberForPageNumber:(NSInteger)aPageNumber
{
  return [NSString stringWithFormat:@"%d", aPageNumber];
}

- (CGRect)firstPageRect {
    if ([self pageCount] > 0) {
        CGPDFPageRef firstPage = CGPDFDocumentGetPage(pdf, 1);
        CGFloat inset = -kBlioLayoutShadow;
        CGRect insetBounds = UIEdgeInsetsInsetRect([[UIScreen mainScreen] bounds], UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
        CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(firstPage, kCGPDFCropBox, insetBounds, 0, true);
        CGRect coverRect = CGPDFPageGetBoxRect(firstPage, kCGPDFCropBox);
        return CGRectApplyAffineTransform(coverRect, fitTransform);
    } else {
        return [[UIScreen mainScreen] bounds];
    }
}
 
#pragma mark -
#pragma mark Notification Callbacks

- (void)layoutZoomInProgress:(NSNotification *)notification {
    //[self.scrollView setScrollEnabled:NO];
}

- (void)layoutZoomEnded:(NSNotification *)notification {
    //[self.scrollView setScrollEnabled:YES];
}


- (BlioPDFPageView *)loadPage:(int)aPageNumber current:(BOOL)current preload:(BOOL)preload {
    return [self loadPage:aPageNumber current:current preload:preload forceReload:NO];
}

- (BlioPDFPageView *)loadPage:(int)aPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload {
    return [self loadPage:aPageNumber current:current preload:preload forceReload:NO preserve:nil];
}
    
- (BlioPDFPageView *)loadPage:(int)aPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload preserve:(NSArray *)preservedPages {
    if (aPageNumber < 1) return nil;
    if (aPageNumber > CGPDFDocumentGetNumberOfPages (pdf)) return nil;
    
    //NSLog(@"LoadPage:%d current:%d preload:%d", aPageNumber, current, preload);
	
    BlioPDFPageView *pageView = nil;
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, aPageNumber);
    
    NSUInteger furthestPageIndex = 0;
    NSUInteger furthestPageDifference = 0;
    
    // First, see if we have it cached and determine the furthest away page
    NSInteger viewCacheCount = [self.pageViews count];
    for(NSInteger i = 0; i < viewCacheCount; ++i) {
        BlioPDFPageView *cachedPageView = [self.pageViews objectAtIndex:i];
        NSUInteger cachedPageNumber = CGPDFPageGetPageNumber([(BlioPDFDrawingView *)[cachedPageView view] page]);
        if((cachedPageNumber == aPageNumber) && [cachedPageView isValid]) {
            pageView = cachedPageView;
            break;
        } else {
            NSInteger pageDifference = abs(aPageNumber - cachedPageNumber);
            if (pageDifference >= furthestPageDifference) {
                if (![preservedPages containsObject:cachedPageView]) {
                    furthestPageDifference = pageDifference;
                    furthestPageIndex = i;
                    //NSLog(@"looking for page %d, cachedPage %d, furthestIndex now %d, preserve: %@", aPageNumber, cachedPageNumber, furthestPageIndex, [preservedPages description]);
                }// else {
//                    NSLog(@"rejected whilst looking for page %d, cachedPage %d, furthestIndex now %d, preserve: %@", aPageNumber, cachedPageNumber, furthestPageIndex, [preservedPages description]);
//
//                }
            }
        }
    }
    
    // Not found in cache, so we need to create it.
    CGRect newFrame;
    
    if(nil == pageView || reload) {
        if (viewCacheCount < kBlioLayoutMaxViews) {
            BlioPDFDrawingView *pdfView = [[BlioPDFDrawingView alloc] initWithFrame:self.scrollView.bounds document:pdf page:aPageNumber];
            pageView = [[BlioPDFPageView alloc] initWithView:pdfView andPageRef:pdfPageRef];
            [pdfView release];
            [self.pageViews addObject:pageView];
            [pageView release];
        } else {
            pageView = [self.pageViews objectAtIndex:furthestPageIndex];
            [pageView setPage:pdfPageRef];
            [pageView retain];
            [self.pageViews removeObjectAtIndex:furthestPageIndex];
            [self.pageViews addObject:pageView];
            [pageView release];
            //[(BlioPDFDrawingView *)[pageView view] setPageNumber:aPageNumber];
        }
        
        newFrame = self.scrollView.frame;
        newFrame.origin.x = newFrame.size.width * (aPageNumber - 1);
        newFrame.origin.y = 0;
        [pageView setFrame:newFrame];
        //[self.scrollView addSubview:pageView];
        [self.containerView addSubview:pageView];
    }
    
    if (current) self.currentPageView = pageView;
    
    if (preload) [pageView renderSharpPageAtScale:1];
    
    [pageView setPreload:preload];
    [pageView setCover:(aPageNumber == 1)];
    [pageView setValid:YES];
    
    return pageView;
}

#pragma mark -
#pragma mark Container UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.containerView;
}

- (void)hideSharpPage {
    if ([sharpLayer opacity] != 0) {
        //NSLog(@"setting z and opacity to hide sharp page");
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        sharpLayer.opacity = 0;
        sharpLayer.contents = nil;
        //[sharpLayer setDelegate:nil];
        //[sharpLayer setNeedsDisplay];
        //        [[self.view sharpLayer] setNeedsDisplay];
        [CATransaction commit]; 
    }
    
}

- (void)renderSharpPageAtScale:(CGFloat)scale {
    return;
//    NSLog(@"deciding to render sharp page with scale: %f", scale);
    if (scale <= 3) {
        NSLog(@"render SPECIAL sharp page");
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        if (nil == sharpLayer)
            sharpLayer = [CALayer layer];
        
        BlioPDFSharpLayerDelegate *aSharpDelegate = [[BlioPDFSharpLayerDelegate alloc] init];
        [aSharpDelegate setZoomScale:scale];
        [aSharpDelegate setPageRect:self.currentPageView.view.sharpLayerDelegate.pageRect];
        [aSharpDelegate setPage:self.currentPageView.view.sharpLayerDelegate.page];
        sharpLayer.delegate = aSharpDelegate;
        sharpLayer.geometryFlipped = YES;
        sharpLayer.opacity = 1;

        //CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
        //sharpLayer.frame = CGRectApplyAffineTransform(self.currentPageView.frame, CGAffineTransformInvert(scaleTransform));
        CGRect currFrame = [self convertRect:self.currentPageView.frame fromView:self.currentPageView];
        
        CGRect pageFrame = currFrame;
        //pageFrame = self.currentPageView.frame;
        
        //CGFloat pageWidth = self.scrollView.frame.size.width * self.scrollView.zoomScale;
        CGPoint contentOffset = self.scrollView.contentOffset;
        //CGPoint pageOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
        CGRect viewFrame = CGRectMake(pageFrame.origin.x - contentOffset.x, pageFrame.origin.y, pageFrame.size.width, pageFrame.size.height);
    
        
        
        sharpLayer.frame = viewFrame;
        //[sharpLayer setBounds:CGRectApplyAffineTransform(sharpLayer.bounds, scaleTransform)];
        [sharpLayer setNeedsDisplay];
        
        [[self layer] addSublayer:sharpLayer];
        [CATransaction commit]; 
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)aScrollView withView:(UIView *)view atScale:(float)scale {
    [self.currentPageView renderSharpPageAtScale:self.scrollView.zoomScale];
    [self renderSharpPageAtScale:self.scrollView.zoomScale];

    if (scale == 1.0f) {
        scrollView.pagingEnabled = YES;
        scrollView.bounces = YES;
        scrollView.directionalLockEnabled = NO;
    } else {
        scrollView.pagingEnabled = NO;
        scrollView.bounces = NO;
        scrollView.directionalLockEnabled = YES;
    }
    
}

- (void)enableInteractions {
    //NSLog(@"Setting zoomPage to NO");
    self.disableScrollUpdating = NO;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.currentPageView hideSharpPage];
    [self hideSharpPage];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self.currentPageView renderSharpPageAtScale:aScrollView.zoomScale];
        [self renderSharpPageAtScale:aScrollView.zoomScale];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (self.disableScrollUpdating) return;
    //if (sender.zoomScale < sender.minimumZoomScale) return;
    //NSLog(@"Scrollview didScroll");
    NSInteger currentPageNumber;
    
    if (sender.zoomScale != lastZoomScale) {
        [sender setContentSize:CGSizeMake(sender.frame.size.width * pageCount * sender.zoomScale, sender.frame.size.height * sender.zoomScale)];
        self.lastZoomScale = sender.zoomScale;
        //[sender setBounds:CGRectMake(0,0,320 * sender.zoomScale, 480)];
        //NSLog(@"ContentSize changed to %@", NSStringFromCGSize(sender.contentSize));
        
        // If we are zooming, don't update the page number - (contentOffset gets set to zero so it wouldn't work)
        currentPageNumber = self.pageNumber;
    } else {
        CGFloat pageWidth = sender.contentSize.width / pageCount;
        currentPageNumber = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 2;   
    }
    
    //CGFloat pageWidth = self.scrollView.frame.size.width;
    
    //NSLog(@"ContentOffset is %@", NSStringFromCGPoint(sender.contentOffset));
    //NSLog(@"pageWidth: %f, currentPageNumber: %d", pageWidth, currentPageNumber);
    if (currentPageNumber != self.pageNumber) {
        //NSLog(@"Loading new page %d", currentPageNumber);
        
        [self loadPage:currentPageNumber current:YES preload:NO];
        if (!self.scrollToPageInProgress) {
            if (currentPageNumber < self.pageNumber) {
                [self loadPage:currentPageNumber - 1 current:NO preload:NO];
            }
            if (currentPageNumber > self.pageNumber) {
                [self loadPage:currentPageNumber + 1 current:NO preload:NO];
            }
            self.pageNumber = currentPageNumber;
        }
        
        if (![sender isDragging] && ![sender isDecelerating]) {
            [self.currentPageView renderSharpPageAtScale:sender.zoomScale];
            [self renderSharpPageAtScale:sender.zoomScale];
        } else {
            [self.currentPageView hideSharpPage];
            [self hideSharpPage];
        }

    }
}

- (void)updateAfterScroll {
    [self.currentPageView renderSharpPageAtScale:self.scrollView.zoomScale];
    [self renderSharpPageAtScale:self.scrollView.zoomScale];
    if (self.disableScrollUpdating) return;
    
    
    if (self.scrollToPageInProgress) {
        //NSLog(@"force reloading pages around page %d", self.pageNumber);
        self.scrollToPageInProgress = NO;
        
        //[self loadPage:self.pageNumber - 1 current:NO preload:NO forceReload:YES];
        //[self loadPage:self.pageNumber + 1 current:NO preload:NO forceReload:YES];   
        [self loadPage:self.pageNumber - 1 current:NO preload:NO forceReload:NO];
        [self loadPage:self.pageNumber + 1 current:NO preload:NO forceReload:NO]; 
    }
    
    //if (tiltScroller) {
//        [tiltScroller setScrollView:self.currentPageView];
//    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.disableScrollUpdating = NO;
    [self updateAfterScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAfterScroll];
}

- (CGFloat)lastZoomScale {
    return lastZoomScale;
}

- (void)setLastZoomScale:(CGFloat)newScale {
    lastZoomScale = newScale;
}

- (void)zoomAtPoint:(NSString *)pointString {
    if ([self.scrollView isDecelerating]) return;
    
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *paras = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSMutableArray *highlights = [NSMutableArray array];
    for (BlioTextFlowParagraph *para in paras) {
        NSArray *words = [para words];
        for (BlioTextFlowPositionedWord *word in words) {
            CGRect wordRect = [word rect];
            [highlights addObject:[NSValue valueWithCGRect:wordRect]];
        }
    }
    
    BlioPDFHighlightLayerDelegate *del = [[self.currentPageView view] highlightLayerDelegate];
    [del setHighlights:highlights];
    [[[self.currentPageView view] highlightLayer] setNeedsDisplay];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    CGPoint point = CGPointFromString(pointString);
    
    self.disableScrollUpdating = YES;
    if (self.scrollView.zoomScale > 1.0f) {
        [UIView beginAnimations:@"BlioZoomPage" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.35f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [self.scrollView setZoomScale:1.0f];
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * self.scrollView.frame.size.width, 0)];
        self.lastZoomScale = self.scrollView.zoomScale;
        [UIView commitAnimations];
    } else {
        NSInteger pageIndex = self.pageNumber - 1;
        NSArray *paragraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
        for (BlioTextFlowParagraph *paragraph in paragraphs) {
            NSLog(@"PageIndex: %d\n Words: %@", [paragraph pageIndex], [paragraph string]); 
        }

        
        NSArray *textBlocks = [self.parsedPage textBlocks];
        
        [self.scrollView setPagingEnabled:NO];
        [self.scrollView setBounces:NO];
        
        BlioPDFPositionedString *targetBlock = nil;
        
        if ([textBlocks count]) {
            CGPoint pagePoint = [self.scrollView convertPoint:point toView:self.currentPageView];
            CGPoint pdfPoint = [self.currentPageView convertPointToPDFPage:pagePoint];
            
            for (BlioPDFPositionedString *block in textBlocks) {
                if (CGRectContainsPoint(block.boundingRect, pdfPoint)) {
                    targetBlock = block;
                    break;
                }
            }
        }
        
        if (nil != targetBlock) {            
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            CGRect targetRect = [self.currentPageView convertRectFromPDFPage:targetBlock.boundingRect];
            targetRect = CGRectInset(targetRect, -kBlioPDFBlockInsetX, -kBlioPDFBlockInsetY);
            
            if (CGRectGetWidth(targetRect) < kBlioPDFBlockMinimumWidth) {
                targetRect.origin.x -= ((kBlioPDFBlockMinimumWidth - CGRectGetWidth(targetRect)))/2.0f;
                targetRect.size.width += (kBlioPDFBlockMinimumWidth - CGRectGetWidth(targetRect));
                
                if (targetRect.origin.x < 0) {
                    targetRect.origin.x = 0;
                    targetRect.size.width += (kBlioPDFBlockMinimumWidth - CGRectGetWidth(targetRect));
                }
                
                if (CGRectGetMaxX(targetRect) > CGRectGetWidth(self.scrollView.bounds)) {
                    targetRect.origin.x = CGRectGetWidth(targetRect) - kBlioPDFBlockMinimumWidth;
                }
            }
            
            CGFloat zoomScale = CGRectGetWidth(self.scrollView.bounds) / CGRectGetWidth(targetRect);
            [self.scrollView setZoomScale:zoomScale];
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
            
            CGFloat pageWidth = self.scrollView.frame.size.width * self.scrollView.zoomScale;            
            CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
            
            [self.scrollView setContentOffset:CGPointMake(viewOrigin.x + targetRect.origin.x * zoomScale, viewOrigin.y + targetRect.origin.y * zoomScale)];
            
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
        } else {
            
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            [self.scrollView setZoomScale:2.0f];
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
            
            CGFloat pageWidth = self.scrollView.frame.size.width * self.scrollView.zoomScale;
            CGFloat pageWidthExpansion = pageWidth - self.scrollView.frame.size.width;
            CGFloat pageHeight = self.scrollView.frame.size.height * self.scrollView.zoomScale;
            CGFloat pageHeightExpansion = pageHeight - self.scrollView.frame.size.height;
            
            CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
            CGFloat xOffset = pageWidthExpansion * (point.x / CGRectGetWidth(self.scrollView.bounds));
            CGFloat yOffset = pageHeightExpansion * (point.y / CGRectGetHeight(self.scrollView.bounds));
            [self.scrollView setContentOffset:CGPointMake(viewOrigin.x + xOffset, viewOrigin.y + yOffset)];
            
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
        }
        
    }
    [self.currentPageView renderSharpPageAtScale:self.scrollView.zoomScale];
    [self renderSharpPageAtScale:self.scrollView.zoomScale];
}

#pragma mark -
#pragma mark Manual KVO overrides

- (void)setPageNumber:(NSInteger)newPageNumber {
    if (!self.scrollToPageInProgress) {
        //NSLog(@"Setting pagenumber to %d whilst scrolltopage not in progress", newPageNumber);
        [self willChangeValueForKey:@"pageNumber"];
        pageNumber=newPageNumber;
        [self didChangeValueForKey:@"pageNumber"];
    } else {
        //NSLog(@"Setting pagenumber to %d whilst scrolltopage is in progress", newPageNumber);
        pageNumber=newPageNumber;
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    
    if ([theKey isEqualToString:@"pageNumber"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)blioCoverPageDidFinishRenderAfterDelay:(NSNotification *)notification {
    [self goToPageNumber:self.pageNumber animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"blioCoverPageDidFinishRender" 
                                                  object:nil];
}

- (void)blioCoverPageDidFinishRenderOnMainThread:(NSNotification *)notification {
    // To allow the tiled view to do its fading out.
    [self performSelector:@selector(blioCoverPageDidFinishRenderAfterDelay:) withObject:notification afterDelay:0.75];
}

- (void)blioCoverPageDidFinishRender:(NSNotification *)notification  {
    [self performSelectorOnMainThread:@selector(blioCoverPageDidFinishRenderOnMainThread:) withObject:notification waitUntilDone:YES];
}


@end

@implementation BlioPDFPageView

@synthesize view, page, valid;        

- (void)dealloc {
    CGPDFPageRelease(page);
    self.view = nil;
    [super dealloc];
}

- (id)initWithView:(BlioPDFDrawingView *)newView andPageRef:(CGPDFPageRef)newPage {
    NSAssert1(kBlioLayoutMaxViews >= 3, @"Error: kBlioLayoutMaxViews is %d. This must be 3 or greater.", kBlioLayoutMaxViews);

	self = [super initWithFrame:newView.frame];
	if(self != nil) {
        page = newPage;
        CGPDFPageRetain(page);
        
        [self addSubview:newView];
        [newView setFrame:newView.bounds];
        self.view = newView;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.valid = YES;
    }
    return self;
}

- (void)setPage:(CGPDFPageRef)newPage {
    CGPDFPageRetain(newPage);
    CGPDFPageRelease(page);
    page = newPage;
    [self.view setPageNumber:CGPDFPageGetPageNumber(newPage)];
}

- (CGPoint)convertPointToPDFPage:(CGPoint)point {
    CGPoint invertedViewPoint = CGPointMake(point.x, CGRectGetHeight(self.bounds) - point.y);
    
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    CGAffineTransform inverseTransform = CGAffineTransformInvert(fitTransform);
    CGPoint invertedPDFPoint = CGPointApplyAffineTransform(invertedViewPoint, inverseTransform);
    
    return invertedPDFPoint;
}

- (CGRect)convertRectFromPDFPage:(CGRect)rect {
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    CGRect fittedRect = CGRectApplyAffineTransform(rect, fitTransform);
    
    //CGRect invertedRect = CGRectMake(fittedRect.origin.x, CGRectGetHeight(self.bounds) - CGRectGetMaxY(fittedRect), fittedRect.size.width, fittedRect.size.height);

    return fittedRect;
}

- (void)setPreload:(BOOL)preload {
    // Clear the contents if previously preloaded
    if ([[self.view shadowLayerDelegate] preloadPage])
        [[self.view shadowLayer] setContents:nil];
    
    [[self.view shadowLayerDelegate] setPreloadPage:preload];
    [[self.view shadowLayer] setNeedsDisplay];
}

- (void)setCover:(BOOL)cover {
    [[self.view tiledLayerDelegate] setCover:cover];
}

- (void)renderSharpPageAtScale:(CGFloat)scale {
    return;
    NSLog(@"deciding to render sharp page with scale: %f", scale);
    if (scale <= 3) {
        NSLog(@"render sharp page");
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        [[self.view sharpLayerDelegate] setZoomScale:scale];
        [self.view sharpLayer].zPosition = 1;
        [self.view sharpLayer].opacity = 1;
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
        [[self.view sharpLayer] setBounds:CGRectApplyAffineTransform(self.bounds, scaleTransform)];
        [[self.view sharpLayer] setTransform:CATransform3DInvert(CATransform3DMakeAffineTransform(scaleTransform))];
        [[self.view sharpLayer] setNeedsDisplay];
        [CATransaction commit]; 
    } else {
        [self hideSharpPage];
    }
}

- (void)hideSharpPage {
    return;
    NSLog(@"deciding to hide sharp page");
   
    
    if ([[self.view sharpLayer] zPosition] != 0) {
        //NSLog(@"setting z and opacity to hide sharp page");
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        [self.view sharpLayer].opacity = 0;
        [self.view sharpLayer].zPosition = 0;
//        [[self.view sharpLayer] setNeedsDisplay];
        [CATransaction commit]; 
    }
 
}

@end
    
@implementation BlioPDFContainerScrollView

@synthesize pageCount;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches began in scrollview");
    UITouch * t = [touches anyObject];
    if( [t tapCount]>1 ) {
        CGPoint point = [t locationInView:(UIView *)self.delegate];
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomAtPoint:)])
            [(NSObject *)self.delegate performSelector:@selector(zoomAtPoint:) withObject:NSStringFromCGPoint(point)];
    }
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
  NSLog(@"Touches should begin in scrollview");
    return YES;
}

    
//- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
//    // get any touch
//    UITouch * t = [touches anyObject];
//    if( [t tapCount]>1 ) {
//        CGPoint point = [t locationInView:(UIView *)self.delegate];
//        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomAtPoint:)])
//          [(NSObject *)self.delegate performSelector:@selector(zoomAtPoint:) withObject:NSStringFromCGPoint(point)];
//        return NO;
//    }
//    return YES;
//}
    
@end    


@implementation BlioPDFDrawingView

@synthesize layoutView, tiledLayer, shadowLayer, sharpLayer, highlightLayer, tiledLayerDelegate, shadowLayerDelegate, sharpLayerDelegate, highlightLayerDelegate;

- (void)dealloc {
    self.layoutView = nil;
    [self.tiledLayer setDelegate:nil];
    [self.shadowLayer setDelegate:nil];
    [self.sharpLayer setDelegate:nil];
    [self.highlightLayer setDelegate:nil];
    self.tiledLayerDelegate = nil;
    self.shadowLayerDelegate = nil;
    self.sharpLayerDelegate = nil;
    self.highlightLayerDelegate = nil;
    self.tiledLayer = nil;
    self.shadowLayer = nil;
    self.sharpLayer = nil;
    self.highlightLayer = nil;
    CGPDFDocumentRelease(document);
	[super dealloc];
}

- (CGAffineTransform)textFlowTransform {
    if (CGAffineTransformIsIdentity(textFlowTransform)) {
        CGRect cropRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
        CGRect mediaRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        CGAffineTransform dpiScale = CGAffineTransformMakeScale(72/96.0f, 72/96.0f);
        CGAffineTransform mediaAdjust = CGAffineTransformMakeTranslation(cropRect.origin.x - mediaRect.origin.x, cropRect.origin.y - mediaRect.origin.y);
        textFlowTransform = CGAffineTransformConcat(dpiScale, mediaAdjust);
    }
    return textFlowTransform;
}

- (void)configureLayers {
    self.tiledLayer = [BlioFastCATiledLayer layer];
    
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    //CGPDFPageRef firstPage = CGPDFDocumentGetPage(document, 1);
    //CGAffineTransform firstTransform = CGPDFPageGetDrawingTransform(firstPage, kCGPDFArtBox, insetBounds, 0, true);
    //CGAffineTransform highlightsTransform = fitTransform;
    CGRect fittedPageRect = CGRectApplyAffineTransform(pageRect, fitTransform);     
    
    int w = pageRect.size.width;
    int h = pageRect.size.height;
    
    int levels = 1;
    while (w > 1 && h > 1) {
        levels++;
        w = w >> 1;
        h = h >> 1;
    }
    
    tiledLayer.levelsOfDetail = levels + 4;
    tiledLayer.levelsOfDetailBias = levels;
    tiledLayer.tileSize = CGSizeMake(2048, 2048);
    //tiledLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(2.0f, 2.0f));
    //tiledLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(0.5/fitTransform.a, 0.5/fitTransform.a));
    
    CGRect origBounds = self.bounds;
    CGRect newBounds = self.bounds;
    
    // Stretch the layer so that it overlaps with prev and next layers forcing a draw
    newBounds.size.width = origBounds.size.width*2;
    insetBounds.origin.x += (newBounds.size.width - origBounds.size.width)/2.0f;
    
    tiledLayer.bounds = newBounds;
    CGAffineTransform offsetFitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    
//    CGRect offsetFittedPageRect = CGRectApplyAffineTransform(pageRect, fitTransform);     
//    fitTransform = CGAffineTransformMake(fitTransform.a, 
//                                         fitTransform.b, 
//                                         fitTransform.c, 
//                                         fitTransform.d, 
//                                         fitTransform.tx - (offsetFittedPageRect.origin.x - (int)offsetFittedPageRect.origin.x),
//                                         fitTransform.ty - (offsetFittedPageRect.origin.y - (int)offsetFittedPageRect.origin.y));
    
    BlioPDFTiledLayerDelegate *aTileDelegate = [[BlioPDFTiledLayerDelegate alloc] init];
    [aTileDelegate setPage:page];
    [aTileDelegate setFitTransform:offsetFitTransform];
    tiledLayer.delegate = aTileDelegate;
    self.tiledLayerDelegate = aTileDelegate;
    [aTileDelegate release];
    
    tiledLayer.position = CGPointMake(self.layer.bounds.size.width/2.0f, self.layer.bounds.size.height/2.0f);  
    
    // transform the super layer so things draw 'right side up'
    CATransform3D superTransform = CATransform3DMakeTranslation(0.0f, self.bounds.size.height, 0.0f);
    self.layer.transform = CATransform3DScale(superTransform, 1.0, -1.0f, 1.0f);
    [self.layer addSublayer:tiledLayer];
    
    [tiledLayer setNeedsDisplay];
    
    self.shadowLayer = [CALayer layer];
    CGAffineTransform zoomScale = CGAffineTransformMakeScale(kBlioPDFShadowShrinkScale, kBlioPDFShadowShrinkScale);
    CGAffineTransform shrinkScale = CGAffineTransformInvert(zoomScale);
    shadowLayer.transform = CATransform3DMakeAffineTransform(zoomScale);
    shadowLayer.bounds = CGRectApplyAffineTransform(self.bounds, shrinkScale);
    //shadowLayer.bounds = self.bounds;
    shadowLayer.position = tiledLayer.position;
    
    BlioPDFShadowLayerDelegate *aShadowDelegate = [[BlioPDFShadowLayerDelegate alloc] init];
    //[aShadowDelegate setPageRect:fittedPageRect];
    [aShadowDelegate setPageRect:CGRectApplyAffineTransform(fittedPageRect, shrinkScale)];
    [aShadowDelegate setPage:page];
    shadowLayer.delegate = aShadowDelegate;
    self.shadowLayerDelegate = aShadowDelegate;
    [aShadowDelegate release];
    
    [self.layer insertSublayer:shadowLayer below:tiledLayer];
    [shadowLayer setNeedsDisplay];
    
    self.highlightLayer = [CALayer layer];
    BlioPDFHighlightLayerDelegate *aHighlightDelegate = [[BlioPDFHighlightLayerDelegate alloc] init];
    [aHighlightDelegate setFitTransform:fitTransform];
    // TODO - change teh way we are getting this transform
    [aHighlightDelegate setHighlightsTransform:self.textFlowTransform];

    [aHighlightDelegate setPage:page];
    highlightLayer.delegate = aHighlightDelegate;
    self.highlightLayerDelegate = aHighlightDelegate;
    [aHighlightDelegate release];
    
    highlightLayer.bounds = self.bounds;
    highlightLayer.position = tiledLayer.position;
    [self.layer addSublayer:highlightLayer]; 
    
//    self.sharpLayer = [CALayer layer];
//    BlioPDFSharpLayerDelegate *aSharpDelegate = [[BlioPDFSharpLayerDelegate alloc] init];
//    [aSharpDelegate setZoomScale:1];
//    [aSharpDelegate setPageRect:fittedPageRect];
//    [aSharpDelegate setPage:page];
//    sharpLayer.delegate = aSharpDelegate;
//    self.sharpLayerDelegate = aSharpDelegate;
//    [aSharpDelegate release];
//    
//    sharpLayer.bounds = self.bounds;
//    sharpLayer.position = tiledLayer.position;
//    sharpLayer.opacity = 0;
    //[self.layer insertSublayer:sharpLayer below:tiledLayer];    
}

- (id)initWithFrame:(CGRect)frame document:(CGPDFDocumentRef)aDocument page:(NSInteger)aPageNumber {
	self = [super initWithFrame:frame];
	if(self != nil) {
        document = aDocument;
        CGPDFDocumentRetain(document);
        page = CGPDFDocumentGetPage(document, aPageNumber);
        
        self.backgroundColor = [UIColor clearColor];
        textFlowTransform = CGAffineTransformIdentity;
        
        [self configureLayers];
	}
	return self;
}

- (CGPDFPageRef)page {
    return page;
}

- (void)setPageNumber:(NSInteger)newPageNumber {
    CGRect currentPageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);

    page = CGPDFDocumentGetPage(document, newPageNumber);
    CGRect newPageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    textFlowTransform = CGAffineTransformIdentity;
    
    if (!CGRectEqualToRect(CGRectIntegral(currentPageRect), CGRectIntegral(newPageRect))) {
        [tiledLayer setDelegate:nil];
        [shadowLayer setDelegate:nil];
        [sharpLayer setDelegate:nil];
        [highlightLayer setDelegate:nil];
        [tiledLayer removeFromSuperlayer];
        [shadowLayer removeFromSuperlayer];
        [sharpLayer removeFromSuperlayer];
        [highlightLayer removeFromSuperlayer];
        self.tiledLayerDelegate = nil;
        self.shadowLayerDelegate = nil;
        self.sharpLayerDelegate = nil;
        self.highlightLayerDelegate = nil;
        
        [self configureLayers];
    } else {
        [sharpLayerDelegate setPage:page];
        sharpLayer.opacity = 0;
        sharpLayer.zPosition = 0;        
        [sharpLayer setNeedsDisplay];
        
        [shadowLayerDelegate setPage:page];
        [shadowLayer setNeedsDisplay];
        
        [highlightLayerDelegate setPage:page];
        [highlightLayerDelegate setHighlights:nil];
        [highlightLayerDelegate setHighlightsTransform:self.textFlowTransform];
        [highlightLayer setNeedsDisplay];
        
        // Force the tiled layer to discard it's tile caches
        [tiledLayerDelegate setPage:page];
        [tiledLayer setContents:nil];
        [tiledLayer setNeedsDisplay];
        
    }
}

@end


@implementation BlioPDFTiledLayerDelegate

@synthesize page, fitTransform, cover;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    
    CGContextConcatCTM(ctx, fitTransform);
    
    CGRect compareRect = pageRect;
    CGRect originRect = CGRectApplyAffineTransform(compareRect, CGContextGetCTM(ctx));
    
    CGFloat integralHeight = roundf(CGRectGetHeight(originRect));
    CGFloat integralWidth = roundf(CGRectGetWidth(originRect));
    CGFloat yScale = integralHeight/CGRectGetHeight(originRect);
    CGFloat xScale = integralWidth/CGRectGetWidth(originRect);
    CGContextScaleCTM(ctx, xScale, yScale);
    CGRect scaledRect = CGRectApplyAffineTransform(compareRect, CGContextGetCTM(ctx));
    
    CGAffineTransform current = CGContextGetCTM(ctx);
    CGAffineTransform integral = CGAffineTransformMakeTranslation(-(scaledRect.origin.x - roundf(scaledRect.origin.x)) / current.a, -(scaledRect.origin.y - roundf(scaledRect.origin.y)) / current.d);
    CGContextConcatCTM(ctx, integral);
    
    CGContextClipToRect(ctx, pageRect);
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillRect(ctx, pageRect);
    
    if (page) CGContextDrawPDFPage(ctx, page);
    if (cover) [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:nil];
}

- (void)setPage:(CGPDFPageRef)newPage {
    page = newPage;
    pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
}

@end

@implementation BlioPDFShadowLayerDelegate

@synthesize pageRect, page, preloadPage;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    
    CGRect insetRect = CGRectInset(pageRect, 1.0f/kBlioPDFShadowShrinkScale, 1.0f/kBlioPDFShadowShrinkScale);
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, (kBlioLayoutShadow/2.0f)), kBlioLayoutShadow, [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, insetRect);
    CGContextRestoreGState(ctx);
    
    CGContextClipToRect(ctx, insetRect);
    
    if (preloadPage && page) {
        //NSLog(@"Start preload render");
        CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, pageRect, 0, true));
        //CGContextClipToRect(ctx, pageRect);
        CGContextDrawPDFPage(ctx, page);
        //NSLog(@"End preload render");
    }
}

@end

@implementation BlioPDFSharpLayerDelegate

@synthesize pageRect, page, zoomScale;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextConcatCTM(ctx, CGAffineTransformMakeScale(zoomScale, zoomScale));
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);

    CGContextFillRect(ctx, pageRect);
    
    CGContextSetLineWidth(ctx, 1);
    CGContextStrokeRect(ctx, pageRect);
    
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, pageRect, 0, true);
    
    CGContextConcatCTM(ctx, fitTransform);
    
    CGAffineTransform current = CGContextGetCTM(ctx);
    
    CGRect cropRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    //CGRect originRect = CGRectApplyAffineTransform(CGRectZero, current);
    CGRect originRect = CGRectApplyAffineTransform(cropRect, current);
    NSLog(@"current rect box: %@", NSStringFromCGRect(originRect));
    
    
    //CGAffineTransform integral = CGAffineTransformMakeTranslation(-(originRect.origin.x - roundf(originRect.origin.x)) / current.a, -(originRect.origin.y - roundf(originRect.origin.y)) / current.d);
    //CGContextConcatCTM(ctx, integral);
    //current = CGContextGetCTM(ctx);
    //CGRect integralRect = CGRectApplyAffineTransform(cropRect, current);
    //NSLog(@"current rect box: %@", NSStringFromCGRect(integralRect));
    
    CGContextClipToRect(ctx, CGPDFPageGetBoxRect(page, kCGPDFCropBox));

    NSLog(@"current ctm: %@", NSStringFromCGAffineTransform(CGContextGetCTM(ctx)));
    CGContextDrawPDFPage(ctx, page);
}

@end

@implementation BlioPDFHighlightLayerDelegate


@synthesize page, fitTransform, highlights, highlightsTransform;

- (void)dealloc {
    self.highlights = nil;
    [super dealloc];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGRect boundingRect = CGContextGetClipBoundingBox(ctx);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -CGRectGetHeight(boundingRect));
    
    CGContextSetRGBFillColor(ctx, 1, 1, 0, 0.3f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.5f green:0.3f blue:0 alpha:1.0f].CGColor);
    CGContextSetLineWidth(ctx, 0.5f);
    CGFloat dash[2]={0.5f,1.5f};
    CGContextSetLineDash (ctx, 0, dash, 2);
    
    CGContextConcatCTM(ctx, fitTransform);
        
    for (NSValue *rectVal in self.highlights) {
        CGRect highlightRect = [rectVal CGRectValue];
        CGRect adjustedRect = CGRectApplyAffineTransform(highlightRect, highlightsTransform);
        CGContextClearRect(ctx, CGRectInset(adjustedRect, -1, -1));
        CGContextFillRect(ctx, adjustedRect);
        CGContextStrokeRect(ctx, adjustedRect);
    }
}

@end

@implementation BlioFastCATiledLayer

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

static void parseFont(const char *key, CGPDFObjectRef object, void *info) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    const char *name;
    CGPDFDictionaryRef dict;
    NSString *baseFont, *fontType, *encodingName;
    BlioPDFEncoding encoding;
    
    BlioPDFFontList *fonts = info;
    
    // Mandatory elements
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict))
        return;
    
    NSValue *uniqueFont = [NSValue valueWithPointer:dict];
    
    if ([[fonts dictionary] objectForKey:uniqueFont]) {
        return;
    }
    
    //CGPDFDictionaryApplyFunction(dict, &logDictContents, @"fontDict"); // TODO REMOVE
    if (CGPDFDictionaryGetName(dict, "BaseFont", &name))
        baseFont = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    else
        return;
    
    if (CGPDFDictionaryGetName(dict, "Subtype", &name))
        fontType = [NSString stringWithCString: name encoding:NSASCIIStringEncoding];
    else
        return;
    
    BlioPDFFont *font = [[BlioPDFFont alloc] initWithKey:[NSString stringWithUTF8String:key]];
    [font setBaseFont:baseFont];
    [font setType:fontType];
	
    CGPDFDictionaryRef encodingDict;
    encoding = -1;
    encodingName = nil;
    NSMutableDictionary *glyphs = nil;
    
    if (CGPDFDictionaryGetDictionary(dict, "Encoding", &encodingDict)) {
        //CGPDFDictionaryApplyFunction(encodingDict, &logDictContents, @"encodingDict"); // TODO REMOVE
        // Attempt to retrieve a base encoding
        if (CGPDFDictionaryGetName(encodingDict, "BaseEncoding", &name)) {
            encodingName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
            if ([encodingName isEqualToString:@"MacRomanEncoding"])
                encoding = kBlioPDFEncodingMacRoman;
            if ([encodingName isEqualToString:@"WinAnsiEncoding"])
                encoding = kBlioPDFEncodingWin;
        }
        
        [font setGlyphs:[BlioPDFFont glyphDictionaryForEncoding:encoding]];
        glyphs = [font glyphs];
        
        // Attempt to retrieve a differences array
        CGPDFArrayRef diffArray;
        if (CGPDFDictionaryGetArray(encodingDict, "Differences", &diffArray)) {
            int arraySize = CGPDFArrayGetCount(diffArray);
            int charIndex = 0;
            for(int n = 0; n < arraySize; n++) {
                if (n >= arraySize) continue;
                CGPDFInteger startIndex;
                
                if (!CGPDFArrayGetInteger(diffArray, n, &startIndex)) {
                    if (CGPDFArrayGetName(diffArray, n, &name)) {
                        NSString *glyphName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
                        NSNumber *charLookup = [NSNumber numberWithInt:charIndex];
                        [glyphs removeObjectForKey:charLookup];
                        [glyphs setObject:glyphName forKey:charLookup];
                        charIndex++;
                    }
                } else {
                    charIndex = startIndex;
                }
            }
        }        
    } else if (CGPDFDictionaryGetName(dict, "Encoding", &name)) {
        encodingName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
        if ([encodingName isEqualToString:@"MacRomanEncoding"])
            encoding = kBlioPDFEncodingMacRoman;
        if ([encodingName isEqualToString:@"WinAnsiEncoding"])
            encoding = kBlioPDFEncodingWin;
    }
    
    if (nil == glyphs) {
        [font setGlyphs:[BlioPDFFont glyphDictionaryForEncoding:encoding]];
        glyphs = [font glyphs];
    }
    
    // Create the encoding lookup
    [font setFontEncoding:encoding];
    [font createEncoding];
    
    CGPDFDictionaryRef descriptorDict;
    
    NSUInteger firstWidthChar = 0;
    CGPDFInteger firstChar;
    if (CGPDFDictionaryGetInteger(dict, "FirstChar", &firstChar))
        firstWidthChar = (NSUInteger)firstChar;
    
    NSUInteger lastWidthChar = 255;
    CGPDFInteger lastChar;
    if (CGPDFDictionaryGetInteger(dict, "LastChar", &lastChar))
        lastWidthChar = (NSUInteger)lastChar;
    
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
//        NSLog(@"%@: Calculated width: %d", baseFont, defaultWidth);
    }
    
    if (CGPDFDictionaryGetDictionary(dict, "FontDescriptor", &descriptorDict)) {
        //CGPDFDictionaryApplyFunction(descriptorDict, &logDictContents, @"descriptorDict"); // TODO REMOVE
            
        CGPDFReal missingWidth;
        CGPDFReal averageWidth;
        CGPDFReal maxWidth;
        CGPDFArrayRef fontBBox;
        if (CGPDFDictionaryGetNumber(descriptorDict, "MissingWidth", &missingWidth)) {
            //NSLog(@"%@: Missing width: %d", baseFont, (NSInteger)missingWidth);
            defaultWidth = (NSInteger)missingWidth;
        } else if (CGPDFDictionaryGetNumber(descriptorDict, "AverageWidth", &averageWidth)) {
            //NSLog(@"%@: Average width: %d", baseFont, (NSInteger)averageWidth);
            defaultWidth = (NSInteger)averageWidth;
        } 
        
        // Use the maxWidths if we have nothing better
        if (defaultWidth == 0) {
            if (CGPDFDictionaryGetNumber(descriptorDict, "MaxWidth", &maxWidth)) {
                //NSLog(@"%@: Max width: %d", baseFont, (NSInteger)maxWidth);
                defaultWidth = (NSInteger)maxWidth;
            } else if (CGPDFDictionaryGetArray(descriptorDict, "FontBBox", &fontBBox)) {
                CGPDFReal x1, x2;
                if (CGPDFArrayGetNumber(fontBBox, 0, &x1) && CGPDFArrayGetNumber(fontBBox, 2, &x2)) {
                    CGFloat boxWidth = fabs(x2 - x1);
                    //NSLog(@"%@: BBox: %d", baseFont, (NSInteger)boxWidth);
                    defaultWidth = (NSInteger)boxWidth;
                }
            }
        }
    }
    [font setMissingWidth:defaultWidth];
    
    CGPDFStreamRef unicodeStream;
    if (CGPDFDictionaryGetStream(dict, "ToUnicode", &unicodeStream)) {
        NSMutableDictionary *toUnicodeDict = [font toUnicode];
        

        CGPDFDataFormat constant;
        NSData *data = (NSData *)CGPDFStreamCopyData(unicodeStream, &constant);
        NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        
        NSString *BEGINBFCHAR = @"beginbfchar";
        NSString *BEGINBFRANGE = @"beginbfrange";
        NSInteger entries = 0;
        
        while ([scanner isAtEnd] == NO) {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
            [scanner scanInteger:&entries];
            if ([scanner scanString:BEGINBFCHAR intoString:NULL]) {
                for (int i = 0; i < entries; i++) {
                    NSUInteger srcCode;
                    NSString *destCodesString;
                    NSMutableString *destCharsString = [NSMutableString string];
                    [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                    [scanner scanHexInt:&srcCode];
                    [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                    [scanner scanUpToString:@">" intoString:&destCodesString];
                    for (int k = 0; k < [destCodesString length]; k+=4) {
                        NSUInteger hexInt;
                        NSScanner *hexScanner = [NSScanner scannerWithString:[destCodesString substringWithRange:NSMakeRange(k, 4)]];
                        if ([hexScanner scanHexInt:&hexInt]) {
                          [destCharsString appendFormat:@"%C", hexInt];
                        }
                    }
                    if (destCharsString) [toUnicodeDict setObject:destCharsString forKey:[NSNumber numberWithInt:srcCode]];
                }
            }
            if ([scanner scanString:BEGINBFRANGE intoString:NULL]) {
                for (int i = 0; i < entries; i++) {
                    NSUInteger beginSrcCode, endSrcCode, lastDestCode;
                    NSString *destCodesString;
                    
                    [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                    [scanner scanHexInt:&beginSrcCode];
                    [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                    [scanner scanHexInt:&endSrcCode];
                    int rangeEntries = endSrcCode - beginSrcCode + 1;
                    if ([scanner scanString:@">[" intoString:NULL]) {
                        for (int j = 0; j < rangeEntries; j++) {
                            NSMutableString *destCharsString = [NSMutableString string];
                            [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                            [scanner scanUpToString:@">" intoString:&destCodesString];
                            for (int k = 0; k < [destCodesString length]; k+=4) {
                                NSUInteger hexInt;
                                NSScanner *hexScanner = [NSScanner scannerWithString:[destCodesString substringWithRange:NSMakeRange(k, 4)]];
                                if ([hexScanner scanHexInt:&hexInt]) {
                                    [destCharsString appendFormat:@"%C", hexInt];
                                }
                            }
                            if (destCharsString) [toUnicodeDict setObject:destCharsString forKey:[NSNumber numberWithInt:beginSrcCode+j]];
                        }
                    } else {
                        NSMutableString *destCharsString = [NSMutableString string];
                        [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL];
                        [scanner scanUpToString:@">" intoString:&destCodesString];
                        int k;
                        for (k = 0; k < [destCodesString length] - 4; k+=4) {
                            NSUInteger hexInt;
                            NSScanner *hexScanner = [NSScanner scannerWithString:[destCodesString substringWithRange:NSMakeRange(k, 4)]];
                            if ([hexScanner scanHexInt:&hexInt]) {
                                [destCharsString appendFormat:@"%C", hexInt];
                            }
                        }       
                        NSScanner *lastCharScanner = [NSScanner scannerWithString:[destCodesString substringWithRange:NSMakeRange(k, 4)]];
                        [lastCharScanner scanHexInt:&lastDestCode];
                        for (int j = 0; j < rangeEntries; j++) {
                            NSString *concatString = [NSString stringWithFormat:@"%@%C", destCharsString, lastDestCode+j];
                            if (concatString) [toUnicodeDict setObject:concatString forKey:[NSNumber numberWithInt:beginSrcCode+j]];
                        }
                    }
                }
            }
        }
        //NSLog(@"Font: %@, toUnicode: %@", baseFont, [font toUnicode]);
    }
    
    //NSLog(@"Adding font (%@): %@", baseFont, [uniqueFont description]);
    [[fonts dictionary] setObject:font forKey:uniqueFont];
    [font release];
    [pool drain];
}

@implementation BlioPDFFontList

@synthesize dictionary;

- (id)init {
    if ((self = [super init])) {
        self.dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.dictionary = nil;
    [super dealloc];
}
        

- (void)addFontsFromPage:(CGPDFPageRef)pageRef {
    CGPDFDictionaryRef dict, resources, pageFonts;
    
    dict = CGPDFPageGetDictionary(pageRef);
    if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
        return;
    if (!CGPDFDictionaryGetDictionary(resources, "Font", &pageFonts))
        return;
    CGPDFDictionaryApplyFunction(pageFonts, &parseFont, self);
}

@end

@implementation BlioPDFFont

static NSDictionary *blioStandardEncodingDict = nil;
static NSDictionary *blioWinAnsiEncodingDict = nil;
static NSDictionary *blioMacRomanEncodingDict = nil;
static NSDictionary *blioAdobeGlyphList = nil;

@synthesize key, baseFont, type, fontEncoding, glyphs, widths, toUnicode, charEncoding, notdef, missingWidth, spaceWidth;

- (id)initWithKey:(NSString *)fontKey {
    
    if ((self = [super init])) {
        self.key = fontKey;
        self.toUnicode = [NSMutableDictionary dictionaryWithCapacity:256];
        self.glyphs = [NSMutableDictionary dictionaryWithCapacity:256];
        self.widths = [NSMutableDictionary dictionaryWithCapacity:256];
        spaceWidth = 0;
    }
    
    return self;
}

- (void)dealloc {
    self.key = nil;
    self.baseFont = nil;
    self.type = nil;
    self.glyphs = nil;
    self.widths = nil;
    self.toUnicode = nil;
    self.charEncoding = nil;
    [super dealloc];
}

- (NSString *)stringForCharacterCode:(unichar)character withDecode:(unichar)decodedChar {
    NSNumber *lookup = [NSNumber numberWithInt:character];
    NSString *value = [toUnicode objectForKey:lookup];
    
    if (value)
        return value;

    //return @"";
    if (decodedChar)
        return [NSString stringWithFormat:@"%C", decodedChar];
    
    return nil;
}
//
//- (BOOL)isEqualToFont:(BlioPDFFont *)font {
//    return [key isEqualToString:[font key]];
//}



//- (void)makeGlyphArray {
//    NSEnumerator *enumerator = [self.glyphs objectEnumerator];
//    NSNumber *object;
//    
//    self.glyphLookup = [NSMutableDictionary dictionary];
//    
//    while ((object = [enumerator nextObject])) {
//        [self.glyphLookup setObject:]
//    }
//    
//    
//    
//    [self.glyphs arraySor
//    while ((key = [enumerator nextObject])) {
//        /* code that uses the returned key */
//        NSSet 
//    }
//}

//- (void)setGlyphLookup:(unichar)glyphCode atIndex:(NSUInteger)glyphIndex {
//    if (glyphIndex > 255) {
//        NSLog(@"Unexpectedly high glyphIndex (%d) for %C", glyphIndex, glyphCode);
//    } else {
//        //lookup[glyphIndex] = glyphCode;
//    }
//}

- (NSInteger)glyphWidthForCharacter:(unichar)character {
    NSNumber *glyphWidth = [widths objectForKey:[NSNumber numberWithInteger:character]];
    if (glyphWidth) {
        return [glyphWidth integerValue];
    } else {
        //NSLog(@"Warning: character not in widths: %C [%d]", character, character); // TODO take out
        return missingWidth;
    }
}

- (CGFloat)spaceWidth {
    if (spaceWidth == 0) {
        NSNumber *lookup = [NSNumber numberWithInt:32];
        NSNumber *encodedNum = [[charEncoding allKeysForObject:lookup] lastObject];
        NSNumber *spaceGlyphWidth = [widths objectForKey:encodedNum];
        if (spaceGlyphWidth)
            spaceWidth = [spaceGlyphWidth intValue]/1000.0f;
        else
            spaceWidth = -1;
    }
    return spaceWidth;
}

//- (CGSize)displacementForGlyph:(unichar)glyph {
//    if (glyph < 256) {
//        //NSInteger width = widths[glyph];
//        NSInteger width = [[widths objectForKey:[NSNumber numberWithInt:glyph]] intValue];
//        if (width == 0) {
//            // RENDER DEBUG NSLog(@"unichar not in widths: %C [%d]", glyph, glyph);
//            width = 300;
//        }
//        return CGSizeMake(width,300);
//    } else {
//        //NSLog(@"unichar outside bounds: %C [%d]", glyph, glyph);
//        return CGSizeMake(280,300);
//    }
//}

- (NSInteger)decodedCharacterForCharacter:(unichar)character {
    NSNumber *lookup = [NSNumber numberWithInt:character];
    NSNumber *decodedNum = [charEncoding objectForKey:lookup];
    
    if (decodedNum) {
        return [decodedNum integerValue];
    } else {
        //NSLog(@"Couldn't decode character: %d '%C'", character, character);
        return -1;
    }
}

- (void)createEncoding {
    self.charEncoding = [NSMutableDictionary dictionaryWithCapacity:256];
    NSEnumerator *enumerator = [glyphs keyEnumerator];
    NSString *glyphName;
    NSNumber *characterCode;
    
    while ((characterCode = [enumerator nextObject])) {
        glyphName = [glyphs objectForKey:characterCode];
        
        NSNumber *unicodeMapping = [blioAdobeGlyphList objectForKey:glyphName];
        if (nil != unicodeMapping) {
            [charEncoding setObject:unicodeMapping forKey:characterCode];
        } else if ([glyphName isEqualToString:@".notdef"]) {
            self.notdef = [characterCode integerValue];
        } else {
            NSLog(@"%@ is Missing glyph: '%@', setting to %@", baseFont, glyphName, [characterCode description]); // TODO take out
            //[charEncoding setObject:characterCode forKey:characterCode];
        }
    }
    //NSLog(@"Encoding:\n%@", [self.fromEncoding description]);
}

+ (void)initialize {
	if(self == [BlioPDFFont class]) {
		blioStandardEncodingDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"A", [NSNumber numberWithInt:0101],
                                     @"AE", [NSNumber numberWithInt:0341],
                                     @"B", [NSNumber numberWithInt:0102],
                                     @"C", [NSNumber numberWithInt:0103],
                                     @"D", [NSNumber numberWithInt:0104],
                                     @"E", [NSNumber numberWithInt:0105],
                                     @"F", [NSNumber numberWithInt:0106],
                                     @"G", [NSNumber numberWithInt:0107],
                                     @"H", [NSNumber numberWithInt:0110],
                                     @"I", [NSNumber numberWithInt:0111],
                                     @"J", [NSNumber numberWithInt:0112],
                                     @"K", [NSNumber numberWithInt:0113],
                                     @"L", [NSNumber numberWithInt:0114],
                                     @"Lslash", [NSNumber numberWithInt:0350],
                                     @"M", [NSNumber numberWithInt:0115],
                                     @"N", [NSNumber numberWithInt:0116],
                                     @"O", [NSNumber numberWithInt:0117],
                                     @"OE", [NSNumber numberWithInt:0352],
                                     @"Oslash", [NSNumber numberWithInt:0351],
                                     @"P", [NSNumber numberWithInt:0120],
                                     @"Q", [NSNumber numberWithInt:0121],
                                     @"R", [NSNumber numberWithInt:0122],
                                     @"S", [NSNumber numberWithInt:0123],
                                     @"T", [NSNumber numberWithInt:0124],
                                     @"U", [NSNumber numberWithInt:0125],
                                     @"V", [NSNumber numberWithInt:0126],
                                     @"W", [NSNumber numberWithInt:0127],
                                     @"X", [NSNumber numberWithInt:0130],
                                     @"Y", [NSNumber numberWithInt:0131],
                                     @"Z", [NSNumber numberWithInt:0132],
                                     @"a", [NSNumber numberWithInt:0141],
                                     @"acute", [NSNumber numberWithInt:0302],
                                     @"ae", [NSNumber numberWithInt:0361],
                                     @"ampersand", [NSNumber numberWithInt:046],
                                     @"asciicircum", [NSNumber numberWithInt:0136],
                                     @"asciitilde", [NSNumber numberWithInt:0176],
                                     @"asterisk", [NSNumber numberWithInt:052],
                                     @"at", [NSNumber numberWithInt:0100],
                                     @"b", [NSNumber numberWithInt:0142],
                                     @"backslash", [NSNumber numberWithInt:0134],
                                     @"bar", [NSNumber numberWithInt:0174],
                                     @"braceleft", [NSNumber numberWithInt:0173],
                                     @"braceright", [NSNumber numberWithInt:0175],
                                     @"bracketleft", [NSNumber numberWithInt:0133],
                                     @"bracketright", [NSNumber numberWithInt:0135],
                                     @"breve", [NSNumber numberWithInt:0306],
                                     @"bullet", [NSNumber numberWithInt:0267],
                                     @"c", [NSNumber numberWithInt:0143],
                                     @"caron", [NSNumber numberWithInt:0317],
                                     @"cedilla", [NSNumber numberWithInt:0313],
                                     @"cent", [NSNumber numberWithInt:0242],
                                     @"circumflex", [NSNumber numberWithInt:0303],
                                     @"colon", [NSNumber numberWithInt:072],
                                     @"comma", [NSNumber numberWithInt:054],
                                     @"currency", [NSNumber numberWithInt:0250],
                                     @"d", [NSNumber numberWithInt:0144],
                                     @"dagger", [NSNumber numberWithInt:0262],
                                     @"daggerdbl", [NSNumber numberWithInt:0263],
                                     @"dieresis", [NSNumber numberWithInt:0310],
                                     @"dollar", [NSNumber numberWithInt:044],
                                     @"dotaccent", [NSNumber numberWithInt:0307],
                                     @"dotlessi", [NSNumber numberWithInt:0365],
                                     @"e", [NSNumber numberWithInt:0145],
                                     @"eight", [NSNumber numberWithInt:070],
                                     @"ellipsis", [NSNumber numberWithInt:0274],
                                     @"emdash", [NSNumber numberWithInt:0320],
                                     @"endash", [NSNumber numberWithInt:0261],
                                     @"equal", [NSNumber numberWithInt:075],
                                     @"exclam", [NSNumber numberWithInt:041],
                                     @"exclamdown", [NSNumber numberWithInt:0241],
                                     @"f", [NSNumber numberWithInt:0146],
                                     @"fi", [NSNumber numberWithInt:0256],
                                     @"five", [NSNumber numberWithInt:065],
                                     @"fl", [NSNumber numberWithInt:0257],
                                     @"florin", [NSNumber numberWithInt:0246],
                                     @"four", [NSNumber numberWithInt:064],
                                     @"fraction", [NSNumber numberWithInt:0244],
                                     @"g", [NSNumber numberWithInt:0147],
                                     @"germandbls", [NSNumber numberWithInt:0373],
                                     @"grave", [NSNumber numberWithInt:0301],
                                     @"greater", [NSNumber numberWithInt:076],
                                     @"guillemotleft", [NSNumber numberWithInt:0253],
                                     @"guillemotright", [NSNumber numberWithInt:0273],
                                     @"guilsinglleft", [NSNumber numberWithInt:0254],
                                     @"guilsinglright", [NSNumber numberWithInt:0255],
                                     @"h", [NSNumber numberWithInt:0150],
                                     @"hungarumlaut", [NSNumber numberWithInt:0315],
                                     @"hyphen", [NSNumber numberWithInt:055],
                                     @"i", [NSNumber numberWithInt:0151],
                                     @"j", [NSNumber numberWithInt:0152],
                                     @"k", [NSNumber numberWithInt:0153],
                                     @"l", [NSNumber numberWithInt:0154],
                                     @"less", [NSNumber numberWithInt:074],
                                     @"lslash", [NSNumber numberWithInt:0370],
                                     @"m", [NSNumber numberWithInt:0155],
                                     @"macron", [NSNumber numberWithInt:0305],
                                     @"n", [NSNumber numberWithInt:0156],
                                     @"nine", [NSNumber numberWithInt:071],
                                     @"numbersign", [NSNumber numberWithInt:043],
                                     @"o", [NSNumber numberWithInt:0157],
                                     @"oe", [NSNumber numberWithInt:0372],
                                     @"ogonek", [NSNumber numberWithInt:0316],
                                     @"one", [NSNumber numberWithInt:061],
                                     @"ordfeminine", [NSNumber numberWithInt:0343],
                                     @"ordmasculine", [NSNumber numberWithInt:0353],
                                     @"oslash", [NSNumber numberWithInt:0371],
                                     @"p", [NSNumber numberWithInt:0160],
                                     @"paragraph", [NSNumber numberWithInt:0266],
                                     @"parenleft", [NSNumber numberWithInt:050],
                                     @"parenright", [NSNumber numberWithInt:051],
                                     @"percent", [NSNumber numberWithInt:045],
                                     @"period", [NSNumber numberWithInt:056],
                                     @"periodcentered", [NSNumber numberWithInt:0264],
                                     @"perthousand", [NSNumber numberWithInt:0275],
                                     @"plus", [NSNumber numberWithInt:053],
                                     @"q", [NSNumber numberWithInt:0161],
                                     @"question", [NSNumber numberWithInt:077],
                                     @"questiondown", [NSNumber numberWithInt:0277],
                                     @"quotedbl", [NSNumber numberWithInt:042],
                                     @"quotedblbase", [NSNumber numberWithInt:0271],
                                     @"quotedblleft", [NSNumber numberWithInt:0252],
                                     @"quotedblright", [NSNumber numberWithInt:0272],
                                     @"quoteleft", [NSNumber numberWithInt:0140],
                                     @"quoteright", [NSNumber numberWithInt:047],
                                     @"quotesinglbase", [NSNumber numberWithInt:0270],
                                     @"quotesingle", [NSNumber numberWithInt:0251],
                                     @"r", [NSNumber numberWithInt:0162],
                                     @"ring", [NSNumber numberWithInt:0312],
                                     @"s", [NSNumber numberWithInt:0163],
                                     @"section", [NSNumber numberWithInt:0247],
                                     @"semicolon", [NSNumber numberWithInt:073],
                                     @"seven", [NSNumber numberWithInt:067],
                                     @"six", [NSNumber numberWithInt:066],
                                     @"slash", [NSNumber numberWithInt:057],
                                     @"space", [NSNumber numberWithInt:040],
                                     @"sterling", [NSNumber numberWithInt:0243],
                                     @"t", [NSNumber numberWithInt:0164],
                                     @"three", [NSNumber numberWithInt:063],
                                     @"tilde", [NSNumber numberWithInt:0304],
                                     @"two", [NSNumber numberWithInt:062],
                                     @"u", [NSNumber numberWithInt:0165],
                                     @"underscore", [NSNumber numberWithInt:0137],
                                     @"v", [NSNumber numberWithInt:0166],
                                     @"w", [NSNumber numberWithInt:0167],
                                     @"x", [NSNumber numberWithInt:0170],
                                     @"y", [NSNumber numberWithInt:0171],
                                     @"yen", [NSNumber numberWithInt:0245],
                                     @"z", [NSNumber numberWithInt:0172],
                                     @"zero", [NSNumber numberWithInt:060],
                                     nil] retain];
        
        blioMacRomanEncodingDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"A", [NSNumber numberWithInt:0101],
                                     @"AE", [NSNumber numberWithInt:0256],
                                     @"Aacute", [NSNumber numberWithInt:0347],
                                     @"Acircumflex", [NSNumber numberWithInt:0345],
                                     @"Adieresis", [NSNumber numberWithInt:0200],
                                     @"Agrave", [NSNumber numberWithInt:0313],
                                     @"Aring", [NSNumber numberWithInt:0201],
                                     @"Atilde", [NSNumber numberWithInt:0314],
                                     @"B", [NSNumber numberWithInt:0102],
                                     @"C", [NSNumber numberWithInt:0103],
                                     @"Ccedilla", [NSNumber numberWithInt:0202],
                                     @"D", [NSNumber numberWithInt:0104],
                                     @"E", [NSNumber numberWithInt:0105],
                                     @"Eacute", [NSNumber numberWithInt:0203],  
                                     @"Ecircumflex",[NSNumber numberWithInt:0346], 
                                     @"Edieresis",[NSNumber numberWithInt:0350],  
                                     @"Egrave", [NSNumber numberWithInt:0351], 
                                     @"F", [NSNumber numberWithInt:0106],
                                     @"G", [NSNumber numberWithInt:0107],
                                     @"H", [NSNumber numberWithInt:0110],
                                     @"I", [NSNumber numberWithInt:0111],
                                     @"Iacute", [NSNumber numberWithInt:0352],
                                     @"Icircumflex", [NSNumber numberWithInt:0353],
                                     @"Idieresis", [NSNumber numberWithInt:0354],
                                     @"Igrave", [NSNumber numberWithInt:0355],
                                     @"J", [NSNumber numberWithInt:0112],
                                     @"K", [NSNumber numberWithInt:0113],
                                     @"L", [NSNumber numberWithInt:0114],
                                     @"M", [NSNumber numberWithInt:0115],
                                     @"N", [NSNumber numberWithInt:0116],
                                     @"Ntilde", [NSNumber numberWithInt:0204],
                                     @"O", [NSNumber numberWithInt:0117],
                                     @"OE", [NSNumber numberWithInt:0316],
                                     @"Oacute", [NSNumber numberWithInt:0356],
                                     @"Ocircumflex", [NSNumber numberWithInt:0357],
                                     @"Odieresis", [NSNumber numberWithInt:0205],
                                     @"Ograve", [NSNumber numberWithInt:0361],
                                     @"Oslash", [NSNumber numberWithInt:0257],
                                     @"Otilde", [NSNumber numberWithInt:0315],
                                     @"P", [NSNumber numberWithInt:0120],
                                     @"Q", [NSNumber numberWithInt:0121],
                                     @"R", [NSNumber numberWithInt:0122],
                                     @"S", [NSNumber numberWithInt:0123],
                                     @"T", [NSNumber numberWithInt:0124],
                                     @"U", [NSNumber numberWithInt:0125],
                                     @"Uacute", [NSNumber numberWithInt:0362],
                                     @"Ucircumflex", [NSNumber numberWithInt:0363],
                                     @"Udieresis", [NSNumber numberWithInt:0206],
                                     @"Ugrave", [NSNumber numberWithInt:0364],
                                     @"V", [NSNumber numberWithInt:0126],
                                     @"W", [NSNumber numberWithInt:0127],
                                     @"X", [NSNumber numberWithInt:0130],
                                     @"Y", [NSNumber numberWithInt:0131],
                                     @"Ydieresis", [NSNumber numberWithInt:0331],
                                     @"Z", [NSNumber numberWithInt:0132],
                                     @"a", [NSNumber numberWithInt:0141],
                                     @"aacute", [NSNumber numberWithInt:0207],
                                     @"acircumflex", [NSNumber numberWithInt:0211],
                                     @"acute", [NSNumber numberWithInt:0253],
                                     @"adieresis", [NSNumber numberWithInt:0212],
                                     @"ae", [NSNumber numberWithInt:0276],
                                     @"agrave", [NSNumber numberWithInt:0210],
                                     @"ampersand", [NSNumber numberWithInt:046],
                                     @"aring", [NSNumber numberWithInt:0214],
                                     @"asciicircum", [NSNumber numberWithInt:0136],
                                     @"asciitilde", [NSNumber numberWithInt:0176],
                                     @"asterisk", [NSNumber numberWithInt:052],
                                     @"at", [NSNumber numberWithInt:0100],
                                     @"atilde", [NSNumber numberWithInt:0213],
                                     @"b", [NSNumber numberWithInt:0142],
                                     @"backslash", [NSNumber numberWithInt:0134],
                                     @"bar", [NSNumber numberWithInt:0174],
                                     @"braceleft", [NSNumber numberWithInt:0173],
                                     @"braceright", [NSNumber numberWithInt:0175],
                                     @"bracketleft", [NSNumber numberWithInt:0133],
                                     @"bracketright", [NSNumber numberWithInt:0135],
                                     @"breve", [NSNumber numberWithInt:0371],
                                     @"brokenbar", [NSNumber numberWithInt:0],
                                     @"bullet", [NSNumber numberWithInt:0245],
                                     @"c", [NSNumber numberWithInt:0143],
                                     @"caron", [NSNumber numberWithInt:0377],
                                     @"ccedilla", [NSNumber numberWithInt:0215],
                                     @"cedilla", [NSNumber numberWithInt:0374],
                                     @"cent", [NSNumber numberWithInt:0242],
                                     @"circumflex", [NSNumber numberWithInt:0366],
                                     @"colon", [NSNumber numberWithInt:072],
                                     @"comma", [NSNumber numberWithInt:054],
                                     @"copyright", [NSNumber numberWithInt:0251],
                                     @"currency", [NSNumber numberWithInt:0333],
                                     @"d", [NSNumber numberWithInt:0144],
                                     @"dagger", [NSNumber numberWithInt:0240],
                                     @"daggerdbl", [NSNumber numberWithInt:0340],
                                     @"degree", [NSNumber numberWithInt:0241],
                                     @"dieresis", [NSNumber numberWithInt:0254],
                                     @"divide", [NSNumber numberWithInt:0326],
                                     @"dollar", [NSNumber numberWithInt:044],
                                     @"dotaccent", [NSNumber numberWithInt:0372],
                                     @"dotlessi", [NSNumber numberWithInt:0365],
                                     @"e", [NSNumber numberWithInt:0145],
                                     @"eacute", [NSNumber numberWithInt:0216],
                                     @"ecircumflex", [NSNumber numberWithInt:0220],
                                     @"edieresis", [NSNumber numberWithInt:0221],
                                     @"egrave", [NSNumber numberWithInt:0217],
                                     @"eight", [NSNumber numberWithInt:070],
                                     @"ellipsis", [NSNumber numberWithInt:0311],
                                     @"emdash", [NSNumber numberWithInt:0321],
                                     @"endash", [NSNumber numberWithInt:0320],
                                     @"equal", [NSNumber numberWithInt:075],
                                     @"exclam", [NSNumber numberWithInt:041],
                                     @"exclamdown", [NSNumber numberWithInt:0301],
                                     @"f", [NSNumber numberWithInt:0146],
                                     @"fi", [NSNumber numberWithInt:0336],
                                     @"five", [NSNumber numberWithInt:065],
                                     @"fl", [NSNumber numberWithInt:0337],
                                     @"florin", [NSNumber numberWithInt:0304],
                                     @"four", [NSNumber numberWithInt:064],
                                     @"fraction", [NSNumber numberWithInt:0332],
                                     @"g", [NSNumber numberWithInt:0147],
                                     @"germandbls", [NSNumber numberWithInt:0247],
                                     @"grave", [NSNumber numberWithInt:0140],
                                     @"greater", [NSNumber numberWithInt:076],
                                     @"guillemotleft", [NSNumber numberWithInt:0307],
                                     @"guillemotright", [NSNumber numberWithInt:0310],
                                     @"guilsinglleft", [NSNumber numberWithInt:0334],
                                     @"guilsinglright", [NSNumber numberWithInt:0335],
                                     @"h", [NSNumber numberWithInt:0150],
                                     @"hungarumlaut", [NSNumber numberWithInt:0375],
                                     @"hyphen", [NSNumber numberWithInt:055],
                                     @"i", [NSNumber numberWithInt:0151],
                                     @"iacute", [NSNumber numberWithInt:0222],
                                     @"icircumflex", [NSNumber numberWithInt:0224],
                                     @"idieresis", [NSNumber numberWithInt:0225],
                                     @"igrave", [NSNumber numberWithInt:0223],
                                     @"j", [NSNumber numberWithInt:0152],
                                     @"k", [NSNumber numberWithInt:0153],
                                     @"l", [NSNumber numberWithInt:0154],
                                     @"less", [NSNumber numberWithInt:074],
                                     @"logicalnot", [NSNumber numberWithInt:0302],
                                     @"m", [NSNumber numberWithInt:0155],
                                     @"macron", [NSNumber numberWithInt:0370],
                                     @"mu", [NSNumber numberWithInt:0265],
                                     @"n", [NSNumber numberWithInt:0156],
                                     @"nine", [NSNumber numberWithInt:071],
                                     @"ntilde", [NSNumber numberWithInt:0226],
                                     @"numbersign", [NSNumber numberWithInt:043],
                                     @"o", [NSNumber numberWithInt:0157],
                                     @"oacute", [NSNumber numberWithInt:0227],
                                     @"ocircumflex", [NSNumber numberWithInt:0231],
                                     @"odieresis", [NSNumber numberWithInt:0232],
                                     @"oe", [NSNumber numberWithInt:0317],
                                     @"ogonek", [NSNumber numberWithInt:0376],
                                     @"ograve", [NSNumber numberWithInt:0230],
                                     @"one", [NSNumber numberWithInt:061],
                                     @"ordfeminine", [NSNumber numberWithInt:0273],
                                     @"ordmasculine", [NSNumber numberWithInt:0274],
                                     @"oslash", [NSNumber numberWithInt:0277],
                                     @"otilde", [NSNumber numberWithInt:0233],
                                     @"p", [NSNumber numberWithInt:0160],
                                     @"paragraph", [NSNumber numberWithInt:0246],
                                     @"parenleft", [NSNumber numberWithInt:050],
                                     @"parenright", [NSNumber numberWithInt:051],
                                     @"percent", [NSNumber numberWithInt:045],
                                     @"period", [NSNumber numberWithInt:056],
                                     @"periodcentered", [NSNumber numberWithInt:0341],
                                     @"perthousand", [NSNumber numberWithInt:0344],
                                     @"plus", [NSNumber numberWithInt:053],
                                     @"plusminus", [NSNumber numberWithInt:0261],
                                     @"q", [NSNumber numberWithInt:0161],
                                     @"question", [NSNumber numberWithInt:077],
                                     @"questiondown", [NSNumber numberWithInt:0300],
                                     @"quotedbl", [NSNumber numberWithInt:042],
                                     @"quotedblbase", [NSNumber numberWithInt:0343],
                                     @"quotedblleft", [NSNumber numberWithInt:0322],
                                     @"quotedblright", [NSNumber numberWithInt:0323],
                                     @"quoteleft", [NSNumber numberWithInt:0324],
                                     @"quoteright", [NSNumber numberWithInt:0325],
                                     @"quotesinglbase", [NSNumber numberWithInt:0342],
                                     @"quotesingle", [NSNumber numberWithInt:047],
                                     @"r", [NSNumber numberWithInt:0162],
                                     @"registered", [NSNumber numberWithInt:0250],
                                     @"ring", [NSNumber numberWithInt:0373],
                                     @"s", [NSNumber numberWithInt:0163],
                                     @"section", [NSNumber numberWithInt:0244],
                                     @"semicolon", [NSNumber numberWithInt:073],
                                     @"seven", [NSNumber numberWithInt:067],
                                     @"six", [NSNumber numberWithInt:066],
                                     @"slash", [NSNumber numberWithInt:057],
                                     @"space", [NSNumber numberWithInt:040],
                                     @"space", [NSNumber numberWithInt:312],
                                     @"sterling", [NSNumber numberWithInt:0243],
                                     @"t", [NSNumber numberWithInt:0164],
                                     @"three", [NSNumber numberWithInt:063],
                                     @"tilde", [NSNumber numberWithInt:0367],
                                     @"trademark", [NSNumber numberWithInt:0252],
                                     @"two", [NSNumber numberWithInt:062],
                                     @"u", [NSNumber numberWithInt:0165],
                                     @"uacute", [NSNumber numberWithInt:0234],
                                     @"ucircumflex", [NSNumber numberWithInt:0236],
                                     @"udieresis", [NSNumber numberWithInt:0237],
                                     @"ugrave", [NSNumber numberWithInt:0235],
                                     @"underscore", [NSNumber numberWithInt:0137],
                                     @"v", [NSNumber numberWithInt:0166],
                                     @"w", [NSNumber numberWithInt:0167],
                                     @"x", [NSNumber numberWithInt:0170],
                                     @"y", [NSNumber numberWithInt:0171],
                                     @"ydieresis", [NSNumber numberWithInt:0330],
                                     @"yen", [NSNumber numberWithInt:0264],
                                     @"z", [NSNumber numberWithInt:0172],
                                     @"zero", [NSNumber numberWithInt:060],
                                     nil] retain];        
                
        blioWinAnsiEncodingDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"A", [NSNumber numberWithInt:0101],
                                    @"AE", [NSNumber numberWithInt:0306],
                                    @"Aacute", [NSNumber numberWithInt:0301],
                                    @"Acircumflex", [NSNumber numberWithInt:0302],
                                    @"Adieresis", [NSNumber numberWithInt:0304],
                                    @"Agrave", [NSNumber numberWithInt:0300],
                                    @"Aring", [NSNumber numberWithInt:0305],
                                    @"Atilde", [NSNumber numberWithInt:0303],
                                    @"B", [NSNumber numberWithInt:0102],
                                    @"C", [NSNumber numberWithInt:0103],
                                    @"Ccedilla", [NSNumber numberWithInt:0307],
                                    @"D", [NSNumber numberWithInt:0104],
                                    @"E", [NSNumber numberWithInt:0105],
                                    @"Eacute",[NSNumber numberWithInt:0311],  
                                    @"Ecircumflex", [NSNumber numberWithInt:0312],  
                                    @"Edieresis", [NSNumber numberWithInt:0313],  
                                    @"Egrave", [NSNumber numberWithInt:0310], 
                                    @"Eth", [NSNumber numberWithInt:0320], 
                                    @"Euro", [NSNumber numberWithInt:0200], 
                                    @"F", [NSNumber numberWithInt:0106],
                                    @"G", [NSNumber numberWithInt:0107],
                                    @"H", [NSNumber numberWithInt:0110],
                                    @"I", [NSNumber numberWithInt:0111],
                                    @"Iacute", [NSNumber numberWithInt:0315],
                                    @"Icircumflex", [NSNumber numberWithInt:0316],
                                    @"Idieresis", [NSNumber numberWithInt:0317],
                                    @"Igrave", [NSNumber numberWithInt:0314],
                                    @"J", [NSNumber numberWithInt:0112],
                                    @"K", [NSNumber numberWithInt:0113],
                                    @"L", [NSNumber numberWithInt:0114],
                                    @"M", [NSNumber numberWithInt:0115],
                                    @"N", [NSNumber numberWithInt:0116],
                                    @"Ntilde", [NSNumber numberWithInt:0321],
                                    @"O", [NSNumber numberWithInt:0117],
                                    @"OE", [NSNumber numberWithInt:0214],
                                    @"Oacute", [NSNumber numberWithInt:0323],
                                    @"Ocircumflex", [NSNumber numberWithInt:0324],
                                    @"Odieresis", [NSNumber numberWithInt:0326],
                                    @"Ograve", [NSNumber numberWithInt:0322],
                                    @"Oslash", [NSNumber numberWithInt:0330],
                                    @"Otilde", [NSNumber numberWithInt:0325],
                                    @"P", [NSNumber numberWithInt:0120],
                                    @"Q", [NSNumber numberWithInt:0121],
                                    @"R", [NSNumber numberWithInt:0122],
                                    @"S", [NSNumber numberWithInt:0123],
                                    @"Scaron", [NSNumber numberWithInt:0212],
                                    @"T", [NSNumber numberWithInt:0124],
                                    @"Thorn", [NSNumber numberWithInt:0336],
                                    @"U", [NSNumber numberWithInt:0125],
                                    @"Uacute", [NSNumber numberWithInt:0332],
                                    @"Ucircumflex", [NSNumber numberWithInt:0333],
                                    @"Udieresis", [NSNumber numberWithInt:0334],
                                    @"Ugrave", [NSNumber numberWithInt:0331],
                                    @"V", [NSNumber numberWithInt:0126],
                                    @"W", [NSNumber numberWithInt:0127],
                                    @"X", [NSNumber numberWithInt:0130],
                                    @"Y", [NSNumber numberWithInt:0131],
                                    @"Yacute", [NSNumber numberWithInt:0335],
                                    @"Ydieresis", [NSNumber numberWithInt:0237],
                                    @"Z", [NSNumber numberWithInt:0132],
                                    @"Zcaron", [NSNumber numberWithInt:0216],
                                    @"a", [NSNumber numberWithInt:0141],
                                    @"aacute", [NSNumber numberWithInt:0341],
                                    @"acircumflex", [NSNumber numberWithInt:0341],
                                    @"acute", [NSNumber numberWithInt:0264],
                                    @"adieresis", [NSNumber numberWithInt:0344],
                                    @"ae", [NSNumber numberWithInt:0346],
                                    @"agrave", [NSNumber numberWithInt:0340],
                                    @"ampersand", [NSNumber numberWithInt:046],
                                    @"aring", [NSNumber numberWithInt:0345],
                                    @"asciicircum", [NSNumber numberWithInt:0136],
                                    @"asciitilde", [NSNumber numberWithInt:0176],
                                    @"asterisk", [NSNumber numberWithInt:052],
                                    @"at", [NSNumber numberWithInt:0100],
                                    @"atilde", [NSNumber numberWithInt:0343],
                                    @"b", [NSNumber numberWithInt:0142],
                                    @"backslash", [NSNumber numberWithInt:0134],
                                    @"bar", [NSNumber numberWithInt:0174],
                                    @"braceleft", [NSNumber numberWithInt:0173],
                                    @"braceright", [NSNumber numberWithInt:0175],
                                    @"bracketleft", [NSNumber numberWithInt:0133],
                                    @"bracketright", [NSNumber numberWithInt:0135],
                                    @"brokenbar", [NSNumber numberWithInt:0246],
                                    @"bullet", [NSNumber numberWithInt:0225],
                                    @"c", [NSNumber numberWithInt:0143],
                                    @"ccedilla", [NSNumber numberWithInt:0347],
                                    @"cedilla", [NSNumber numberWithInt:0270],
                                    @"cent", [NSNumber numberWithInt:0242],
                                    @"circumflex", [NSNumber numberWithInt:0210],
                                    @"colon", [NSNumber numberWithInt:072],
                                    @"comma", [NSNumber numberWithInt:054],
                                    @"copyright", [NSNumber numberWithInt:0251],
                                    @"currency", [NSNumber numberWithInt:0244],
                                    @"d", [NSNumber numberWithInt:0144],
                                    @"dagger", [NSNumber numberWithInt:0206],
                                    @"daggerdbl", [NSNumber numberWithInt:0207],
                                    @"degree", [NSNumber numberWithInt:0260],
                                    @"dieresis", [NSNumber numberWithInt:0250],
                                    @"divide", [NSNumber numberWithInt:0367],
                                    @"dollar", [NSNumber numberWithInt:044],
                                    @"e", [NSNumber numberWithInt:0145],
                                    @"eacute", [NSNumber numberWithInt:0351],
                                    @"ecircumflex", [NSNumber numberWithInt:0352],
                                    @"edieresis", [NSNumber numberWithInt:0353],
                                    @"egrave", [NSNumber numberWithInt:0350],
                                    @"eight", [NSNumber numberWithInt:070],
                                    @"ellipsis", [NSNumber numberWithInt:0205],
                                    @"emdash", [NSNumber numberWithInt:0227],
                                    @"endash", [NSNumber numberWithInt:0226],
                                    @"equal", [NSNumber numberWithInt:075],
                                    @"eth", [NSNumber numberWithInt:0360],
                                    @"exclam", [NSNumber numberWithInt:041],
                                    @"exclamdown", [NSNumber numberWithInt:0241],
                                    @"f", [NSNumber numberWithInt:0146],
                                    @"five", [NSNumber numberWithInt:065],
                                    @"florin", [NSNumber numberWithInt:0203],
                                    @"four", [NSNumber numberWithInt:064],
                                    @"g", [NSNumber numberWithInt:0147],
                                    @"germandbls", [NSNumber numberWithInt:0337],
                                    @"grave", [NSNumber numberWithInt:0140],
                                    @"greater", [NSNumber numberWithInt:076],
                                    @"guillemotleft", [NSNumber numberWithInt:0253],
                                    @"guillemotright", [NSNumber numberWithInt:0273],
                                    @"guilsinglleft", [NSNumber numberWithInt:0213],
                                    @"guilsinglright", [NSNumber numberWithInt:0233],
                                    @"h", [NSNumber numberWithInt:0150],
                                    @"hyphen", [NSNumber numberWithInt:055],
                                    @"i", [NSNumber numberWithInt:0151],
                                    @"iacute", [NSNumber numberWithInt:0355],
                                    @"icircumflex", [NSNumber numberWithInt:0356],
                                    @"idieresis", [NSNumber numberWithInt:0357],
                                    @"igrave", [NSNumber numberWithInt:0354],
                                    @"j", [NSNumber numberWithInt:0152],
                                    @"k", [NSNumber numberWithInt:0153],
                                    @"l", [NSNumber numberWithInt:0154],
                                    @"less", [NSNumber numberWithInt:074],
                                    @"logicalnot", [NSNumber numberWithInt:0254],
                                    @"m", [NSNumber numberWithInt:0155],
                                    @"macron", [NSNumber numberWithInt:0257],
                                    @"mu", [NSNumber numberWithInt:0265],
                                    @"multiply", [NSNumber numberWithInt:0327],
                                    @"n", [NSNumber numberWithInt:0156],
                                    @"nine", [NSNumber numberWithInt:071],
                                    @"ntilde", [NSNumber numberWithInt:0361],
                                    @"numbersign", [NSNumber numberWithInt:043],
                                    @"o", [NSNumber numberWithInt:0157],
                                    @"oacute", [NSNumber numberWithInt:0363],
                                    @"ocircumflex", [NSNumber numberWithInt:0364],
                                    @"odieresis", [NSNumber numberWithInt:0366],
                                    @"oe", [NSNumber numberWithInt:0234],
                                    @"ograve", [NSNumber numberWithInt:0362],
                                    @"one", [NSNumber numberWithInt:061],
                                    @"onehalf", [NSNumber numberWithInt:0275],
                                    @"onequarter", [NSNumber numberWithInt:0274],
                                    @"onesuperior", [NSNumber numberWithInt:0271],
                                    @"ordfeminine", [NSNumber numberWithInt:0252],
                                    @"ordmasculine", [NSNumber numberWithInt:0272],
                                    @"oslash", [NSNumber numberWithInt:0370],
                                    @"otilde", [NSNumber numberWithInt:0365],
                                    @"p", [NSNumber numberWithInt:0160],
                                    @"paragraph", [NSNumber numberWithInt:0266],
                                    @"parenleft", [NSNumber numberWithInt:050],
                                    @"parenright", [NSNumber numberWithInt:051],
                                    @"percent", [NSNumber numberWithInt:045],
                                    @"period", [NSNumber numberWithInt:056],
                                    @"periodcentered", [NSNumber numberWithInt:0267],
                                    @"perthousand", [NSNumber numberWithInt:0211],
                                    @"plus", [NSNumber numberWithInt:053],
                                    @"plusminus", [NSNumber numberWithInt:0261],
                                    @"q", [NSNumber numberWithInt:0161],
                                    @"question", [NSNumber numberWithInt:077],
                                    @"questiondown", [NSNumber numberWithInt:0277],
                                    @"quotedbl", [NSNumber numberWithInt:042],
                                    @"quotedblbase", [NSNumber numberWithInt:0204],
                                    @"quotedblleft", [NSNumber numberWithInt:0223],
                                    @"quotedblright", [NSNumber numberWithInt:0224],
                                    @"quoteleft", [NSNumber numberWithInt:0221],
                                    @"quoteright", [NSNumber numberWithInt:0222],
                                    @"quotesinglbase", [NSNumber numberWithInt:0202],
                                    @"quotesingle", [NSNumber numberWithInt:047],
                                    @"r", [NSNumber numberWithInt:0162],
                                    @"registered", [NSNumber numberWithInt:0256],
                                    @"s", [NSNumber numberWithInt:0163],
                                    @"scaron", [NSNumber numberWithInt:0232],
                                    @"section", [NSNumber numberWithInt:0247],
                                    @"semicolon", [NSNumber numberWithInt:073],
                                    @"seven", [NSNumber numberWithInt:067],
                                    @"six", [NSNumber numberWithInt:066],
                                    @"slash", [NSNumber numberWithInt:057],
                                    @"space", [NSNumber numberWithInt:040],
                                    @"sterling", [NSNumber numberWithInt:0243],
                                    @"t", [NSNumber numberWithInt:0164],
                                    @"thorn", [NSNumber numberWithInt:0376],
                                    @"three", [NSNumber numberWithInt:063],
                                    @"threequarters", [NSNumber numberWithInt:0276],
                                    @"threesuperior", [NSNumber numberWithInt:0263],
                                    @"tilde", [NSNumber numberWithInt:0230],
                                    @"trademark", [NSNumber numberWithInt:0231],
                                    @"two", [NSNumber numberWithInt:062],
                                    @"twosuperior", [NSNumber numberWithInt:0262],
                                    @"u", [NSNumber numberWithInt:0165],
                                    @"uacute", [NSNumber numberWithInt:0372],
                                    @"ucircumflex", [NSNumber numberWithInt:0373],
                                    @"udieresis", [NSNumber numberWithInt:0374],
                                    @"ugrave", [NSNumber numberWithInt:0371],
                                    @"underscore", [NSNumber numberWithInt:0137],
                                    @"v", [NSNumber numberWithInt:0166],
                                    @"w", [NSNumber numberWithInt:0167],
                                    @"x", [NSNumber numberWithInt:0170],
                                    @"y", [NSNumber numberWithInt:0171],
                                    @"yacute", [NSNumber numberWithInt:0375],
                                    @"ydieresis", [NSNumber numberWithInt:0377],
                                    @"yen", [NSNumber numberWithInt:0245],
                                    @"z", [NSNumber numberWithInt:0172],
                                    @"zcaron", [NSNumber numberWithInt:0236],
                                    @"zero", [NSNumber numberWithInt:060],
                                    nil] retain];        
        
        blioAdobeGlyphList = [[NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt:0x0041], @"A",
                               [NSNumber numberWithInt:0x00C6], @"AE",
                               [NSNumber numberWithInt:0x01FC], @"AEacute",
                               [NSNumber numberWithInt:0x01E2], @"AEmacron",
                               [NSNumber numberWithInt:0xF7E6], @"AEsmall",
                               [NSNumber numberWithInt:0x00C1], @"Aacute",
                               [NSNumber numberWithInt:0xF7E1], @"Aacutesmall",
                               [NSNumber numberWithInt:0x0102], @"Abreve",
                               [NSNumber numberWithInt:0x1EAE], @"Abreveacute",
                               [NSNumber numberWithInt:0x04D0], @"Abrevecyrillic",
                               [NSNumber numberWithInt:0x1EB6], @"Abrevedotbelow",
                               [NSNumber numberWithInt:0x1EB0], @"Abrevegrave",
                               [NSNumber numberWithInt:0x1EB2], @"Abrevehookabove",
                               [NSNumber numberWithInt:0x1EB4], @"Abrevetilde",
                               [NSNumber numberWithInt:0x01CD], @"Acaron",
                               [NSNumber numberWithInt:0x24B6], @"Acircle",
                               [NSNumber numberWithInt:0x00C2], @"Acircumflex",
                               [NSNumber numberWithInt:0x1EA4], @"Acircumflexacute",
                               [NSNumber numberWithInt:0x1EAC], @"Acircumflexdotbelow",
                               [NSNumber numberWithInt:0x1EA6], @"Acircumflexgrave",
                               [NSNumber numberWithInt:0x1EA8], @"Acircumflexhookabove",
                               [NSNumber numberWithInt:0xF7E2], @"Acircumflexsmall",
                               [NSNumber numberWithInt:0x1EAA], @"Acircumflextilde",
                               [NSNumber numberWithInt:0xF6C9], @"Acute",
                               [NSNumber numberWithInt:0xF7B4], @"Acutesmall",
                               [NSNumber numberWithInt:0x0410], @"Acyrillic",
                               [NSNumber numberWithInt:0x0200], @"Adblgrave",
                               [NSNumber numberWithInt:0x00C4], @"Adieresis",
                               [NSNumber numberWithInt:0x04D2], @"Adieresiscyrillic",
                               [NSNumber numberWithInt:0x01DE], @"Adieresismacron",
                               [NSNumber numberWithInt:0xF7E4], @"Adieresissmall",
                               [NSNumber numberWithInt:0x1EA0], @"Adotbelow",
                               [NSNumber numberWithInt:0x01E0], @"Adotmacron",
                               [NSNumber numberWithInt:0x00C0], @"Agrave",
                               [NSNumber numberWithInt:0xF7E0], @"Agravesmall",
                               [NSNumber numberWithInt:0x1EA2], @"Ahookabove",
                               [NSNumber numberWithInt:0x04D4], @"Aiecyrillic",
                               [NSNumber numberWithInt:0x0202], @"Ainvertedbreve",
                               [NSNumber numberWithInt:0x0391], @"Alpha",
                               [NSNumber numberWithInt:0x0386], @"Alphatonos",
                               [NSNumber numberWithInt:0x0100], @"Amacron",
                               [NSNumber numberWithInt:0xFF21], @"Amonospace",
                               [NSNumber numberWithInt:0x0104], @"Aogonek",
                               [NSNumber numberWithInt:0x00C5], @"Aring",
                               [NSNumber numberWithInt:0x01FA], @"Aringacute",
                               [NSNumber numberWithInt:0x1E00], @"Aringbelow",
                               [NSNumber numberWithInt:0xF7E5], @"Aringsmall",
                               [NSNumber numberWithInt:0xF761], @"Asmall",
                               [NSNumber numberWithInt:0x00C3], @"Atilde",
                               [NSNumber numberWithInt:0xF7E3], @"Atildesmall",
                               [NSNumber numberWithInt:0x0531], @"Aybarmenian",
                               [NSNumber numberWithInt:0x0042], @"B",
                               [NSNumber numberWithInt:0x24B7], @"Bcircle",
                               [NSNumber numberWithInt:0x1E02], @"Bdotaccent",
                               [NSNumber numberWithInt:0x1E04], @"Bdotbelow",
                               [NSNumber numberWithInt:0x0411], @"Becyrillic",
                               [NSNumber numberWithInt:0x0532], @"Benarmenian",
                               [NSNumber numberWithInt:0x0392], @"Beta",
                               [NSNumber numberWithInt:0x0181], @"Bhook",
                               [NSNumber numberWithInt:0x1E06], @"Blinebelow",
                               [NSNumber numberWithInt:0xFF22], @"Bmonospace",
                               [NSNumber numberWithInt:0xF6F4], @"Brevesmall",
                               [NSNumber numberWithInt:0xF762], @"Bsmall",
                               [NSNumber numberWithInt:0x0182], @"Btopbar",
                               [NSNumber numberWithInt:0x0043], @"C",
                               [NSNumber numberWithInt:0x053E], @"Caarmenian",
                               [NSNumber numberWithInt:0x0106], @"Cacute",
                               [NSNumber numberWithInt:0xF6CA], @"Caron",
                               [NSNumber numberWithInt:0xF6F5], @"Caronsmall",
                               [NSNumber numberWithInt:0x010C], @"Ccaron",
                               [NSNumber numberWithInt:0x00C7], @"Ccedilla",
                               [NSNumber numberWithInt:0x1E08], @"Ccedillaacute",
                               [NSNumber numberWithInt:0xF7E7], @"Ccedillasmall",
                               [NSNumber numberWithInt:0x24B8], @"Ccircle",
                               [NSNumber numberWithInt:0x0108], @"Ccircumflex",
                               [NSNumber numberWithInt:0x010A], @"Cdot",
                               [NSNumber numberWithInt:0x010A], @"Cdotaccent",
                               [NSNumber numberWithInt:0xF7B8], @"Cedillasmall",
                               [NSNumber numberWithInt:0x0549], @"Chaarmenian",
                               [NSNumber numberWithInt:0x04BC], @"Cheabkhasiancyrillic",
                               [NSNumber numberWithInt:0x0427], @"Checyrillic",
                               [NSNumber numberWithInt:0x04BE], @"Chedescenderabkhasiancyrillic",
                               [NSNumber numberWithInt:0x04B6], @"Chedescendercyrillic",
                               [NSNumber numberWithInt:0x04F4], @"Chedieresiscyrillic",
                               [NSNumber numberWithInt:0x0543], @"Cheharmenian",
                               [NSNumber numberWithInt:0x04CB], @"Chekhakassiancyrillic",
                               [NSNumber numberWithInt:0x04B8], @"Cheverticalstrokecyrillic",
                               [NSNumber numberWithInt:0x03A7], @"Chi",
                               [NSNumber numberWithInt:0x0187], @"Chook",
                               [NSNumber numberWithInt:0xF6F6], @"Circumflexsmall",
                               [NSNumber numberWithInt:0xFF23], @"Cmonospace",
                               [NSNumber numberWithInt:0x0551], @"Coarmenian",
                               [NSNumber numberWithInt:0xF763], @"Csmall",
                               [NSNumber numberWithInt:0x0044], @"D",
                               [NSNumber numberWithInt:0x01F1], @"DZ",
                               [NSNumber numberWithInt:0x01C4], @"DZcaron",
                               [NSNumber numberWithInt:0x0534], @"Daarmenian",
                               [NSNumber numberWithInt:0x0189], @"Dafrican",
                               [NSNumber numberWithInt:0x010E], @"Dcaron",
                               [NSNumber numberWithInt:0x1E10], @"Dcedilla",
                               [NSNumber numberWithInt:0x24B9], @"Dcircle",
                               [NSNumber numberWithInt:0x1E12], @"Dcircumflexbelow",
                               [NSNumber numberWithInt:0x0110], @"Dcroat",
                               [NSNumber numberWithInt:0x1E0A], @"Ddotaccent",
                               [NSNumber numberWithInt:0x1E0C], @"Ddotbelow",
                               [NSNumber numberWithInt:0x0414], @"Decyrillic",
                               [NSNumber numberWithInt:0x03EE], @"Deicoptic",
                               [NSNumber numberWithInt:0x2206], @"Delta",
                               [NSNumber numberWithInt:0x0394], @"Deltagreek",
                               [NSNumber numberWithInt:0x018A], @"Dhook",
                               [NSNumber numberWithInt:0xF6CB], @"Dieresis",
                               [NSNumber numberWithInt:0xF6CC], @"DieresisAcute",
                               [NSNumber numberWithInt:0xF6CD], @"DieresisGrave",
                               [NSNumber numberWithInt:0xF7A8], @"Dieresissmall",
                               [NSNumber numberWithInt:0x03DC], @"Digammagreek",
                               [NSNumber numberWithInt:0x0402], @"Djecyrillic",
                               [NSNumber numberWithInt:0x1E0E], @"Dlinebelow",
                               [NSNumber numberWithInt:0xFF24], @"Dmonospace",
                               [NSNumber numberWithInt:0xF6F7], @"Dotaccentsmall",
                               [NSNumber numberWithInt:0x0110], @"Dslash",
                               [NSNumber numberWithInt:0xF764], @"Dsmall",
                               [NSNumber numberWithInt:0x018B], @"Dtopbar",
                               [NSNumber numberWithInt:0x01F2], @"Dz",
                               [NSNumber numberWithInt:0x01C5], @"Dzcaron",
                               [NSNumber numberWithInt:0x04E0], @"Dzeabkhasiancyrillic",
                               [NSNumber numberWithInt:0x0405], @"Dzecyrillic",
                               [NSNumber numberWithInt:0x040F], @"Dzhecyrillic",
                               [NSNumber numberWithInt:0x0045], @"E",
                               [NSNumber numberWithInt:0x00C9], @"Eacute",
                               [NSNumber numberWithInt:0xF7E9], @"Eacutesmall",
                               [NSNumber numberWithInt:0x0114], @"Ebreve",
                               [NSNumber numberWithInt:0x011A], @"Ecaron",
                               [NSNumber numberWithInt:0x1E1C], @"Ecedillabreve",
                               [NSNumber numberWithInt:0x0535], @"Echarmenian",
                               [NSNumber numberWithInt:0x24BA], @"Ecircle",
                               [NSNumber numberWithInt:0x00CA], @"Ecircumflex",
                               [NSNumber numberWithInt:0x1EBE], @"Ecircumflexacute",
                               [NSNumber numberWithInt:0x1E18], @"Ecircumflexbelow",
                               [NSNumber numberWithInt:0x1EC6], @"Ecircumflexdotbelow",
                               [NSNumber numberWithInt:0x1EC0], @"Ecircumflexgrave",
                               [NSNumber numberWithInt:0x1EC2], @"Ecircumflexhookabove",
                               [NSNumber numberWithInt:0xF7EA], @"Ecircumflexsmall",
                               [NSNumber numberWithInt:0x1EC4], @"Ecircumflextilde",
                               [NSNumber numberWithInt:0x0404], @"Ecyrillic",
                               [NSNumber numberWithInt:0x0204], @"Edblgrave",
                               [NSNumber numberWithInt:0x00CB], @"Edieresis",
                               [NSNumber numberWithInt:0xF7EB], @"Edieresissmall",
                               [NSNumber numberWithInt:0x0116], @"Edot",
                               [NSNumber numberWithInt:0x0116], @"Edotaccent",
                               [NSNumber numberWithInt:0x1EB8], @"Edotbelow",
                               [NSNumber numberWithInt:0x0424], @"Efcyrillic",
                               [NSNumber numberWithInt:0x00C8], @"Egrave",
                               [NSNumber numberWithInt:0xF7E8], @"Egravesmall",
                               [NSNumber numberWithInt:0x0537], @"Eharmenian",
                               [NSNumber numberWithInt:0x1EBA], @"Ehookabove",
                               [NSNumber numberWithInt:0x2167], @"Eightroman",
                               [NSNumber numberWithInt:0x0206], @"Einvertedbreve",
                               [NSNumber numberWithInt:0x0464], @"Eiotifiedcyrillic",
                               [NSNumber numberWithInt:0x041B], @"Elcyrillic",
                               [NSNumber numberWithInt:0x216A], @"Elevenroman",
                               [NSNumber numberWithInt:0x0112], @"Emacron",
                               [NSNumber numberWithInt:0x1E16], @"Emacronacute",
                               [NSNumber numberWithInt:0x1E14], @"Emacrongrave",
                               [NSNumber numberWithInt:0x041C], @"Emcyrillic",
                               [NSNumber numberWithInt:0xFF25], @"Emonospace",
                               [NSNumber numberWithInt:0x041D], @"Encyrillic",
                               [NSNumber numberWithInt:0x04A2], @"Endescendercyrillic",
                               [NSNumber numberWithInt:0x014A], @"Eng",
                               [NSNumber numberWithInt:0x04A4], @"Enghecyrillic",
                               [NSNumber numberWithInt:0x04C7], @"Enhookcyrillic",
                               [NSNumber numberWithInt:0x0118], @"Eogonek",
                               [NSNumber numberWithInt:0x0190], @"Eopen",
                               [NSNumber numberWithInt:0x0395], @"Epsilon",
                               [NSNumber numberWithInt:0x0388], @"Epsilontonos",
                               [NSNumber numberWithInt:0x0420], @"Ercyrillic",
                               [NSNumber numberWithInt:0x018E], @"Ereversed",
                               [NSNumber numberWithInt:0x042D], @"Ereversedcyrillic",
                               [NSNumber numberWithInt:0x0421], @"Escyrillic",
                               [NSNumber numberWithInt:0x04AA], @"Esdescendercyrillic",
                               [NSNumber numberWithInt:0x01A9], @"Esh",
                               [NSNumber numberWithInt:0xF765], @"Esmall",
                               [NSNumber numberWithInt:0x0397], @"Eta",
                               [NSNumber numberWithInt:0x0538], @"Etarmenian",
                               [NSNumber numberWithInt:0x0389], @"Etatonos",
                               [NSNumber numberWithInt:0x00D0], @"Eth",
                               [NSNumber numberWithInt:0xF7F0], @"Ethsmall",
                               [NSNumber numberWithInt:0x1EBC], @"Etilde",
                               [NSNumber numberWithInt:0x1E1A], @"Etildebelow",
                               [NSNumber numberWithInt:0x20AC], @"Euro",
                               [NSNumber numberWithInt:0x01B7], @"Ezh",
                               [NSNumber numberWithInt:0x01EE], @"Ezhcaron",
                               [NSNumber numberWithInt:0x01B8], @"Ezhreversed",
                               [NSNumber numberWithInt:0x0046], @"F",
                               [NSNumber numberWithInt:0x24BB], @"Fcircle",
                               [NSNumber numberWithInt:0x1E1E], @"Fdotaccent",
                               [NSNumber numberWithInt:0x0556], @"Feharmenian",
                               [NSNumber numberWithInt:0x03E4], @"Feicoptic",
                               [NSNumber numberWithInt:0x0191], @"Fhook",
                               [NSNumber numberWithInt:0x0472], @"Fitacyrillic",
                               [NSNumber numberWithInt:0x2164], @"Fiveroman",
                               [NSNumber numberWithInt:0xFF26], @"Fmonospace",
                               [NSNumber numberWithInt:0x2163], @"Fourroman",
                               [NSNumber numberWithInt:0xF766], @"Fsmall",
                               [NSNumber numberWithInt:0x0047], @"G",
                               [NSNumber numberWithInt:0x3387], @"GBsquare",
                               [NSNumber numberWithInt:0x01F4], @"Gacute",
                               [NSNumber numberWithInt:0x0393], @"Gamma",
                               [NSNumber numberWithInt:0x0194], @"Gammaafrican",
                               [NSNumber numberWithInt:0x03EA], @"Gangiacoptic",
                               [NSNumber numberWithInt:0x011E], @"Gbreve",
                               [NSNumber numberWithInt:0x01E6], @"Gcaron",
                               [NSNumber numberWithInt:0x0122], @"Gcedilla",
                               [NSNumber numberWithInt:0x24BC], @"Gcircle",
                               [NSNumber numberWithInt:0x011C], @"Gcircumflex",
                               [NSNumber numberWithInt:0x0122], @"Gcommaaccent",
                               [NSNumber numberWithInt:0x0120], @"Gdot",
                               [NSNumber numberWithInt:0x0120], @"Gdotaccent",
                               [NSNumber numberWithInt:0x0413], @"Gecyrillic",
                               [NSNumber numberWithInt:0x0542], @"Ghadarmenian",
                               [NSNumber numberWithInt:0x0494], @"Ghemiddlehookcyrillic",
                               [NSNumber numberWithInt:0x0492], @"Ghestrokecyrillic",
                               [NSNumber numberWithInt:0x0490], @"Gheupturncyrillic",
                               [NSNumber numberWithInt:0x0193], @"Ghook",
                               [NSNumber numberWithInt:0x0533], @"Gimarmenian",
                               [NSNumber numberWithInt:0x0403], @"Gjecyrillic",
                               [NSNumber numberWithInt:0x1E20], @"Gmacron",
                               [NSNumber numberWithInt:0xFF27], @"Gmonospace",
                               [NSNumber numberWithInt:0xF6CE], @"Grave",
                               [NSNumber numberWithInt:0xF760], @"Gravesmall",
                               [NSNumber numberWithInt:0xF767], @"Gsmall",
                               [NSNumber numberWithInt:0x029B], @"Gsmallhook",
                               [NSNumber numberWithInt:0x01E4], @"Gstroke",
                               [NSNumber numberWithInt:0x0048], @"H",
                               [NSNumber numberWithInt:0x25CF], @"H18533",
                               [NSNumber numberWithInt:0x25AA], @"H18543",
                               [NSNumber numberWithInt:0x25AB], @"H18551",
                               [NSNumber numberWithInt:0x25A1], @"H22073",
                               [NSNumber numberWithInt:0x33CB], @"HPsquare",
                               [NSNumber numberWithInt:0x04A8], @"Haabkhasiancyrillic",
                               [NSNumber numberWithInt:0x04B2], @"Hadescendercyrillic",
                               [NSNumber numberWithInt:0x042A], @"Hardsigncyrillic",
                               [NSNumber numberWithInt:0x0126], @"Hbar",
                               [NSNumber numberWithInt:0x1E2A], @"Hbrevebelow",
                               [NSNumber numberWithInt:0x1E28], @"Hcedilla",
                               [NSNumber numberWithInt:0x24BD], @"Hcircle",
                               [NSNumber numberWithInt:0x0124], @"Hcircumflex",
                               [NSNumber numberWithInt:0x1E26], @"Hdieresis",
                               [NSNumber numberWithInt:0x1E22], @"Hdotaccent",
                               [NSNumber numberWithInt:0x1E24], @"Hdotbelow",
                               [NSNumber numberWithInt:0xFF28], @"Hmonospace",
                               [NSNumber numberWithInt:0x0540], @"Hoarmenian",
                               [NSNumber numberWithInt:0x03E8], @"Horicoptic",
                               [NSNumber numberWithInt:0xF768], @"Hsmall",
                               [NSNumber numberWithInt:0xF6CF], @"Hungarumlaut",
                               [NSNumber numberWithInt:0xF6F8], @"Hungarumlautsmall",
                               [NSNumber numberWithInt:0x3390], @"Hzsquare",
                               [NSNumber numberWithInt:0x0049], @"I",
                               [NSNumber numberWithInt:0x042F], @"IAcyrillic",
                               [NSNumber numberWithInt:0x0132], @"IJ",
                               [NSNumber numberWithInt:0x042E], @"IUcyrillic",
                               [NSNumber numberWithInt:0x00CD], @"Iacute",
                               [NSNumber numberWithInt:0xF7ED], @"Iacutesmall",
                               [NSNumber numberWithInt:0x012C], @"Ibreve",
                               [NSNumber numberWithInt:0x01CF], @"Icaron",
                               [NSNumber numberWithInt:0x24BE], @"Icircle",
                               [NSNumber numberWithInt:0x00CE], @"Icircumflex",
                               [NSNumber numberWithInt:0xF7EE], @"Icircumflexsmall",
                               [NSNumber numberWithInt:0x0406], @"Icyrillic",
                               [NSNumber numberWithInt:0x0208], @"Idblgrave",
                               [NSNumber numberWithInt:0x00CF], @"Idieresis",
                               [NSNumber numberWithInt:0x1E2E], @"Idieresisacute",
                               [NSNumber numberWithInt:0x04E4], @"Idieresiscyrillic",
                               [NSNumber numberWithInt:0xF7EF], @"Idieresissmall",
                               [NSNumber numberWithInt:0x0130], @"Idot",
                               [NSNumber numberWithInt:0x0130], @"Idotaccent",
                               [NSNumber numberWithInt:0x1ECA], @"Idotbelow",
                               [NSNumber numberWithInt:0x04D6], @"Iebrevecyrillic",
                               [NSNumber numberWithInt:0x0415], @"Iecyrillic",
                               [NSNumber numberWithInt:0x2111], @"Ifraktur",
                               [NSNumber numberWithInt:0x00CC], @"Igrave",
                               [NSNumber numberWithInt:0xF7EC], @"Igravesmall",
                               [NSNumber numberWithInt:0x1EC8], @"Ihookabove",
                               [NSNumber numberWithInt:0x0418], @"Iicyrillic",
                               [NSNumber numberWithInt:0x020A], @"Iinvertedbreve",
                               [NSNumber numberWithInt:0x0419], @"Iishortcyrillic",
                               [NSNumber numberWithInt:0x012A], @"Imacron",
                               [NSNumber numberWithInt:0x04E2], @"Imacroncyrillic",
                               [NSNumber numberWithInt:0xFF29], @"Imonospace",
                               [NSNumber numberWithInt:0x053B], @"Iniarmenian",
                               [NSNumber numberWithInt:0x0401], @"Iocyrillic",
                               [NSNumber numberWithInt:0x012E], @"Iogonek",
                               [NSNumber numberWithInt:0x0399], @"Iota",
                               [NSNumber numberWithInt:0x0196], @"Iotaafrican",
                               [NSNumber numberWithInt:0x03AA], @"Iotadieresis",
                               [NSNumber numberWithInt:0x038A], @"Iotatonos",
                               [NSNumber numberWithInt:0xF769], @"Ismall",
                               [NSNumber numberWithInt:0x0197], @"Istroke",
                               [NSNumber numberWithInt:0x0128], @"Itilde",
                               [NSNumber numberWithInt:0x1E2C], @"Itildebelow",
                               [NSNumber numberWithInt:0x0474], @"Izhitsacyrillic",
                               [NSNumber numberWithInt:0x0476], @"Izhitsadblgravecyrillic",
                               [NSNumber numberWithInt:0x004A], @"J",
                               [NSNumber numberWithInt:0x0541], @"Jaarmenian",
                               [NSNumber numberWithInt:0x24BF], @"Jcircle",
                               [NSNumber numberWithInt:0x0134], @"Jcircumflex",
                               [NSNumber numberWithInt:0x0408], @"Jecyrillic",
                               [NSNumber numberWithInt:0x054B], @"Jheharmenian",
                               [NSNumber numberWithInt:0xFF2A], @"Jmonospace",
                               [NSNumber numberWithInt:0xF76A], @"Jsmall",
                               [NSNumber numberWithInt:0x004B], @"K",
                               [NSNumber numberWithInt:0x3385], @"KBsquare",
                               [NSNumber numberWithInt:0x33CD], @"KKsquare",
                               [NSNumber numberWithInt:0x04A0], @"Kabashkircyrillic",
                               [NSNumber numberWithInt:0x1E30], @"Kacute",
                               [NSNumber numberWithInt:0x041A], @"Kacyrillic",
                               [NSNumber numberWithInt:0x049A], @"Kadescendercyrillic",
                               [NSNumber numberWithInt:0x04C3], @"Kahookcyrillic",
                               [NSNumber numberWithInt:0x039A], @"Kappa",
                               [NSNumber numberWithInt:0x049E], @"Kastrokecyrillic",
                               [NSNumber numberWithInt:0x049C], @"Kaverticalstrokecyrillic",
                               [NSNumber numberWithInt:0x01E8], @"Kcaron",
                               [NSNumber numberWithInt:0x0136], @"Kcedilla",
                               [NSNumber numberWithInt:0x24C0], @"Kcircle",
                               [NSNumber numberWithInt:0x0136], @"Kcommaaccent",
                               [NSNumber numberWithInt:0x1E32], @"Kdotbelow",
                               [NSNumber numberWithInt:0x0554], @"Keharmenian",
                               [NSNumber numberWithInt:0x053F], @"Kenarmenian",
                               [NSNumber numberWithInt:0x0425], @"Khacyrillic",
                               [NSNumber numberWithInt:0x03E6], @"Kheicoptic",
                               [NSNumber numberWithInt:0x0198], @"Khook",
                               [NSNumber numberWithInt:0x040C], @"Kjecyrillic",
                               [NSNumber numberWithInt:0x1E34], @"Klinebelow",
                               [NSNumber numberWithInt:0xFF2B], @"Kmonospace",
                               [NSNumber numberWithInt:0x0480], @"Koppacyrillic",
                               [NSNumber numberWithInt:0x03DE], @"Koppagreek",
                               [NSNumber numberWithInt:0x046E], @"Ksicyrillic",
                               [NSNumber numberWithInt:0xF76B], @"Ksmall",
                               [NSNumber numberWithInt:0x004C], @"L",
                               [NSNumber numberWithInt:0x01C7], @"LJ",
                               [NSNumber numberWithInt:0xF6BF], @"LL",
                               [NSNumber numberWithInt:0x0139], @"Lacute",
                               [NSNumber numberWithInt:0x039B], @"Lambda",
                               [NSNumber numberWithInt:0x013D], @"Lcaron",
                               [NSNumber numberWithInt:0x013B], @"Lcedilla",
                               [NSNumber numberWithInt:0x24C1], @"Lcircle",
                               [NSNumber numberWithInt:0x1E3C], @"Lcircumflexbelow",
                               [NSNumber numberWithInt:0x013B], @"Lcommaaccent",
                               [NSNumber numberWithInt:0x013F], @"Ldot",
                               [NSNumber numberWithInt:0x013F], @"Ldotaccent",
                               [NSNumber numberWithInt:0x1E36], @"Ldotbelow",
                               [NSNumber numberWithInt:0x1E38], @"Ldotbelowmacron",
                               [NSNumber numberWithInt:0x053C], @"Liwnarmenian",
                               [NSNumber numberWithInt:0x01C8], @"Lj",
                               [NSNumber numberWithInt:0x0409], @"Ljecyrillic",
                               [NSNumber numberWithInt:0x1E3A], @"Llinebelow",
                               [NSNumber numberWithInt:0xFF2C], @"Lmonospace",
                               [NSNumber numberWithInt:0x0141], @"Lslash",
                               [NSNumber numberWithInt:0xF6F9], @"Lslashsmall",
                               [NSNumber numberWithInt:0xF76C], @"Lsmall",
                               [NSNumber numberWithInt:0x004D], @"M",
                               [NSNumber numberWithInt:0x3386], @"MBsquare",
                               [NSNumber numberWithInt:0xF6D0], @"Macron",
                               [NSNumber numberWithInt:0xF7AF], @"Macronsmall",
                               [NSNumber numberWithInt:0x1E3E], @"Macute",
                               [NSNumber numberWithInt:0x24C2], @"Mcircle",
                               [NSNumber numberWithInt:0x1E40], @"Mdotaccent",
                               [NSNumber numberWithInt:0x1E42], @"Mdotbelow",
                               [NSNumber numberWithInt:0x0544], @"Menarmenian",
                               [NSNumber numberWithInt:0xFF2D], @"Mmonospace",
                               [NSNumber numberWithInt:0xF76D], @"Msmall",
                               [NSNumber numberWithInt:0x019C], @"Mturned",
                               [NSNumber numberWithInt:0x039C], @"Mu",
                               [NSNumber numberWithInt:0x004E], @"N",
                               [NSNumber numberWithInt:0x01CA], @"NJ",
                               [NSNumber numberWithInt:0x0143], @"Nacute",
                               [NSNumber numberWithInt:0x0147], @"Ncaron",
                               [NSNumber numberWithInt:0x0145], @"Ncedilla",
                               [NSNumber numberWithInt:0x24C3], @"Ncircle",
                               [NSNumber numberWithInt:0x1E4A], @"Ncircumflexbelow",
                               [NSNumber numberWithInt:0x0145], @"Ncommaaccent",
                               [NSNumber numberWithInt:0x1E44], @"Ndotaccent",
                               [NSNumber numberWithInt:0x1E46], @"Ndotbelow",
                               [NSNumber numberWithInt:0x019D], @"Nhookleft",
                               [NSNumber numberWithInt:0x2168], @"Nineroman",
                               [NSNumber numberWithInt:0x01CB], @"Nj",
                               [NSNumber numberWithInt:0x040A], @"Njecyrillic",
                               [NSNumber numberWithInt:0x1E48], @"Nlinebelow",
                               [NSNumber numberWithInt:0xFF2E], @"Nmonospace",
                               [NSNumber numberWithInt:0x0546], @"Nowarmenian",
                               [NSNumber numberWithInt:0xF76E], @"Nsmall",
                               [NSNumber numberWithInt:0x00D1], @"Ntilde",
                               [NSNumber numberWithInt:0xF7F1], @"Ntildesmall",
                               [NSNumber numberWithInt:0x039D], @"Nu",
                               [NSNumber numberWithInt:0x004F], @"O",
                               [NSNumber numberWithInt:0x0152], @"OE",
                               [NSNumber numberWithInt:0xF6FA], @"OEsmall",
                               [NSNumber numberWithInt:0x00D3], @"Oacute",
                               [NSNumber numberWithInt:0xF7F3], @"Oacutesmall",
                               [NSNumber numberWithInt:0x04E8], @"Obarredcyrillic",
                               [NSNumber numberWithInt:0x04EA], @"Obarreddieresiscyrillic",
                               [NSNumber numberWithInt:0x014E], @"Obreve",
                               [NSNumber numberWithInt:0x01D1], @"Ocaron",
                               [NSNumber numberWithInt:0x019F], @"Ocenteredtilde",
                               [NSNumber numberWithInt:0x24C4], @"Ocircle",
                               [NSNumber numberWithInt:0x00D4], @"Ocircumflex",
                               [NSNumber numberWithInt:0x1ED0], @"Ocircumflexacute",
                               [NSNumber numberWithInt:0x1ED8], @"Ocircumflexdotbelow",
                               [NSNumber numberWithInt:0x1ED2], @"Ocircumflexgrave",
                               [NSNumber numberWithInt:0x1ED4], @"Ocircumflexhookabove",
                               [NSNumber numberWithInt:0xF7F4], @"Ocircumflexsmall",
                               [NSNumber numberWithInt:0x1ED6], @"Ocircumflextilde",
                               [NSNumber numberWithInt:0x041E], @"Ocyrillic",
                               [NSNumber numberWithInt:0x0150], @"Odblacute",
                               [NSNumber numberWithInt:0x020C], @"Odblgrave",
                               [NSNumber numberWithInt:0x00D6], @"Odieresis",
                               [NSNumber numberWithInt:0x04E6], @"Odieresiscyrillic",
                               [NSNumber numberWithInt:0xF7F6], @"Odieresissmall",
                               [NSNumber numberWithInt:0x1ECC], @"Odotbelow",
                               [NSNumber numberWithInt:0xF6FB], @"Ogoneksmall",
                               [NSNumber numberWithInt:0x00D2], @"Ograve",
                               [NSNumber numberWithInt:0xF7F2], @"Ogravesmall",
                               [NSNumber numberWithInt:0x0555], @"Oharmenian",
                               [NSNumber numberWithInt:0x2126], @"Ohm",
                               [NSNumber numberWithInt:0x1ECE], @"Ohookabove",
                               [NSNumber numberWithInt:0x01A0], @"Ohorn",
                               [NSNumber numberWithInt:0x1EDA], @"Ohornacute",
                               [NSNumber numberWithInt:0x1EE2], @"Ohorndotbelow",
                               [NSNumber numberWithInt:0x1EDC], @"Ohorngrave",
                               [NSNumber numberWithInt:0x1EDE], @"Ohornhookabove",
                               [NSNumber numberWithInt:0x1EE0], @"Ohorntilde",
                               [NSNumber numberWithInt:0x0150], @"Ohungarumlaut",
                               [NSNumber numberWithInt:0x01A2], @"Oi",
                               [NSNumber numberWithInt:0x020E], @"Oinvertedbreve",
                               [NSNumber numberWithInt:0x014C], @"Omacron",
                               [NSNumber numberWithInt:0x1E52], @"Omacronacute",
                               [NSNumber numberWithInt:0x1E50], @"Omacrongrave",
                               [NSNumber numberWithInt:0x2126], @"Omega",
                               [NSNumber numberWithInt:0x0460], @"Omegacyrillic",
                               [NSNumber numberWithInt:0x03A9], @"Omegagreek",
                               [NSNumber numberWithInt:0x047A], @"Omegaroundcyrillic",
                               [NSNumber numberWithInt:0x047C], @"Omegatitlocyrillic",
                               [NSNumber numberWithInt:0x038F], @"Omegatonos",
                               [NSNumber numberWithInt:0x039F], @"Omicron",
                               [NSNumber numberWithInt:0x038C], @"Omicrontonos",
                               [NSNumber numberWithInt:0xFF2F], @"Omonospace",
                               [NSNumber numberWithInt:0x2160], @"Oneroman",
                               [NSNumber numberWithInt:0x01EA], @"Oogonek",
                               [NSNumber numberWithInt:0x01EC], @"Oogonekmacron",
                               [NSNumber numberWithInt:0x0186], @"Oopen",
                               [NSNumber numberWithInt:0x00D8], @"Oslash",
                               [NSNumber numberWithInt:0x01FE], @"Oslashacute",
                               [NSNumber numberWithInt:0xF7F8], @"Oslashsmall",
                               [NSNumber numberWithInt:0xF76F], @"Osmall",
                               [NSNumber numberWithInt:0x01FE], @"Ostrokeacute",
                               [NSNumber numberWithInt:0x047E], @"Otcyrillic",
                               [NSNumber numberWithInt:0x00D5], @"Otilde",
                               [NSNumber numberWithInt:0x1E4C], @"Otildeacute",
                               [NSNumber numberWithInt:0x1E4E], @"Otildedieresis",
                               [NSNumber numberWithInt:0xF7F5], @"Otildesmall",
                               [NSNumber numberWithInt:0x0050], @"P",
                               [NSNumber numberWithInt:0x1E54], @"Pacute",
                               [NSNumber numberWithInt:0x24C5], @"Pcircle",
                               [NSNumber numberWithInt:0x1E56], @"Pdotaccent",
                               [NSNumber numberWithInt:0x041F], @"Pecyrillic",
                               [NSNumber numberWithInt:0x054A], @"Peharmenian",
                               [NSNumber numberWithInt:0x04A6], @"Pemiddlehookcyrillic",
                               [NSNumber numberWithInt:0x03A6], @"Phi",
                               [NSNumber numberWithInt:0x01A4], @"Phook",
                               [NSNumber numberWithInt:0x03A0], @"Pi",
                               [NSNumber numberWithInt:0x0553], @"Piwrarmenian",
                               [NSNumber numberWithInt:0xFF30], @"Pmonospace",
                               [NSNumber numberWithInt:0x03A8], @"Psi",
                               [NSNumber numberWithInt:0x0470], @"Psicyrillic",
                               [NSNumber numberWithInt:0xF770], @"Psmall",
                               [NSNumber numberWithInt:0x0051], @"Q",
                               [NSNumber numberWithInt:0x24C6], @"Qcircle",
                               [NSNumber numberWithInt:0xFF31], @"Qmonospace",
                               [NSNumber numberWithInt:0xF771], @"Qsmall",
                               [NSNumber numberWithInt:0x0052], @"R",
                               [NSNumber numberWithInt:0x054C], @"Raarmenian",
                               [NSNumber numberWithInt:0x0154], @"Racute",
                               [NSNumber numberWithInt:0x0158], @"Rcaron",
                               [NSNumber numberWithInt:0x0156], @"Rcedilla",
                               [NSNumber numberWithInt:0x24C7], @"Rcircle",
                               [NSNumber numberWithInt:0x0156], @"Rcommaaccent",
                               [NSNumber numberWithInt:0x0210], @"Rdblgrave",
                               [NSNumber numberWithInt:0x1E58], @"Rdotaccent",
                               [NSNumber numberWithInt:0x1E5A], @"Rdotbelow",
                               [NSNumber numberWithInt:0x1E5C], @"Rdotbelowmacron",
                               [NSNumber numberWithInt:0x0550], @"Reharmenian",
                               [NSNumber numberWithInt:0x211C], @"Rfraktur",
                               [NSNumber numberWithInt:0x03A1], @"Rho",
                               [NSNumber numberWithInt:0xF6FC], @"Ringsmall",
                               [NSNumber numberWithInt:0x0212], @"Rinvertedbreve",
                               [NSNumber numberWithInt:0x1E5E], @"Rlinebelow",
                               [NSNumber numberWithInt:0xFF32], @"Rmonospace",
                               [NSNumber numberWithInt:0xF772], @"Rsmall",
                               [NSNumber numberWithInt:0x0281], @"Rsmallinverted",
                               [NSNumber numberWithInt:0x02B6], @"Rsmallinvertedsuperior",
                               [NSNumber numberWithInt:0x0053], @"S",
                               [NSNumber numberWithInt:0x250C], @"SF010000",
                               [NSNumber numberWithInt:0x2514], @"SF020000",
                               [NSNumber numberWithInt:0x2510], @"SF030000",
                               [NSNumber numberWithInt:0x2518], @"SF040000",
                               [NSNumber numberWithInt:0x253C], @"SF050000",
                               [NSNumber numberWithInt:0x252C], @"SF060000",
                               [NSNumber numberWithInt:0x2534], @"SF070000",
                               [NSNumber numberWithInt:0x251C], @"SF080000",
                               [NSNumber numberWithInt:0x2524], @"SF090000",
                               [NSNumber numberWithInt:0x2500], @"SF100000",
                               [NSNumber numberWithInt:0x2502], @"SF110000",
                               [NSNumber numberWithInt:0x2561], @"SF190000",
                               [NSNumber numberWithInt:0x2562], @"SF200000",
                               [NSNumber numberWithInt:0x2556], @"SF210000",
                               [NSNumber numberWithInt:0x2555], @"SF220000",
                               [NSNumber numberWithInt:0x2563], @"SF230000",
                               [NSNumber numberWithInt:0x2551], @"SF240000",
                               [NSNumber numberWithInt:0x2557], @"SF250000",
                               [NSNumber numberWithInt:0x255D], @"SF260000",
                               [NSNumber numberWithInt:0x255C], @"SF270000",
                               [NSNumber numberWithInt:0x255B], @"SF280000",
                               [NSNumber numberWithInt:0x255E], @"SF360000",
                               [NSNumber numberWithInt:0x255F], @"SF370000",
                               [NSNumber numberWithInt:0x255A], @"SF380000",
                               [NSNumber numberWithInt:0x2554], @"SF390000",
                               [NSNumber numberWithInt:0x2569], @"SF400000",
                               [NSNumber numberWithInt:0x2566], @"SF410000",
                               [NSNumber numberWithInt:0x2560], @"SF420000",
                               [NSNumber numberWithInt:0x2550], @"SF430000",
                               [NSNumber numberWithInt:0x256C], @"SF440000",
                               [NSNumber numberWithInt:0x2567], @"SF450000",
                               [NSNumber numberWithInt:0x2568], @"SF460000",
                               [NSNumber numberWithInt:0x2564], @"SF470000",
                               [NSNumber numberWithInt:0x2565], @"SF480000",
                               [NSNumber numberWithInt:0x2559], @"SF490000",
                               [NSNumber numberWithInt:0x2558], @"SF500000",
                               [NSNumber numberWithInt:0x2552], @"SF510000",
                               [NSNumber numberWithInt:0x2553], @"SF520000",
                               [NSNumber numberWithInt:0x256B], @"SF530000",
                               [NSNumber numberWithInt:0x256A], @"SF540000",
                               [NSNumber numberWithInt:0x015A], @"Sacute",
                               [NSNumber numberWithInt:0x1E64], @"Sacutedotaccent",
                               [NSNumber numberWithInt:0x03E0], @"Sampigreek",
                               [NSNumber numberWithInt:0x0160], @"Scaron",
                               [NSNumber numberWithInt:0x1E66], @"Scarondotaccent",
                               [NSNumber numberWithInt:0xF6FD], @"Scaronsmall",
                               [NSNumber numberWithInt:0x015E], @"Scedilla",
                               [NSNumber numberWithInt:0x018F], @"Schwa",
                               [NSNumber numberWithInt:0x04D8], @"Schwacyrillic",
                               [NSNumber numberWithInt:0x04DA], @"Schwadieresiscyrillic",
                               [NSNumber numberWithInt:0x24C8], @"Scircle",
                               [NSNumber numberWithInt:0x015C], @"Scircumflex",
                               [NSNumber numberWithInt:0x0218], @"Scommaaccent",
                               [NSNumber numberWithInt:0x1E60], @"Sdotaccent",
                               [NSNumber numberWithInt:0x1E62], @"Sdotbelow",
                               [NSNumber numberWithInt:0x1E68], @"Sdotbelowdotaccent",
                               [NSNumber numberWithInt:0x054D], @"Seharmenian",
                               [NSNumber numberWithInt:0x2166], @"Sevenroman",
                               [NSNumber numberWithInt:0x0547], @"Shaarmenian",
                               [NSNumber numberWithInt:0x0428], @"Shacyrillic",
                               [NSNumber numberWithInt:0x0429], @"Shchacyrillic",
                               [NSNumber numberWithInt:0x03E2], @"Sheicoptic",
                               [NSNumber numberWithInt:0x04BA], @"Shhacyrillic",
                               [NSNumber numberWithInt:0x03EC], @"Shimacoptic",
                               [NSNumber numberWithInt:0x03A3], @"Sigma",
                               [NSNumber numberWithInt:0x2165], @"Sixroman",
                               [NSNumber numberWithInt:0xFF33], @"Smonospace",
                               [NSNumber numberWithInt:0x042C], @"Softsigncyrillic",
                               [NSNumber numberWithInt:0xF773], @"Ssmall",
                               [NSNumber numberWithInt:0x03DA], @"Stigmagreek",
                               [NSNumber numberWithInt:0x0054], @"T",
                               [NSNumber numberWithInt:0x03A4], @"Tau",
                               [NSNumber numberWithInt:0x0166], @"Tbar",
                               [NSNumber numberWithInt:0x0164], @"Tcaron",
                               [NSNumber numberWithInt:0x0162], @"Tcedilla",
                               [NSNumber numberWithInt:0x24C9], @"Tcircle",
                               [NSNumber numberWithInt:0x1E70], @"Tcircumflexbelow",
                               [NSNumber numberWithInt:0x0162], @"Tcommaaccent",
                               [NSNumber numberWithInt:0x1E6A], @"Tdotaccent",
                               [NSNumber numberWithInt:0x1E6C], @"Tdotbelow",
                               [NSNumber numberWithInt:0x0422], @"Tecyrillic",
                               [NSNumber numberWithInt:0x04AC], @"Tedescendercyrillic",
                               [NSNumber numberWithInt:0x2169], @"Tenroman",
                               [NSNumber numberWithInt:0x04B4], @"Tetsecyrillic",
                               [NSNumber numberWithInt:0x0398], @"Theta",
                               [NSNumber numberWithInt:0x01AC], @"Thook",
                               [NSNumber numberWithInt:0x00DE], @"Thorn",
                               [NSNumber numberWithInt:0xF7FE], @"Thornsmall",
                               [NSNumber numberWithInt:0x2162], @"Threeroman",
                               [NSNumber numberWithInt:0xF6FE], @"Tildesmall",
                               [NSNumber numberWithInt:0x054F], @"Tiwnarmenian",
                               [NSNumber numberWithInt:0x1E6E], @"Tlinebelow",
                               [NSNumber numberWithInt:0xFF34], @"Tmonospace",
                               [NSNumber numberWithInt:0x0539], @"Toarmenian",
                               [NSNumber numberWithInt:0x01BC], @"Tonefive",
                               [NSNumber numberWithInt:0x0184], @"Tonesix",
                               [NSNumber numberWithInt:0x01A7], @"Tonetwo",
                               [NSNumber numberWithInt:0x01AE], @"Tretroflexhook",
                               [NSNumber numberWithInt:0x0426], @"Tsecyrillic",
                               [NSNumber numberWithInt:0x040B], @"Tshecyrillic",
                               [NSNumber numberWithInt:0xF774], @"Tsmall",
                               [NSNumber numberWithInt:0x216B], @"Twelveroman",
                               [NSNumber numberWithInt:0x2161], @"Tworoman",
                               [NSNumber numberWithInt:0x0055], @"U",
                               [NSNumber numberWithInt:0x00DA], @"Uacute",
                               [NSNumber numberWithInt:0xF7FA], @"Uacutesmall",
                               [NSNumber numberWithInt:0x016C], @"Ubreve",
                               [NSNumber numberWithInt:0x01D3], @"Ucaron",
                               [NSNumber numberWithInt:0x24CA], @"Ucircle",
                               [NSNumber numberWithInt:0x00DB], @"Ucircumflex",
                               [NSNumber numberWithInt:0x1E76], @"Ucircumflexbelow",
                               [NSNumber numberWithInt:0xF7FB], @"Ucircumflexsmall",
                               [NSNumber numberWithInt:0x0423], @"Ucyrillic",
                               [NSNumber numberWithInt:0x0170], @"Udblacute",
                               [NSNumber numberWithInt:0x0214], @"Udblgrave",
                               [NSNumber numberWithInt:0x00DC], @"Udieresis",
                               [NSNumber numberWithInt:0x01D7], @"Udieresisacute",
                               [NSNumber numberWithInt:0x1E72], @"Udieresisbelow",
                               [NSNumber numberWithInt:0x01D9], @"Udieresiscaron",
                               [NSNumber numberWithInt:0x04F0], @"Udieresiscyrillic",
                               [NSNumber numberWithInt:0x01DB], @"Udieresisgrave",
                               [NSNumber numberWithInt:0x01D5], @"Udieresismacron",
                               [NSNumber numberWithInt:0xF7FC], @"Udieresissmall",
                               [NSNumber numberWithInt:0x1EE4], @"Udotbelow",
                               [NSNumber numberWithInt:0x00D9], @"Ugrave",
                               [NSNumber numberWithInt:0xF7F9], @"Ugravesmall",
                               [NSNumber numberWithInt:0x1EE6], @"Uhookabove",
                               [NSNumber numberWithInt:0x01AF], @"Uhorn",
                               [NSNumber numberWithInt:0x1EE8], @"Uhornacute",
                               [NSNumber numberWithInt:0x1EF0], @"Uhorndotbelow",
                               [NSNumber numberWithInt:0x1EEA], @"Uhorngrave",
                               [NSNumber numberWithInt:0x1EEC], @"Uhornhookabove",
                               [NSNumber numberWithInt:0x1EEE], @"Uhorntilde",
                               [NSNumber numberWithInt:0x0170], @"Uhungarumlaut",
                               [NSNumber numberWithInt:0x04F2], @"Uhungarumlautcyrillic",
                               [NSNumber numberWithInt:0x0216], @"Uinvertedbreve",
                               [NSNumber numberWithInt:0x0478], @"Ukcyrillic",
                               [NSNumber numberWithInt:0x016A], @"Umacron",
                               [NSNumber numberWithInt:0x04EE], @"Umacroncyrillic",
                               [NSNumber numberWithInt:0x1E7A], @"Umacrondieresis",
                               [NSNumber numberWithInt:0xFF35], @"Umonospace",
                               [NSNumber numberWithInt:0x0172], @"Uogonek",
                               [NSNumber numberWithInt:0x03A5], @"Upsilon",
                               [NSNumber numberWithInt:0x03D2], @"Upsilon1",
                               [NSNumber numberWithInt:0x03D3], @"Upsilonacutehooksymbolgreek",
                               [NSNumber numberWithInt:0x01B1], @"Upsilonafrican",
                               [NSNumber numberWithInt:0x03AB], @"Upsilondieresis",
                               [NSNumber numberWithInt:0x03D4], @"Upsilondieresishooksymbolgreek",
                               [NSNumber numberWithInt:0x03D2], @"Upsilonhooksymbol",
                               [NSNumber numberWithInt:0x038E], @"Upsilontonos",
                               [NSNumber numberWithInt:0x016E], @"Uring",
                               [NSNumber numberWithInt:0x040E], @"Ushortcyrillic",
                               [NSNumber numberWithInt:0xF775], @"Usmall",
                               [NSNumber numberWithInt:0x04AE], @"Ustraightcyrillic",
                               [NSNumber numberWithInt:0x04B0], @"Ustraightstrokecyrillic",
                               [NSNumber numberWithInt:0x0168], @"Utilde",
                               [NSNumber numberWithInt:0x1E78], @"Utildeacute",
                               [NSNumber numberWithInt:0x1E74], @"Utildebelow",
                               [NSNumber numberWithInt:0x0056], @"V",
                               [NSNumber numberWithInt:0x24CB], @"Vcircle",
                               [NSNumber numberWithInt:0x1E7E], @"Vdotbelow",
                               [NSNumber numberWithInt:0x0412], @"Vecyrillic",
                               [NSNumber numberWithInt:0x054E], @"Vewarmenian",
                               [NSNumber numberWithInt:0x01B2], @"Vhook",
                               [NSNumber numberWithInt:0xFF36], @"Vmonospace",
                               [NSNumber numberWithInt:0x0548], @"Voarmenian",
                               [NSNumber numberWithInt:0xF776], @"Vsmall",
                               [NSNumber numberWithInt:0x1E7C], @"Vtilde",
                               [NSNumber numberWithInt:0x0057], @"W",
                               [NSNumber numberWithInt:0x1E82], @"Wacute",
                               [NSNumber numberWithInt:0x24CC], @"Wcircle",
                               [NSNumber numberWithInt:0x0174], @"Wcircumflex",
                               [NSNumber numberWithInt:0x1E84], @"Wdieresis",
                               [NSNumber numberWithInt:0x1E86], @"Wdotaccent",
                               [NSNumber numberWithInt:0x1E88], @"Wdotbelow",
                               [NSNumber numberWithInt:0x1E80], @"Wgrave",
                               [NSNumber numberWithInt:0xFF37], @"Wmonospace",
                               [NSNumber numberWithInt:0xF777], @"Wsmall",
                               [NSNumber numberWithInt:0x0058], @"X",
                               [NSNumber numberWithInt:0x24CD], @"Xcircle",
                               [NSNumber numberWithInt:0x1E8C], @"Xdieresis",
                               [NSNumber numberWithInt:0x1E8A], @"Xdotaccent",
                               [NSNumber numberWithInt:0x053D], @"Xeharmenian",
                               [NSNumber numberWithInt:0x039E], @"Xi",
                               [NSNumber numberWithInt:0xFF38], @"Xmonospace",
                               [NSNumber numberWithInt:0xF778], @"Xsmall",
                               [NSNumber numberWithInt:0x0059], @"Y",
                               [NSNumber numberWithInt:0x00DD], @"Yacute",
                               [NSNumber numberWithInt:0xF7FD], @"Yacutesmall",
                               [NSNumber numberWithInt:0x0462], @"Yatcyrillic",
                               [NSNumber numberWithInt:0x24CE], @"Ycircle",
                               [NSNumber numberWithInt:0x0176], @"Ycircumflex",
                               [NSNumber numberWithInt:0x0178], @"Ydieresis",
                               [NSNumber numberWithInt:0xF7FF], @"Ydieresissmall",
                               [NSNumber numberWithInt:0x1E8E], @"Ydotaccent",
                               [NSNumber numberWithInt:0x1EF4], @"Ydotbelow",
                               [NSNumber numberWithInt:0x042B], @"Yericyrillic",
                               [NSNumber numberWithInt:0x04F8], @"Yerudieresiscyrillic",
                               [NSNumber numberWithInt:0x1EF2], @"Ygrave",
                               [NSNumber numberWithInt:0x01B3], @"Yhook",
                               [NSNumber numberWithInt:0x1EF6], @"Yhookabove",
                               [NSNumber numberWithInt:0x0545], @"Yiarmenian",
                               [NSNumber numberWithInt:0x0407], @"Yicyrillic",
                               [NSNumber numberWithInt:0x0552], @"Yiwnarmenian",
                               [NSNumber numberWithInt:0xFF39], @"Ymonospace",
                               [NSNumber numberWithInt:0xF779], @"Ysmall",
                               [NSNumber numberWithInt:0x1EF8], @"Ytilde",
                               [NSNumber numberWithInt:0x046A], @"Yusbigcyrillic",
                               [NSNumber numberWithInt:0x046C], @"Yusbigiotifiedcyrillic",
                               [NSNumber numberWithInt:0x0466], @"Yuslittlecyrillic",
                               [NSNumber numberWithInt:0x0468], @"Yuslittleiotifiedcyrillic",
                               [NSNumber numberWithInt:0x005A], @"Z",
                               [NSNumber numberWithInt:0x0536], @"Zaarmenian",
                               [NSNumber numberWithInt:0x0179], @"Zacute",
                               [NSNumber numberWithInt:0x017D], @"Zcaron",
                               [NSNumber numberWithInt:0xF6FF], @"Zcaronsmall",
                               [NSNumber numberWithInt:0x24CF], @"Zcircle",
                               [NSNumber numberWithInt:0x1E90], @"Zcircumflex",
                               [NSNumber numberWithInt:0x017B], @"Zdot",
                               [NSNumber numberWithInt:0x017B], @"Zdotaccent",
                               [NSNumber numberWithInt:0x1E92], @"Zdotbelow",
                               [NSNumber numberWithInt:0x0417], @"Zecyrillic",
                               [NSNumber numberWithInt:0x0498], @"Zedescendercyrillic",
                               [NSNumber numberWithInt:0x04DE], @"Zedieresiscyrillic",
                               [NSNumber numberWithInt:0x0396], @"Zeta",
                               [NSNumber numberWithInt:0x053A], @"Zhearmenian",
                               [NSNumber numberWithInt:0x04C1], @"Zhebrevecyrillic",
                               [NSNumber numberWithInt:0x0416], @"Zhecyrillic",
                               [NSNumber numberWithInt:0x0496], @"Zhedescendercyrillic",
                               [NSNumber numberWithInt:0x04DC], @"Zhedieresiscyrillic",
                               [NSNumber numberWithInt:0x1E94], @"Zlinebelow",
                               [NSNumber numberWithInt:0xFF3A], @"Zmonospace",
                               [NSNumber numberWithInt:0xF77A], @"Zsmall",
                               [NSNumber numberWithInt:0x01B5], @"Zstroke",
                               [NSNumber numberWithInt:0x0061], @"a",
                               [NSNumber numberWithInt:0x0986], @"aabengali",
                               [NSNumber numberWithInt:0x00E1], @"aacute",
                               [NSNumber numberWithInt:0x0906], @"aadeva",
                               [NSNumber numberWithInt:0x0A86], @"aagujarati",
                               [NSNumber numberWithInt:0x0A06], @"aagurmukhi",
                               [NSNumber numberWithInt:0x0A3E], @"aamatragurmukhi",
                               [NSNumber numberWithInt:0x3303], @"aarusquare",
                               [NSNumber numberWithInt:0x09BE], @"aavowelsignbengali",
                               [NSNumber numberWithInt:0x093E], @"aavowelsigndeva",
                               [NSNumber numberWithInt:0x0ABE], @"aavowelsigngujarati",
                               [NSNumber numberWithInt:0x055F], @"abbreviationmarkarmenian",
                               [NSNumber numberWithInt:0x0970], @"abbreviationsigndeva",
                               [NSNumber numberWithInt:0x0985], @"abengali",
                               [NSNumber numberWithInt:0x311A], @"abopomofo",
                               [NSNumber numberWithInt:0x0103], @"abreve",
                               [NSNumber numberWithInt:0x1EAF], @"abreveacute",
                               [NSNumber numberWithInt:0x04D1], @"abrevecyrillic",
                               [NSNumber numberWithInt:0x1EB7], @"abrevedotbelow",
                               [NSNumber numberWithInt:0x1EB1], @"abrevegrave",
                               [NSNumber numberWithInt:0x1EB3], @"abrevehookabove",
                               [NSNumber numberWithInt:0x1EB5], @"abrevetilde",
                               [NSNumber numberWithInt:0x01CE], @"acaron",
                               [NSNumber numberWithInt:0x24D0], @"acircle",
                               [NSNumber numberWithInt:0x00E2], @"acircumflex",
                               [NSNumber numberWithInt:0x1EA5], @"acircumflexacute",
                               [NSNumber numberWithInt:0x1EAD], @"acircumflexdotbelow",
                               [NSNumber numberWithInt:0x1EA7], @"acircumflexgrave",
                               [NSNumber numberWithInt:0x1EA9], @"acircumflexhookabove",
                               [NSNumber numberWithInt:0x1EAB], @"acircumflextilde",
                               [NSNumber numberWithInt:0x00B4], @"acute",
                               [NSNumber numberWithInt:0x0317], @"acutebelowcmb",
                               [NSNumber numberWithInt:0x0301], @"acutecmb",
                               [NSNumber numberWithInt:0x0301], @"acutecomb",
                               [NSNumber numberWithInt:0x0954], @"acutedeva",
                               [NSNumber numberWithInt:0x02CF], @"acutelowmod",
                               [NSNumber numberWithInt:0x0341], @"acutetonecmb",
                               [NSNumber numberWithInt:0x0430], @"acyrillic",
                               [NSNumber numberWithInt:0x0201], @"adblgrave",
                               [NSNumber numberWithInt:0x0A71], @"addakgurmukhi",
                               [NSNumber numberWithInt:0x0905], @"adeva",
                               [NSNumber numberWithInt:0x00E4], @"adieresis",
                               [NSNumber numberWithInt:0x04D3], @"adieresiscyrillic",
                               [NSNumber numberWithInt:0x01DF], @"adieresismacron",
                               [NSNumber numberWithInt:0x1EA1], @"adotbelow",
                               [NSNumber numberWithInt:0x01E1], @"adotmacron",
                               [NSNumber numberWithInt:0x00E6], @"ae",
                               [NSNumber numberWithInt:0x01FD], @"aeacute",
                               [NSNumber numberWithInt:0x3150], @"aekorean",
                               [NSNumber numberWithInt:0x01E3], @"aemacron",
                               [NSNumber numberWithInt:0x2015], @"afii00208",
                               [NSNumber numberWithInt:0x20A4], @"afii08941",
                               [NSNumber numberWithInt:0x0410], @"afii10017",
                               [NSNumber numberWithInt:0x0411], @"afii10018",
                               [NSNumber numberWithInt:0x0412], @"afii10019",
                               [NSNumber numberWithInt:0x0413], @"afii10020",
                               [NSNumber numberWithInt:0x0414], @"afii10021",
                               [NSNumber numberWithInt:0x0415], @"afii10022",
                               [NSNumber numberWithInt:0x0401], @"afii10023",
                               [NSNumber numberWithInt:0x0416], @"afii10024",
                               [NSNumber numberWithInt:0x0417], @"afii10025",
                               [NSNumber numberWithInt:0x0418], @"afii10026",
                               [NSNumber numberWithInt:0x0419], @"afii10027",
                               [NSNumber numberWithInt:0x041A], @"afii10028",
                               [NSNumber numberWithInt:0x041B], @"afii10029",
                               [NSNumber numberWithInt:0x041C], @"afii10030",
                               [NSNumber numberWithInt:0x041D], @"afii10031",
                               [NSNumber numberWithInt:0x041E], @"afii10032",
                               [NSNumber numberWithInt:0x041F], @"afii10033",
                               [NSNumber numberWithInt:0x0420], @"afii10034",
                               [NSNumber numberWithInt:0x0421], @"afii10035",
                               [NSNumber numberWithInt:0x0422], @"afii10036",
                               [NSNumber numberWithInt:0x0423], @"afii10037",
                               [NSNumber numberWithInt:0x0424], @"afii10038",
                               [NSNumber numberWithInt:0x0425], @"afii10039",
                               [NSNumber numberWithInt:0x0426], @"afii10040",
                               [NSNumber numberWithInt:0x0427], @"afii10041",
                               [NSNumber numberWithInt:0x0428], @"afii10042",
                               [NSNumber numberWithInt:0x0429], @"afii10043",
                               [NSNumber numberWithInt:0x042A], @"afii10044",
                               [NSNumber numberWithInt:0x042B], @"afii10045",
                               [NSNumber numberWithInt:0x042C], @"afii10046",
                               [NSNumber numberWithInt:0x042D], @"afii10047",
                               [NSNumber numberWithInt:0x042E], @"afii10048",
                               [NSNumber numberWithInt:0x042F], @"afii10049",
                               [NSNumber numberWithInt:0x0490], @"afii10050",
                               [NSNumber numberWithInt:0x0402], @"afii10051",
                               [NSNumber numberWithInt:0x0403], @"afii10052",
                               [NSNumber numberWithInt:0x0404], @"afii10053",
                               [NSNumber numberWithInt:0x0405], @"afii10054",
                               [NSNumber numberWithInt:0x0406], @"afii10055",
                               [NSNumber numberWithInt:0x0407], @"afii10056",
                               [NSNumber numberWithInt:0x0408], @"afii10057",
                               [NSNumber numberWithInt:0x0409], @"afii10058",
                               [NSNumber numberWithInt:0x040A], @"afii10059",
                               [NSNumber numberWithInt:0x040B], @"afii10060",
                               [NSNumber numberWithInt:0x040C], @"afii10061",
                               [NSNumber numberWithInt:0x040E], @"afii10062",
                               [NSNumber numberWithInt:0xF6C4], @"afii10063",
                               [NSNumber numberWithInt:0xF6C5], @"afii10064",
                               [NSNumber numberWithInt:0x0430], @"afii10065",
                               [NSNumber numberWithInt:0x0431], @"afii10066",
                               [NSNumber numberWithInt:0x0432], @"afii10067",
                               [NSNumber numberWithInt:0x0433], @"afii10068",
                               [NSNumber numberWithInt:0x0434], @"afii10069",
                               [NSNumber numberWithInt:0x0435], @"afii10070",
                               [NSNumber numberWithInt:0x0451], @"afii10071",
                               [NSNumber numberWithInt:0x0436], @"afii10072",
                               [NSNumber numberWithInt:0x0437], @"afii10073",
                               [NSNumber numberWithInt:0x0438], @"afii10074",
                               [NSNumber numberWithInt:0x0439], @"afii10075",
                               [NSNumber numberWithInt:0x043A], @"afii10076",
                               [NSNumber numberWithInt:0x043B], @"afii10077",
                               [NSNumber numberWithInt:0x043C], @"afii10078",
                               [NSNumber numberWithInt:0x043D], @"afii10079",
                               [NSNumber numberWithInt:0x043E], @"afii10080",
                               [NSNumber numberWithInt:0x043F], @"afii10081",
                               [NSNumber numberWithInt:0x0440], @"afii10082",
                               [NSNumber numberWithInt:0x0441], @"afii10083",
                               [NSNumber numberWithInt:0x0442], @"afii10084",
                               [NSNumber numberWithInt:0x0443], @"afii10085",
                               [NSNumber numberWithInt:0x0444], @"afii10086",
                               [NSNumber numberWithInt:0x0445], @"afii10087",
                               [NSNumber numberWithInt:0x0446], @"afii10088",
                               [NSNumber numberWithInt:0x0447], @"afii10089",
                               [NSNumber numberWithInt:0x0448], @"afii10090",
                               [NSNumber numberWithInt:0x0449], @"afii10091",
                               [NSNumber numberWithInt:0x044A], @"afii10092",
                               [NSNumber numberWithInt:0x044B], @"afii10093",
                               [NSNumber numberWithInt:0x044C], @"afii10094",
                               [NSNumber numberWithInt:0x044D], @"afii10095",
                               [NSNumber numberWithInt:0x044E], @"afii10096",
                               [NSNumber numberWithInt:0x044F], @"afii10097",
                               [NSNumber numberWithInt:0x0491], @"afii10098",
                               [NSNumber numberWithInt:0x0452], @"afii10099",
                               [NSNumber numberWithInt:0x0453], @"afii10100",
                               [NSNumber numberWithInt:0x0454], @"afii10101",
                               [NSNumber numberWithInt:0x0455], @"afii10102",
                               [NSNumber numberWithInt:0x0456], @"afii10103",
                               [NSNumber numberWithInt:0x0457], @"afii10104",
                               [NSNumber numberWithInt:0x0458], @"afii10105",
                               [NSNumber numberWithInt:0x0459], @"afii10106",
                               [NSNumber numberWithInt:0x045A], @"afii10107",
                               [NSNumber numberWithInt:0x045B], @"afii10108",
                               [NSNumber numberWithInt:0x045C], @"afii10109",
                               [NSNumber numberWithInt:0x045E], @"afii10110",
                               [NSNumber numberWithInt:0x040F], @"afii10145",
                               [NSNumber numberWithInt:0x0462], @"afii10146",
                               [NSNumber numberWithInt:0x0472], @"afii10147",
                               [NSNumber numberWithInt:0x0474], @"afii10148",
                               [NSNumber numberWithInt:0xF6C6], @"afii10192",
                               [NSNumber numberWithInt:0x045F], @"afii10193",
                               [NSNumber numberWithInt:0x0463], @"afii10194",
                               [NSNumber numberWithInt:0x0473], @"afii10195",
                               [NSNumber numberWithInt:0x0475], @"afii10196",
                               [NSNumber numberWithInt:0xF6C7], @"afii10831",
                               [NSNumber numberWithInt:0xF6C8], @"afii10832",
                               [NSNumber numberWithInt:0x04D9], @"afii10846",
                               [NSNumber numberWithInt:0x200E], @"afii299",
                               [NSNumber numberWithInt:0x200F], @"afii300",
                               [NSNumber numberWithInt:0x200D], @"afii301",
                               [NSNumber numberWithInt:0x066A], @"afii57381",
                               [NSNumber numberWithInt:0x060C], @"afii57388",
                               [NSNumber numberWithInt:0x0660], @"afii57392",
                               [NSNumber numberWithInt:0x0661], @"afii57393",
                               [NSNumber numberWithInt:0x0662], @"afii57394",
                               [NSNumber numberWithInt:0x0663], @"afii57395",
                               [NSNumber numberWithInt:0x0664], @"afii57396",
                               [NSNumber numberWithInt:0x0665], @"afii57397",
                               [NSNumber numberWithInt:0x0666], @"afii57398",
                               [NSNumber numberWithInt:0x0667], @"afii57399",
                               [NSNumber numberWithInt:0x0668], @"afii57400",
                               [NSNumber numberWithInt:0x0669], @"afii57401",
                               [NSNumber numberWithInt:0x061B], @"afii57403",
                               [NSNumber numberWithInt:0x061F], @"afii57407",
                               [NSNumber numberWithInt:0x0621], @"afii57409",
                               [NSNumber numberWithInt:0x0622], @"afii57410",
                               [NSNumber numberWithInt:0x0623], @"afii57411",
                               [NSNumber numberWithInt:0x0624], @"afii57412",
                               [NSNumber numberWithInt:0x0625], @"afii57413",
                               [NSNumber numberWithInt:0x0626], @"afii57414",
                               [NSNumber numberWithInt:0x0627], @"afii57415",
                               [NSNumber numberWithInt:0x0628], @"afii57416",
                               [NSNumber numberWithInt:0x0629], @"afii57417",
                               [NSNumber numberWithInt:0x062A], @"afii57418",
                               [NSNumber numberWithInt:0x062B], @"afii57419",
                               [NSNumber numberWithInt:0x062C], @"afii57420",
                               [NSNumber numberWithInt:0x062D], @"afii57421",
                               [NSNumber numberWithInt:0x062E], @"afii57422",
                               [NSNumber numberWithInt:0x062F], @"afii57423",
                               [NSNumber numberWithInt:0x0630], @"afii57424",
                               [NSNumber numberWithInt:0x0631], @"afii57425",
                               [NSNumber numberWithInt:0x0632], @"afii57426",
                               [NSNumber numberWithInt:0x0633], @"afii57427",
                               [NSNumber numberWithInt:0x0634], @"afii57428",
                               [NSNumber numberWithInt:0x0635], @"afii57429",
                               [NSNumber numberWithInt:0x0636], @"afii57430",
                               [NSNumber numberWithInt:0x0637], @"afii57431",
                               [NSNumber numberWithInt:0x0638], @"afii57432",
                               [NSNumber numberWithInt:0x0639], @"afii57433",
                               [NSNumber numberWithInt:0x063A], @"afii57434",
                               [NSNumber numberWithInt:0x0640], @"afii57440",
                               [NSNumber numberWithInt:0x0641], @"afii57441",
                               [NSNumber numberWithInt:0x0642], @"afii57442",
                               [NSNumber numberWithInt:0x0643], @"afii57443",
                               [NSNumber numberWithInt:0x0644], @"afii57444",
                               [NSNumber numberWithInt:0x0645], @"afii57445",
                               [NSNumber numberWithInt:0x0646], @"afii57446",
                               [NSNumber numberWithInt:0x0648], @"afii57448",
                               [NSNumber numberWithInt:0x0649], @"afii57449",
                               [NSNumber numberWithInt:0x064A], @"afii57450",
                               [NSNumber numberWithInt:0x064B], @"afii57451",
                               [NSNumber numberWithInt:0x064C], @"afii57452",
                               [NSNumber numberWithInt:0x064D], @"afii57453",
                               [NSNumber numberWithInt:0x064E], @"afii57454",
                               [NSNumber numberWithInt:0x064F], @"afii57455",
                               [NSNumber numberWithInt:0x0650], @"afii57456",
                               [NSNumber numberWithInt:0x0651], @"afii57457",
                               [NSNumber numberWithInt:0x0652], @"afii57458",
                               [NSNumber numberWithInt:0x0647], @"afii57470",
                               [NSNumber numberWithInt:0x06A4], @"afii57505",
                               [NSNumber numberWithInt:0x067E], @"afii57506",
                               [NSNumber numberWithInt:0x0686], @"afii57507",
                               [NSNumber numberWithInt:0x0698], @"afii57508",
                               [NSNumber numberWithInt:0x06AF], @"afii57509",
                               [NSNumber numberWithInt:0x0679], @"afii57511",
                               [NSNumber numberWithInt:0x0688], @"afii57512",
                               [NSNumber numberWithInt:0x0691], @"afii57513",
                               [NSNumber numberWithInt:0x06BA], @"afii57514",
                               [NSNumber numberWithInt:0x06D2], @"afii57519",
                               [NSNumber numberWithInt:0x06D5], @"afii57534",
                               [NSNumber numberWithInt:0x20AA], @"afii57636",
                               [NSNumber numberWithInt:0x05BE], @"afii57645",
                               [NSNumber numberWithInt:0x05C3], @"afii57658",
                               [NSNumber numberWithInt:0x05D0], @"afii57664",
                               [NSNumber numberWithInt:0x05D1], @"afii57665",
                               [NSNumber numberWithInt:0x05D2], @"afii57666",
                               [NSNumber numberWithInt:0x05D3], @"afii57667",
                               [NSNumber numberWithInt:0x05D4], @"afii57668",
                               [NSNumber numberWithInt:0x05D5], @"afii57669",
                               [NSNumber numberWithInt:0x05D6], @"afii57670",
                               [NSNumber numberWithInt:0x05D7], @"afii57671",
                               [NSNumber numberWithInt:0x05D8], @"afii57672",
                               [NSNumber numberWithInt:0x05D9], @"afii57673",
                               [NSNumber numberWithInt:0x05DA], @"afii57674",
                               [NSNumber numberWithInt:0x05DB], @"afii57675",
                               [NSNumber numberWithInt:0x05DC], @"afii57676",
                               [NSNumber numberWithInt:0x05DD], @"afii57677",
                               [NSNumber numberWithInt:0x05DE], @"afii57678",
                               [NSNumber numberWithInt:0x05DF], @"afii57679",
                               [NSNumber numberWithInt:0x05E0], @"afii57680",
                               [NSNumber numberWithInt:0x05E1], @"afii57681",
                               [NSNumber numberWithInt:0x05E2], @"afii57682",
                               [NSNumber numberWithInt:0x05E3], @"afii57683",
                               [NSNumber numberWithInt:0x05E4], @"afii57684",
                               [NSNumber numberWithInt:0x05E5], @"afii57685",
                               [NSNumber numberWithInt:0x05E6], @"afii57686",
                               [NSNumber numberWithInt:0x05E7], @"afii57687",
                               [NSNumber numberWithInt:0x05E8], @"afii57688",
                               [NSNumber numberWithInt:0x05E9], @"afii57689",
                               [NSNumber numberWithInt:0x05EA], @"afii57690",
                               [NSNumber numberWithInt:0xFB2A], @"afii57694",
                               [NSNumber numberWithInt:0xFB2B], @"afii57695",
                               [NSNumber numberWithInt:0xFB4B], @"afii57700",
                               [NSNumber numberWithInt:0xFB1F], @"afii57705",
                               [NSNumber numberWithInt:0x05F0], @"afii57716",
                               [NSNumber numberWithInt:0x05F1], @"afii57717",
                               [NSNumber numberWithInt:0x05F2], @"afii57718",
                               [NSNumber numberWithInt:0xFB35], @"afii57723",
                               [NSNumber numberWithInt:0x05B4], @"afii57793",
                               [NSNumber numberWithInt:0x05B5], @"afii57794",
                               [NSNumber numberWithInt:0x05B6], @"afii57795",
                               [NSNumber numberWithInt:0x05BB], @"afii57796",
                               [NSNumber numberWithInt:0x05B8], @"afii57797",
                               [NSNumber numberWithInt:0x05B7], @"afii57798",
                               [NSNumber numberWithInt:0x05B0], @"afii57799",
                               [NSNumber numberWithInt:0x05B2], @"afii57800",
                               [NSNumber numberWithInt:0x05B1], @"afii57801",
                               [NSNumber numberWithInt:0x05B3], @"afii57802",
                               [NSNumber numberWithInt:0x05C2], @"afii57803",
                               [NSNumber numberWithInt:0x05C1], @"afii57804",
                               [NSNumber numberWithInt:0x05B9], @"afii57806",
                               [NSNumber numberWithInt:0x05BC], @"afii57807",
                               [NSNumber numberWithInt:0x05BD], @"afii57839",
                               [NSNumber numberWithInt:0x05BF], @"afii57841",
                               [NSNumber numberWithInt:0x05C0], @"afii57842",
                               [NSNumber numberWithInt:0x02BC], @"afii57929",
                               [NSNumber numberWithInt:0x2105], @"afii61248",
                               [NSNumber numberWithInt:0x2113], @"afii61289",
                               [NSNumber numberWithInt:0x2116], @"afii61352",
                               [NSNumber numberWithInt:0x202C], @"afii61573",
                               [NSNumber numberWithInt:0x202D], @"afii61574",
                               [NSNumber numberWithInt:0x202E], @"afii61575",
                               [NSNumber numberWithInt:0x200C], @"afii61664",
                               [NSNumber numberWithInt:0x066D], @"afii63167",
                               [NSNumber numberWithInt:0x02BD], @"afii64937",
                               [NSNumber numberWithInt:0x00E0], @"agrave",
                               [NSNumber numberWithInt:0x0A85], @"agujarati",
                               [NSNumber numberWithInt:0x0A05], @"agurmukhi",
                               [NSNumber numberWithInt:0x3042], @"ahiragana",
                               [NSNumber numberWithInt:0x1EA3], @"ahookabove",
                               [NSNumber numberWithInt:0x0990], @"aibengali",
                               [NSNumber numberWithInt:0x311E], @"aibopomofo",
                               [NSNumber numberWithInt:0x0910], @"aideva",
                               [NSNumber numberWithInt:0x04D5], @"aiecyrillic",
                               [NSNumber numberWithInt:0x0A90], @"aigujarati",
                               [NSNumber numberWithInt:0x0A10], @"aigurmukhi",
                               [NSNumber numberWithInt:0x0A48], @"aimatragurmukhi",
                               [NSNumber numberWithInt:0x0639], @"ainarabic",
                               [NSNumber numberWithInt:0xFECA], @"ainfinalarabic",
                               [NSNumber numberWithInt:0xFECB], @"aininitialarabic",
                               [NSNumber numberWithInt:0xFECC], @"ainmedialarabic",
                               [NSNumber numberWithInt:0x0203], @"ainvertedbreve",
                               [NSNumber numberWithInt:0x09C8], @"aivowelsignbengali",
                               [NSNumber numberWithInt:0x0948], @"aivowelsigndeva",
                               [NSNumber numberWithInt:0x0AC8], @"aivowelsigngujarati",
                               [NSNumber numberWithInt:0x30A2], @"akatakana",
                               [NSNumber numberWithInt:0xFF71], @"akatakanahalfwidth",
                               [NSNumber numberWithInt:0x314F], @"akorean",
                               [NSNumber numberWithInt:0x05D0], @"alef",
                               [NSNumber numberWithInt:0x0627], @"alefarabic",
                               [NSNumber numberWithInt:0xFB30], @"alefdageshhebrew",
                               [NSNumber numberWithInt:0xFE8E], @"aleffinalarabic",
                               [NSNumber numberWithInt:0x0623], @"alefhamzaabovearabic",
                               [NSNumber numberWithInt:0xFE84], @"alefhamzaabovefinalarabic",
                               [NSNumber numberWithInt:0x0625], @"alefhamzabelowarabic",
                               [NSNumber numberWithInt:0xFE88], @"alefhamzabelowfinalarabic",
                               [NSNumber numberWithInt:0x05D0], @"alefhebrew",
                               [NSNumber numberWithInt:0xFB4F], @"aleflamedhebrew",
                               [NSNumber numberWithInt:0x0622], @"alefmaddaabovearabic",
                               [NSNumber numberWithInt:0xFE82], @"alefmaddaabovefinalarabic",
                               [NSNumber numberWithInt:0x0649], @"alefmaksuraarabic",
                               [NSNumber numberWithInt:0xFEF0], @"alefmaksurafinalarabic",
                               [NSNumber numberWithInt:0xFEF3], @"alefmaksurainitialarabic",
                               [NSNumber numberWithInt:0xFEF4], @"alefmaksuramedialarabic",
                               [NSNumber numberWithInt:0xFB2E], @"alefpatahhebrew",
                               [NSNumber numberWithInt:0xFB2F], @"alefqamatshebrew",
                               [NSNumber numberWithInt:0x2135], @"aleph",
                               [NSNumber numberWithInt:0x224C], @"allequal",
                               [NSNumber numberWithInt:0x03B1], @"alpha",
                               [NSNumber numberWithInt:0x03AC], @"alphatonos",
                               [NSNumber numberWithInt:0x0101], @"amacron",
                               [NSNumber numberWithInt:0xFF41], @"amonospace",
                               [NSNumber numberWithInt:0x0026], @"ampersand",
                               [NSNumber numberWithInt:0xFF06], @"ampersandmonospace",
                               [NSNumber numberWithInt:0xF726], @"ampersandsmall",
                               [NSNumber numberWithInt:0x33C2], @"amsquare",
                               [NSNumber numberWithInt:0x3122], @"anbopomofo",
                               [NSNumber numberWithInt:0x3124], @"angbopomofo",
                               [NSNumber numberWithInt:0x0E5A], @"angkhankhuthai",
                               [NSNumber numberWithInt:0x2220], @"angle",
                               [NSNumber numberWithInt:0x3008], @"anglebracketleft",
                               [NSNumber numberWithInt:0xFE3F], @"anglebracketleftvertical",
                               [NSNumber numberWithInt:0x3009], @"anglebracketright",
                               [NSNumber numberWithInt:0xFE40], @"anglebracketrightvertical",
                               [NSNumber numberWithInt:0x2329], @"angleleft",
                               [NSNumber numberWithInt:0x232A], @"angleright",
                               [NSNumber numberWithInt:0x212B], @"angstrom",
                               [NSNumber numberWithInt:0x0387], @"anoteleia",
                               [NSNumber numberWithInt:0x0952], @"anudattadeva",
                               [NSNumber numberWithInt:0x0982], @"anusvarabengali",
                               [NSNumber numberWithInt:0x0902], @"anusvaradeva",
                               [NSNumber numberWithInt:0x0A82], @"anusvaragujarati",
                               [NSNumber numberWithInt:0x0105], @"aogonek",
                               [NSNumber numberWithInt:0x3300], @"apaatosquare",
                               [NSNumber numberWithInt:0x249C], @"aparen",
                               [NSNumber numberWithInt:0x055A], @"apostrophearmenian",
                               [NSNumber numberWithInt:0x02BC], @"apostrophemod",
                               [NSNumber numberWithInt:0xF8FF], @"apple",
                               [NSNumber numberWithInt:0x2250], @"approaches",
                               [NSNumber numberWithInt:0x2248], @"approxequal",
                               [NSNumber numberWithInt:0x2252], @"approxequalorimage",
                               [NSNumber numberWithInt:0x2245], @"approximatelyequal",
                               [NSNumber numberWithInt:0x318E], @"araeaekorean",
                               [NSNumber numberWithInt:0x318D], @"araeakorean",
                               [NSNumber numberWithInt:0x2312], @"arc",
                               [NSNumber numberWithInt:0x1E9A], @"arighthalfring",
                               [NSNumber numberWithInt:0x00E5], @"aring",
                               [NSNumber numberWithInt:0x01FB], @"aringacute",
                               [NSNumber numberWithInt:0x1E01], @"aringbelow",
                               [NSNumber numberWithInt:0x2194], @"arrowboth",
                               [NSNumber numberWithInt:0x21E3], @"arrowdashdown",
                               [NSNumber numberWithInt:0x21E0], @"arrowdashleft",
                               [NSNumber numberWithInt:0x21E2], @"arrowdashright",
                               [NSNumber numberWithInt:0x21E1], @"arrowdashup",
                               [NSNumber numberWithInt:0x21D4], @"arrowdblboth",
                               [NSNumber numberWithInt:0x21D3], @"arrowdbldown",
                               [NSNumber numberWithInt:0x21D0], @"arrowdblleft",
                               [NSNumber numberWithInt:0x21D2], @"arrowdblright",
                               [NSNumber numberWithInt:0x21D1], @"arrowdblup",
                               [NSNumber numberWithInt:0x2193], @"arrowdown",
                               [NSNumber numberWithInt:0x2199], @"arrowdownleft",
                               [NSNumber numberWithInt:0x2198], @"arrowdownright",
                               [NSNumber numberWithInt:0x21E9], @"arrowdownwhite",
                               [NSNumber numberWithInt:0x02C5], @"arrowheaddownmod",
                               [NSNumber numberWithInt:0x02C2], @"arrowheadleftmod",
                               [NSNumber numberWithInt:0x02C3], @"arrowheadrightmod",
                               [NSNumber numberWithInt:0x02C4], @"arrowheadupmod",
                               [NSNumber numberWithInt:0xF8E7], @"arrowhorizex",
                               [NSNumber numberWithInt:0x2190], @"arrowleft",
                               [NSNumber numberWithInt:0x21D0], @"arrowleftdbl",
                               [NSNumber numberWithInt:0x21CD], @"arrowleftdblstroke",
                               [NSNumber numberWithInt:0x21C6], @"arrowleftoverright",
                               [NSNumber numberWithInt:0x21E6], @"arrowleftwhite",
                               [NSNumber numberWithInt:0x2192], @"arrowright",
                               [NSNumber numberWithInt:0x21CF], @"arrowrightdblstroke",
                               [NSNumber numberWithInt:0x279E], @"arrowrightheavy",
                               [NSNumber numberWithInt:0x21C4], @"arrowrightoverleft",
                               [NSNumber numberWithInt:0x21E8], @"arrowrightwhite",
                               [NSNumber numberWithInt:0x21E4], @"arrowtableft",
                               [NSNumber numberWithInt:0x21E5], @"arrowtabright",
                               [NSNumber numberWithInt:0x2191], @"arrowup",
                               [NSNumber numberWithInt:0x2195], @"arrowupdn",
                               [NSNumber numberWithInt:0x21A8], @"arrowupdnbse",
                               [NSNumber numberWithInt:0x21A8], @"arrowupdownbase",
                               [NSNumber numberWithInt:0x2196], @"arrowupleft",
                               [NSNumber numberWithInt:0x21C5], @"arrowupleftofdown",
                               [NSNumber numberWithInt:0x2197], @"arrowupright",
                               [NSNumber numberWithInt:0x21E7], @"arrowupwhite",
                               [NSNumber numberWithInt:0xF8E6], @"arrowvertex",
                               [NSNumber numberWithInt:0x005E], @"asciicircum",
                               [NSNumber numberWithInt:0xFF3E], @"asciicircummonospace",
                               [NSNumber numberWithInt:0x007E], @"asciitilde",
                               [NSNumber numberWithInt:0xFF5E], @"asciitildemonospace",
                               [NSNumber numberWithInt:0x0251], @"ascript",
                               [NSNumber numberWithInt:0x0252], @"ascriptturned",
                               [NSNumber numberWithInt:0x3041], @"asmallhiragana",
                               [NSNumber numberWithInt:0x30A1], @"asmallkatakana",
                               [NSNumber numberWithInt:0xFF67], @"asmallkatakanahalfwidth",
                               [NSNumber numberWithInt:0x002A], @"asterisk",
                               [NSNumber numberWithInt:0x066D], @"asteriskaltonearabic",
                               [NSNumber numberWithInt:0x066D], @"asteriskarabic",
                               [NSNumber numberWithInt:0x2217], @"asteriskmath",
                               [NSNumber numberWithInt:0xFF0A], @"asteriskmonospace",
                               [NSNumber numberWithInt:0xFE61], @"asterisksmall",
                               [NSNumber numberWithInt:0x2042], @"asterism",
                               [NSNumber numberWithInt:0xF6E9], @"asuperior",
                               [NSNumber numberWithInt:0x2243], @"asymptoticallyequal",
                               [NSNumber numberWithInt:0x0040], @"at",
                               [NSNumber numberWithInt:0x00E3], @"atilde",
                               [NSNumber numberWithInt:0xFF20], @"atmonospace",
                               [NSNumber numberWithInt:0xFE6B], @"atsmall",
                               [NSNumber numberWithInt:0x0250], @"aturned",
                               [NSNumber numberWithInt:0x0994], @"aubengali",
                               [NSNumber numberWithInt:0x3120], @"aubopomofo",
                               [NSNumber numberWithInt:0x0914], @"audeva",
                               [NSNumber numberWithInt:0x0A94], @"augujarati",
                               [NSNumber numberWithInt:0x0A14], @"augurmukhi",
                               [NSNumber numberWithInt:0x09D7], @"aulengthmarkbengali",
                               [NSNumber numberWithInt:0x0A4C], @"aumatragurmukhi",
                               [NSNumber numberWithInt:0x09CC], @"auvowelsignbengali",
                               [NSNumber numberWithInt:0x094C], @"auvowelsigndeva",
                               [NSNumber numberWithInt:0x0ACC], @"auvowelsigngujarati",
                               [NSNumber numberWithInt:0x093D], @"avagrahadeva",
                               [NSNumber numberWithInt:0x0561], @"aybarmenian",
                               [NSNumber numberWithInt:0x05E2], @"ayin",
                               [NSNumber numberWithInt:0xFB20], @"ayinaltonehebrew",
                               [NSNumber numberWithInt:0x05E2], @"ayinhebrew",
                               [NSNumber numberWithInt:0x0062], @"b",
                               [NSNumber numberWithInt:0x09AC], @"babengali",
                               [NSNumber numberWithInt:0x005C], @"backslash",
                               [NSNumber numberWithInt:0xFF3C], @"backslashmonospace",
                               [NSNumber numberWithInt:0x092C], @"badeva",
                               [NSNumber numberWithInt:0x0AAC], @"bagujarati",
                               [NSNumber numberWithInt:0x0A2C], @"bagurmukhi",
                               [NSNumber numberWithInt:0x3070], @"bahiragana",
                               [NSNumber numberWithInt:0x0E3F], @"bahtthai",
                               [NSNumber numberWithInt:0x30D0], @"bakatakana",
                               [NSNumber numberWithInt:0x007C], @"bar",
                               [NSNumber numberWithInt:0xFF5C], @"barmonospace",
                               [NSNumber numberWithInt:0x3105], @"bbopomofo",
                               [NSNumber numberWithInt:0x24D1], @"bcircle",
                               [NSNumber numberWithInt:0x1E03], @"bdotaccent",
                               [NSNumber numberWithInt:0x1E05], @"bdotbelow",
                               [NSNumber numberWithInt:0x266C], @"beamedsixteenthnotes",
                               [NSNumber numberWithInt:0x2235], @"because",
                               [NSNumber numberWithInt:0x0431], @"becyrillic",
                               [NSNumber numberWithInt:0x0628], @"beharabic",
                               [NSNumber numberWithInt:0xFE90], @"behfinalarabic",
                               [NSNumber numberWithInt:0xFE91], @"behinitialarabic",
                               [NSNumber numberWithInt:0x3079], @"behiragana",
                               [NSNumber numberWithInt:0xFE92], @"behmedialarabic",
                               [NSNumber numberWithInt:0xFC9F], @"behmeeminitialarabic",
                               [NSNumber numberWithInt:0xFC08], @"behmeemisolatedarabic",
                               [NSNumber numberWithInt:0xFC6D], @"behnoonfinalarabic",
                               [NSNumber numberWithInt:0x30D9], @"bekatakana",
                               [NSNumber numberWithInt:0x0562], @"benarmenian",
                               [NSNumber numberWithInt:0x05D1], @"bet",
                               [NSNumber numberWithInt:0x03B2], @"beta",
                               [NSNumber numberWithInt:0x03D0], @"betasymbolgreek",
                               [NSNumber numberWithInt:0xFB31], @"betdagesh",
                               [NSNumber numberWithInt:0xFB31], @"betdageshhebrew",
                               [NSNumber numberWithInt:0x05D1], @"bethebrew",
                               [NSNumber numberWithInt:0xFB4C], @"betrafehebrew",
                               [NSNumber numberWithInt:0x09AD], @"bhabengali",
                               [NSNumber numberWithInt:0x092D], @"bhadeva",
                               [NSNumber numberWithInt:0x0AAD], @"bhagujarati",
                               [NSNumber numberWithInt:0x0A2D], @"bhagurmukhi",
                               [NSNumber numberWithInt:0x0253], @"bhook",
                               [NSNumber numberWithInt:0x3073], @"bihiragana",
                               [NSNumber numberWithInt:0x30D3], @"bikatakana",
                               [NSNumber numberWithInt:0x0298], @"bilabialclick",
                               [NSNumber numberWithInt:0x0A02], @"bindigurmukhi",
                               [NSNumber numberWithInt:0x3331], @"birusquare",
                               [NSNumber numberWithInt:0x25CF], @"blackcircle",
                               [NSNumber numberWithInt:0x25C6], @"blackdiamond",
                               [NSNumber numberWithInt:0x25BC], @"blackdownpointingtriangle",
                               [NSNumber numberWithInt:0x25C4], @"blackleftpointingpointer",
                               [NSNumber numberWithInt:0x25C0], @"blackleftpointingtriangle",
                               [NSNumber numberWithInt:0x3010], @"blacklenticularbracketleft",
                               [NSNumber numberWithInt:0xFE3B], @"blacklenticularbracketleftvertical",
                               [NSNumber numberWithInt:0x3011], @"blacklenticularbracketright",
                               [NSNumber numberWithInt:0xFE3C], @"blacklenticularbracketrightvertical",
                               [NSNumber numberWithInt:0x25E3], @"blacklowerlefttriangle",
                               [NSNumber numberWithInt:0x25E2], @"blacklowerrighttriangle",
                               [NSNumber numberWithInt:0x25AC], @"blackrectangle",
                               [NSNumber numberWithInt:0x25BA], @"blackrightpointingpointer",
                               [NSNumber numberWithInt:0x25B6], @"blackrightpointingtriangle",
                               [NSNumber numberWithInt:0x25AA], @"blacksmallsquare",
                               [NSNumber numberWithInt:0x263B], @"blacksmilingface",
                               [NSNumber numberWithInt:0x25A0], @"blacksquare",
                               [NSNumber numberWithInt:0x2605], @"blackstar",
                               [NSNumber numberWithInt:0x25E4], @"blackupperlefttriangle",
                               [NSNumber numberWithInt:0x25E5], @"blackupperrighttriangle",
                               [NSNumber numberWithInt:0x25B4], @"blackuppointingsmalltriangle",
                               [NSNumber numberWithInt:0x25B2], @"blackuppointingtriangle",
                               [NSNumber numberWithInt:0x2423], @"blank",
                               [NSNumber numberWithInt:0x1E07], @"blinebelow",
                               [NSNumber numberWithInt:0x2588], @"block",
                               [NSNumber numberWithInt:0xFF42], @"bmonospace",
                               [NSNumber numberWithInt:0x0E1A], @"bobaimaithai",
                               [NSNumber numberWithInt:0x307C], @"bohiragana",
                               [NSNumber numberWithInt:0x30DC], @"bokatakana",
                               [NSNumber numberWithInt:0x249D], @"bparen",
                               [NSNumber numberWithInt:0x33C3], @"bqsquare",
                               [NSNumber numberWithInt:0xF8F4], @"braceex",
                               [NSNumber numberWithInt:0x007B], @"braceleft",
                               [NSNumber numberWithInt:0xF8F3], @"braceleftbt",
                               [NSNumber numberWithInt:0xF8F2], @"braceleftmid",
                               [NSNumber numberWithInt:0xFF5B], @"braceleftmonospace",
                               [NSNumber numberWithInt:0xFE5B], @"braceleftsmall",
                               [NSNumber numberWithInt:0xF8F1], @"bracelefttp",
                               [NSNumber numberWithInt:0xFE37], @"braceleftvertical",
                               [NSNumber numberWithInt:0x007D], @"braceright",
                               [NSNumber numberWithInt:0xF8FE], @"bracerightbt",
                               [NSNumber numberWithInt:0xF8FD], @"bracerightmid",
                               [NSNumber numberWithInt:0xFF5D], @"bracerightmonospace",
                               [NSNumber numberWithInt:0xFE5C], @"bracerightsmall",
                               [NSNumber numberWithInt:0xF8FC], @"bracerighttp",
                               [NSNumber numberWithInt:0xFE38], @"bracerightvertical",
                               [NSNumber numberWithInt:0x005B], @"bracketleft",
                               [NSNumber numberWithInt:0xF8F0], @"bracketleftbt",
                               [NSNumber numberWithInt:0xF8EF], @"bracketleftex",
                               [NSNumber numberWithInt:0xFF3B], @"bracketleftmonospace",
                               [NSNumber numberWithInt:0xF8EE], @"bracketlefttp",
                               [NSNumber numberWithInt:0x005D], @"bracketright",
                               [NSNumber numberWithInt:0xF8FB], @"bracketrightbt",
                               [NSNumber numberWithInt:0xF8FA], @"bracketrightex",
                               [NSNumber numberWithInt:0xFF3D], @"bracketrightmonospace",
                               [NSNumber numberWithInt:0xF8F9], @"bracketrighttp",
                               [NSNumber numberWithInt:0x02D8], @"breve",
                               [NSNumber numberWithInt:0x032E], @"brevebelowcmb",
                               [NSNumber numberWithInt:0x0306], @"brevecmb",
                               [NSNumber numberWithInt:0x032F], @"breveinvertedbelowcmb",
                               [NSNumber numberWithInt:0x0311], @"breveinvertedcmb",
                               [NSNumber numberWithInt:0x0361], @"breveinverteddoublecmb",
                               [NSNumber numberWithInt:0x032A], @"bridgebelowcmb",
                               [NSNumber numberWithInt:0x033A], @"bridgeinvertedbelowcmb",
                               [NSNumber numberWithInt:0x00A6], @"brokenbar",
                               [NSNumber numberWithInt:0x0180], @"bstroke",
                               [NSNumber numberWithInt:0xF6EA], @"bsuperior",
                               [NSNumber numberWithInt:0x0183], @"btopbar",
                               [NSNumber numberWithInt:0x3076], @"buhiragana",
                               [NSNumber numberWithInt:0x30D6], @"bukatakana",
                               [NSNumber numberWithInt:0x2022], @"bullet",
                               [NSNumber numberWithInt:0x25D8], @"bulletinverse",
                               [NSNumber numberWithInt:0x2219], @"bulletoperator",
                               [NSNumber numberWithInt:0x25CE], @"bullseye",
                               [NSNumber numberWithInt:0x0063], @"c",
                               [NSNumber numberWithInt:0x056E], @"caarmenian",
                               [NSNumber numberWithInt:0x099A], @"cabengali",
                               [NSNumber numberWithInt:0x0107], @"cacute",
                               [NSNumber numberWithInt:0x091A], @"cadeva",
                               [NSNumber numberWithInt:0x0A9A], @"cagujarati",
                               [NSNumber numberWithInt:0x0A1A], @"cagurmukhi",
                               [NSNumber numberWithInt:0x3388], @"calsquare",
                               [NSNumber numberWithInt:0x0981], @"candrabindubengali",
                               [NSNumber numberWithInt:0x0310], @"candrabinducmb",
                               [NSNumber numberWithInt:0x0901], @"candrabindudeva",
                               [NSNumber numberWithInt:0x0A81], @"candrabindugujarati",
                               [NSNumber numberWithInt:0x21EA], @"capslock",
                               [NSNumber numberWithInt:0x2105], @"careof",
                               [NSNumber numberWithInt:0x02C7], @"caron",
                               [NSNumber numberWithInt:0x032C], @"caronbelowcmb",
                               [NSNumber numberWithInt:0x030C], @"caroncmb",
                               [NSNumber numberWithInt:0x21B5], @"carriagereturn",
                               [NSNumber numberWithInt:0x3118], @"cbopomofo",
                               [NSNumber numberWithInt:0x010D], @"ccaron",
                               [NSNumber numberWithInt:0x00E7], @"ccedilla",
                               [NSNumber numberWithInt:0x1E09], @"ccedillaacute",
                               [NSNumber numberWithInt:0x24D2], @"ccircle",
                               [NSNumber numberWithInt:0x0109], @"ccircumflex",
                               [NSNumber numberWithInt:0x0255], @"ccurl",
                               [NSNumber numberWithInt:0x010B], @"cdot",
                               [NSNumber numberWithInt:0x010B], @"cdotaccent",
                               [NSNumber numberWithInt:0x33C5], @"cdsquare",
                               [NSNumber numberWithInt:0x00B8], @"cedilla",
                               [NSNumber numberWithInt:0x0327], @"cedillacmb",
                               [NSNumber numberWithInt:0x00A2], @"cent",
                               [NSNumber numberWithInt:0x2103], @"centigrade",
                               [NSNumber numberWithInt:0xF6DF], @"centinferior",
                               [NSNumber numberWithInt:0xFFE0], @"centmonospace",
                               [NSNumber numberWithInt:0xF7A2], @"centoldstyle",
                               [NSNumber numberWithInt:0xF6E0], @"centsuperior",
                               [NSNumber numberWithInt:0x0579], @"chaarmenian",
                               [NSNumber numberWithInt:0x099B], @"chabengali",
                               [NSNumber numberWithInt:0x091B], @"chadeva",
                               [NSNumber numberWithInt:0x0A9B], @"chagujarati",
                               [NSNumber numberWithInt:0x0A1B], @"chagurmukhi",
                               [NSNumber numberWithInt:0x3114], @"chbopomofo",
                               [NSNumber numberWithInt:0x04BD], @"cheabkhasiancyrillic",
                               [NSNumber numberWithInt:0x2713], @"checkmark",
                               [NSNumber numberWithInt:0x0447], @"checyrillic",
                               [NSNumber numberWithInt:0x04BF], @"chedescenderabkhasiancyrillic",
                               [NSNumber numberWithInt:0x04B7], @"chedescendercyrillic",
                               [NSNumber numberWithInt:0x04F5], @"chedieresiscyrillic",
                               [NSNumber numberWithInt:0x0573], @"cheharmenian",
                               [NSNumber numberWithInt:0x04CC], @"chekhakassiancyrillic",
                               [NSNumber numberWithInt:0x04B9], @"cheverticalstrokecyrillic",
                               [NSNumber numberWithInt:0x03C7], @"chi",
                               [NSNumber numberWithInt:0x3277], @"chieuchacirclekorean",
                               [NSNumber numberWithInt:0x3217], @"chieuchaparenkorean",
                               [NSNumber numberWithInt:0x3269], @"chieuchcirclekorean",
                               [NSNumber numberWithInt:0x314A], @"chieuchkorean",
                               [NSNumber numberWithInt:0x3209], @"chieuchparenkorean",
                               [NSNumber numberWithInt:0x0E0A], @"chochangthai",
                               [NSNumber numberWithInt:0x0E08], @"chochanthai",
                               [NSNumber numberWithInt:0x0E09], @"chochingthai",
                               [NSNumber numberWithInt:0x0E0C], @"chochoethai",
                               [NSNumber numberWithInt:0x0188], @"chook",
                               [NSNumber numberWithInt:0x3276], @"cieucacirclekorean",
                               [NSNumber numberWithInt:0x3216], @"cieucaparenkorean",
                               [NSNumber numberWithInt:0x3268], @"cieuccirclekorean",
                               [NSNumber numberWithInt:0x3148], @"cieuckorean",
                               [NSNumber numberWithInt:0x3208], @"cieucparenkorean",
                               [NSNumber numberWithInt:0x321C], @"cieucuparenkorean",
                               [NSNumber numberWithInt:0x25CB], @"circle",
                               [NSNumber numberWithInt:0x2297], @"circlemultiply",
                               [NSNumber numberWithInt:0x2299], @"circleot",
                               [NSNumber numberWithInt:0x2295], @"circleplus",
                               [NSNumber numberWithInt:0x3036], @"circlepostalmark",
                               [NSNumber numberWithInt:0x25D0], @"circlewithlefthalfblack",
                               [NSNumber numberWithInt:0x25D1], @"circlewithrighthalfblack",
                               [NSNumber numberWithInt:0x02C6], @"circumflex",
                               [NSNumber numberWithInt:0x032D], @"circumflexbelowcmb",
                               [NSNumber numberWithInt:0x0302], @"circumflexcmb",
                               [NSNumber numberWithInt:0x2327], @"clear",
                               [NSNumber numberWithInt:0x01C2], @"clickalveolar",
                               [NSNumber numberWithInt:0x01C0], @"clickdental",
                               [NSNumber numberWithInt:0x01C1], @"clicklateral",
                               [NSNumber numberWithInt:0x01C3], @"clickretroflex",
                               [NSNumber numberWithInt:0x2663], @"club",
                               [NSNumber numberWithInt:0x2663], @"clubsuitblack",
                               [NSNumber numberWithInt:0x2667], @"clubsuitwhite",
                               [NSNumber numberWithInt:0x33A4], @"cmcubedsquare",
                               [NSNumber numberWithInt:0xFF43], @"cmonospace",
                               [NSNumber numberWithInt:0x33A0], @"cmsquaredsquare",
                               [NSNumber numberWithInt:0x0581], @"coarmenian",
                               [NSNumber numberWithInt:0x003A], @"colon",
                               [NSNumber numberWithInt:0x20A1], @"colonmonetary",
                               [NSNumber numberWithInt:0xFF1A], @"colonmonospace",
                               [NSNumber numberWithInt:0x20A1], @"colonsign",
                               [NSNumber numberWithInt:0xFE55], @"colonsmall",
                               [NSNumber numberWithInt:0x02D1], @"colontriangularhalfmod",
                               [NSNumber numberWithInt:0x02D0], @"colontriangularmod",
                               [NSNumber numberWithInt:0x002C], @"comma",
                               [NSNumber numberWithInt:0x0313], @"commaabovecmb",
                               [NSNumber numberWithInt:0x0315], @"commaaboverightcmb",
                               [NSNumber numberWithInt:0xF6C3], @"commaaccent",
                               [NSNumber numberWithInt:0x060C], @"commaarabic",
                               [NSNumber numberWithInt:0x055D], @"commaarmenian",
                               [NSNumber numberWithInt:0xF6E1], @"commainferior",
                               [NSNumber numberWithInt:0xFF0C], @"commamonospace",
                               [NSNumber numberWithInt:0x0314], @"commareversedabovecmb",
                               [NSNumber numberWithInt:0x02BD], @"commareversedmod",
                               [NSNumber numberWithInt:0xFE50], @"commasmall",
                               [NSNumber numberWithInt:0xF6E2], @"commasuperior",
                               [NSNumber numberWithInt:0x0312], @"commaturnedabovecmb",
                               [NSNumber numberWithInt:0x02BB], @"commaturnedmod",
                               [NSNumber numberWithInt:0x263C], @"compass",
                               [NSNumber numberWithInt:0x2245], @"congruent",
                               [NSNumber numberWithInt:0x222E], @"contourintegral",
                               [NSNumber numberWithInt:0x2303], @"control",
                               [NSNumber numberWithInt:0x0006], @"controlACK",
                               [NSNumber numberWithInt:0x0007], @"controlBEL",
                               [NSNumber numberWithInt:0x0008], @"controlBS",
                               [NSNumber numberWithInt:0x0018], @"controlCAN",
                               [NSNumber numberWithInt:0x000D], @"controlCR",
                               [NSNumber numberWithInt:0x0011], @"controlDC1",
                               [NSNumber numberWithInt:0x0012], @"controlDC2",
                               [NSNumber numberWithInt:0x0013], @"controlDC3",
                               [NSNumber numberWithInt:0x0014], @"controlDC4",
                               [NSNumber numberWithInt:0x007F], @"controlDEL",
                               [NSNumber numberWithInt:0x0010], @"controlDLE",
                               [NSNumber numberWithInt:0x0019], @"controlEM",
                               [NSNumber numberWithInt:0x0005], @"controlENQ",
                               [NSNumber numberWithInt:0x0004], @"controlEOT",
                               [NSNumber numberWithInt:0x001B], @"controlESC",
                               [NSNumber numberWithInt:0x0017], @"controlETB",
                               [NSNumber numberWithInt:0x0003], @"controlETX",
                               [NSNumber numberWithInt:0x000C], @"controlFF",
                               [NSNumber numberWithInt:0x001C], @"controlFS",
                               [NSNumber numberWithInt:0x001D], @"controlGS",
                               [NSNumber numberWithInt:0x0009], @"controlHT",
                               [NSNumber numberWithInt:0x000A], @"controlLF",
                               [NSNumber numberWithInt:0x0015], @"controlNAK",
                               [NSNumber numberWithInt:0x001E], @"controlRS",
                               [NSNumber numberWithInt:0x000F], @"controlSI",
                               [NSNumber numberWithInt:0x000E], @"controlSO",
                               [NSNumber numberWithInt:0x0002], @"controlSOT",
                               [NSNumber numberWithInt:0x0001], @"controlSTX",
                               [NSNumber numberWithInt:0x001A], @"controlSUB",
                               [NSNumber numberWithInt:0x0016], @"controlSYN",
                               [NSNumber numberWithInt:0x001F], @"controlUS",
                               [NSNumber numberWithInt:0x000B], @"controlVT",
                               [NSNumber numberWithInt:0x00A9], @"copyright",
                               [NSNumber numberWithInt:0xF8E9], @"copyrightsans",
                               [NSNumber numberWithInt:0xF6D9], @"copyrightserif",
                               [NSNumber numberWithInt:0x300C], @"cornerbracketleft",
                               [NSNumber numberWithInt:0xFF62], @"cornerbracketlefthalfwidth",
                               [NSNumber numberWithInt:0xFE41], @"cornerbracketleftvertical",
                               [NSNumber numberWithInt:0x300D], @"cornerbracketright",
                               [NSNumber numberWithInt:0xFF63], @"cornerbracketrighthalfwidth",
                               [NSNumber numberWithInt:0xFE42], @"cornerbracketrightvertical",
                               [NSNumber numberWithInt:0x337F], @"corporationsquare",
                               [NSNumber numberWithInt:0x33C7], @"cosquare",
                               [NSNumber numberWithInt:0x33C6], @"coverkgsquare",
                               [NSNumber numberWithInt:0x249E], @"cparen",
                               [NSNumber numberWithInt:0x20A2], @"cruzeiro",
                               [NSNumber numberWithInt:0x0297], @"cstretched",
                               [NSNumber numberWithInt:0x22CF], @"curlyand",
                               [NSNumber numberWithInt:0x22CE], @"curlyor",
                               [NSNumber numberWithInt:0x00A4], @"currency",
                               [NSNumber numberWithInt:0xF6D1], @"cyrBreve",
                               [NSNumber numberWithInt:0xF6D2], @"cyrFlex",
                               [NSNumber numberWithInt:0xF6D4], @"cyrbreve",
                               [NSNumber numberWithInt:0xF6D5], @"cyrflex",
                               [NSNumber numberWithInt:0x0064], @"d",
                               [NSNumber numberWithInt:0x0564], @"daarmenian",
                               [NSNumber numberWithInt:0x09A6], @"dabengali",
                               [NSNumber numberWithInt:0x0636], @"dadarabic",
                               [NSNumber numberWithInt:0x0926], @"dadeva",
                               [NSNumber numberWithInt:0xFEBE], @"dadfinalarabic",
                               [NSNumber numberWithInt:0xFEBF], @"dadinitialarabic",
                               [NSNumber numberWithInt:0xFEC0], @"dadmedialarabic",
                               [NSNumber numberWithInt:0x05BC], @"dagesh",
                               [NSNumber numberWithInt:0x05BC], @"dageshhebrew",
                               [NSNumber numberWithInt:0x2020], @"dagger",
                               [NSNumber numberWithInt:0x2021], @"daggerdbl",
                               [NSNumber numberWithInt:0x0AA6], @"dagujarati",
                               [NSNumber numberWithInt:0x0A26], @"dagurmukhi",
                               [NSNumber numberWithInt:0x3060], @"dahiragana",
                               [NSNumber numberWithInt:0x30C0], @"dakatakana",
                               [NSNumber numberWithInt:0x062F], @"dalarabic",
                               [NSNumber numberWithInt:0x05D3], @"dalet",
                               [NSNumber numberWithInt:0xFB33], @"daletdagesh",
                               [NSNumber numberWithInt:0xFB33], @"daletdageshhebrew",
                               //[NSNumber numberWithInt:0x05D3 05B2], @"dalethatafpatah",
//                               [NSNumber numberWithInt:0x05D3 05B2], @"dalethatafpatahhebrew",
//                               [NSNumber numberWithInt:0x05D3 05B1], @"dalethatafsegol",
//                               [NSNumber numberWithInt:0x05D3 05B1], @"dalethatafsegolhebrew",
//                               [NSNumber numberWithInt:0x05D3], @"dalethebrew",
//                               [NSNumber numberWithInt:0x05D3 05B4], @"dalethiriq",
//                               [NSNumber numberWithInt:0x05D3 05B4], @"dalethiriqhebrew",
//                               [NSNumber numberWithInt:0x05D3 05B9], @"daletholam",
//                               [NSNumber numberWithInt:0x05D3 05B9], @"daletholamhebrew",
//                               [NSNumber numberWithInt:0x05D3 05B7], @"daletpatah",
//                               [NSNumber numberWithInt:0x05D3 05B7], @"daletpatahhebrew",
//                               [NSNumber numberWithInt:0x05D3 05B8], @"daletqamats",
//                               [NSNumber numberWithInt:0x05D3 05B8], @"daletqamatshebrew",
//                               [NSNumber numberWithInt:0x05D3 05BB], @"daletqubuts",
//                               [NSNumber numberWithInt:0x05D3 05BB], @"daletqubutshebrew",
//                               [NSNumber numberWithInt:0x05D3 05B6], @"daletsegol",
//                               [NSNumber numberWithInt:0x05D3 05B6], @"daletsegolhebrew",
//                               [NSNumber numberWithInt:0x05D3 05B0], @"daletsheva",
//                               [NSNumber numberWithInt:0x05D3 05B0], @"daletshevahebrew",
//                               [NSNumber numberWithInt:0x05D3 05B5], @"dalettsere",
//                               [NSNumber numberWithInt:0x05D3 05B5], @"dalettserehebrew",
                               [NSNumber numberWithInt:0xFEAA], @"dalfinalarabic",
                               [NSNumber numberWithInt:0x064F], @"dammaarabic",
                               [NSNumber numberWithInt:0x064F], @"dammalowarabic",
                               [NSNumber numberWithInt:0x064C], @"dammatanaltonearabic",
                               [NSNumber numberWithInt:0x064C], @"dammatanarabic",
                               [NSNumber numberWithInt:0x0964], @"danda",
                               [NSNumber numberWithInt:0x05A7], @"dargahebrew",
                               [NSNumber numberWithInt:0x05A7], @"dargalefthebrew",
                               [NSNumber numberWithInt:0x0485], @"dasiapneumatacyrilliccmb",
                               [NSNumber numberWithInt:0xF6D3], @"dblGrave",
                               [NSNumber numberWithInt:0x300A], @"dblanglebracketleft",
                               [NSNumber numberWithInt:0xFE3D], @"dblanglebracketleftvertical",
                               [NSNumber numberWithInt:0x300B], @"dblanglebracketright",
                               [NSNumber numberWithInt:0xFE3E], @"dblanglebracketrightvertical",
                               [NSNumber numberWithInt:0x032B], @"dblarchinvertedbelowcmb",
                               [NSNumber numberWithInt:0x21D4], @"dblarrowleft",
                               [NSNumber numberWithInt:0x21D2], @"dblarrowright",
                               [NSNumber numberWithInt:0x0965], @"dbldanda",
                               [NSNumber numberWithInt:0xF6D6], @"dblgrave",
                               [NSNumber numberWithInt:0x030F], @"dblgravecmb",
                               [NSNumber numberWithInt:0x222C], @"dblintegral",
                               [NSNumber numberWithInt:0x2017], @"dbllowline",
                               [NSNumber numberWithInt:0x0333], @"dbllowlinecmb",
                               [NSNumber numberWithInt:0x033F], @"dbloverlinecmb",
                               [NSNumber numberWithInt:0x02BA], @"dblprimemod",
                               [NSNumber numberWithInt:0x2016], @"dblverticalbar",
                               [NSNumber numberWithInt:0x030E], @"dblverticallineabovecmb",
                               [NSNumber numberWithInt:0x3109], @"dbopomofo",
                               [NSNumber numberWithInt:0x33C8], @"dbsquare",
                               [NSNumber numberWithInt:0x010F], @"dcaron",
                               [NSNumber numberWithInt:0x1E11], @"dcedilla",
                               [NSNumber numberWithInt:0x24D3], @"dcircle",
                               [NSNumber numberWithInt:0x1E13], @"dcircumflexbelow",
                               [NSNumber numberWithInt:0x0111], @"dcroat",
                               [NSNumber numberWithInt:0x09A1], @"ddabengali",
                               [NSNumber numberWithInt:0x0921], @"ddadeva",
                               [NSNumber numberWithInt:0x0AA1], @"ddagujarati",
                               [NSNumber numberWithInt:0x0A21], @"ddagurmukhi",
                               [NSNumber numberWithInt:0x0688], @"ddalarabic",
                               [NSNumber numberWithInt:0xFB89], @"ddalfinalarabic",
                               [NSNumber numberWithInt:0x095C], @"dddhadeva",
                               [NSNumber numberWithInt:0x09A2], @"ddhabengali",
                               [NSNumber numberWithInt:0x0922], @"ddhadeva",
                               [NSNumber numberWithInt:0x0AA2], @"ddhagujarati",
                               [NSNumber numberWithInt:0x0A22], @"ddhagurmukhi",
                               [NSNumber numberWithInt:0x1E0B], @"ddotaccent",
                               [NSNumber numberWithInt:0x1E0D], @"ddotbelow",
                               [NSNumber numberWithInt:0x066B], @"decimalseparatorarabic",
                               [NSNumber numberWithInt:0x066B], @"decimalseparatorpersian",
                               [NSNumber numberWithInt:0x0434], @"decyrillic",
                               [NSNumber numberWithInt:0x00B0], @"degree",
                               [NSNumber numberWithInt:0x05AD], @"dehihebrew",
                               [NSNumber numberWithInt:0x3067], @"dehiragana",
                               [NSNumber numberWithInt:0x03EF], @"deicoptic",
                               [NSNumber numberWithInt:0x30C7], @"dekatakana",
                               [NSNumber numberWithInt:0x232B], @"deleteleft",
                               [NSNumber numberWithInt:0x2326], @"deleteright",
                               [NSNumber numberWithInt:0x03B4], @"delta",
                               [NSNumber numberWithInt:0x018D], @"deltaturned",
                               [NSNumber numberWithInt:0x09F8], @"denominatorminusonenumeratorbengali",
                               [NSNumber numberWithInt:0x02A4], @"dezh",
                               [NSNumber numberWithInt:0x09A7], @"dhabengali",
                               [NSNumber numberWithInt:0x0927], @"dhadeva",
                               [NSNumber numberWithInt:0x0AA7], @"dhagujarati",
                               [NSNumber numberWithInt:0x0A27], @"dhagurmukhi",
                               [NSNumber numberWithInt:0x0257], @"dhook",
                               [NSNumber numberWithInt:0x0385], @"dialytikatonos",
                               [NSNumber numberWithInt:0x0344], @"dialytikatonoscmb",
                               [NSNumber numberWithInt:0x2666], @"diamond",
                               [NSNumber numberWithInt:0x2662], @"diamondsuitwhite",
                               [NSNumber numberWithInt:0x00A8], @"dieresis",
                               [NSNumber numberWithInt:0xF6D7], @"dieresisacute",
                               [NSNumber numberWithInt:0x0324], @"dieresisbelowcmb",
                               [NSNumber numberWithInt:0x0308], @"dieresiscmb",
                               [NSNumber numberWithInt:0xF6D8], @"dieresisgrave",
                               [NSNumber numberWithInt:0x0385], @"dieresistonos",
                               [NSNumber numberWithInt:0x3062], @"dihiragana",
                               [NSNumber numberWithInt:0x30C2], @"dikatakana",
                               [NSNumber numberWithInt:0x3003], @"dittomark",
                               [NSNumber numberWithInt:0x00F7], @"divide",
                               [NSNumber numberWithInt:0x2223], @"divides",
                               [NSNumber numberWithInt:0x2215], @"divisionslash",
                               [NSNumber numberWithInt:0x0452], @"djecyrillic",
                               [NSNumber numberWithInt:0x2593], @"dkshade",
                               [NSNumber numberWithInt:0x1E0F], @"dlinebelow",
                               [NSNumber numberWithInt:0x3397], @"dlsquare",
                               [NSNumber numberWithInt:0x0111], @"dmacron",
                               [NSNumber numberWithInt:0xFF44], @"dmonospace",
                               [NSNumber numberWithInt:0x2584], @"dnblock",
                               [NSNumber numberWithInt:0x0E0E], @"dochadathai",
                               [NSNumber numberWithInt:0x0E14], @"dodekthai",
                               [NSNumber numberWithInt:0x3069], @"dohiragana",
                               [NSNumber numberWithInt:0x30C9], @"dokatakana",
                               [NSNumber numberWithInt:0x0024], @"dollar",
                               [NSNumber numberWithInt:0xF6E3], @"dollarinferior",
                               [NSNumber numberWithInt:0xFF04], @"dollarmonospace",
                               [NSNumber numberWithInt:0xF724], @"dollaroldstyle",
                               [NSNumber numberWithInt:0xFE69], @"dollarsmall",
                               [NSNumber numberWithInt:0xF6E4], @"dollarsuperior",
                               [NSNumber numberWithInt:0x20AB], @"dong",
                               [NSNumber numberWithInt:0x3326], @"dorusquare",
                               [NSNumber numberWithInt:0x02D9], @"dotaccent",
                               [NSNumber numberWithInt:0x0307], @"dotaccentcmb",
                               [NSNumber numberWithInt:0x0323], @"dotbelowcmb",
                               [NSNumber numberWithInt:0x0323], @"dotbelowcomb",
                               [NSNumber numberWithInt:0x30FB], @"dotkatakana",
                               [NSNumber numberWithInt:0x0131], @"dotlessi",
                               [NSNumber numberWithInt:0xF6BE], @"dotlessj",
                               [NSNumber numberWithInt:0x0284], @"dotlessjstrokehook",
                               [NSNumber numberWithInt:0x22C5], @"dotmath",
                               [NSNumber numberWithInt:0x25CC], @"dottedcircle",
                               [NSNumber numberWithInt:0xFB1F], @"doubleyodpatah",
                               [NSNumber numberWithInt:0xFB1F], @"doubleyodpatahhebrew",
                               [NSNumber numberWithInt:0x031E], @"downtackbelowcmb",
                               [NSNumber numberWithInt:0x02D5], @"downtackmod",
                               [NSNumber numberWithInt:0x249F], @"dparen",
                               [NSNumber numberWithInt:0xF6EB], @"dsuperior",
                               [NSNumber numberWithInt:0x0256], @"dtail",
                               [NSNumber numberWithInt:0x018C], @"dtopbar",
                               [NSNumber numberWithInt:0x3065], @"duhiragana",
                               [NSNumber numberWithInt:0x30C5], @"dukatakana",
                               [NSNumber numberWithInt:0x01F3], @"dz",
                               [NSNumber numberWithInt:0x02A3], @"dzaltone",
                               [NSNumber numberWithInt:0x01C6], @"dzcaron",
                               [NSNumber numberWithInt:0x02A5], @"dzcurl",
                               [NSNumber numberWithInt:0x04E1], @"dzeabkhasiancyrillic",
                               [NSNumber numberWithInt:0x0455], @"dzecyrillic",
                               [NSNumber numberWithInt:0x045F], @"dzhecyrillic",
                               [NSNumber numberWithInt:0x0065], @"e",
                               [NSNumber numberWithInt:0x00E9], @"eacute",
                               [NSNumber numberWithInt:0x2641], @"earth",
                               [NSNumber numberWithInt:0x098F], @"ebengali",
                               [NSNumber numberWithInt:0x311C], @"ebopomofo",
                               [NSNumber numberWithInt:0x0115], @"ebreve",
                               [NSNumber numberWithInt:0x090D], @"ecandradeva",
                               [NSNumber numberWithInt:0x0A8D], @"ecandragujarati",
                               [NSNumber numberWithInt:0x0945], @"ecandravowelsigndeva",
                               [NSNumber numberWithInt:0x0AC5], @"ecandravowelsigngujarati",
                               [NSNumber numberWithInt:0x011B], @"ecaron",
                               [NSNumber numberWithInt:0x1E1D], @"ecedillabreve",
                               [NSNumber numberWithInt:0x0565], @"echarmenian",
                               [NSNumber numberWithInt:0x0587], @"echyiwnarmenian",
                               [NSNumber numberWithInt:0x24D4], @"ecircle",
                               [NSNumber numberWithInt:0x00EA], @"ecircumflex",
                               [NSNumber numberWithInt:0x1EBF], @"ecircumflexacute",
                               [NSNumber numberWithInt:0x1E19], @"ecircumflexbelow",
                               [NSNumber numberWithInt:0x1EC7], @"ecircumflexdotbelow",
                               [NSNumber numberWithInt:0x1EC1], @"ecircumflexgrave",
                               [NSNumber numberWithInt:0x1EC3], @"ecircumflexhookabove",
                               [NSNumber numberWithInt:0x1EC5], @"ecircumflextilde",
                               [NSNumber numberWithInt:0x0454], @"ecyrillic",
                               [NSNumber numberWithInt:0x0205], @"edblgrave",
                               [NSNumber numberWithInt:0x090F], @"edeva",
                               [NSNumber numberWithInt:0x00EB], @"edieresis",
                               [NSNumber numberWithInt:0x0117], @"edot",
                               [NSNumber numberWithInt:0x0117], @"edotaccent",
                               [NSNumber numberWithInt:0x1EB9], @"edotbelow",
                               [NSNumber numberWithInt:0x0A0F], @"eegurmukhi",
                               [NSNumber numberWithInt:0x0A47], @"eematragurmukhi",
                               [NSNumber numberWithInt:0x0444], @"efcyrillic",
                               [NSNumber numberWithInt:0x00E8], @"egrave",
                               [NSNumber numberWithInt:0x0A8F], @"egujarati",
                               [NSNumber numberWithInt:0x0567], @"eharmenian",
                               [NSNumber numberWithInt:0x311D], @"ehbopomofo",
                               [NSNumber numberWithInt:0x3048], @"ehiragana",
                               [NSNumber numberWithInt:0x1EBB], @"ehookabove",
                               [NSNumber numberWithInt:0x311F], @"eibopomofo",
                               [NSNumber numberWithInt:0x0038], @"eight",
                               [NSNumber numberWithInt:0x0668], @"eightarabic",
                               [NSNumber numberWithInt:0x09EE], @"eightbengali",
                               [NSNumber numberWithInt:0x2467], @"eightcircle",
                               [NSNumber numberWithInt:0x2791], @"eightcircleinversesansserif",
                               [NSNumber numberWithInt:0x096E], @"eightdeva",
                               [NSNumber numberWithInt:0x2471], @"eighteencircle",
                               [NSNumber numberWithInt:0x2485], @"eighteenparen",
                               [NSNumber numberWithInt:0x2499], @"eighteenperiod",
                               [NSNumber numberWithInt:0x0AEE], @"eightgujarati",
                               [NSNumber numberWithInt:0x0A6E], @"eightgurmukhi",
                               [NSNumber numberWithInt:0x0668], @"eighthackarabic",
                               [NSNumber numberWithInt:0x3028], @"eighthangzhou",
                               [NSNumber numberWithInt:0x266B], @"eighthnotebeamed",
                               [NSNumber numberWithInt:0x3227], @"eightideographicparen",
                               [NSNumber numberWithInt:0x2088], @"eightinferior",
                               [NSNumber numberWithInt:0xFF18], @"eightmonospace",
                               [NSNumber numberWithInt:0xF738], @"eightoldstyle",
                               [NSNumber numberWithInt:0x247B], @"eightparen",
                               [NSNumber numberWithInt:0x248F], @"eightperiod",
                               [NSNumber numberWithInt:0x06F8], @"eightpersian",
                               [NSNumber numberWithInt:0x2177], @"eightroman",
                               [NSNumber numberWithInt:0x2078], @"eightsuperior",
                               [NSNumber numberWithInt:0x0E58], @"eightthai",
                               [NSNumber numberWithInt:0x0207], @"einvertedbreve",
                               [NSNumber numberWithInt:0x0465], @"eiotifiedcyrillic",
                               [NSNumber numberWithInt:0x30A8], @"ekatakana",
                               [NSNumber numberWithInt:0xFF74], @"ekatakanahalfwidth",
                               [NSNumber numberWithInt:0x0A74], @"ekonkargurmukhi",
                               [NSNumber numberWithInt:0x3154], @"ekorean",
                               [NSNumber numberWithInt:0x043B], @"elcyrillic",
                               [NSNumber numberWithInt:0x2208], @"element",
                               [NSNumber numberWithInt:0x246A], @"elevencircle",
                               [NSNumber numberWithInt:0x247E], @"elevenparen",
                               [NSNumber numberWithInt:0x2492], @"elevenperiod",
                               [NSNumber numberWithInt:0x217A], @"elevenroman",
                               [NSNumber numberWithInt:0x2026], @"ellipsis",
                               [NSNumber numberWithInt:0x22EE], @"ellipsisvertical",
                               [NSNumber numberWithInt:0x0113], @"emacron",
                               [NSNumber numberWithInt:0x1E17], @"emacronacute",
                               [NSNumber numberWithInt:0x1E15], @"emacrongrave",
                               [NSNumber numberWithInt:0x043C], @"emcyrillic",
                               [NSNumber numberWithInt:0x2014], @"emdash",
                               [NSNumber numberWithInt:0xFE31], @"emdashvertical",
                               [NSNumber numberWithInt:0xFF45], @"emonospace",
                               [NSNumber numberWithInt:0x055B], @"emphasismarkarmenian",
                               [NSNumber numberWithInt:0x2205], @"emptyset",
                               [NSNumber numberWithInt:0x3123], @"enbopomofo",
                               [NSNumber numberWithInt:0x043D], @"encyrillic",
                               [NSNumber numberWithInt:0x2013], @"endash",
                               [NSNumber numberWithInt:0xFE32], @"endashvertical",
                               [NSNumber numberWithInt:0x04A3], @"endescendercyrillic",
                               [NSNumber numberWithInt:0x014B], @"eng",
                               [NSNumber numberWithInt:0x3125], @"engbopomofo",
                               [NSNumber numberWithInt:0x04A5], @"enghecyrillic",
                               [NSNumber numberWithInt:0x04C8], @"enhookcyrillic",
                               [NSNumber numberWithInt:0x2002], @"enspace",
                               [NSNumber numberWithInt:0x0119], @"eogonek",
                               [NSNumber numberWithInt:0x3153], @"eokorean",
                               [NSNumber numberWithInt:0x025B], @"eopen",
                               [NSNumber numberWithInt:0x029A], @"eopenclosed",
                               [NSNumber numberWithInt:0x025C], @"eopenreversed",
                               [NSNumber numberWithInt:0x025E], @"eopenreversedclosed",
                               [NSNumber numberWithInt:0x025D], @"eopenreversedhook",
                               [NSNumber numberWithInt:0x24A0], @"eparen",
                               [NSNumber numberWithInt:0x03B5], @"epsilon",
                               [NSNumber numberWithInt:0x03AD], @"epsilontonos",
                               [NSNumber numberWithInt:0x003D], @"equal",
                               [NSNumber numberWithInt:0xFF1D], @"equalmonospace",
                               [NSNumber numberWithInt:0xFE66], @"equalsmall",
                               [NSNumber numberWithInt:0x207C], @"equalsuperior",
                               [NSNumber numberWithInt:0x2261], @"equivalence",
                               [NSNumber numberWithInt:0x3126], @"erbopomofo",
                               [NSNumber numberWithInt:0x0440], @"ercyrillic",
                               [NSNumber numberWithInt:0x0258], @"ereversed",
                               [NSNumber numberWithInt:0x044D], @"ereversedcyrillic",
                               [NSNumber numberWithInt:0x0441], @"escyrillic",
                               [NSNumber numberWithInt:0x04AB], @"esdescendercyrillic",
                               [NSNumber numberWithInt:0x0283], @"esh",
                               [NSNumber numberWithInt:0x0286], @"eshcurl",
                               [NSNumber numberWithInt:0x090E], @"eshortdeva",
                               [NSNumber numberWithInt:0x0946], @"eshortvowelsigndeva",
                               [NSNumber numberWithInt:0x01AA], @"eshreversedloop",
                               [NSNumber numberWithInt:0x0285], @"eshsquatreversed",
                               [NSNumber numberWithInt:0x3047], @"esmallhiragana",
                               [NSNumber numberWithInt:0x30A7], @"esmallkatakana",
                               [NSNumber numberWithInt:0xFF6A], @"esmallkatakanahalfwidth",
                               [NSNumber numberWithInt:0x212E], @"estimated",
                               [NSNumber numberWithInt:0xF6EC], @"esuperior",
                               [NSNumber numberWithInt:0x03B7], @"eta",
                               [NSNumber numberWithInt:0x0568], @"etarmenian",
                               [NSNumber numberWithInt:0x03AE], @"etatonos",
                               [NSNumber numberWithInt:0x00F0], @"eth",
                               [NSNumber numberWithInt:0x1EBD], @"etilde",
                               [NSNumber numberWithInt:0x1E1B], @"etildebelow",
                               [NSNumber numberWithInt:0x0591], @"etnahtafoukhhebrew",
                               [NSNumber numberWithInt:0x0591], @"etnahtafoukhlefthebrew",
                               [NSNumber numberWithInt:0x0591], @"etnahtahebrew",
                               [NSNumber numberWithInt:0x0591], @"etnahtalefthebrew",
                               [NSNumber numberWithInt:0x01DD], @"eturned",
                               [NSNumber numberWithInt:0x3161], @"eukorean",
                               [NSNumber numberWithInt:0x20AC], @"euro",
                               [NSNumber numberWithInt:0x09C7], @"evowelsignbengali",
                               [NSNumber numberWithInt:0x0947], @"evowelsigndeva",
                               [NSNumber numberWithInt:0x0AC7], @"evowelsigngujarati",
                               [NSNumber numberWithInt:0x0021], @"exclam",
                               [NSNumber numberWithInt:0x055C], @"exclamarmenian",
                               [NSNumber numberWithInt:0x203C], @"exclamdbl",
                               [NSNumber numberWithInt:0x00A1], @"exclamdown",
                               [NSNumber numberWithInt:0xF7A1], @"exclamdownsmall",
                               [NSNumber numberWithInt:0xFF01], @"exclammonospace",
                               [NSNumber numberWithInt:0xF721], @"exclamsmall",
                               [NSNumber numberWithInt:0x2203], @"existential",
                               [NSNumber numberWithInt:0x0292], @"ezh",
                               [NSNumber numberWithInt:0x01EF], @"ezhcaron",
                               [NSNumber numberWithInt:0x0293], @"ezhcurl",
                               [NSNumber numberWithInt:0x01B9], @"ezhreversed",
                               [NSNumber numberWithInt:0x01BA], @"ezhtail",
                               [NSNumber numberWithInt:0x0066], @"f",
                               [NSNumber numberWithInt:0x095E], @"fadeva",
                               [NSNumber numberWithInt:0x0A5E], @"fagurmukhi",
                               [NSNumber numberWithInt:0x2109], @"fahrenheit",
                               [NSNumber numberWithInt:0x064E], @"fathaarabic",
                               [NSNumber numberWithInt:0x064E], @"fathalowarabic",
                               [NSNumber numberWithInt:0x064B], @"fathatanarabic",
                               [NSNumber numberWithInt:0x3108], @"fbopomofo",
                               [NSNumber numberWithInt:0x24D5], @"fcircle",
                               [NSNumber numberWithInt:0x1E1F], @"fdotaccent",
                               [NSNumber numberWithInt:0x0641], @"feharabic",
                               [NSNumber numberWithInt:0x0586], @"feharmenian",
                               [NSNumber numberWithInt:0xFED2], @"fehfinalarabic",
                               [NSNumber numberWithInt:0xFED3], @"fehinitialarabic",
                               [NSNumber numberWithInt:0xFED4], @"fehmedialarabic",
                               [NSNumber numberWithInt:0x03E5], @"feicoptic",
                               [NSNumber numberWithInt:0x2640], @"female",
                               [NSNumber numberWithInt:0xFB00], @"ff",
                               [NSNumber numberWithInt:0xFB03], @"ffi",
                               [NSNumber numberWithInt:0xFB04], @"ffl",
                               [NSNumber numberWithInt:0xFB01], @"fi",
                               [NSNumber numberWithInt:0xFB01], @"f_i", // Manually added
                               [NSNumber numberWithInt:0x246E], @"fifteencircle",
                               [NSNumber numberWithInt:0x2482], @"fifteenparen",
                               [NSNumber numberWithInt:0x2496], @"fifteenperiod",
                               [NSNumber numberWithInt:0x2012], @"figuredash",
                               [NSNumber numberWithInt:0x25A0], @"filledbox",
                               [NSNumber numberWithInt:0x25AC], @"filledrect",
                               [NSNumber numberWithInt:0x05DA], @"finalkaf",
                               [NSNumber numberWithInt:0xFB3A], @"finalkafdagesh",
                               [NSNumber numberWithInt:0xFB3A], @"finalkafdageshhebrew",
                               [NSNumber numberWithInt:0x05DA], @"finalkafhebrew",
                               //[NSNumber numberWithInt:0x05DA 05B8], @"finalkafqamats",
//                               [NSNumber numberWithInt:0x05DA 05B8], @"finalkafqamatshebrew",
//                               [NSNumber numberWithInt:0x05DA 05B0], @"finalkafsheva",
//                               [NSNumber numberWithInt:0x05DA 05B0], @"finalkafshevahebrew",
                               [NSNumber numberWithInt:0x05DD], @"finalmem",
                               [NSNumber numberWithInt:0x05DD], @"finalmemhebrew",
                               [NSNumber numberWithInt:0x05DF], @"finalnun",
                               [NSNumber numberWithInt:0x05DF], @"finalnunhebrew",
                               [NSNumber numberWithInt:0x05E3], @"finalpe",
                               [NSNumber numberWithInt:0x05E3], @"finalpehebrew",
                               [NSNumber numberWithInt:0x05E5], @"finaltsadi",
                               [NSNumber numberWithInt:0x05E5], @"finaltsadihebrew",
                               [NSNumber numberWithInt:0x02C9], @"firsttonechinese",
                               [NSNumber numberWithInt:0x25C9], @"fisheye",
                               [NSNumber numberWithInt:0x0473], @"fitacyrillic",
                               [NSNumber numberWithInt:0x0035], @"five",
                               [NSNumber numberWithInt:0x0665], @"fivearabic",
                               [NSNumber numberWithInt:0x09EB], @"fivebengali",
                               [NSNumber numberWithInt:0x2464], @"fivecircle",
                               [NSNumber numberWithInt:0x278E], @"fivecircleinversesansserif",
                               [NSNumber numberWithInt:0x096B], @"fivedeva",
                               [NSNumber numberWithInt:0x215D], @"fiveeighths",
                               [NSNumber numberWithInt:0x0AEB], @"fivegujarati",
                               [NSNumber numberWithInt:0x0A6B], @"fivegurmukhi",
                               [NSNumber numberWithInt:0x0665], @"fivehackarabic",
                               [NSNumber numberWithInt:0x3025], @"fivehangzhou",
                               [NSNumber numberWithInt:0x3224], @"fiveideographicparen",
                               [NSNumber numberWithInt:0x2085], @"fiveinferior",
                               [NSNumber numberWithInt:0xFF15], @"fivemonospace",
                               [NSNumber numberWithInt:0xF735], @"fiveoldstyle",
                               [NSNumber numberWithInt:0x2478], @"fiveparen",
                               [NSNumber numberWithInt:0x248C], @"fiveperiod",
                               [NSNumber numberWithInt:0x06F5], @"fivepersian",
                               [NSNumber numberWithInt:0x2174], @"fiveroman",
                               [NSNumber numberWithInt:0x2075], @"fivesuperior",
                               [NSNumber numberWithInt:0x0E55], @"fivethai",
                               [NSNumber numberWithInt:0xFB02], @"fl",
                               [NSNumber numberWithInt:0xFB02], @"f_l",
                               [NSNumber numberWithInt:0x0192], @"florin",
                               [NSNumber numberWithInt:0xFF46], @"fmonospace",
                               [NSNumber numberWithInt:0x3399], @"fmsquare",
                               [NSNumber numberWithInt:0x0E1F], @"fofanthai",
                               [NSNumber numberWithInt:0x0E1D], @"fofathai",
                               [NSNumber numberWithInt:0x0E4F], @"fongmanthai",
                               [NSNumber numberWithInt:0x2200], @"forall",
                               [NSNumber numberWithInt:0x0034], @"four",
                               [NSNumber numberWithInt:0x0664], @"fourarabic",
                               [NSNumber numberWithInt:0x09EA], @"fourbengali",
                               [NSNumber numberWithInt:0x2463], @"fourcircle",
                               [NSNumber numberWithInt:0x278D], @"fourcircleinversesansserif",
                               [NSNumber numberWithInt:0x096A], @"fourdeva",
                               [NSNumber numberWithInt:0x0AEA], @"fourgujarati",
                               [NSNumber numberWithInt:0x0A6A], @"fourgurmukhi",
                               [NSNumber numberWithInt:0x0664], @"fourhackarabic",
                               [NSNumber numberWithInt:0x3024], @"fourhangzhou",
                               [NSNumber numberWithInt:0x3223], @"fourideographicparen",
                               [NSNumber numberWithInt:0x2084], @"fourinferior",
                               [NSNumber numberWithInt:0xFF14], @"fourmonospace",
                               [NSNumber numberWithInt:0x09F7], @"fournumeratorbengali",
                               [NSNumber numberWithInt:0xF734], @"fouroldstyle",
                               [NSNumber numberWithInt:0x2477], @"fourparen",
                               [NSNumber numberWithInt:0x248B], @"fourperiod",
                               [NSNumber numberWithInt:0x06F4], @"fourpersian",
                               [NSNumber numberWithInt:0x2173], @"fourroman",
                               [NSNumber numberWithInt:0x2074], @"foursuperior",
                               [NSNumber numberWithInt:0x246D], @"fourteencircle",
                               [NSNumber numberWithInt:0x2481], @"fourteenparen",
                               [NSNumber numberWithInt:0x2495], @"fourteenperiod",
                               [NSNumber numberWithInt:0x0E54], @"fourthai",
                               [NSNumber numberWithInt:0x02CB], @"fourthtonechinese",
                               [NSNumber numberWithInt:0x24A1], @"fparen",
                               [NSNumber numberWithInt:0x2044], @"fraction",
                               [NSNumber numberWithInt:0x20A3], @"franc",
                               [NSNumber numberWithInt:0x0067], @"g",
                               [NSNumber numberWithInt:0x0997], @"gabengali",
                               [NSNumber numberWithInt:0x01F5], @"gacute",
                               [NSNumber numberWithInt:0x0917], @"gadeva",
                               [NSNumber numberWithInt:0x06AF], @"gafarabic",
                               [NSNumber numberWithInt:0xFB93], @"gaffinalarabic",
                               [NSNumber numberWithInt:0xFB94], @"gafinitialarabic",
                               [NSNumber numberWithInt:0xFB95], @"gafmedialarabic",
                               [NSNumber numberWithInt:0x0A97], @"gagujarati",
                               [NSNumber numberWithInt:0x0A17], @"gagurmukhi",
                               [NSNumber numberWithInt:0x304C], @"gahiragana",
                               [NSNumber numberWithInt:0x30AC], @"gakatakana",
                               [NSNumber numberWithInt:0x03B3], @"gamma",
                               [NSNumber numberWithInt:0x0263], @"gammalatinsmall",
                               [NSNumber numberWithInt:0x02E0], @"gammasuperior",
                               [NSNumber numberWithInt:0x03EB], @"gangiacoptic",
                               [NSNumber numberWithInt:0x310D], @"gbopomofo",
                               [NSNumber numberWithInt:0x011F], @"gbreve",
                               [NSNumber numberWithInt:0x01E7], @"gcaron",
                               [NSNumber numberWithInt:0x0123], @"gcedilla",
                               [NSNumber numberWithInt:0x24D6], @"gcircle",
                               [NSNumber numberWithInt:0x011D], @"gcircumflex",
                               [NSNumber numberWithInt:0x0123], @"gcommaaccent",
                               [NSNumber numberWithInt:0x0121], @"gdot",
                               [NSNumber numberWithInt:0x0121], @"gdotaccent",
                               [NSNumber numberWithInt:0x0433], @"gecyrillic",
                               [NSNumber numberWithInt:0x3052], @"gehiragana",
                               [NSNumber numberWithInt:0x30B2], @"gekatakana",
                               [NSNumber numberWithInt:0x2251], @"geometricallyequal",
                               [NSNumber numberWithInt:0x059C], @"gereshaccenthebrew",
                               [NSNumber numberWithInt:0x05F3], @"gereshhebrew",
                               [NSNumber numberWithInt:0x059D], @"gereshmuqdamhebrew",
                               [NSNumber numberWithInt:0x00DF], @"germandbls",
                               [NSNumber numberWithInt:0x059E], @"gershayimaccenthebrew",
                               [NSNumber numberWithInt:0x05F4], @"gershayimhebrew",
                               [NSNumber numberWithInt:0x3013], @"getamark",
                               [NSNumber numberWithInt:0x0998], @"ghabengali",
                               [NSNumber numberWithInt:0x0572], @"ghadarmenian",
                               [NSNumber numberWithInt:0x0918], @"ghadeva",
                               [NSNumber numberWithInt:0x0A98], @"ghagujarati",
                               [NSNumber numberWithInt:0x0A18], @"ghagurmukhi",
                               [NSNumber numberWithInt:0x063A], @"ghainarabic",
                               [NSNumber numberWithInt:0xFECE], @"ghainfinalarabic",
                               [NSNumber numberWithInt:0xFECF], @"ghaininitialarabic",
                               [NSNumber numberWithInt:0xFED0], @"ghainmedialarabic",
                               [NSNumber numberWithInt:0x0495], @"ghemiddlehookcyrillic",
                               [NSNumber numberWithInt:0x0493], @"ghestrokecyrillic",
                               [NSNumber numberWithInt:0x0491], @"gheupturncyrillic",
                               [NSNumber numberWithInt:0x095A], @"ghhadeva",
                               [NSNumber numberWithInt:0x0A5A], @"ghhagurmukhi",
                               [NSNumber numberWithInt:0x0260], @"ghook",
                               [NSNumber numberWithInt:0x3393], @"ghzsquare",
                               [NSNumber numberWithInt:0x304E], @"gihiragana",
                               [NSNumber numberWithInt:0x30AE], @"gikatakana",
                               [NSNumber numberWithInt:0x0563], @"gimarmenian",
                               [NSNumber numberWithInt:0x05D2], @"gimel",
                               [NSNumber numberWithInt:0xFB32], @"gimeldagesh",
                               [NSNumber numberWithInt:0xFB32], @"gimeldageshhebrew",
                               [NSNumber numberWithInt:0x05D2], @"gimelhebrew",
                               [NSNumber numberWithInt:0x0453], @"gjecyrillic",
                               [NSNumber numberWithInt:0x01BE], @"glottalinvertedstroke",
                               [NSNumber numberWithInt:0x0294], @"glottalstop",
                               [NSNumber numberWithInt:0x0296], @"glottalstopinverted",
                               [NSNumber numberWithInt:0x02C0], @"glottalstopmod",
                               [NSNumber numberWithInt:0x0295], @"glottalstopreversed",
                               [NSNumber numberWithInt:0x02C1], @"glottalstopreversedmod",
                               [NSNumber numberWithInt:0x02E4], @"glottalstopreversedsuperior",
                               [NSNumber numberWithInt:0x02A1], @"glottalstopstroke",
                               [NSNumber numberWithInt:0x02A2], @"glottalstopstrokereversed",
                               [NSNumber numberWithInt:0x1E21], @"gmacron",
                               [NSNumber numberWithInt:0xFF47], @"gmonospace",
                               [NSNumber numberWithInt:0x3054], @"gohiragana",
                               [NSNumber numberWithInt:0x30B4], @"gokatakana",
                               [NSNumber numberWithInt:0x24A2], @"gparen",
                               [NSNumber numberWithInt:0x33AC], @"gpasquare",
                               [NSNumber numberWithInt:0x2207], @"gradient",
                               [NSNumber numberWithInt:0x0060], @"grave",
                               [NSNumber numberWithInt:0x0316], @"gravebelowcmb",
                               [NSNumber numberWithInt:0x0300], @"gravecmb",
                               [NSNumber numberWithInt:0x0300], @"gravecomb",
                               [NSNumber numberWithInt:0x0953], @"gravedeva",
                               [NSNumber numberWithInt:0x02CE], @"gravelowmod",
                               [NSNumber numberWithInt:0xFF40], @"gravemonospace",
                               [NSNumber numberWithInt:0x0340], @"gravetonecmb",
                               [NSNumber numberWithInt:0x003E], @"greater",
                               [NSNumber numberWithInt:0x2265], @"greaterequal",
                               [NSNumber numberWithInt:0x22DB], @"greaterequalorless",
                               [NSNumber numberWithInt:0xFF1E], @"greatermonospace",
                               [NSNumber numberWithInt:0x2273], @"greaterorequivalent",
                               [NSNumber numberWithInt:0x2277], @"greaterorless",
                               [NSNumber numberWithInt:0x2267], @"greateroverequal",
                               [NSNumber numberWithInt:0xFE65], @"greatersmall",
                               [NSNumber numberWithInt:0x0261], @"gscript",
                               [NSNumber numberWithInt:0x01E5], @"gstroke",
                               [NSNumber numberWithInt:0x3050], @"guhiragana",
                               [NSNumber numberWithInt:0x00AB], @"guillemotleft",
                               [NSNumber numberWithInt:0x00BB], @"guillemotright",
                               [NSNumber numberWithInt:0x2039], @"guilsinglleft",
                               [NSNumber numberWithInt:0x203A], @"guilsinglright",
                               [NSNumber numberWithInt:0x30B0], @"gukatakana",
                               [NSNumber numberWithInt:0x3318], @"guramusquare",
                               [NSNumber numberWithInt:0x33C9], @"gysquare",
            [NSNumber numberWithInt:0x0068], @"h",
[NSNumber numberWithInt:0x04A9], @"haabkhasiancyrillic",
[NSNumber numberWithInt:0x06C1], @"haaltonearabic",
[NSNumber numberWithInt:0x09B9], @"habengali",
[NSNumber numberWithInt:0x04B3], @"hadescendercyrillic",
[NSNumber numberWithInt:0x0939], @"hadeva",
[NSNumber numberWithInt:0x0AB9], @"hagujarati",
[NSNumber numberWithInt:0x0A39], @"hagurmukhi",
[NSNumber numberWithInt:0x062D], @"haharabic",
[NSNumber numberWithInt:0xFEA2], @"hahfinalarabic",
[NSNumber numberWithInt:0xFEA3], @"hahinitialarabic",
[NSNumber numberWithInt:0x306F], @"hahiragana",
[NSNumber numberWithInt:0xFEA4], @"hahmedialarabic",
[NSNumber numberWithInt:0x332A], @"haitusquare",
[NSNumber numberWithInt:0x30CF], @"hakatakana",
[NSNumber numberWithInt:0xFF8A], @"hakatakanahalfwidth",
[NSNumber numberWithInt:0x0A4D], @"halantgurmukhi",
[NSNumber numberWithInt:0x0621], @"hamzaarabic",
//[NSNumber numberWithInt:0x0621 064F], @"hamzadammaarabic",
//[NSNumber numberWithInt:0x0621 064C], @"hamzadammatanarabic",
//[NSNumber numberWithInt:0x0621 064E], @"hamzafathaarabic",
//[NSNumber numberWithInt:0x0621 064B], @"hamzafathatanarabic",
[NSNumber numberWithInt:0x0621], @"hamzalowarabic",
//[NSNumber numberWithInt:0x0621 0650], @"hamzalowkasraarabic",
//[NSNumber numberWithInt:0x0621 064D], @"hamzalowkasratanarabic",
//[NSNumber numberWithInt:0x0621 0652], @"hamzasukunarabic",
[NSNumber numberWithInt:0x3164], @"hangulfiller",
[NSNumber numberWithInt:0x044A], @"hardsigncyrillic",
[NSNumber numberWithInt:0x21BC], @"harpoonleftbarbup",
[NSNumber numberWithInt:0x21C0], @"harpoonrightbarbup",
[NSNumber numberWithInt:0x33CA], @"hasquare",
[NSNumber numberWithInt:0x05B2], @"hatafpatah",
[NSNumber numberWithInt:0x05B2], @"hatafpatah16",
[NSNumber numberWithInt:0x05B2], @"hatafpatah23",
[NSNumber numberWithInt:0x05B2], @"hatafpatah2f",
[NSNumber numberWithInt:0x05B2], @"hatafpatahhebrew",
[NSNumber numberWithInt:0x05B2], @"hatafpatahnarrowhebrew",
[NSNumber numberWithInt:0x05B2], @"hatafpatahquarterhebrew",
[NSNumber numberWithInt:0x05B2], @"hatafpatahwidehebrew",
[NSNumber numberWithInt:0x05B3], @"hatafqamats",
[NSNumber numberWithInt:0x05B3], @"hatafqamats1b",
[NSNumber numberWithInt:0x05B3], @"hatafqamats28",
[NSNumber numberWithInt:0x05B3], @"hatafqamats34",
[NSNumber numberWithInt:0x05B3], @"hatafqamatshebrew",
[NSNumber numberWithInt:0x05B3], @"hatafqamatsnarrowhebrew",
[NSNumber numberWithInt:0x05B3], @"hatafqamatsquarterhebrew",
[NSNumber numberWithInt:0x05B3], @"hatafqamatswidehebrew",
[NSNumber numberWithInt:0x05B1], @"hatafsegol",
[NSNumber numberWithInt:0x05B1], @"hatafsegol17",
[NSNumber numberWithInt:0x05B1], @"hatafsegol24",
[NSNumber numberWithInt:0x05B1], @"hatafsegol30",
[NSNumber numberWithInt:0x05B1], @"hatafsegolhebrew",
[NSNumber numberWithInt:0x05B1], @"hatafsegolnarrowhebrew",
[NSNumber numberWithInt:0x05B1], @"hatafsegolquarterhebrew",
[NSNumber numberWithInt:0x05B1], @"hatafsegolwidehebrew",
[NSNumber numberWithInt:0x0127], @"hbar",
[NSNumber numberWithInt:0x310F], @"hbopomofo",
[NSNumber numberWithInt:0x1E2B], @"hbrevebelow",
[NSNumber numberWithInt:0x1E29], @"hcedilla",
[NSNumber numberWithInt:0x24D7], @"hcircle",
[NSNumber numberWithInt:0x0125], @"hcircumflex",
[NSNumber numberWithInt:0x1E27], @"hdieresis",
[NSNumber numberWithInt:0x1E23], @"hdotaccent",
[NSNumber numberWithInt:0x1E25], @"hdotbelow",
[NSNumber numberWithInt:0x05D4], @"he",
[NSNumber numberWithInt:0x2665], @"heart",
[NSNumber numberWithInt:0x2665], @"heartsuitblack",
[NSNumber numberWithInt:0x2661], @"heartsuitwhite",
[NSNumber numberWithInt:0xFB34], @"hedagesh",
[NSNumber numberWithInt:0xFB34], @"hedageshhebrew",
[NSNumber numberWithInt:0x06C1], @"hehaltonearabic",
[NSNumber numberWithInt:0x0647], @"heharabic",
[NSNumber numberWithInt:0x05D4], @"hehebrew",
[NSNumber numberWithInt:0xFBA7], @"hehfinalaltonearabic",
[NSNumber numberWithInt:0xFEEA], @"hehfinalalttwoarabic",
[NSNumber numberWithInt:0xFEEA], @"hehfinalarabic",
[NSNumber numberWithInt:0xFBA5], @"hehhamzaabovefinalarabic",
[NSNumber numberWithInt:0xFBA4], @"hehhamzaaboveisolatedarabic",
[NSNumber numberWithInt:0xFBA8], @"hehinitialaltonearabic",
[NSNumber numberWithInt:0xFEEB], @"hehinitialarabic",
[NSNumber numberWithInt:0x3078], @"hehiragana",
[NSNumber numberWithInt:0xFBA9], @"hehmedialaltonearabic",
[NSNumber numberWithInt:0xFEEC], @"hehmedialarabic",
[NSNumber numberWithInt:0x337B], @"heiseierasquare",
[NSNumber numberWithInt:0x30D8], @"hekatakana",
[NSNumber numberWithInt:0xFF8D], @"hekatakanahalfwidth",
[NSNumber numberWithInt:0x3336], @"hekutaarusquare",
[NSNumber numberWithInt:0x0267], @"henghook",
[NSNumber numberWithInt:0x3339], @"herutusquare",
[NSNumber numberWithInt:0x05D7], @"het",
[NSNumber numberWithInt:0x05D7], @"hethebrew",
[NSNumber numberWithInt:0x0266], @"hhook",
[NSNumber numberWithInt:0x02B1], @"hhooksuperior",
[NSNumber numberWithInt:0x327B], @"hieuhacirclekorean",
[NSNumber numberWithInt:0x321B], @"hieuhaparenkorean",
[NSNumber numberWithInt:0x326D], @"hieuhcirclekorean",
[NSNumber numberWithInt:0x314E], @"hieuhkorean",
[NSNumber numberWithInt:0x320D], @"hieuhparenkorean",
[NSNumber numberWithInt:0x3072], @"hihiragana",
[NSNumber numberWithInt:0x30D2], @"hikatakana",
[NSNumber numberWithInt:0xFF8B], @"hikatakanahalfwidth",
[NSNumber numberWithInt:0x05B4], @"hiriq",
[NSNumber numberWithInt:0x05B4], @"hiriq14",
[NSNumber numberWithInt:0x05B4], @"hiriq21",
[NSNumber numberWithInt:0x05B4], @"hiriq2d",
[NSNumber numberWithInt:0x05B4], @"hiriqhebrew",
[NSNumber numberWithInt:0x05B4], @"hiriqnarrowhebrew",
[NSNumber numberWithInt:0x05B4], @"hiriqquarterhebrew",
[NSNumber numberWithInt:0x05B4], @"hiriqwidehebrew",
[NSNumber numberWithInt:0x1E96], @"hlinebelow",
[NSNumber numberWithInt:0xFF48], @"hmonospace",
[NSNumber numberWithInt:0x0570], @"hoarmenian",
[NSNumber numberWithInt:0x0E2B], @"hohipthai",
[NSNumber numberWithInt:0x307B], @"hohiragana",
[NSNumber numberWithInt:0x30DB], @"hokatakana",
[NSNumber numberWithInt:0xFF8E], @"hokatakanahalfwidth",
[NSNumber numberWithInt:0x05B9], @"holam",
[NSNumber numberWithInt:0x05B9], @"holam19",
[NSNumber numberWithInt:0x05B9], @"holam26",
[NSNumber numberWithInt:0x05B9], @"holam32",
[NSNumber numberWithInt:0x05B9], @"holamhebrew",
[NSNumber numberWithInt:0x05B9], @"holamnarrowhebrew",
[NSNumber numberWithInt:0x05B9], @"holamquarterhebrew",
[NSNumber numberWithInt:0x05B9], @"holamwidehebrew",
[NSNumber numberWithInt:0x0E2E], @"honokhukthai",
[NSNumber numberWithInt:0x0309], @"hookabovecomb",
[NSNumber numberWithInt:0x0309], @"hookcmb",
[NSNumber numberWithInt:0x0321], @"hookpalatalizedbelowcmb",
[NSNumber numberWithInt:0x0322], @"hookretroflexbelowcmb",
[NSNumber numberWithInt:0x3342], @"hoonsquare",
[NSNumber numberWithInt:0x03E9], @"horicoptic",
[NSNumber numberWithInt:0x2015], @"horizontalbar",
[NSNumber numberWithInt:0x031B], @"horncmb",
[NSNumber numberWithInt:0x2668], @"hotsprings",
[NSNumber numberWithInt:0x2302], @"house",
[NSNumber numberWithInt:0x24A3], @"hparen",
[NSNumber numberWithInt:0x02B0], @"hsuperior",
[NSNumber numberWithInt:0x0265], @"hturned",
[NSNumber numberWithInt:0x3075], @"huhiragana",
[NSNumber numberWithInt:0x3333], @"huiitosquare",
[NSNumber numberWithInt:0x30D5], @"hukatakana",
[NSNumber numberWithInt:0xFF8C], @"hukatakanahalfwidth",
[NSNumber numberWithInt:0x02DD], @"hungarumlaut",
[NSNumber numberWithInt:0x030B], @"hungarumlautcmb",
[NSNumber numberWithInt:0x0195], @"hv",
[NSNumber numberWithInt:0x002D], @"hyphen",
[NSNumber numberWithInt:0xF6E5], @"hypheninferior",
[NSNumber numberWithInt:0xFF0D], @"hyphenmonospace",
[NSNumber numberWithInt:0xFE63], @"hyphensmall",
[NSNumber numberWithInt:0xF6E6], @"hyphensuperior",
[NSNumber numberWithInt:0x2010], @"hyphentwo",
[NSNumber numberWithInt:0x0069], @"i",
[NSNumber numberWithInt:0x00ED], @"iacute",
[NSNumber numberWithInt:0x044F], @"iacyrillic",
[NSNumber numberWithInt:0x0987], @"ibengali",
[NSNumber numberWithInt:0x3127], @"ibopomofo",
[NSNumber numberWithInt:0x012D], @"ibreve",
[NSNumber numberWithInt:0x01D0], @"icaron",
[NSNumber numberWithInt:0x24D8], @"icircle",
[NSNumber numberWithInt:0x00EE], @"icircumflex",
[NSNumber numberWithInt:0x0456], @"icyrillic",
[NSNumber numberWithInt:0x0209], @"idblgrave",
[NSNumber numberWithInt:0x328F], @"ideographearthcircle",
[NSNumber numberWithInt:0x328B], @"ideographfirecircle",
[NSNumber numberWithInt:0x323F], @"ideographicallianceparen",
[NSNumber numberWithInt:0x323A], @"ideographiccallparen",
[NSNumber numberWithInt:0x32A5], @"ideographiccentrecircle",
[NSNumber numberWithInt:0x3006], @"ideographicclose",
[NSNumber numberWithInt:0x3001], @"ideographiccomma",
[NSNumber numberWithInt:0xFF64], @"ideographiccommaleft",
[NSNumber numberWithInt:0x3237], @"ideographiccongratulationparen",
[NSNumber numberWithInt:0x32A3], @"ideographiccorrectcircle",
[NSNumber numberWithInt:0x322F], @"ideographicearthparen",
[NSNumber numberWithInt:0x323D], @"ideographicenterpriseparen",
[NSNumber numberWithInt:0x329D], @"ideographicexcellentcircle",
[NSNumber numberWithInt:0x3240], @"ideographicfestivalparen",
[NSNumber numberWithInt:0x3296], @"ideographicfinancialcircle",
[NSNumber numberWithInt:0x3236], @"ideographicfinancialparen",
[NSNumber numberWithInt:0x322B], @"ideographicfireparen",
[NSNumber numberWithInt:0x3232], @"ideographichaveparen",
[NSNumber numberWithInt:0x32A4], @"ideographichighcircle",
[NSNumber numberWithInt:0x3005], @"ideographiciterationmark",
[NSNumber numberWithInt:0x3298], @"ideographiclaborcircle",
[NSNumber numberWithInt:0x3238], @"ideographiclaborparen",
[NSNumber numberWithInt:0x32A7], @"ideographicleftcircle",
[NSNumber numberWithInt:0x32A6], @"ideographiclowcircle",
[NSNumber numberWithInt:0x32A9], @"ideographicmedicinecircle",
[NSNumber numberWithInt:0x322E], @"ideographicmetalparen",
[NSNumber numberWithInt:0x322A], @"ideographicmoonparen",
[NSNumber numberWithInt:0x3234], @"ideographicnameparen",
[NSNumber numberWithInt:0x3002], @"ideographicperiod",
[NSNumber numberWithInt:0x329E], @"ideographicprintcircle",
[NSNumber numberWithInt:0x3243], @"ideographicreachparen",
[NSNumber numberWithInt:0x3239], @"ideographicrepresentparen",
[NSNumber numberWithInt:0x323E], @"ideographicresourceparen",
[NSNumber numberWithInt:0x32A8], @"ideographicrightcircle",
[NSNumber numberWithInt:0x3299], @"ideographicsecretcircle",
[NSNumber numberWithInt:0x3242], @"ideographicselfparen",
[NSNumber numberWithInt:0x3233], @"ideographicsocietyparen",
[NSNumber numberWithInt:0x3000], @"ideographicspace",
[NSNumber numberWithInt:0x3235], @"ideographicspecialparen",
[NSNumber numberWithInt:0x3231], @"ideographicstockparen",
[NSNumber numberWithInt:0x323B], @"ideographicstudyparen",
[NSNumber numberWithInt:0x3230], @"ideographicsunparen",
[NSNumber numberWithInt:0x323C], @"ideographicsuperviseparen",
[NSNumber numberWithInt:0x322C], @"ideographicwaterparen",
[NSNumber numberWithInt:0x322D], @"ideographicwoodparen",
[NSNumber numberWithInt:0x3007], @"ideographiczero",
[NSNumber numberWithInt:0x328E], @"ideographmetalcircle",
[NSNumber numberWithInt:0x328A], @"ideographmooncircle",
[NSNumber numberWithInt:0x3294], @"ideographnamecircle",
[NSNumber numberWithInt:0x3290], @"ideographsuncircle",
[NSNumber numberWithInt:0x328C], @"ideographwatercircle",
[NSNumber numberWithInt:0x328D], @"ideographwoodcircle",
[NSNumber numberWithInt:0x0907], @"ideva",
[NSNumber numberWithInt:0x00EF], @"idieresis",
[NSNumber numberWithInt:0x1E2F], @"idieresisacute",
[NSNumber numberWithInt:0x04E5], @"idieresiscyrillic",
[NSNumber numberWithInt:0x1ECB], @"idotbelow",
[NSNumber numberWithInt:0x04D7], @"iebrevecyrillic",
[NSNumber numberWithInt:0x0435], @"iecyrillic",
[NSNumber numberWithInt:0x3275], @"ieungacirclekorean",
[NSNumber numberWithInt:0x3215], @"ieungaparenkorean",
[NSNumber numberWithInt:0x3267], @"ieungcirclekorean",
[NSNumber numberWithInt:0x3147], @"ieungkorean",
[NSNumber numberWithInt:0x3207], @"ieungparenkorean",
[NSNumber numberWithInt:0x00EC], @"igrave",
[NSNumber numberWithInt:0x0A87], @"igujarati",
[NSNumber numberWithInt:0x0A07], @"igurmukhi",
[NSNumber numberWithInt:0x3044], @"ihiragana",
[NSNumber numberWithInt:0x1EC9], @"ihookabove",
[NSNumber numberWithInt:0x0988], @"iibengali",
[NSNumber numberWithInt:0x0438], @"iicyrillic",
[NSNumber numberWithInt:0x0908], @"iideva",
[NSNumber numberWithInt:0x0A88], @"iigujarati",
[NSNumber numberWithInt:0x0A08], @"iigurmukhi",
[NSNumber numberWithInt:0x0A40], @"iimatragurmukhi",
[NSNumber numberWithInt:0x020B], @"iinvertedbreve",
[NSNumber numberWithInt:0x0439], @"iishortcyrillic",
[NSNumber numberWithInt:0x09C0], @"iivowelsignbengali",
[NSNumber numberWithInt:0x0940], @"iivowelsigndeva",
[NSNumber numberWithInt:0x0AC0], @"iivowelsigngujarati",
[NSNumber numberWithInt:0x0133], @"ij",
[NSNumber numberWithInt:0x30A4], @"ikatakana",
[NSNumber numberWithInt:0xFF72], @"ikatakanahalfwidth",
[NSNumber numberWithInt:0x3163], @"ikorean",
[NSNumber numberWithInt:0x02DC], @"ilde",
[NSNumber numberWithInt:0x05AC], @"iluyhebrew",
[NSNumber numberWithInt:0x012B], @"imacron",
[NSNumber numberWithInt:0x04E3], @"imacroncyrillic",
[NSNumber numberWithInt:0x2253], @"imageorapproximatelyequal",
[NSNumber numberWithInt:0x0A3F], @"imatragurmukhi",
[NSNumber numberWithInt:0xFF49], @"imonospace",
[NSNumber numberWithInt:0x2206], @"increment",
[NSNumber numberWithInt:0x221E], @"infinity",
[NSNumber numberWithInt:0x056B], @"iniarmenian",
[NSNumber numberWithInt:0x222B], @"integral",
[NSNumber numberWithInt:0x2321], @"integralbottom",
[NSNumber numberWithInt:0x2321], @"integralbt",
[NSNumber numberWithInt:0xF8F5], @"integralex",
[NSNumber numberWithInt:0x2320], @"integraltop",
[NSNumber numberWithInt:0x2320], @"integraltp",
[NSNumber numberWithInt:0x2229], @"intersection",
[NSNumber numberWithInt:0x3305], @"intisquare",
[NSNumber numberWithInt:0x25D8], @"invbullet",
[NSNumber numberWithInt:0x25D9], @"invcircle",
[NSNumber numberWithInt:0x263B], @"invsmileface",
[NSNumber numberWithInt:0x0451], @"iocyrillic",
[NSNumber numberWithInt:0x012F], @"iogonek",
[NSNumber numberWithInt:0x03B9], @"iota",
[NSNumber numberWithInt:0x03CA], @"iotadieresis",
[NSNumber numberWithInt:0x0390], @"iotadieresistonos",
[NSNumber numberWithInt:0x0269], @"iotalatin",
[NSNumber numberWithInt:0x03AF], @"iotatonos",
[NSNumber numberWithInt:0x24A4], @"iparen",
[NSNumber numberWithInt:0x0A72], @"irigurmukhi",
[NSNumber numberWithInt:0x3043], @"ismallhiragana",
[NSNumber numberWithInt:0x30A3], @"ismallkatakana",
[NSNumber numberWithInt:0xFF68], @"ismallkatakanahalfwidth",
[NSNumber numberWithInt:0x09FA], @"issharbengali",
[NSNumber numberWithInt:0x0268], @"istroke",
[NSNumber numberWithInt:0xF6ED], @"isuperior",
[NSNumber numberWithInt:0x309D], @"iterationhiragana",
[NSNumber numberWithInt:0x30FD], @"iterationkatakana",
[NSNumber numberWithInt:0x0129], @"itilde",
[NSNumber numberWithInt:0x1E2D], @"itildebelow",
[NSNumber numberWithInt:0x3129], @"iubopomofo",
[NSNumber numberWithInt:0x044E], @"iucyrillic",
[NSNumber numberWithInt:0x09BF], @"ivowelsignbengali",
[NSNumber numberWithInt:0x093F], @"ivowelsigndeva",
[NSNumber numberWithInt:0x0ABF], @"ivowelsigngujarati",
[NSNumber numberWithInt:0x0475], @"izhitsacyrillic",
[NSNumber numberWithInt:0x0477], @"izhitsadblgravecyrillic",
[NSNumber numberWithInt:0x006A], @"j",
[NSNumber numberWithInt:0x0571], @"jaarmenian",
[NSNumber numberWithInt:0x099C], @"jabengali",
[NSNumber numberWithInt:0x091C], @"jadeva",
[NSNumber numberWithInt:0x0A9C], @"jagujarati",
[NSNumber numberWithInt:0x0A1C], @"jagurmukhi",
[NSNumber numberWithInt:0x3110], @"jbopomofo",
[NSNumber numberWithInt:0x01F0], @"jcaron",
[NSNumber numberWithInt:0x24D9], @"jcircle",
[NSNumber numberWithInt:0x0135], @"jcircumflex",
[NSNumber numberWithInt:0x029D], @"jcrossedtail",
[NSNumber numberWithInt:0x025F], @"jdotlessstroke",
[NSNumber numberWithInt:0x0458], @"jecyrillic",
[NSNumber numberWithInt:0x062C], @"jeemarabic",
[NSNumber numberWithInt:0xFE9E], @"jeemfinalarabic",
[NSNumber numberWithInt:0xFE9F], @"jeeminitialarabic",
[NSNumber numberWithInt:0xFEA0], @"jeemmedialarabic",
[NSNumber numberWithInt:0x0698], @"jeharabic",
[NSNumber numberWithInt:0xFB8B], @"jehfinalarabic",
[NSNumber numberWithInt:0x099D], @"jhabengali",
[NSNumber numberWithInt:0x091D], @"jhadeva",
[NSNumber numberWithInt:0x0A9D], @"jhagujarati",
[NSNumber numberWithInt:0x0A1D], @"jhagurmukhi",
[NSNumber numberWithInt:0x057B], @"jheharmenian",
[NSNumber numberWithInt:0x3004], @"jis",
[NSNumber numberWithInt:0xFF4A], @"jmonospace",
[NSNumber numberWithInt:0x24A5], @"jparen",
[NSNumber numberWithInt:0x02B2], @"jsuperior",
[NSNumber numberWithInt:0x006B], @"k",
[NSNumber numberWithInt:0x04A1], @"kabashkircyrillic",
[NSNumber numberWithInt:0x0995], @"kabengali",
[NSNumber numberWithInt:0x1E31], @"kacute",
[NSNumber numberWithInt:0x043A], @"kacyrillic",
[NSNumber numberWithInt:0x049B], @"kadescendercyrillic",
[NSNumber numberWithInt:0x0915], @"kadeva",
[NSNumber numberWithInt:0x05DB], @"kaf",
[NSNumber numberWithInt:0x0643], @"kafarabic",
[NSNumber numberWithInt:0xFB3B], @"kafdagesh",
[NSNumber numberWithInt:0xFB3B], @"kafdageshhebrew",
[NSNumber numberWithInt:0xFEDA], @"kaffinalarabic",
[NSNumber numberWithInt:0x05DB], @"kafhebrew",
[NSNumber numberWithInt:0xFEDB], @"kafinitialarabic",
[NSNumber numberWithInt:0xFEDC], @"kafmedialarabic",
[NSNumber numberWithInt:0xFB4D], @"kafrafehebrew",
[NSNumber numberWithInt:0x0A95], @"kagujarati",
[NSNumber numberWithInt:0x0A15], @"kagurmukhi",
[NSNumber numberWithInt:0x304B], @"kahiragana",
[NSNumber numberWithInt:0x04C4], @"kahookcyrillic",
[NSNumber numberWithInt:0x30AB], @"kakatakana",
[NSNumber numberWithInt:0xFF76], @"kakatakanahalfwidth",
[NSNumber numberWithInt:0x03BA], @"kappa",
[NSNumber numberWithInt:0x03F0], @"kappasymbolgreek",
[NSNumber numberWithInt:0x3171], @"kapyeounmieumkorean",
[NSNumber numberWithInt:0x3184], @"kapyeounphieuphkorean",
[NSNumber numberWithInt:0x3178], @"kapyeounpieupkorean",
[NSNumber numberWithInt:0x3179], @"kapyeounssangpieupkorean",
[NSNumber numberWithInt:0x330D], @"karoriisquare",
[NSNumber numberWithInt:0x0640], @"kashidaautoarabic",
[NSNumber numberWithInt:0x0640], @"kashidaautonosidebearingarabic",
[NSNumber numberWithInt:0x30F5], @"kasmallkatakana",
[NSNumber numberWithInt:0x3384], @"kasquare",
[NSNumber numberWithInt:0x0650], @"kasraarabic",
[NSNumber numberWithInt:0x064D], @"kasratanarabic",
[NSNumber numberWithInt:0x049F], @"kastrokecyrillic",
[NSNumber numberWithInt:0xFF70], @"katahiraprolongmarkhalfwidth",
[NSNumber numberWithInt:0x049D], @"kaverticalstrokecyrillic",
[NSNumber numberWithInt:0x310E], @"kbopomofo",
[NSNumber numberWithInt:0x3389], @"kcalsquare",
[NSNumber numberWithInt:0x01E9], @"kcaron",
[NSNumber numberWithInt:0x0137], @"kcedilla",
[NSNumber numberWithInt:0x24DA], @"kcircle",
[NSNumber numberWithInt:0x0137], @"kcommaaccent",
[NSNumber numberWithInt:0x1E33], @"kdotbelow",
[NSNumber numberWithInt:0x0584], @"keharmenian",
[NSNumber numberWithInt:0x3051], @"kehiragana",
[NSNumber numberWithInt:0x30B1], @"kekatakana",
[NSNumber numberWithInt:0xFF79], @"kekatakanahalfwidth",
[NSNumber numberWithInt:0x056F], @"kenarmenian",
[NSNumber numberWithInt:0x30F6], @"kesmallkatakana",
[NSNumber numberWithInt:0x0138], @"kgreenlandic",
[NSNumber numberWithInt:0x0996], @"khabengali",
[NSNumber numberWithInt:0x0445], @"khacyrillic",
[NSNumber numberWithInt:0x0916], @"khadeva",
[NSNumber numberWithInt:0x0A96], @"khagujarati",
[NSNumber numberWithInt:0x0A16], @"khagurmukhi",
[NSNumber numberWithInt:0x062E], @"khaharabic",
[NSNumber numberWithInt:0xFEA6], @"khahfinalarabic",
[NSNumber numberWithInt:0xFEA7], @"khahinitialarabic",
[NSNumber numberWithInt:0xFEA8], @"khahmedialarabic",
[NSNumber numberWithInt:0x03E7], @"kheicoptic",
[NSNumber numberWithInt:0x0959], @"khhadeva",
[NSNumber numberWithInt:0x0A59], @"khhagurmukhi",
[NSNumber numberWithInt:0x3278], @"khieukhacirclekorean",
[NSNumber numberWithInt:0x3218], @"khieukhaparenkorean",
[NSNumber numberWithInt:0x326A], @"khieukhcirclekorean",
[NSNumber numberWithInt:0x314B], @"khieukhkorean",
[NSNumber numberWithInt:0x320A], @"khieukhparenkorean",
[NSNumber numberWithInt:0x0E02], @"khokhaithai",
[NSNumber numberWithInt:0x0E05], @"khokhonthai",
[NSNumber numberWithInt:0x0E03], @"khokhuatthai",
[NSNumber numberWithInt:0x0E04], @"khokhwaithai",
[NSNumber numberWithInt:0x0E5B], @"khomutthai",
[NSNumber numberWithInt:0x0199], @"khook",
[NSNumber numberWithInt:0x0E06], @"khorakhangthai",
[NSNumber numberWithInt:0x3391], @"khzsquare",
[NSNumber numberWithInt:0x304D], @"kihiragana",
[NSNumber numberWithInt:0x30AD], @"kikatakana",
[NSNumber numberWithInt:0xFF77], @"kikatakanahalfwidth",
[NSNumber numberWithInt:0x3315], @"kiroguramusquare",
[NSNumber numberWithInt:0x3316], @"kiromeetorusquare",
[NSNumber numberWithInt:0x3314], @"kirosquare",
[NSNumber numberWithInt:0x326E], @"kiyeokacirclekorean",
[NSNumber numberWithInt:0x320E], @"kiyeokaparenkorean",
[NSNumber numberWithInt:0x3260], @"kiyeokcirclekorean",
[NSNumber numberWithInt:0x3131], @"kiyeokkorean",
[NSNumber numberWithInt:0x3200], @"kiyeokparenkorean",
[NSNumber numberWithInt:0x3133], @"kiyeoksioskorean",
[NSNumber numberWithInt:0x045C], @"kjecyrillic",
[NSNumber numberWithInt:0x1E35], @"klinebelow",
[NSNumber numberWithInt:0x3398], @"klsquare",
[NSNumber numberWithInt:0x33A6], @"kmcubedsquare",
[NSNumber numberWithInt:0xFF4B], @"kmonospace",
[NSNumber numberWithInt:0x33A2], @"kmsquaredsquare",
[NSNumber numberWithInt:0x3053], @"kohiragana",
[NSNumber numberWithInt:0x33C0], @"kohmsquare",
[NSNumber numberWithInt:0x0E01], @"kokaithai",
[NSNumber numberWithInt:0x30B3], @"kokatakana",
[NSNumber numberWithInt:0xFF7A], @"kokatakanahalfwidth",
[NSNumber numberWithInt:0x331E], @"kooposquare",
[NSNumber numberWithInt:0x0481], @"koppacyrillic",
[NSNumber numberWithInt:0x327F], @"koreanstandardsymbol",
[NSNumber numberWithInt:0x0343], @"koroniscmb",
[NSNumber numberWithInt:0x24A6], @"kparen",
[NSNumber numberWithInt:0x33AA], @"kpasquare",
[NSNumber numberWithInt:0x046F], @"ksicyrillic",
[NSNumber numberWithInt:0x33CF], @"ktsquare",
[NSNumber numberWithInt:0x029E], @"kturned",
[NSNumber numberWithInt:0x304F], @"kuhiragana",
[NSNumber numberWithInt:0x30AF], @"kukatakana",
[NSNumber numberWithInt:0xFF78], @"kukatakanahalfwidth",
[NSNumber numberWithInt:0x33B8], @"kvsquare",
[NSNumber numberWithInt:0x33BE], @"kwsquare",
[NSNumber numberWithInt:0x006C], @"l",
[NSNumber numberWithInt:0x09B2], @"labengali",
[NSNumber numberWithInt:0x013A], @"lacute",
[NSNumber numberWithInt:0x0932], @"ladeva",
[NSNumber numberWithInt:0x0AB2], @"lagujarati",
[NSNumber numberWithInt:0x0A32], @"lagurmukhi",
[NSNumber numberWithInt:0x0E45], @"lakkhangyaothai",
[NSNumber numberWithInt:0xFEFC], @"lamaleffinalarabic",
[NSNumber numberWithInt:0xFEF8], @"lamalefhamzaabovefinalarabic",
[NSNumber numberWithInt:0xFEF7], @"lamalefhamzaaboveisolatedarabic",
[NSNumber numberWithInt:0xFEFA], @"lamalefhamzabelowfinalarabic",
[NSNumber numberWithInt:0xFEF9], @"lamalefhamzabelowisolatedarabic",
[NSNumber numberWithInt:0xFEFB], @"lamalefisolatedarabic",
[NSNumber numberWithInt:0xFEF6], @"lamalefmaddaabovefinalarabic",
[NSNumber numberWithInt:0xFEF5], @"lamalefmaddaaboveisolatedarabic",
[NSNumber numberWithInt:0x0644], @"lamarabic",
[NSNumber numberWithInt:0x03BB], @"lambda",
[NSNumber numberWithInt:0x019B], @"lambdastroke",
[NSNumber numberWithInt:0x05DC], @"lamed",
[NSNumber numberWithInt:0xFB3C], @"lameddagesh",
[NSNumber numberWithInt:0xFB3C], @"lameddageshhebrew",
[NSNumber numberWithInt:0x05DC], @"lamedhebrew",
//[NSNumber numberWithInt:0x05DC 05B9], @"lamedholam",
//[NSNumber numberWithInt:0x05DC 05B9 05BC], @"lamedholamdagesh",
//[NSNumber numberWithInt:0x05DC 05B9 05BC], @"lamedholamdageshhebrew",
//[NSNumber numberWithInt:0x05DC 05B9], @"lamedholamhebrew",
[NSNumber numberWithInt:0xFEDE], @"lamfinalarabic",
[NSNumber numberWithInt:0xFCCA], @"lamhahinitialarabic",
[NSNumber numberWithInt:0xFEDF], @"laminitialarabic",
[NSNumber numberWithInt:0xFCC9], @"lamjeeminitialarabic",
[NSNumber numberWithInt:0xFCCB], @"lamkhahinitialarabic",
[NSNumber numberWithInt:0xFDF2], @"lamlamhehisolatedarabic",
[NSNumber numberWithInt:0xFEE0], @"lammedialarabic",
[NSNumber numberWithInt:0xFD88], @"lammeemhahinitialarabic",
[NSNumber numberWithInt:0xFCCC], @"lammeeminitialarabic",
//[NSNumber numberWithInt:0xFEDF FEE4 FEA0], @"lammeemjeeminitialarabic",
//[NSNumber numberWithInt:0xFEDF FEE4 FEA8], @"lammeemkhahinitialarabic",
[NSNumber numberWithInt:0x25EF], @"largecircle",
[NSNumber numberWithInt:0x019A], @"lbar",
[NSNumber numberWithInt:0x026C], @"lbelt",
[NSNumber numberWithInt:0x310C], @"lbopomofo",
[NSNumber numberWithInt:0x013E], @"lcaron",
[NSNumber numberWithInt:0x013C], @"lcedilla",
[NSNumber numberWithInt:0x24DB], @"lcircle",
[NSNumber numberWithInt:0x1E3D], @"lcircumflexbelow",
[NSNumber numberWithInt:0x013C], @"lcommaaccent",
[NSNumber numberWithInt:0x0140], @"ldot",
[NSNumber numberWithInt:0x0140], @"ldotaccent",
[NSNumber numberWithInt:0x1E37], @"ldotbelow",
[NSNumber numberWithInt:0x1E39], @"ldotbelowmacron",
[NSNumber numberWithInt:0x031A], @"leftangleabovecmb",
[NSNumber numberWithInt:0x0318], @"lefttackbelowcmb",
[NSNumber numberWithInt:0x003C], @"less",
[NSNumber numberWithInt:0x2264], @"lessequal",
[NSNumber numberWithInt:0x22DA], @"lessequalorgreater",
[NSNumber numberWithInt:0xFF1C], @"lessmonospace",
[NSNumber numberWithInt:0x2272], @"lessorequivalent",
[NSNumber numberWithInt:0x2276], @"lessorgreater",
[NSNumber numberWithInt:0x2266], @"lessoverequal",
[NSNumber numberWithInt:0xFE64], @"lesssmall",
[NSNumber numberWithInt:0x026E], @"lezh",
[NSNumber numberWithInt:0x258C], @"lfblock",
[NSNumber numberWithInt:0x026D], @"lhookretroflex",
[NSNumber numberWithInt:0x20A4], @"lira",
[NSNumber numberWithInt:0x056C], @"liwnarmenian",
[NSNumber numberWithInt:0x01C9], @"lj",
[NSNumber numberWithInt:0x0459], @"ljecyrillic",
[NSNumber numberWithInt:0xF6C0], @"ll",
[NSNumber numberWithInt:0x0933], @"lladeva",
[NSNumber numberWithInt:0x0AB3], @"llagujarati",
[NSNumber numberWithInt:0x1E3B], @"llinebelow",
[NSNumber numberWithInt:0x0934], @"llladeva",
[NSNumber numberWithInt:0x09E1], @"llvocalicbengali",
[NSNumber numberWithInt:0x0961], @"llvocalicdeva",
[NSNumber numberWithInt:0x09E3], @"llvocalicvowelsignbengali",
[NSNumber numberWithInt:0x0963], @"llvocalicvowelsigndeva",
[NSNumber numberWithInt:0x026B], @"lmiddletilde",
[NSNumber numberWithInt:0xFF4C], @"lmonospace",
[NSNumber numberWithInt:0x33D0], @"lmsquare",
[NSNumber numberWithInt:0x0E2C], @"lochulathai",
[NSNumber numberWithInt:0x2227], @"logicaland",
[NSNumber numberWithInt:0x00AC], @"logicalnot",
[NSNumber numberWithInt:0x2310], @"logicalnotreversed",
[NSNumber numberWithInt:0x2228], @"logicalor",
[NSNumber numberWithInt:0x0E25], @"lolingthai",
[NSNumber numberWithInt:0x017F], @"longs",
[NSNumber numberWithInt:0xFE4E], @"lowlinecenterline",
[NSNumber numberWithInt:0x0332], @"lowlinecmb",
[NSNumber numberWithInt:0xFE4D], @"lowlinedashed",
[NSNumber numberWithInt:0x25CA], @"lozenge",
[NSNumber numberWithInt:0x24A7], @"lparen",
[NSNumber numberWithInt:0x0142], @"lslash",
[NSNumber numberWithInt:0x2113], @"lsquare",
[NSNumber numberWithInt:0xF6EE], @"lsuperior",
[NSNumber numberWithInt:0x2591], @"ltshade",
[NSNumber numberWithInt:0x0E26], @"luthai",
[NSNumber numberWithInt:0x098C], @"lvocalicbengali",
[NSNumber numberWithInt:0x090C], @"lvocalicdeva",
[NSNumber numberWithInt:0x09E2], @"lvocalicvowelsignbengali",
[NSNumber numberWithInt:0x0962], @"lvocalicvowelsigndeva",
[NSNumber numberWithInt:0x33D3], @"lxsquare",
[NSNumber numberWithInt:0x006D], @"m",
[NSNumber numberWithInt:0x09AE], @"mabengali",
[NSNumber numberWithInt:0x00AF], @"macron",
[NSNumber numberWithInt:0x0331], @"macronbelowcmb",
[NSNumber numberWithInt:0x0304], @"macroncmb",
[NSNumber numberWithInt:0x02CD], @"macronlowmod",
[NSNumber numberWithInt:0xFFE3], @"macronmonospace",
[NSNumber numberWithInt:0x1E3F], @"macute",
[NSNumber numberWithInt:0x092E], @"madeva",
[NSNumber numberWithInt:0x0AAE], @"magujarati",
[NSNumber numberWithInt:0x0A2E], @"magurmukhi",
[NSNumber numberWithInt:0x05A4], @"mahapakhhebrew",
[NSNumber numberWithInt:0x05A4], @"mahapakhlefthebrew",
[NSNumber numberWithInt:0x307E], @"mahiragana",
[NSNumber numberWithInt:0xF895], @"maichattawalowleftthai",
[NSNumber numberWithInt:0xF894], @"maichattawalowrightthai",
[NSNumber numberWithInt:0x0E4B], @"maichattawathai",
[NSNumber numberWithInt:0xF893], @"maichattawaupperleftthai",
[NSNumber numberWithInt:0xF88C], @"maieklowleftthai",
[NSNumber numberWithInt:0xF88B], @"maieklowrightthai",
[NSNumber numberWithInt:0x0E48], @"maiekthai",
[NSNumber numberWithInt:0xF88A], @"maiekupperleftthai",
[NSNumber numberWithInt:0xF884], @"maihanakatleftthai",
[NSNumber numberWithInt:0x0E31], @"maihanakatthai",
[NSNumber numberWithInt:0xF889], @"maitaikhuleftthai",
[NSNumber numberWithInt:0x0E47], @"maitaikhuthai",
[NSNumber numberWithInt:0xF88F], @"maitholowleftthai",
[NSNumber numberWithInt:0xF88E], @"maitholowrightthai",
[NSNumber numberWithInt:0x0E49], @"maithothai",
[NSNumber numberWithInt:0xF88D], @"maithoupperleftthai",
[NSNumber numberWithInt:0xF892], @"maitrilowleftthai",
[NSNumber numberWithInt:0xF891], @"maitrilowrightthai",
[NSNumber numberWithInt:0x0E4A], @"maitrithai",
[NSNumber numberWithInt:0xF890], @"maitriupperleftthai",
[NSNumber numberWithInt:0x0E46], @"maiyamokthai",
[NSNumber numberWithInt:0x30DE], @"makatakana",
[NSNumber numberWithInt:0xFF8F], @"makatakanahalfwidth",
[NSNumber numberWithInt:0x2642], @"male",
[NSNumber numberWithInt:0x3347], @"mansyonsquare",
[NSNumber numberWithInt:0x05BE], @"maqafhebrew",
[NSNumber numberWithInt:0x2642], @"mars",
[NSNumber numberWithInt:0x05AF], @"masoracirclehebrew",
[NSNumber numberWithInt:0x3383], @"masquare",
[NSNumber numberWithInt:0x3107], @"mbopomofo",
[NSNumber numberWithInt:0x33D4], @"mbsquare",
[NSNumber numberWithInt:0x24DC], @"mcircle",
[NSNumber numberWithInt:0x33A5], @"mcubedsquare",
[NSNumber numberWithInt:0x1E41], @"mdotaccent",
[NSNumber numberWithInt:0x1E43], @"mdotbelow",
[NSNumber numberWithInt:0x0645], @"meemarabic",
[NSNumber numberWithInt:0xFEE2], @"meemfinalarabic",
[NSNumber numberWithInt:0xFEE3], @"meeminitialarabic",
[NSNumber numberWithInt:0xFEE4], @"meemmedialarabic",
[NSNumber numberWithInt:0xFCD1], @"meemmeeminitialarabic",
[NSNumber numberWithInt:0xFC48], @"meemmeemisolatedarabic",
[NSNumber numberWithInt:0x334D], @"meetorusquare",
[NSNumber numberWithInt:0x3081], @"mehiragana",
[NSNumber numberWithInt:0x337E], @"meizierasquare",
[NSNumber numberWithInt:0x30E1], @"mekatakana",
[NSNumber numberWithInt:0xFF92], @"mekatakanahalfwidth",
[NSNumber numberWithInt:0x05DE], @"mem",
[NSNumber numberWithInt:0xFB3E], @"memdagesh",
[NSNumber numberWithInt:0xFB3E], @"memdageshhebrew",
[NSNumber numberWithInt:0x05DE], @"memhebrew",
[NSNumber numberWithInt:0x0574], @"menarmenian",
[NSNumber numberWithInt:0x05A5], @"merkhahebrew",
[NSNumber numberWithInt:0x05A6], @"merkhakefulahebrew",
[NSNumber numberWithInt:0x05A6], @"merkhakefulalefthebrew",
[NSNumber numberWithInt:0x05A5], @"merkhalefthebrew",
[NSNumber numberWithInt:0x0271], @"mhook",
[NSNumber numberWithInt:0x3392], @"mhzsquare",
[NSNumber numberWithInt:0xFF65], @"middledotkatakanahalfwidth",
[NSNumber numberWithInt:0x00B7], @"middot",
[NSNumber numberWithInt:0x3272], @"mieumacirclekorean",
[NSNumber numberWithInt:0x3212], @"mieumaparenkorean",
[NSNumber numberWithInt:0x3264], @"mieumcirclekorean",
[NSNumber numberWithInt:0x3141], @"mieumkorean",
[NSNumber numberWithInt:0x3170], @"mieumpansioskorean",
[NSNumber numberWithInt:0x3204], @"mieumparenkorean",
[NSNumber numberWithInt:0x316E], @"mieumpieupkorean",
[NSNumber numberWithInt:0x316F], @"mieumsioskorean",
[NSNumber numberWithInt:0x307F], @"mihiragana",
[NSNumber numberWithInt:0x30DF], @"mikatakana",
[NSNumber numberWithInt:0xFF90], @"mikatakanahalfwidth",
[NSNumber numberWithInt:0x2212], @"minus",
[NSNumber numberWithInt:0x0320], @"minusbelowcmb",
[NSNumber numberWithInt:0x2296], @"minuscircle",
[NSNumber numberWithInt:0x02D7], @"minusmod",
[NSNumber numberWithInt:0x2213], @"minusplus",
[NSNumber numberWithInt:0x2032], @"minute",
[NSNumber numberWithInt:0x334A], @"miribaarusquare",
[NSNumber numberWithInt:0x3349], @"mirisquare",
[NSNumber numberWithInt:0x0270], @"mlonglegturned",
[NSNumber numberWithInt:0x3396], @"mlsquare",
[NSNumber numberWithInt:0x33A3], @"mmcubedsquare",
[NSNumber numberWithInt:0xFF4D], @"mmonospace",
[NSNumber numberWithInt:0x339F], @"mmsquaredsquare",
[NSNumber numberWithInt:0x3082], @"mohiragana",
[NSNumber numberWithInt:0x33C1], @"mohmsquare",
[NSNumber numberWithInt:0x30E2], @"mokatakana",
[NSNumber numberWithInt:0xFF93], @"mokatakanahalfwidth",
[NSNumber numberWithInt:0x33D6], @"molsquare",
[NSNumber numberWithInt:0x0E21], @"momathai",
[NSNumber numberWithInt:0x33A7], @"moverssquare",
[NSNumber numberWithInt:0x33A8], @"moverssquaredsquare",
[NSNumber numberWithInt:0x24A8], @"mparen",
[NSNumber numberWithInt:0x33AB], @"mpasquare",
[NSNumber numberWithInt:0x33B3], @"mssquare",
[NSNumber numberWithInt:0xF6EF], @"msuperior",
[NSNumber numberWithInt:0x026F], @"mturned",
[NSNumber numberWithInt:0x00B5], @"mu",
[NSNumber numberWithInt:0x00B5], @"mu1",
[NSNumber numberWithInt:0x3382], @"muasquare",
[NSNumber numberWithInt:0x226B], @"muchgreater",
[NSNumber numberWithInt:0x226A], @"muchless",
[NSNumber numberWithInt:0x338C], @"mufsquare",
[NSNumber numberWithInt:0x03BC], @"mugreek",
[NSNumber numberWithInt:0x338D], @"mugsquare",
[NSNumber numberWithInt:0x3080], @"muhiragana",
[NSNumber numberWithInt:0x30E0], @"mukatakana",
[NSNumber numberWithInt:0xFF91], @"mukatakanahalfwidth",
[NSNumber numberWithInt:0x3395], @"mulsquare",
[NSNumber numberWithInt:0x00D7], @"multiply",
[NSNumber numberWithInt:0x339B], @"mumsquare",
[NSNumber numberWithInt:0x05A3], @"munahhebrew",
[NSNumber numberWithInt:0x05A3], @"munahlefthebrew",
[NSNumber numberWithInt:0x266A], @"musicalnote",
[NSNumber numberWithInt:0x266B], @"musicalnotedbl",
[NSNumber numberWithInt:0x266D], @"musicflatsign",
[NSNumber numberWithInt:0x266F], @"musicsharpsign",
[NSNumber numberWithInt:0x33B2], @"mussquare",
[NSNumber numberWithInt:0x33B6], @"muvsquare",
[NSNumber numberWithInt:0x33BC], @"muwsquare",
[NSNumber numberWithInt:0x33B9], @"mvmegasquare",
[NSNumber numberWithInt:0x33B7], @"mvsquare",
[NSNumber numberWithInt:0x33BF], @"mwmegasquare",
[NSNumber numberWithInt:0x33BD], @"mwsquare",
[NSNumber numberWithInt:0x006E], @"n",
[NSNumber numberWithInt:0x09A8], @"nabengali",
[NSNumber numberWithInt:0x2207], @"nabla",
[NSNumber numberWithInt:0x0144], @"nacute",
[NSNumber numberWithInt:0x0928], @"nadeva",
[NSNumber numberWithInt:0x0AA8], @"nagujarati",
[NSNumber numberWithInt:0x0A28], @"nagurmukhi",
[NSNumber numberWithInt:0x306A], @"nahiragana",
[NSNumber numberWithInt:0x30CA], @"nakatakana",
[NSNumber numberWithInt:0xFF85], @"nakatakanahalfwidth",
[NSNumber numberWithInt:0x0149], @"napostrophe",
[NSNumber numberWithInt:0x3381], @"nasquare",
[NSNumber numberWithInt:0x310B], @"nbopomofo",
[NSNumber numberWithInt:0x00A0], @"nbspace",
[NSNumber numberWithInt:0x0148], @"ncaron",
[NSNumber numberWithInt:0x0146], @"ncedilla",
[NSNumber numberWithInt:0x24DD], @"ncircle",
[NSNumber numberWithInt:0x1E4B], @"ncircumflexbelow",
[NSNumber numberWithInt:0x0146], @"ncommaaccent",
[NSNumber numberWithInt:0x1E45], @"ndotaccent",
[NSNumber numberWithInt:0x1E47], @"ndotbelow",
[NSNumber numberWithInt:0x306D], @"nehiragana",
[NSNumber numberWithInt:0x30CD], @"nekatakana",
[NSNumber numberWithInt:0xFF88], @"nekatakanahalfwidth",
[NSNumber numberWithInt:0x20AA], @"newsheqelsign",
[NSNumber numberWithInt:0x338B], @"nfsquare",
[NSNumber numberWithInt:0x0999], @"ngabengali",
[NSNumber numberWithInt:0x0919], @"ngadeva",
[NSNumber numberWithInt:0x0A99], @"ngagujarati",
[NSNumber numberWithInt:0x0A19], @"ngagurmukhi",
[NSNumber numberWithInt:0x0E07], @"ngonguthai",
[NSNumber numberWithInt:0x3093], @"nhiragana",
[NSNumber numberWithInt:0x0272], @"nhookleft",
[NSNumber numberWithInt:0x0273], @"nhookretroflex",
[NSNumber numberWithInt:0x326F], @"nieunacirclekorean",
[NSNumber numberWithInt:0x320F], @"nieunaparenkorean",
[NSNumber numberWithInt:0x3135], @"nieuncieuckorean",
[NSNumber numberWithInt:0x3261], @"nieuncirclekorean",
[NSNumber numberWithInt:0x3136], @"nieunhieuhkorean",
[NSNumber numberWithInt:0x3134], @"nieunkorean",
[NSNumber numberWithInt:0x3168], @"nieunpansioskorean",
[NSNumber numberWithInt:0x3201], @"nieunparenkorean",
[NSNumber numberWithInt:0x3167], @"nieunsioskorean",
[NSNumber numberWithInt:0x3166], @"nieuntikeutkorean",
[NSNumber numberWithInt:0x306B], @"nihiragana",
[NSNumber numberWithInt:0x30CB], @"nikatakana",
[NSNumber numberWithInt:0xFF86], @"nikatakanahalfwidth",
[NSNumber numberWithInt:0xF899], @"nikhahitleftthai",
[NSNumber numberWithInt:0x0E4D], @"nikhahitthai",
[NSNumber numberWithInt:0x0039], @"nine",
[NSNumber numberWithInt:0x0669], @"ninearabic",
[NSNumber numberWithInt:0x09EF], @"ninebengali",
[NSNumber numberWithInt:0x2468], @"ninecircle",
[NSNumber numberWithInt:0x2792], @"ninecircleinversesansserif",
[NSNumber numberWithInt:0x096F], @"ninedeva",
[NSNumber numberWithInt:0x0AEF], @"ninegujarati",
[NSNumber numberWithInt:0x0A6F], @"ninegurmukhi",
[NSNumber numberWithInt:0x0669], @"ninehackarabic",
[NSNumber numberWithInt:0x3029], @"ninehangzhou",
[NSNumber numberWithInt:0x3228], @"nineideographicparen",
[NSNumber numberWithInt:0x2089], @"nineinferior",
[NSNumber numberWithInt:0xFF19], @"ninemonospace",
[NSNumber numberWithInt:0xF739], @"nineoldstyle",
[NSNumber numberWithInt:0x247C], @"nineparen",
[NSNumber numberWithInt:0x2490], @"nineperiod",
[NSNumber numberWithInt:0x06F9], @"ninepersian",
[NSNumber numberWithInt:0x2178], @"nineroman",
[NSNumber numberWithInt:0x2079], @"ninesuperior",
[NSNumber numberWithInt:0x2472], @"nineteencircle",
[NSNumber numberWithInt:0x2486], @"nineteenparen",
[NSNumber numberWithInt:0x249A], @"nineteenperiod",
[NSNumber numberWithInt:0x0E59], @"ninethai",
[NSNumber numberWithInt:0x01CC], @"nj",
[NSNumber numberWithInt:0x045A], @"njecyrillic",
[NSNumber numberWithInt:0x30F3], @"nkatakana",
[NSNumber numberWithInt:0xFF9D], @"nkatakanahalfwidth",
[NSNumber numberWithInt:0x019E], @"nlegrightlong",
[NSNumber numberWithInt:0x1E49], @"nlinebelow",
[NSNumber numberWithInt:0xFF4E], @"nmonospace",
[NSNumber numberWithInt:0x339A], @"nmsquare",
[NSNumber numberWithInt:0x09A3], @"nnabengali",
[NSNumber numberWithInt:0x0923], @"nnadeva",
[NSNumber numberWithInt:0x0AA3], @"nnagujarati",
[NSNumber numberWithInt:0x0A23], @"nnagurmukhi",
[NSNumber numberWithInt:0x0929], @"nnnadeva",
[NSNumber numberWithInt:0x306E], @"nohiragana",
[NSNumber numberWithInt:0x30CE], @"nokatakana",
[NSNumber numberWithInt:0xFF89], @"nokatakanahalfwidth",
[NSNumber numberWithInt:0x00A0], @"nonbreakingspace",
[NSNumber numberWithInt:0x0E13], @"nonenthai",
[NSNumber numberWithInt:0x0E19], @"nonuthai",
[NSNumber numberWithInt:0x0646], @"noonarabic",
[NSNumber numberWithInt:0xFEE6], @"noonfinalarabic",
[NSNumber numberWithInt:0x06BA], @"noonghunnaarabic",
[NSNumber numberWithInt:0xFB9F], @"noonghunnafinalarabic",
//[NSNumber numberWithInt:0xFEE7 FEEC], @"noonhehinitialarabic",
[NSNumber numberWithInt:0xFEE7], @"nooninitialarabic",
[NSNumber numberWithInt:0xFCD2], @"noonjeeminitialarabic",
[NSNumber numberWithInt:0xFC4B], @"noonjeemisolatedarabic",
[NSNumber numberWithInt:0xFEE8], @"noonmedialarabic",
[NSNumber numberWithInt:0xFCD5], @"noonmeeminitialarabic",
[NSNumber numberWithInt:0xFC4E], @"noonmeemisolatedarabic",
[NSNumber numberWithInt:0xFC8D], @"noonnoonfinalarabic",
[NSNumber numberWithInt:0x220C], @"notcontains",
[NSNumber numberWithInt:0x2209], @"notelement",
[NSNumber numberWithInt:0x2209], @"notelementof",
[NSNumber numberWithInt:0x2260], @"notequal",
[NSNumber numberWithInt:0x226F], @"notgreater",
[NSNumber numberWithInt:0x2271], @"notgreaternorequal",
[NSNumber numberWithInt:0x2279], @"notgreaternorless",
[NSNumber numberWithInt:0x2262], @"notidentical",
[NSNumber numberWithInt:0x226E], @"notless",
[NSNumber numberWithInt:0x2270], @"notlessnorequal",
[NSNumber numberWithInt:0x2226], @"notparallel",
[NSNumber numberWithInt:0x2280], @"notprecedes",
[NSNumber numberWithInt:0x2284], @"notsubset",
[NSNumber numberWithInt:0x2281], @"notsucceeds",
[NSNumber numberWithInt:0x2285], @"notsuperset",
[NSNumber numberWithInt:0x0576], @"nowarmenian",
[NSNumber numberWithInt:0x24A9], @"nparen",
[NSNumber numberWithInt:0x33B1], @"nssquare",
[NSNumber numberWithInt:0x207F], @"nsuperior",
[NSNumber numberWithInt:0x00F1], @"ntilde",
[NSNumber numberWithInt:0x03BD], @"nu",
[NSNumber numberWithInt:0x306C], @"nuhiragana",
[NSNumber numberWithInt:0x30CC], @"nukatakana",
[NSNumber numberWithInt:0xFF87], @"nukatakanahalfwidth",
[NSNumber numberWithInt:0x09BC], @"nuktabengali",
[NSNumber numberWithInt:0x093C], @"nuktadeva",
[NSNumber numberWithInt:0x0ABC], @"nuktagujarati",
[NSNumber numberWithInt:0x0A3C], @"nuktagurmukhi",
[NSNumber numberWithInt:0x0023], @"numbersign",
[NSNumber numberWithInt:0xFF03], @"numbersignmonospace",
[NSNumber numberWithInt:0xFE5F], @"numbersignsmall",
[NSNumber numberWithInt:0x0374], @"numeralsigngreek",
[NSNumber numberWithInt:0x0375], @"numeralsignlowergreek",
[NSNumber numberWithInt:0x2116], @"numero",
[NSNumber numberWithInt:0x05E0], @"nun",
[NSNumber numberWithInt:0xFB40], @"nundagesh",
[NSNumber numberWithInt:0xFB40], @"nundageshhebrew",
[NSNumber numberWithInt:0x05E0], @"nunhebrew",
[NSNumber numberWithInt:0x33B5], @"nvsquare",
[NSNumber numberWithInt:0x33BB], @"nwsquare",
[NSNumber numberWithInt:0x099E], @"nyabengali",
[NSNumber numberWithInt:0x091E], @"nyadeva",
[NSNumber numberWithInt:0x0A9E], @"nyagujarati",
[NSNumber numberWithInt:0x0A1E], @"nyagurmukhi",
[NSNumber numberWithInt:0x006F], @"o",
[NSNumber numberWithInt:0x00F3], @"oacute",
[NSNumber numberWithInt:0x0E2D], @"oangthai",
[NSNumber numberWithInt:0x0275], @"obarred",
[NSNumber numberWithInt:0x04E9], @"obarredcyrillic",
[NSNumber numberWithInt:0x04EB], @"obarreddieresiscyrillic",
[NSNumber numberWithInt:0x0993], @"obengali",
[NSNumber numberWithInt:0x311B], @"obopomofo",
[NSNumber numberWithInt:0x014F], @"obreve",
[NSNumber numberWithInt:0x0911], @"ocandradeva",
[NSNumber numberWithInt:0x0A91], @"ocandragujarati",
[NSNumber numberWithInt:0x0949], @"ocandravowelsigndeva",
[NSNumber numberWithInt:0x0AC9], @"ocandravowelsigngujarati",
[NSNumber numberWithInt:0x01D2], @"ocaron",
[NSNumber numberWithInt:0x24DE], @"ocircle",
[NSNumber numberWithInt:0x00F4], @"ocircumflex",
[NSNumber numberWithInt:0x1ED1], @"ocircumflexacute",
[NSNumber numberWithInt:0x1ED9], @"ocircumflexdotbelow",
[NSNumber numberWithInt:0x1ED3], @"ocircumflexgrave",
[NSNumber numberWithInt:0x1ED5], @"ocircumflexhookabove",
[NSNumber numberWithInt:0x1ED7], @"ocircumflextilde",
[NSNumber numberWithInt:0x043E], @"ocyrillic",
[NSNumber numberWithInt:0x0151], @"odblacute",
[NSNumber numberWithInt:0x020D], @"odblgrave",
[NSNumber numberWithInt:0x0913], @"odeva",
[NSNumber numberWithInt:0x00F6], @"odieresis",
[NSNumber numberWithInt:0x04E7], @"odieresiscyrillic",
[NSNumber numberWithInt:0x1ECD], @"odotbelow",
[NSNumber numberWithInt:0x0153], @"oe",
[NSNumber numberWithInt:0x315A], @"oekorean",
[NSNumber numberWithInt:0x02DB], @"ogonek",
[NSNumber numberWithInt:0x0328], @"ogonekcmb",
[NSNumber numberWithInt:0x00F2], @"ograve",
[NSNumber numberWithInt:0x0A93], @"ogujarati",
[NSNumber numberWithInt:0x0585], @"oharmenian",
[NSNumber numberWithInt:0x304A], @"ohiragana",
[NSNumber numberWithInt:0x1ECF], @"ohookabove",
[NSNumber numberWithInt:0x01A1], @"ohorn",
[NSNumber numberWithInt:0x1EDB], @"ohornacute",
[NSNumber numberWithInt:0x1EE3], @"ohorndotbelow",
[NSNumber numberWithInt:0x1EDD], @"ohorngrave",
[NSNumber numberWithInt:0x1EDF], @"ohornhookabove",
[NSNumber numberWithInt:0x1EE1], @"ohorntilde",
[NSNumber numberWithInt:0x0151], @"ohungarumlaut",
[NSNumber numberWithInt:0x01A3], @"oi",
[NSNumber numberWithInt:0x020F], @"oinvertedbreve",
[NSNumber numberWithInt:0x30AA], @"okatakana",
[NSNumber numberWithInt:0xFF75], @"okatakanahalfwidth",
[NSNumber numberWithInt:0x3157], @"okorean",
[NSNumber numberWithInt:0x05AB], @"olehebrew",
[NSNumber numberWithInt:0x014D], @"omacron",
[NSNumber numberWithInt:0x1E53], @"omacronacute",
[NSNumber numberWithInt:0x1E51], @"omacrongrave",
[NSNumber numberWithInt:0x0950], @"omdeva",
[NSNumber numberWithInt:0x03C9], @"omega",
[NSNumber numberWithInt:0x03D6], @"omega1",
[NSNumber numberWithInt:0x0461], @"omegacyrillic",
[NSNumber numberWithInt:0x0277], @"omegalatinclosed",
[NSNumber numberWithInt:0x047B], @"omegaroundcyrillic",
[NSNumber numberWithInt:0x047D], @"omegatitlocyrillic",
[NSNumber numberWithInt:0x03CE], @"omegatonos",
[NSNumber numberWithInt:0x0AD0], @"omgujarati",
[NSNumber numberWithInt:0x03BF], @"omicron",
[NSNumber numberWithInt:0x03CC], @"omicrontonos",
[NSNumber numberWithInt:0xFF4F], @"omonospace",
[NSNumber numberWithInt:0x0031], @"one",
[NSNumber numberWithInt:0x0661], @"onearabic",
[NSNumber numberWithInt:0x09E7], @"onebengali",
[NSNumber numberWithInt:0x2460], @"onecircle",
[NSNumber numberWithInt:0x278A], @"onecircleinversesansserif",
[NSNumber numberWithInt:0x0967], @"onedeva",
[NSNumber numberWithInt:0x2024], @"onedotenleader",
[NSNumber numberWithInt:0x215B], @"oneeighth",
[NSNumber numberWithInt:0xF6DC], @"onefitted",
[NSNumber numberWithInt:0x0AE7], @"onegujarati",
[NSNumber numberWithInt:0x0A67], @"onegurmukhi",
[NSNumber numberWithInt:0x0661], @"onehackarabic",
[NSNumber numberWithInt:0x00BD], @"onehalf",
[NSNumber numberWithInt:0x3021], @"onehangzhou",
[NSNumber numberWithInt:0x3220], @"oneideographicparen",
[NSNumber numberWithInt:0x2081], @"oneinferior",
[NSNumber numberWithInt:0xFF11], @"onemonospace",
[NSNumber numberWithInt:0x09F4], @"onenumeratorbengali",
[NSNumber numberWithInt:0xF731], @"oneoldstyle",
[NSNumber numberWithInt:0x2474], @"oneparen",
[NSNumber numberWithInt:0x2488], @"oneperiod",
[NSNumber numberWithInt:0x06F1], @"onepersian",
[NSNumber numberWithInt:0x00BC], @"onequarter",
[NSNumber numberWithInt:0x2170], @"oneroman",
[NSNumber numberWithInt:0x00B9], @"onesuperior",
[NSNumber numberWithInt:0x0E51], @"onethai",
[NSNumber numberWithInt:0x2153], @"onethird",
[NSNumber numberWithInt:0x01EB], @"oogonek",
[NSNumber numberWithInt:0x01ED], @"oogonekmacron",
[NSNumber numberWithInt:0x0A13], @"oogurmukhi",
[NSNumber numberWithInt:0x0A4B], @"oomatragurmukhi",
[NSNumber numberWithInt:0x0254], @"oopen",
[NSNumber numberWithInt:0x24AA], @"oparen",
[NSNumber numberWithInt:0x25E6], @"openbullet",
[NSNumber numberWithInt:0x2325], @"option",
[NSNumber numberWithInt:0x00AA], @"ordfeminine",
[NSNumber numberWithInt:0x00BA], @"ordmasculine",
[NSNumber numberWithInt:0x221F], @"orthogonal",
[NSNumber numberWithInt:0x0912], @"oshortdeva",
[NSNumber numberWithInt:0x094A], @"oshortvowelsigndeva",
[NSNumber numberWithInt:0x00F8], @"oslash",
[NSNumber numberWithInt:0x01FF], @"oslashacute",
[NSNumber numberWithInt:0x3049], @"osmallhiragana",
[NSNumber numberWithInt:0x30A9], @"osmallkatakana",
[NSNumber numberWithInt:0xFF6B], @"osmallkatakanahalfwidth",
[NSNumber numberWithInt:0x01FF], @"ostrokeacute",
[NSNumber numberWithInt:0xF6F0], @"osuperior",
[NSNumber numberWithInt:0x047F], @"otcyrillic",
[NSNumber numberWithInt:0x00F5], @"otilde",
[NSNumber numberWithInt:0x1E4D], @"otildeacute",
[NSNumber numberWithInt:0x1E4F], @"otildedieresis",
[NSNumber numberWithInt:0x3121], @"oubopomofo",
[NSNumber numberWithInt:0x203E], @"overline",
[NSNumber numberWithInt:0xFE4A], @"overlinecenterline",
[NSNumber numberWithInt:0x0305], @"overlinecmb",
[NSNumber numberWithInt:0xFE49], @"overlinedashed",
[NSNumber numberWithInt:0xFE4C], @"overlinedblwavy",
[NSNumber numberWithInt:0xFE4B], @"overlinewavy",
[NSNumber numberWithInt:0x00AF], @"overscore",
[NSNumber numberWithInt:0x09CB], @"ovowelsignbengali",
[NSNumber numberWithInt:0x094B], @"ovowelsigndeva",
[NSNumber numberWithInt:0x0ACB], @"ovowelsigngujarati",
[NSNumber numberWithInt:0x0070], @"p",
[NSNumber numberWithInt:0x3380], @"paampssquare",
[NSNumber numberWithInt:0x332B], @"paasentosquare",
[NSNumber numberWithInt:0x09AA], @"pabengali",
[NSNumber numberWithInt:0x1E55], @"pacute",
[NSNumber numberWithInt:0x092A], @"padeva",
[NSNumber numberWithInt:0x21DF], @"pagedown",
[NSNumber numberWithInt:0x21DE], @"pageup",
[NSNumber numberWithInt:0x0AAA], @"pagujarati",
[NSNumber numberWithInt:0x0A2A], @"pagurmukhi",
[NSNumber numberWithInt:0x3071], @"pahiragana",
[NSNumber numberWithInt:0x0E2F], @"paiyannoithai",
[NSNumber numberWithInt:0x30D1], @"pakatakana",
[NSNumber numberWithInt:0x0484], @"palatalizationcyrilliccmb",
[NSNumber numberWithInt:0x04C0], @"palochkacyrillic",
[NSNumber numberWithInt:0x317F], @"pansioskorean",
[NSNumber numberWithInt:0x00B6], @"paragraph",
[NSNumber numberWithInt:0x2225], @"parallel",
[NSNumber numberWithInt:0x0028], @"parenleft",
[NSNumber numberWithInt:0xFD3E], @"parenleftaltonearabic",
[NSNumber numberWithInt:0xF8ED], @"parenleftbt",
[NSNumber numberWithInt:0xF8EC], @"parenleftex",
[NSNumber numberWithInt:0x208D], @"parenleftinferior",
[NSNumber numberWithInt:0xFF08], @"parenleftmonospace",
[NSNumber numberWithInt:0xFE59], @"parenleftsmall",
[NSNumber numberWithInt:0x207D], @"parenleftsuperior",
[NSNumber numberWithInt:0xF8EB], @"parenlefttp",
[NSNumber numberWithInt:0xFE35], @"parenleftvertical",
[NSNumber numberWithInt:0x0029], @"parenright",
[NSNumber numberWithInt:0xFD3F], @"parenrightaltonearabic",
[NSNumber numberWithInt:0xF8F8], @"parenrightbt",
[NSNumber numberWithInt:0xF8F7], @"parenrightex",
[NSNumber numberWithInt:0x208E], @"parenrightinferior",
[NSNumber numberWithInt:0xFF09], @"parenrightmonospace",
[NSNumber numberWithInt:0xFE5A], @"parenrightsmall",
[NSNumber numberWithInt:0x207E], @"parenrightsuperior",
[NSNumber numberWithInt:0xF8F6], @"parenrighttp",
[NSNumber numberWithInt:0xFE36], @"parenrightvertical",
[NSNumber numberWithInt:0x2202], @"partialdiff",
[NSNumber numberWithInt:0x05C0], @"paseqhebrew",
[NSNumber numberWithInt:0x0599], @"pashtahebrew",
[NSNumber numberWithInt:0x33A9], @"pasquare",
[NSNumber numberWithInt:0x05B7], @"patah",
[NSNumber numberWithInt:0x05B7], @"patah11",
[NSNumber numberWithInt:0x05B7], @"patah1d",
[NSNumber numberWithInt:0x05B7], @"patah2a",
[NSNumber numberWithInt:0x05B7], @"patahhebrew",
[NSNumber numberWithInt:0x05B7], @"patahnarrowhebrew",
[NSNumber numberWithInt:0x05B7], @"patahquarterhebrew",
[NSNumber numberWithInt:0x05B7], @"patahwidehebrew",
[NSNumber numberWithInt:0x05A1], @"pazerhebrew",
[NSNumber numberWithInt:0x3106], @"pbopomofo",
[NSNumber numberWithInt:0x24DF], @"pcircle",
[NSNumber numberWithInt:0x1E57], @"pdotaccent",
[NSNumber numberWithInt:0x05E4], @"pe",
[NSNumber numberWithInt:0x043F], @"pecyrillic",
[NSNumber numberWithInt:0xFB44], @"pedagesh",
[NSNumber numberWithInt:0xFB44], @"pedageshhebrew",
[NSNumber numberWithInt:0x333B], @"peezisquare",
[NSNumber numberWithInt:0xFB43], @"pefinaldageshhebrew",
[NSNumber numberWithInt:0x067E], @"peharabic",
[NSNumber numberWithInt:0x057A], @"peharmenian",
[NSNumber numberWithInt:0x05E4], @"pehebrew",
[NSNumber numberWithInt:0xFB57], @"pehfinalarabic",
[NSNumber numberWithInt:0xFB58], @"pehinitialarabic",
[NSNumber numberWithInt:0x307A], @"pehiragana",
[NSNumber numberWithInt:0xFB59], @"pehmedialarabic",
[NSNumber numberWithInt:0x30DA], @"pekatakana",
[NSNumber numberWithInt:0x04A7], @"pemiddlehookcyrillic",
[NSNumber numberWithInt:0xFB4E], @"perafehebrew",
[NSNumber numberWithInt:0x0025], @"percent",
[NSNumber numberWithInt:0x066A], @"percentarabic",
[NSNumber numberWithInt:0xFF05], @"percentmonospace",
[NSNumber numberWithInt:0xFE6A], @"percentsmall",
[NSNumber numberWithInt:0x002E], @"period",
[NSNumber numberWithInt:0x0589], @"periodarmenian",
[NSNumber numberWithInt:0x00B7], @"periodcentered",
[NSNumber numberWithInt:0xFF61], @"periodhalfwidth",
[NSNumber numberWithInt:0xF6E7], @"periodinferior",
[NSNumber numberWithInt:0xFF0E], @"periodmonospace",
[NSNumber numberWithInt:0xFE52], @"periodsmall",
[NSNumber numberWithInt:0xF6E8], @"periodsuperior",
[NSNumber numberWithInt:0x0342], @"perispomenigreekcmb",
[NSNumber numberWithInt:0x22A5], @"perpendicular",
[NSNumber numberWithInt:0x2030], @"perthousand",
[NSNumber numberWithInt:0x20A7], @"peseta",
[NSNumber numberWithInt:0x338A], @"pfsquare",
[NSNumber numberWithInt:0x09AB], @"phabengali",
[NSNumber numberWithInt:0x092B], @"phadeva",
[NSNumber numberWithInt:0x0AAB], @"phagujarati",
[NSNumber numberWithInt:0x0A2B], @"phagurmukhi",
[NSNumber numberWithInt:0x03C6], @"phi",
[NSNumber numberWithInt:0x03D5], @"phi1",
[NSNumber numberWithInt:0x327A], @"phieuphacirclekorean",
[NSNumber numberWithInt:0x321A], @"phieuphaparenkorean",
[NSNumber numberWithInt:0x326C], @"phieuphcirclekorean",
[NSNumber numberWithInt:0x314D], @"phieuphkorean",
[NSNumber numberWithInt:0x320C], @"phieuphparenkorean",
[NSNumber numberWithInt:0x0278], @"philatin",
[NSNumber numberWithInt:0x0E3A], @"phinthuthai",
[NSNumber numberWithInt:0x03D5], @"phisymbolgreek",
[NSNumber numberWithInt:0x01A5], @"phook",
[NSNumber numberWithInt:0x0E1E], @"phophanthai",
[NSNumber numberWithInt:0x0E1C], @"phophungthai",
[NSNumber numberWithInt:0x0E20], @"phosamphaothai",
[NSNumber numberWithInt:0x03C0], @"pi",
[NSNumber numberWithInt:0x3273], @"pieupacirclekorean",
[NSNumber numberWithInt:0x3213], @"pieupaparenkorean",
[NSNumber numberWithInt:0x3176], @"pieupcieuckorean",
[NSNumber numberWithInt:0x3265], @"pieupcirclekorean",
[NSNumber numberWithInt:0x3172], @"pieupkiyeokkorean",
[NSNumber numberWithInt:0x3142], @"pieupkorean",
[NSNumber numberWithInt:0x3205], @"pieupparenkorean",
[NSNumber numberWithInt:0x3174], @"pieupsioskiyeokkorean",
[NSNumber numberWithInt:0x3144], @"pieupsioskorean",
[NSNumber numberWithInt:0x3175], @"pieupsiostikeutkorean",
[NSNumber numberWithInt:0x3177], @"pieupthieuthkorean",
[NSNumber numberWithInt:0x3173], @"pieuptikeutkorean",
[NSNumber numberWithInt:0x3074], @"pihiragana",
[NSNumber numberWithInt:0x30D4], @"pikatakana",
[NSNumber numberWithInt:0x03D6], @"pisymbolgreek",
[NSNumber numberWithInt:0x0583], @"piwrarmenian",
[NSNumber numberWithInt:0x002B], @"plus",
[NSNumber numberWithInt:0x031F], @"plusbelowcmb",
[NSNumber numberWithInt:0x2295], @"pluscircle",
[NSNumber numberWithInt:0x00B1], @"plusminus",
[NSNumber numberWithInt:0x02D6], @"plusmod",
[NSNumber numberWithInt:0xFF0B], @"plusmonospace",
[NSNumber numberWithInt:0xFE62], @"plussmall",
[NSNumber numberWithInt:0x207A], @"plussuperior",
[NSNumber numberWithInt:0xFF50], @"pmonospace",
[NSNumber numberWithInt:0x33D8], @"pmsquare",
[NSNumber numberWithInt:0x307D], @"pohiragana",
[NSNumber numberWithInt:0x261F], @"pointingindexdownwhite",
[NSNumber numberWithInt:0x261C], @"pointingindexleftwhite",
[NSNumber numberWithInt:0x261E], @"pointingindexrightwhite",
[NSNumber numberWithInt:0x261D], @"pointingindexupwhite",
[NSNumber numberWithInt:0x30DD], @"pokatakana",
[NSNumber numberWithInt:0x0E1B], @"poplathai",
[NSNumber numberWithInt:0x3012], @"postalmark",
[NSNumber numberWithInt:0x3020], @"postalmarkface",
[NSNumber numberWithInt:0x24AB], @"pparen",
[NSNumber numberWithInt:0x227A], @"precedes",
[NSNumber numberWithInt:0x211E], @"prescription",
[NSNumber numberWithInt:0x02B9], @"primemod",
[NSNumber numberWithInt:0x2035], @"primereversed",
[NSNumber numberWithInt:0x220F], @"product",
[NSNumber numberWithInt:0x2305], @"projective",
[NSNumber numberWithInt:0x30FC], @"prolongedkana",
[NSNumber numberWithInt:0x2318], @"propellor",
[NSNumber numberWithInt:0x2282], @"propersubset",
[NSNumber numberWithInt:0x2283], @"propersuperset",
[NSNumber numberWithInt:0x2237], @"proportion",
[NSNumber numberWithInt:0x221D], @"proportional",
[NSNumber numberWithInt:0x03C8], @"psi",
[NSNumber numberWithInt:0x0471], @"psicyrillic",
[NSNumber numberWithInt:0x0486], @"psilipneumatacyrilliccmb",
[NSNumber numberWithInt:0x33B0], @"pssquare",
[NSNumber numberWithInt:0x3077], @"puhiragana",
[NSNumber numberWithInt:0x30D7], @"pukatakana",
[NSNumber numberWithInt:0x33B4], @"pvsquare",
[NSNumber numberWithInt:0x33BA], @"pwsquare",
[NSNumber numberWithInt:0x0071], @"q",
[NSNumber numberWithInt:0x0958], @"qadeva",
[NSNumber numberWithInt:0x05A8], @"qadmahebrew",
[NSNumber numberWithInt:0x0642], @"qafarabic",
[NSNumber numberWithInt:0xFED6], @"qaffinalarabic",
[NSNumber numberWithInt:0xFED7], @"qafinitialarabic",
[NSNumber numberWithInt:0xFED8], @"qafmedialarabic",
[NSNumber numberWithInt:0x05B8], @"qamats",
[NSNumber numberWithInt:0x05B8], @"qamats10",
[NSNumber numberWithInt:0x05B8], @"qamats1a",
[NSNumber numberWithInt:0x05B8], @"qamats1c",
[NSNumber numberWithInt:0x05B8], @"qamats27",
[NSNumber numberWithInt:0x05B8], @"qamats29",
[NSNumber numberWithInt:0x05B8], @"qamats33",
[NSNumber numberWithInt:0x05B8], @"qamatsde",
[NSNumber numberWithInt:0x05B8], @"qamatshebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsnarrowhebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsqatanhebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsqatannarrowhebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsqatanquarterhebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsqatanwidehebrew",
[NSNumber numberWithInt:0x05B8], @"qamatsquarterhebrew",
[NSNumber numberWithInt:0x05B8], @"qamatswidehebrew",
[NSNumber numberWithInt:0x059F], @"qarneyparahebrew",
[NSNumber numberWithInt:0x3111], @"qbopomofo",
[NSNumber numberWithInt:0x24E0], @"qcircle",
[NSNumber numberWithInt:0x02A0], @"qhook",
[NSNumber numberWithInt:0xFF51], @"qmonospace",
[NSNumber numberWithInt:0x05E7], @"qof",
[NSNumber numberWithInt:0xFB47], @"qofdagesh",
[NSNumber numberWithInt:0xFB47], @"qofdageshhebrew",
//[NSNumber numberWithInt:0x05E7 05B2], @"qofhatafpatah",
//[NSNumber numberWithInt:0x05E7 05B2], @"qofhatafpatahhebrew",
//[NSNumber numberWithInt:0x05E7 05B1], @"qofhatafsegol",
//[NSNumber numberWithInt:0x05E7 05B1], @"qofhatafsegolhebrew",
[NSNumber numberWithInt:0x05E7], @"qofhebrew",
//[NSNumber numberWithInt:0x05E7 05B4], @"qofhiriq",
//[NSNumber numberWithInt:0x05E7 05B4], @"qofhiriqhebrew",
//[NSNumber numberWithInt:0x05E7 05B9], @"qofholam",
//[NSNumber numberWithInt:0x05E7 05B9], @"qofholamhebrew",
//[NSNumber numberWithInt:0x05E7 05B7], @"qofpatah",
//[NSNumber numberWithInt:0x05E7 05B7], @"qofpatahhebrew",
//[NSNumber numberWithInt:0x05E7 05B8], @"qofqamats",
//[NSNumber numberWithInt:0x05E7 05B8], @"qofqamatshebrew",
//[NSNumber numberWithInt:0x05E7 05BB], @"qofqubuts",
//[NSNumber numberWithInt:0x05E7 05BB], @"qofqubutshebrew",
//[NSNumber numberWithInt:0x05E7 05B6], @"qofsegol",
//[NSNumber numberWithInt:0x05E7 05B6], @"qofsegolhebrew",
//[NSNumber numberWithInt:0x05E7 05B0], @"qofsheva",
//[NSNumber numberWithInt:0x05E7 05B0], @"qofshevahebrew",
//[NSNumber numberWithInt:0x05E7 05B5], @"qoftsere",
//[NSNumber numberWithInt:0x05E7 05B5], @"qoftserehebrew",
[NSNumber numberWithInt:0x24AC], @"qparen",
[NSNumber numberWithInt:0x2669], @"quarternote",
[NSNumber numberWithInt:0x05BB], @"qubuts",
[NSNumber numberWithInt:0x05BB], @"qubuts18",
[NSNumber numberWithInt:0x05BB], @"qubuts25",
[NSNumber numberWithInt:0x05BB], @"qubuts31",
[NSNumber numberWithInt:0x05BB], @"qubutshebrew",
[NSNumber numberWithInt:0x05BB], @"qubutsnarrowhebrew",
[NSNumber numberWithInt:0x05BB], @"qubutsquarterhebrew",
[NSNumber numberWithInt:0x05BB], @"qubutswidehebrew",
[NSNumber numberWithInt:0x003F], @"question",
[NSNumber numberWithInt:0x061F], @"questionarabic",
[NSNumber numberWithInt:0x055E], @"questionarmenian",
[NSNumber numberWithInt:0x00BF], @"questiondown",
[NSNumber numberWithInt:0xF7BF], @"questiondownsmall",
[NSNumber numberWithInt:0x037E], @"questiongreek",
[NSNumber numberWithInt:0xFF1F], @"questionmonospace",
[NSNumber numberWithInt:0xF73F], @"questionsmall",
[NSNumber numberWithInt:0x0022], @"quotedbl",
[NSNumber numberWithInt:0x201E], @"quotedblbase",
[NSNumber numberWithInt:0x201C], @"quotedblleft",
[NSNumber numberWithInt:0xFF02], @"quotedblmonospace",
[NSNumber numberWithInt:0x301E], @"quotedblprime",
[NSNumber numberWithInt:0x301D], @"quotedblprimereversed",
[NSNumber numberWithInt:0x201D], @"quotedblright",
[NSNumber numberWithInt:0x2018], @"quoteleft",
[NSNumber numberWithInt:0x201B], @"quoteleftreversed",
[NSNumber numberWithInt:0x201B], @"quotereversed",
[NSNumber numberWithInt:0x2019], @"quoteright",
[NSNumber numberWithInt:0x0149], @"quoterightn",
[NSNumber numberWithInt:0x201A], @"quotesinglbase",
[NSNumber numberWithInt:0x0027], @"quotesingle",
[NSNumber numberWithInt:0xFF07], @"quotesinglemonospace",
[NSNumber numberWithInt:0x0072], @"r",
[NSNumber numberWithInt:0x057C], @"raarmenian",
[NSNumber numberWithInt:0x09B0], @"rabengali",
[NSNumber numberWithInt:0x0155], @"racute",
[NSNumber numberWithInt:0x0930], @"radeva",
[NSNumber numberWithInt:0x221A], @"radical",
[NSNumber numberWithInt:0xF8E5], @"radicalex",
[NSNumber numberWithInt:0x33AE], @"radoverssquare",
[NSNumber numberWithInt:0x33AF], @"radoverssquaredsquare",
[NSNumber numberWithInt:0x33AD], @"radsquare",
[NSNumber numberWithInt:0x05BF], @"rafe",
[NSNumber numberWithInt:0x05BF], @"rafehebrew",
[NSNumber numberWithInt:0x0AB0], @"ragujarati",
[NSNumber numberWithInt:0x0A30], @"ragurmukhi",
[NSNumber numberWithInt:0x3089], @"rahiragana",
[NSNumber numberWithInt:0x30E9], @"rakatakana",
[NSNumber numberWithInt:0xFF97], @"rakatakanahalfwidth",
[NSNumber numberWithInt:0x09F1], @"ralowerdiagonalbengali",
[NSNumber numberWithInt:0x09F0], @"ramiddlediagonalbengali",
[NSNumber numberWithInt:0x0264], @"ramshorn",
[NSNumber numberWithInt:0x2236], @"ratio",
[NSNumber numberWithInt:0x3116], @"rbopomofo",
[NSNumber numberWithInt:0x0159], @"rcaron",
[NSNumber numberWithInt:0x0157], @"rcedilla",
[NSNumber numberWithInt:0x24E1], @"rcircle",
[NSNumber numberWithInt:0x0157], @"rcommaaccent",
[NSNumber numberWithInt:0x0211], @"rdblgrave",
[NSNumber numberWithInt:0x1E59], @"rdotaccent",
[NSNumber numberWithInt:0x1E5B], @"rdotbelow",
[NSNumber numberWithInt:0x1E5D], @"rdotbelowmacron",
[NSNumber numberWithInt:0x203B], @"referencemark",
[NSNumber numberWithInt:0x2286], @"reflexsubset",
[NSNumber numberWithInt:0x2287], @"reflexsuperset",
[NSNumber numberWithInt:0x00AE], @"registered",
[NSNumber numberWithInt:0xF8E8], @"registersans",
[NSNumber numberWithInt:0xF6DA], @"registerserif",
[NSNumber numberWithInt:0x0631], @"reharabic",
[NSNumber numberWithInt:0x0580], @"reharmenian",
[NSNumber numberWithInt:0xFEAE], @"rehfinalarabic",
[NSNumber numberWithInt:0x308C], @"rehiragana",
//[NSNumber numberWithInt:0x0631 FEF3 FE8E 0644], @"rehyehaleflamarabic",
[NSNumber numberWithInt:0x30EC], @"rekatakana",
[NSNumber numberWithInt:0xFF9A], @"rekatakanahalfwidth",
[NSNumber numberWithInt:0x05E8], @"resh",
[NSNumber numberWithInt:0xFB48], @"reshdageshhebrew",
//[NSNumber numberWithInt:0x05E8 05B2], @"reshhatafpatah",
//[NSNumber numberWithInt:0x05E8 05B2], @"reshhatafpatahhebrew",
//[NSNumber numberWithInt:0x05E8 05B1], @"reshhatafsegol",
//[NSNumber numberWithInt:0x05E8 05B1], @"reshhatafsegolhebrew",
[NSNumber numberWithInt:0x05E8], @"reshhebrew",
//[NSNumber numberWithInt:0x05E8 05B4], @"reshhiriq",
//[NSNumber numberWithInt:0x05E8 05B4], @"reshhiriqhebrew",
//[NSNumber numberWithInt:0x05E8 05B9], @"reshholam",
//[NSNumber numberWithInt:0x05E8 05B9], @"reshholamhebrew",
//[NSNumber numberWithInt:0x05E8 05B7], @"reshpatah",
//[NSNumber numberWithInt:0x05E8 05B7], @"reshpatahhebrew",
//[NSNumber numberWithInt:0x05E8 05B8], @"reshqamats",
//[NSNumber numberWithInt:0x05E8 05B8], @"reshqamatshebrew",
//[NSNumber numberWithInt:0x05E8 05BB], @"reshqubuts",
//[NSNumber numberWithInt:0x05E8 05BB], @"reshqubutshebrew",
//[NSNumber numberWithInt:0x05E8 05B6], @"reshsegol",
//[NSNumber numberWithInt:0x05E8 05B6], @"reshsegolhebrew",
//[NSNumber numberWithInt:0x05E8 05B0], @"reshsheva",
//[NSNumber numberWithInt:0x05E8 05B0], @"reshshevahebrew",
//[NSNumber numberWithInt:0x05E8 05B5], @"reshtsere",
//[NSNumber numberWithInt:0x05E8 05B5], @"reshtserehebrew",
[NSNumber numberWithInt:0x223D], @"reversedtilde",
[NSNumber numberWithInt:0x0597], @"reviahebrew",
[NSNumber numberWithInt:0x0597], @"reviamugrashhebrew",
[NSNumber numberWithInt:0x2310], @"revlogicalnot",
[NSNumber numberWithInt:0x027E], @"rfishhook",
[NSNumber numberWithInt:0x027F], @"rfishhookreversed",
[NSNumber numberWithInt:0x09DD], @"rhabengali",
[NSNumber numberWithInt:0x095D], @"rhadeva",
[NSNumber numberWithInt:0x03C1], @"rho",
[NSNumber numberWithInt:0x027D], @"rhook",
[NSNumber numberWithInt:0x027B], @"rhookturned",
[NSNumber numberWithInt:0x02B5], @"rhookturnedsuperior",
[NSNumber numberWithInt:0x03F1], @"rhosymbolgreek",
[NSNumber numberWithInt:0x02DE], @"rhotichookmod",
[NSNumber numberWithInt:0x3271], @"rieulacirclekorean",
[NSNumber numberWithInt:0x3211], @"rieulaparenkorean",
[NSNumber numberWithInt:0x3263], @"rieulcirclekorean",
[NSNumber numberWithInt:0x3140], @"rieulhieuhkorean",
[NSNumber numberWithInt:0x313A], @"rieulkiyeokkorean",
[NSNumber numberWithInt:0x3169], @"rieulkiyeoksioskorean",
[NSNumber numberWithInt:0x3139], @"rieulkorean",
[NSNumber numberWithInt:0x313B], @"rieulmieumkorean",
[NSNumber numberWithInt:0x316C], @"rieulpansioskorean",
[NSNumber numberWithInt:0x3203], @"rieulparenkorean",
[NSNumber numberWithInt:0x313F], @"rieulphieuphkorean",
[NSNumber numberWithInt:0x313C], @"rieulpieupkorean",
[NSNumber numberWithInt:0x316B], @"rieulpieupsioskorean",
[NSNumber numberWithInt:0x313D], @"rieulsioskorean",
[NSNumber numberWithInt:0x313E], @"rieulthieuthkorean",
[NSNumber numberWithInt:0x316A], @"rieultikeutkorean",
[NSNumber numberWithInt:0x316D], @"rieulyeorinhieuhkorean",
[NSNumber numberWithInt:0x221F], @"rightangle",
[NSNumber numberWithInt:0x0319], @"righttackbelowcmb",
[NSNumber numberWithInt:0x22BF], @"righttriangle",
[NSNumber numberWithInt:0x308A], @"rihiragana",
[NSNumber numberWithInt:0x30EA], @"rikatakana",
[NSNumber numberWithInt:0xFF98], @"rikatakanahalfwidth",
[NSNumber numberWithInt:0x02DA], @"ring",
[NSNumber numberWithInt:0x0325], @"ringbelowcmb",
[NSNumber numberWithInt:0x030A], @"ringcmb",
[NSNumber numberWithInt:0x02BF], @"ringhalfleft",
[NSNumber numberWithInt:0x0559], @"ringhalfleftarmenian",
[NSNumber numberWithInt:0x031C], @"ringhalfleftbelowcmb",
[NSNumber numberWithInt:0x02D3], @"ringhalfleftcentered",
[NSNumber numberWithInt:0x02BE], @"ringhalfright",
[NSNumber numberWithInt:0x0339], @"ringhalfrightbelowcmb",
[NSNumber numberWithInt:0x02D2], @"ringhalfrightcentered",
[NSNumber numberWithInt:0x0213], @"rinvertedbreve",
[NSNumber numberWithInt:0x3351], @"rittorusquare",
[NSNumber numberWithInt:0x1E5F], @"rlinebelow",
[NSNumber numberWithInt:0x027C], @"rlongleg",
[NSNumber numberWithInt:0x027A], @"rlonglegturned",
[NSNumber numberWithInt:0xFF52], @"rmonospace",
[NSNumber numberWithInt:0x308D], @"rohiragana",
[NSNumber numberWithInt:0x30ED], @"rokatakana",
[NSNumber numberWithInt:0xFF9B], @"rokatakanahalfwidth",
[NSNumber numberWithInt:0x0E23], @"roruathai",
[NSNumber numberWithInt:0x24AD], @"rparen",
[NSNumber numberWithInt:0x09DC], @"rrabengali",
[NSNumber numberWithInt:0x0931], @"rradeva",
[NSNumber numberWithInt:0x0A5C], @"rragurmukhi",
[NSNumber numberWithInt:0x0691], @"rreharabic",
[NSNumber numberWithInt:0xFB8D], @"rrehfinalarabic",
[NSNumber numberWithInt:0x09E0], @"rrvocalicbengali",
[NSNumber numberWithInt:0x0960], @"rrvocalicdeva",
[NSNumber numberWithInt:0x0AE0], @"rrvocalicgujarati",
[NSNumber numberWithInt:0x09C4], @"rrvocalicvowelsignbengali",
[NSNumber numberWithInt:0x0944], @"rrvocalicvowelsigndeva",
[NSNumber numberWithInt:0x0AC4], @"rrvocalicvowelsigngujarati",
[NSNumber numberWithInt:0xF6F1], @"rsuperior",
[NSNumber numberWithInt:0x2590], @"rtblock",
[NSNumber numberWithInt:0x0279], @"rturned",
[NSNumber numberWithInt:0x02B4], @"rturnedsuperior",
[NSNumber numberWithInt:0x308B], @"ruhiragana",
[NSNumber numberWithInt:0x30EB], @"rukatakana",
[NSNumber numberWithInt:0xFF99], @"rukatakanahalfwidth",
[NSNumber numberWithInt:0x09F2], @"rupeemarkbengali",
[NSNumber numberWithInt:0x09F3], @"rupeesignbengali",
[NSNumber numberWithInt:0xF6DD], @"rupiah",
[NSNumber numberWithInt:0x0E24], @"ruthai",
[NSNumber numberWithInt:0x098B], @"rvocalicbengali",
[NSNumber numberWithInt:0x090B], @"rvocalicdeva",
[NSNumber numberWithInt:0x0A8B], @"rvocalicgujarati",
[NSNumber numberWithInt:0x09C3], @"rvocalicvowelsignbengali",
[NSNumber numberWithInt:0x0943], @"rvocalicvowelsigndeva",
[NSNumber numberWithInt:0x0AC3], @"rvocalicvowelsigngujarati",
[NSNumber numberWithInt:0x0073], @"s",
[NSNumber numberWithInt:0x09B8], @"sabengali",
[NSNumber numberWithInt:0x015B], @"sacute",
[NSNumber numberWithInt:0x1E65], @"sacutedotaccent",
[NSNumber numberWithInt:0x0635], @"sadarabic",
[NSNumber numberWithInt:0x0938], @"sadeva",
[NSNumber numberWithInt:0xFEBA], @"sadfinalarabic",
[NSNumber numberWithInt:0xFEBB], @"sadinitialarabic",
[NSNumber numberWithInt:0xFEBC], @"sadmedialarabic",
[NSNumber numberWithInt:0x0AB8], @"sagujarati",
[NSNumber numberWithInt:0x0A38], @"sagurmukhi",
[NSNumber numberWithInt:0x3055], @"sahiragana",
[NSNumber numberWithInt:0x30B5], @"sakatakana",
[NSNumber numberWithInt:0xFF7B], @"sakatakanahalfwidth",
[NSNumber numberWithInt:0xFDFA], @"sallallahoualayhewasallamarabic",
[NSNumber numberWithInt:0x05E1], @"samekh",
[NSNumber numberWithInt:0xFB41], @"samekhdagesh",
[NSNumber numberWithInt:0xFB41], @"samekhdageshhebrew",
[NSNumber numberWithInt:0x05E1], @"samekhhebrew",
[NSNumber numberWithInt:0x0E32], @"saraaathai",
[NSNumber numberWithInt:0x0E41], @"saraaethai",
[NSNumber numberWithInt:0x0E44], @"saraaimaimalaithai",
[NSNumber numberWithInt:0x0E43], @"saraaimaimuanthai",
[NSNumber numberWithInt:0x0E33], @"saraamthai",
[NSNumber numberWithInt:0x0E30], @"saraathai",
[NSNumber numberWithInt:0x0E40], @"saraethai",
[NSNumber numberWithInt:0xF886], @"saraiileftthai",
[NSNumber numberWithInt:0x0E35], @"saraiithai",
[NSNumber numberWithInt:0xF885], @"saraileftthai",
[NSNumber numberWithInt:0x0E34], @"saraithai",
[NSNumber numberWithInt:0x0E42], @"saraothai",
[NSNumber numberWithInt:0xF888], @"saraueeleftthai",
[NSNumber numberWithInt:0x0E37], @"saraueethai",
[NSNumber numberWithInt:0xF887], @"saraueleftthai",
[NSNumber numberWithInt:0x0E36], @"sarauethai",
[NSNumber numberWithInt:0x0E38], @"sarauthai",
[NSNumber numberWithInt:0x0E39], @"sarauuthai",
[NSNumber numberWithInt:0x3119], @"sbopomofo",
[NSNumber numberWithInt:0x0161], @"scaron",
[NSNumber numberWithInt:0x1E67], @"scarondotaccent",
[NSNumber numberWithInt:0x015F], @"scedilla",
[NSNumber numberWithInt:0x0259], @"schwa",
[NSNumber numberWithInt:0x04D9], @"schwacyrillic",
[NSNumber numberWithInt:0x04DB], @"schwadieresiscyrillic",
[NSNumber numberWithInt:0x025A], @"schwahook",
[NSNumber numberWithInt:0x24E2], @"scircle",
[NSNumber numberWithInt:0x015D], @"scircumflex",
[NSNumber numberWithInt:0x0219], @"scommaaccent",
[NSNumber numberWithInt:0x1E61], @"sdotaccent",
[NSNumber numberWithInt:0x1E63], @"sdotbelow",
[NSNumber numberWithInt:0x1E69], @"sdotbelowdotaccent",
[NSNumber numberWithInt:0x033C], @"seagullbelowcmb",
[NSNumber numberWithInt:0x2033], @"second",
[NSNumber numberWithInt:0x02CA], @"secondtonechinese",
[NSNumber numberWithInt:0x00A7], @"section",
[NSNumber numberWithInt:0x0633], @"seenarabic",
[NSNumber numberWithInt:0xFEB2], @"seenfinalarabic",
[NSNumber numberWithInt:0xFEB3], @"seeninitialarabic",
[NSNumber numberWithInt:0xFEB4], @"seenmedialarabic",
[NSNumber numberWithInt:0x05B6], @"segol",
[NSNumber numberWithInt:0x05B6], @"segol13",
[NSNumber numberWithInt:0x05B6], @"segol1f",
[NSNumber numberWithInt:0x05B6], @"segol2c",
[NSNumber numberWithInt:0x05B6], @"segolhebrew",
[NSNumber numberWithInt:0x05B6], @"segolnarrowhebrew",
[NSNumber numberWithInt:0x05B6], @"segolquarterhebrew",
[NSNumber numberWithInt:0x0592], @"segoltahebrew",
[NSNumber numberWithInt:0x05B6], @"segolwidehebrew",
[NSNumber numberWithInt:0x057D], @"seharmenian",
[NSNumber numberWithInt:0x305B], @"sehiragana",
[NSNumber numberWithInt:0x30BB], @"sekatakana",
[NSNumber numberWithInt:0xFF7E], @"sekatakanahalfwidth",
[NSNumber numberWithInt:0x003B], @"semicolon",
[NSNumber numberWithInt:0x061B], @"semicolonarabic",
[NSNumber numberWithInt:0xFF1B], @"semicolonmonospace",
[NSNumber numberWithInt:0xFE54], @"semicolonsmall",
[NSNumber numberWithInt:0x309C], @"semivoicedmarkkana",
[NSNumber numberWithInt:0xFF9F], @"semivoicedmarkkanahalfwidth",
[NSNumber numberWithInt:0x3322], @"sentisquare",
[NSNumber numberWithInt:0x3323], @"sentosquare",
[NSNumber numberWithInt:0x0037], @"seven",
[NSNumber numberWithInt:0x0667], @"sevenarabic",
[NSNumber numberWithInt:0x09ED], @"sevenbengali",
[NSNumber numberWithInt:0x2466], @"sevencircle",
[NSNumber numberWithInt:0x2790], @"sevencircleinversesansserif",
[NSNumber numberWithInt:0x096D], @"sevendeva",
[NSNumber numberWithInt:0x215E], @"seveneighths",
[NSNumber numberWithInt:0x0AED], @"sevengujarati",
[NSNumber numberWithInt:0x0A6D], @"sevengurmukhi",
[NSNumber numberWithInt:0x0667], @"sevenhackarabic",
[NSNumber numberWithInt:0x3027], @"sevenhangzhou",
[NSNumber numberWithInt:0x3226], @"sevenideographicparen",
[NSNumber numberWithInt:0x2087], @"seveninferior",
[NSNumber numberWithInt:0xFF17], @"sevenmonospace",
[NSNumber numberWithInt:0xF737], @"sevenoldstyle",
[NSNumber numberWithInt:0x247A], @"sevenparen",
[NSNumber numberWithInt:0x248E], @"sevenperiod",
[NSNumber numberWithInt:0x06F7], @"sevenpersian",
[NSNumber numberWithInt:0x2176], @"sevenroman",
[NSNumber numberWithInt:0x2077], @"sevensuperior",
[NSNumber numberWithInt:0x2470], @"seventeencircle",
[NSNumber numberWithInt:0x2484], @"seventeenparen",
[NSNumber numberWithInt:0x2498], @"seventeenperiod",
[NSNumber numberWithInt:0x0E57], @"seventhai",
[NSNumber numberWithInt:0x00AD], @"sfthyphen",
[NSNumber numberWithInt:0x0577], @"shaarmenian",
[NSNumber numberWithInt:0x09B6], @"shabengali",
[NSNumber numberWithInt:0x0448], @"shacyrillic",
[NSNumber numberWithInt:0x0651], @"shaddaarabic",
[NSNumber numberWithInt:0xFC61], @"shaddadammaarabic",
[NSNumber numberWithInt:0xFC5E], @"shaddadammatanarabic",
[NSNumber numberWithInt:0xFC60], @"shaddafathaarabic",
//[NSNumber numberWithInt:0x0651 064B], @"shaddafathatanarabic",
[NSNumber numberWithInt:0xFC62], @"shaddakasraarabic",
[NSNumber numberWithInt:0xFC5F], @"shaddakasratanarabic",
[NSNumber numberWithInt:0x2592], @"shade",
[NSNumber numberWithInt:0x2593], @"shadedark",
[NSNumber numberWithInt:0x2591], @"shadelight",
[NSNumber numberWithInt:0x2592], @"shademedium",
[NSNumber numberWithInt:0x0936], @"shadeva",
[NSNumber numberWithInt:0x0AB6], @"shagujarati",
[NSNumber numberWithInt:0x0A36], @"shagurmukhi",
[NSNumber numberWithInt:0x0593], @"shalshelethebrew",
[NSNumber numberWithInt:0x3115], @"shbopomofo",
[NSNumber numberWithInt:0x0449], @"shchacyrillic",
[NSNumber numberWithInt:0x0634], @"sheenarabic",
[NSNumber numberWithInt:0xFEB6], @"sheenfinalarabic",
[NSNumber numberWithInt:0xFEB7], @"sheeninitialarabic",
[NSNumber numberWithInt:0xFEB8], @"sheenmedialarabic",
[NSNumber numberWithInt:0x03E3], @"sheicoptic",
[NSNumber numberWithInt:0x20AA], @"sheqel",
[NSNumber numberWithInt:0x20AA], @"sheqelhebrew",
[NSNumber numberWithInt:0x05B0], @"sheva",
[NSNumber numberWithInt:0x05B0], @"sheva115",
[NSNumber numberWithInt:0x05B0], @"sheva15",
[NSNumber numberWithInt:0x05B0], @"sheva22",
[NSNumber numberWithInt:0x05B0], @"sheva2e",
[NSNumber numberWithInt:0x05B0], @"shevahebrew",
[NSNumber numberWithInt:0x05B0], @"shevanarrowhebrew",
[NSNumber numberWithInt:0x05B0], @"shevaquarterhebrew",
[NSNumber numberWithInt:0x05B0], @"shevawidehebrew",
[NSNumber numberWithInt:0x04BB], @"shhacyrillic",
[NSNumber numberWithInt:0x03ED], @"shimacoptic",
[NSNumber numberWithInt:0x05E9], @"shin",
[NSNumber numberWithInt:0xFB49], @"shindagesh",
[NSNumber numberWithInt:0xFB49], @"shindageshhebrew",
[NSNumber numberWithInt:0xFB2C], @"shindageshshindot",
[NSNumber numberWithInt:0xFB2C], @"shindageshshindothebrew",
[NSNumber numberWithInt:0xFB2D], @"shindageshsindot",
[NSNumber numberWithInt:0xFB2D], @"shindageshsindothebrew",
[NSNumber numberWithInt:0x05C1], @"shindothebrew",
[NSNumber numberWithInt:0x05E9], @"shinhebrew",
[NSNumber numberWithInt:0xFB2A], @"shinshindot",
[NSNumber numberWithInt:0xFB2A], @"shinshindothebrew",
[NSNumber numberWithInt:0xFB2B], @"shinsindot",
[NSNumber numberWithInt:0xFB2B], @"shinsindothebrew",
[NSNumber numberWithInt:0x0282], @"shook",
[NSNumber numberWithInt:0x03C3], @"sigma",
[NSNumber numberWithInt:0x03C2], @"sigma1",
[NSNumber numberWithInt:0x03C2], @"sigmafinal",
[NSNumber numberWithInt:0x03F2], @"sigmalunatesymbolgreek",
[NSNumber numberWithInt:0x3057], @"sihiragana",
[NSNumber numberWithInt:0x30B7], @"sikatakana",
[NSNumber numberWithInt:0xFF7C], @"sikatakanahalfwidth",
[NSNumber numberWithInt:0x05BD], @"siluqhebrew",
[NSNumber numberWithInt:0x05BD], @"siluqlefthebrew",
[NSNumber numberWithInt:0x223C], @"similar",
[NSNumber numberWithInt:0x05C2], @"sindothebrew",
[NSNumber numberWithInt:0x3274], @"siosacirclekorean",
[NSNumber numberWithInt:0x3214], @"siosaparenkorean",
[NSNumber numberWithInt:0x317E], @"sioscieuckorean",
[NSNumber numberWithInt:0x3266], @"sioscirclekorean",
[NSNumber numberWithInt:0x317A], @"sioskiyeokkorean",
[NSNumber numberWithInt:0x3145], @"sioskorean",
[NSNumber numberWithInt:0x317B], @"siosnieunkorean",
[NSNumber numberWithInt:0x3206], @"siosparenkorean",
[NSNumber numberWithInt:0x317D], @"siospieupkorean",
[NSNumber numberWithInt:0x317C], @"siostikeutkorean",
[NSNumber numberWithInt:0x0036], @"six",
[NSNumber numberWithInt:0x0666], @"sixarabic",
[NSNumber numberWithInt:0x09EC], @"sixbengali",
[NSNumber numberWithInt:0x2465], @"sixcircle",
[NSNumber numberWithInt:0x278F], @"sixcircleinversesansserif",
[NSNumber numberWithInt:0x096C], @"sixdeva",
[NSNumber numberWithInt:0x0AEC], @"sixgujarati",
[NSNumber numberWithInt:0x0A6C], @"sixgurmukhi",
[NSNumber numberWithInt:0x0666], @"sixhackarabic",
[NSNumber numberWithInt:0x3026], @"sixhangzhou",
[NSNumber numberWithInt:0x3225], @"sixideographicparen",
[NSNumber numberWithInt:0x2086], @"sixinferior",
[NSNumber numberWithInt:0xFF16], @"sixmonospace",
[NSNumber numberWithInt:0xF736], @"sixoldstyle",
[NSNumber numberWithInt:0x2479], @"sixparen",
[NSNumber numberWithInt:0x248D], @"sixperiod",
[NSNumber numberWithInt:0x06F6], @"sixpersian",
[NSNumber numberWithInt:0x2175], @"sixroman",
[NSNumber numberWithInt:0x2076], @"sixsuperior",
[NSNumber numberWithInt:0x246F], @"sixteencircle",
[NSNumber numberWithInt:0x09F9], @"sixteencurrencydenominatorbengali",
[NSNumber numberWithInt:0x2483], @"sixteenparen",
[NSNumber numberWithInt:0x2497], @"sixteenperiod",
[NSNumber numberWithInt:0x0E56], @"sixthai",
[NSNumber numberWithInt:0x002F], @"slash",
[NSNumber numberWithInt:0xFF0F], @"slashmonospace",
[NSNumber numberWithInt:0x017F], @"slong",
[NSNumber numberWithInt:0x1E9B], @"slongdotaccent",
[NSNumber numberWithInt:0x263A], @"smileface",
[NSNumber numberWithInt:0xFF53], @"smonospace",
[NSNumber numberWithInt:0x05C3], @"sofpasuqhebrew",
[NSNumber numberWithInt:0x00AD], @"softhyphen",
[NSNumber numberWithInt:0x044C], @"softsigncyrillic",
[NSNumber numberWithInt:0x305D], @"sohiragana",
[NSNumber numberWithInt:0x30BD], @"sokatakana",
[NSNumber numberWithInt:0xFF7F], @"sokatakanahalfwidth",
[NSNumber numberWithInt:0x0338], @"soliduslongoverlaycmb",
[NSNumber numberWithInt:0x0337], @"solidusshortoverlaycmb",
[NSNumber numberWithInt:0x0E29], @"sorusithai",
[NSNumber numberWithInt:0x0E28], @"sosalathai",
[NSNumber numberWithInt:0x0E0B], @"sosothai",
[NSNumber numberWithInt:0x0E2A], @"sosuathai",
[NSNumber numberWithInt:0x0020], @"space",
[NSNumber numberWithInt:0x0020], @"spacehackarabic",
[NSNumber numberWithInt:0x2660], @"spade",
[NSNumber numberWithInt:0x2660], @"spadesuitblack",
[NSNumber numberWithInt:0x2664], @"spadesuitwhite",
[NSNumber numberWithInt:0x24AE], @"sparen",
[NSNumber numberWithInt:0x033B], @"squarebelowcmb",
[NSNumber numberWithInt:0x33C4], @"squarecc",
[NSNumber numberWithInt:0x339D], @"squarecm",
[NSNumber numberWithInt:0x25A9], @"squarediagonalcrosshatchfill",
[NSNumber numberWithInt:0x25A4], @"squarehorizontalfill",
[NSNumber numberWithInt:0x338F], @"squarekg",
[NSNumber numberWithInt:0x339E], @"squarekm",
[NSNumber numberWithInt:0x33CE], @"squarekmcapital",
[NSNumber numberWithInt:0x33D1], @"squareln",
[NSNumber numberWithInt:0x33D2], @"squarelog",
[NSNumber numberWithInt:0x338E], @"squaremg",
[NSNumber numberWithInt:0x33D5], @"squaremil",
[NSNumber numberWithInt:0x339C], @"squaremm",
[NSNumber numberWithInt:0x33A1], @"squaremsquared",
[NSNumber numberWithInt:0x25A6], @"squareorthogonalcrosshatchfill",
[NSNumber numberWithInt:0x25A7], @"squareupperlefttolowerrightfill",
[NSNumber numberWithInt:0x25A8], @"squareupperrighttolowerleftfill",
[NSNumber numberWithInt:0x25A5], @"squareverticalfill",
[NSNumber numberWithInt:0x25A3], @"squarewhitewithsmallblack",
[NSNumber numberWithInt:0x33DB], @"srsquare",
[NSNumber numberWithInt:0x09B7], @"ssabengali",
[NSNumber numberWithInt:0x0937], @"ssadeva",
[NSNumber numberWithInt:0x0AB7], @"ssagujarati",
[NSNumber numberWithInt:0x3149], @"ssangcieuckorean",
[NSNumber numberWithInt:0x3185], @"ssanghieuhkorean",
[NSNumber numberWithInt:0x3180], @"ssangieungkorean",
[NSNumber numberWithInt:0x3132], @"ssangkiyeokkorean",
[NSNumber numberWithInt:0x3165], @"ssangnieunkorean",
[NSNumber numberWithInt:0x3143], @"ssangpieupkorean",
[NSNumber numberWithInt:0x3146], @"ssangsioskorean",
[NSNumber numberWithInt:0x3138], @"ssangtikeutkorean",
[NSNumber numberWithInt:0xF6F2], @"ssuperior",
[NSNumber numberWithInt:0x00A3], @"sterling",
[NSNumber numberWithInt:0xFFE1], @"sterlingmonospace",
[NSNumber numberWithInt:0x0336], @"strokelongoverlaycmb",
[NSNumber numberWithInt:0x0335], @"strokeshortoverlaycmb",
[NSNumber numberWithInt:0x2282], @"subset",
[NSNumber numberWithInt:0x228A], @"subsetnotequal",
[NSNumber numberWithInt:0x2286], @"subsetorequal",
[NSNumber numberWithInt:0x227B], @"succeeds",
[NSNumber numberWithInt:0x220B], @"suchthat",
[NSNumber numberWithInt:0x3059], @"suhiragana",
[NSNumber numberWithInt:0x30B9], @"sukatakana",
[NSNumber numberWithInt:0xFF7D], @"sukatakanahalfwidth",
[NSNumber numberWithInt:0x0652], @"sukunarabic",
[NSNumber numberWithInt:0x2211], @"summation",
[NSNumber numberWithInt:0x263C], @"sun",
[NSNumber numberWithInt:0x2283], @"superset",
[NSNumber numberWithInt:0x228B], @"supersetnotequal",
[NSNumber numberWithInt:0x2287], @"supersetorequal",
[NSNumber numberWithInt:0x33DC], @"svsquare",
[NSNumber numberWithInt:0x337C], @"syouwaerasquare",
[NSNumber numberWithInt:0x0074], @"t",
[NSNumber numberWithInt:0x09A4], @"tabengali",
[NSNumber numberWithInt:0x22A4], @"tackdown",
[NSNumber numberWithInt:0x22A3], @"tackleft",
[NSNumber numberWithInt:0x0924], @"tadeva",
[NSNumber numberWithInt:0x0AA4], @"tagujarati",
[NSNumber numberWithInt:0x0A24], @"tagurmukhi",
[NSNumber numberWithInt:0x0637], @"taharabic",
[NSNumber numberWithInt:0xFEC2], @"tahfinalarabic",
[NSNumber numberWithInt:0xFEC3], @"tahinitialarabic",
[NSNumber numberWithInt:0x305F], @"tahiragana",
[NSNumber numberWithInt:0xFEC4], @"tahmedialarabic",
[NSNumber numberWithInt:0x337D], @"taisyouerasquare",
[NSNumber numberWithInt:0x30BF], @"takatakana",
[NSNumber numberWithInt:0xFF80], @"takatakanahalfwidth",
[NSNumber numberWithInt:0x0640], @"tatweelarabic",
[NSNumber numberWithInt:0x03C4], @"tau",
[NSNumber numberWithInt:0x05EA], @"tav",
[NSNumber numberWithInt:0xFB4A], @"tavdages",
[NSNumber numberWithInt:0xFB4A], @"tavdagesh",
[NSNumber numberWithInt:0xFB4A], @"tavdageshhebrew",
[NSNumber numberWithInt:0x05EA], @"tavhebrew",
[NSNumber numberWithInt:0x0167], @"tbar",
[NSNumber numberWithInt:0x310A], @"tbopomofo",
[NSNumber numberWithInt:0x0165], @"tcaron",
[NSNumber numberWithInt:0x02A8], @"tccurl",
[NSNumber numberWithInt:0x0163], @"tcedilla",
[NSNumber numberWithInt:0x0686], @"tcheharabic",
[NSNumber numberWithInt:0xFB7B], @"tchehfinalarabic",
[NSNumber numberWithInt:0xFB7C], @"tchehinitialarabic",
[NSNumber numberWithInt:0xFB7D], @"tchehmedialarabic",
//[NSNumber numberWithInt:0xFB7C FEE4], @"tchehmeeminitialarabic",
[NSNumber numberWithInt:0x24E3], @"tcircle",
[NSNumber numberWithInt:0x1E71], @"tcircumflexbelow",
[NSNumber numberWithInt:0x0163], @"tcommaaccent",
[NSNumber numberWithInt:0x1E97], @"tdieresis",
[NSNumber numberWithInt:0x1E6B], @"tdotaccent",
[NSNumber numberWithInt:0x1E6D], @"tdotbelow",
[NSNumber numberWithInt:0x0442], @"tecyrillic",
[NSNumber numberWithInt:0x04AD], @"tedescendercyrillic",
[NSNumber numberWithInt:0x062A], @"teharabic",
[NSNumber numberWithInt:0xFE96], @"tehfinalarabic",
[NSNumber numberWithInt:0xFCA2], @"tehhahinitialarabic",
[NSNumber numberWithInt:0xFC0C], @"tehhahisolatedarabic",
[NSNumber numberWithInt:0xFE97], @"tehinitialarabic",
[NSNumber numberWithInt:0x3066], @"tehiragana",
[NSNumber numberWithInt:0xFCA1], @"tehjeeminitialarabic",
[NSNumber numberWithInt:0xFC0B], @"tehjeemisolatedarabic",
[NSNumber numberWithInt:0x0629], @"tehmarbutaarabic",
[NSNumber numberWithInt:0xFE94], @"tehmarbutafinalarabic",
[NSNumber numberWithInt:0xFE98], @"tehmedialarabic",
[NSNumber numberWithInt:0xFCA4], @"tehmeeminitialarabic",
[NSNumber numberWithInt:0xFC0E], @"tehmeemisolatedarabic",
[NSNumber numberWithInt:0xFC73], @"tehnoonfinalarabic",
[NSNumber numberWithInt:0x30C6], @"tekatakana",
[NSNumber numberWithInt:0xFF83], @"tekatakanahalfwidth",
[NSNumber numberWithInt:0x2121], @"telephone",
[NSNumber numberWithInt:0x260E], @"telephoneblack",
[NSNumber numberWithInt:0x05A0], @"telishagedolahebrew",
[NSNumber numberWithInt:0x05A9], @"telishaqetanahebrew",
[NSNumber numberWithInt:0x2469], @"tencircle",
[NSNumber numberWithInt:0x3229], @"tenideographicparen",
[NSNumber numberWithInt:0x247D], @"tenparen",
[NSNumber numberWithInt:0x2491], @"tenperiod",
[NSNumber numberWithInt:0x2179], @"tenroman",
[NSNumber numberWithInt:0x02A7], @"tesh",
[NSNumber numberWithInt:0x05D8], @"tet",
[NSNumber numberWithInt:0xFB38], @"tetdagesh",
[NSNumber numberWithInt:0xFB38], @"tetdageshhebrew",
[NSNumber numberWithInt:0x05D8], @"tethebrew",
[NSNumber numberWithInt:0x04B5], @"tetsecyrillic",
[NSNumber numberWithInt:0x059B], @"tevirhebrew",
[NSNumber numberWithInt:0x059B], @"tevirlefthebrew",
[NSNumber numberWithInt:0x09A5], @"thabengali",
[NSNumber numberWithInt:0x0925], @"thadeva",
[NSNumber numberWithInt:0x0AA5], @"thagujarati",
[NSNumber numberWithInt:0x0A25], @"thagurmukhi",
[NSNumber numberWithInt:0x0630], @"thalarabic",
[NSNumber numberWithInt:0xFEAC], @"thalfinalarabic",
[NSNumber numberWithInt:0xF898], @"thanthakhatlowleftthai",
[NSNumber numberWithInt:0xF897], @"thanthakhatlowrightthai",
[NSNumber numberWithInt:0x0E4C], @"thanthakhatthai",
[NSNumber numberWithInt:0xF896], @"thanthakhatupperleftthai",
[NSNumber numberWithInt:0x062B], @"theharabic",
[NSNumber numberWithInt:0xFE9A], @"thehfinalarabic",
[NSNumber numberWithInt:0xFE9B], @"thehinitialarabic",
[NSNumber numberWithInt:0xFE9C], @"thehmedialarabic",
[NSNumber numberWithInt:0x2203], @"thereexists",
[NSNumber numberWithInt:0x2234], @"therefore",
[NSNumber numberWithInt:0x03B8], @"theta",
[NSNumber numberWithInt:0x03D1], @"theta1",
[NSNumber numberWithInt:0x03D1], @"thetasymbolgreek",
[NSNumber numberWithInt:0x3279], @"thieuthacirclekorean",
[NSNumber numberWithInt:0x3219], @"thieuthaparenkorean",
[NSNumber numberWithInt:0x326B], @"thieuthcirclekorean",
[NSNumber numberWithInt:0x314C], @"thieuthkorean",
[NSNumber numberWithInt:0x320B], @"thieuthparenkorean",
[NSNumber numberWithInt:0x246C], @"thirteencircle",
[NSNumber numberWithInt:0x2480], @"thirteenparen",
[NSNumber numberWithInt:0x2494], @"thirteenperiod",
[NSNumber numberWithInt:0x0E11], @"thonangmonthothai",
[NSNumber numberWithInt:0x01AD], @"thook",
[NSNumber numberWithInt:0x0E12], @"thophuthaothai",
[NSNumber numberWithInt:0x00FE], @"thorn",
[NSNumber numberWithInt:0x0E17], @"thothahanthai",
[NSNumber numberWithInt:0x0E10], @"thothanthai",
[NSNumber numberWithInt:0x0E18], @"thothongthai",
[NSNumber numberWithInt:0x0E16], @"thothungthai",
[NSNumber numberWithInt:0x0482], @"thousandcyrillic",
[NSNumber numberWithInt:0x066C], @"thousandsseparatorarabic",
[NSNumber numberWithInt:0x066C], @"thousandsseparatorpersian",
[NSNumber numberWithInt:0x0033], @"three",
[NSNumber numberWithInt:0x0663], @"threearabic",
[NSNumber numberWithInt:0x09E9], @"threebengali",
[NSNumber numberWithInt:0x2462], @"threecircle",
[NSNumber numberWithInt:0x278C], @"threecircleinversesansserif",
[NSNumber numberWithInt:0x0969], @"threedeva",
[NSNumber numberWithInt:0x215C], @"threeeighths",
[NSNumber numberWithInt:0x0AE9], @"threegujarati",
[NSNumber numberWithInt:0x0A69], @"threegurmukhi",
[NSNumber numberWithInt:0x0663], @"threehackarabic",
[NSNumber numberWithInt:0x3023], @"threehangzhou",
[NSNumber numberWithInt:0x3222], @"threeideographicparen",
[NSNumber numberWithInt:0x2083], @"threeinferior",
[NSNumber numberWithInt:0xFF13], @"threemonospace",
[NSNumber numberWithInt:0x09F6], @"threenumeratorbengali",
[NSNumber numberWithInt:0xF733], @"threeoldstyle",
[NSNumber numberWithInt:0x2476], @"threeparen",
[NSNumber numberWithInt:0x248A], @"threeperiod",
[NSNumber numberWithInt:0x06F3], @"threepersian",
[NSNumber numberWithInt:0x00BE], @"threequarters",
[NSNumber numberWithInt:0xF6DE], @"threequartersemdash",
[NSNumber numberWithInt:0x2172], @"threeroman",
[NSNumber numberWithInt:0x00B3], @"threesuperior",
[NSNumber numberWithInt:0x0E53], @"threethai",
[NSNumber numberWithInt:0x3394], @"thzsquare",
[NSNumber numberWithInt:0x3061], @"tihiragana",
[NSNumber numberWithInt:0x30C1], @"tikatakana",
[NSNumber numberWithInt:0xFF81], @"tikatakanahalfwidth",
[NSNumber numberWithInt:0x3270], @"tikeutacirclekorean",
[NSNumber numberWithInt:0x3210], @"tikeutaparenkorean",
[NSNumber numberWithInt:0x3262], @"tikeutcirclekorean",
[NSNumber numberWithInt:0x3137], @"tikeutkorean",
[NSNumber numberWithInt:0x3202], @"tikeutparenkorean",
[NSNumber numberWithInt:0x02DC], @"tilde",
[NSNumber numberWithInt:0x0330], @"tildebelowcmb",
[NSNumber numberWithInt:0x0303], @"tildecmb",
[NSNumber numberWithInt:0x0303], @"tildecomb",
[NSNumber numberWithInt:0x0360], @"tildedoublecmb",
[NSNumber numberWithInt:0x223C], @"tildeoperator",
[NSNumber numberWithInt:0x0334], @"tildeoverlaycmb",
[NSNumber numberWithInt:0x033E], @"tildeverticalcmb",
[NSNumber numberWithInt:0x2297], @"timescircle",
[NSNumber numberWithInt:0x0596], @"tipehahebrew",
[NSNumber numberWithInt:0x0596], @"tipehalefthebrew",
[NSNumber numberWithInt:0x0A70], @"tippigurmukhi",
[NSNumber numberWithInt:0x0483], @"titlocyrilliccmb",
[NSNumber numberWithInt:0x057F], @"tiwnarmenian",
[NSNumber numberWithInt:0x1E6F], @"tlinebelow",
[NSNumber numberWithInt:0xFF54], @"tmonospace",
[NSNumber numberWithInt:0x0569], @"toarmenian",
[NSNumber numberWithInt:0x3068], @"tohiragana",
[NSNumber numberWithInt:0x30C8], @"tokatakana",
[NSNumber numberWithInt:0xFF84], @"tokatakanahalfwidth",
[NSNumber numberWithInt:0x02E5], @"tonebarextrahighmod",
[NSNumber numberWithInt:0x02E9], @"tonebarextralowmod",
[NSNumber numberWithInt:0x02E6], @"tonebarhighmod",
[NSNumber numberWithInt:0x02E8], @"tonebarlowmod",
[NSNumber numberWithInt:0x02E7], @"tonebarmidmod",
[NSNumber numberWithInt:0x01BD], @"tonefive",
[NSNumber numberWithInt:0x0185], @"tonesix",
[NSNumber numberWithInt:0x01A8], @"tonetwo",
[NSNumber numberWithInt:0x0384], @"tonos",
[NSNumber numberWithInt:0x3327], @"tonsquare",
[NSNumber numberWithInt:0x0E0F], @"topatakthai",
[NSNumber numberWithInt:0x3014], @"tortoiseshellbracketleft",
[NSNumber numberWithInt:0xFE5D], @"tortoiseshellbracketleftsmall",
[NSNumber numberWithInt:0xFE39], @"tortoiseshellbracketleftvertical",
[NSNumber numberWithInt:0x3015], @"tortoiseshellbracketright",
[NSNumber numberWithInt:0xFE5E], @"tortoiseshellbracketrightsmall",
[NSNumber numberWithInt:0xFE3A], @"tortoiseshellbracketrightvertical",
[NSNumber numberWithInt:0x0E15], @"totaothai",
[NSNumber numberWithInt:0x01AB], @"tpalatalhook",
[NSNumber numberWithInt:0x24AF], @"tparen",
[NSNumber numberWithInt:0x2122], @"trademark",
[NSNumber numberWithInt:0xF8EA], @"trademarksans",
[NSNumber numberWithInt:0xF6DB], @"trademarkserif",
[NSNumber numberWithInt:0x0288], @"tretroflexhook",
[NSNumber numberWithInt:0x25BC], @"triagdn",
[NSNumber numberWithInt:0x25C4], @"triaglf",
[NSNumber numberWithInt:0x25BA], @"triagrt",
[NSNumber numberWithInt:0x25B2], @"triagup",
[NSNumber numberWithInt:0x02A6], @"ts",
[NSNumber numberWithInt:0x05E6], @"tsadi",
[NSNumber numberWithInt:0xFB46], @"tsadidagesh",
[NSNumber numberWithInt:0xFB46], @"tsadidageshhebrew",
[NSNumber numberWithInt:0x05E6], @"tsadihebrew",
[NSNumber numberWithInt:0x0446], @"tsecyrillic",
[NSNumber numberWithInt:0x05B5], @"tsere",
[NSNumber numberWithInt:0x05B5], @"tsere12",
[NSNumber numberWithInt:0x05B5], @"tsere1e",
[NSNumber numberWithInt:0x05B5], @"tsere2b",
[NSNumber numberWithInt:0x05B5], @"tserehebrew",
[NSNumber numberWithInt:0x05B5], @"tserenarrowhebrew",
[NSNumber numberWithInt:0x05B5], @"tserequarterhebrew",
[NSNumber numberWithInt:0x05B5], @"tserewidehebrew",
[NSNumber numberWithInt:0x045B], @"tshecyrillic",
[NSNumber numberWithInt:0xF6F3], @"tsuperior",
[NSNumber numberWithInt:0x099F], @"ttabengali",
[NSNumber numberWithInt:0x091F], @"ttadeva",
[NSNumber numberWithInt:0x0A9F], @"ttagujarati",
[NSNumber numberWithInt:0x0A1F], @"ttagurmukhi",
[NSNumber numberWithInt:0x0679], @"tteharabic",
[NSNumber numberWithInt:0xFB67], @"ttehfinalarabic",
[NSNumber numberWithInt:0xFB68], @"ttehinitialarabic",
[NSNumber numberWithInt:0xFB69], @"ttehmedialarabic",
[NSNumber numberWithInt:0x09A0], @"tthabengali",
[NSNumber numberWithInt:0x0920], @"tthadeva",
[NSNumber numberWithInt:0x0AA0], @"tthagujarati",
[NSNumber numberWithInt:0x0A20], @"tthagurmukhi",
[NSNumber numberWithInt:0x0287], @"tturned",
[NSNumber numberWithInt:0x3064], @"tuhiragana",
[NSNumber numberWithInt:0x30C4], @"tukatakana",
[NSNumber numberWithInt:0xFF82], @"tukatakanahalfwidth",
[NSNumber numberWithInt:0x3063], @"tusmallhiragana",
[NSNumber numberWithInt:0x30C3], @"tusmallkatakana",
[NSNumber numberWithInt:0xFF6F], @"tusmallkatakanahalfwidth",
[NSNumber numberWithInt:0x246B], @"twelvecircle",
[NSNumber numberWithInt:0x247F], @"twelveparen",
[NSNumber numberWithInt:0x2493], @"twelveperiod",
[NSNumber numberWithInt:0x217B], @"twelveroman",
[NSNumber numberWithInt:0x2473], @"twentycircle",
[NSNumber numberWithInt:0x5344], @"twentyhangzhou",
[NSNumber numberWithInt:0x2487], @"twentyparen",
[NSNumber numberWithInt:0x249B], @"twentyperiod",
[NSNumber numberWithInt:0x0032], @"two",
[NSNumber numberWithInt:0x0662], @"twoarabic",
[NSNumber numberWithInt:0x09E8], @"twobengali",
[NSNumber numberWithInt:0x2461], @"twocircle",
[NSNumber numberWithInt:0x278B], @"twocircleinversesansserif",
[NSNumber numberWithInt:0x0968], @"twodeva",
[NSNumber numberWithInt:0x2025], @"twodotenleader",
[NSNumber numberWithInt:0x2025], @"twodotleader",
[NSNumber numberWithInt:0xFE30], @"twodotleadervertical",
[NSNumber numberWithInt:0x0AE8], @"twogujarati",
[NSNumber numberWithInt:0x0A68], @"twogurmukhi",
[NSNumber numberWithInt:0x0662], @"twohackarabic",
[NSNumber numberWithInt:0x3022], @"twohangzhou",
[NSNumber numberWithInt:0x3221], @"twoideographicparen",
[NSNumber numberWithInt:0x2082], @"twoinferior",
[NSNumber numberWithInt:0xFF12], @"twomonospace",
[NSNumber numberWithInt:0x09F5], @"twonumeratorbengali",
[NSNumber numberWithInt:0xF732], @"twooldstyle",
[NSNumber numberWithInt:0x2475], @"twoparen",
[NSNumber numberWithInt:0x2489], @"twoperiod",
[NSNumber numberWithInt:0x06F2], @"twopersian",
[NSNumber numberWithInt:0x2171], @"tworoman",
[NSNumber numberWithInt:0x01BB], @"twostroke",
[NSNumber numberWithInt:0x00B2], @"twosuperior",
[NSNumber numberWithInt:0x0E52], @"twothai",
[NSNumber numberWithInt:0x2154], @"twothirds",
[NSNumber numberWithInt:0x0075], @"u",
[NSNumber numberWithInt:0x00FA], @"uacute",
[NSNumber numberWithInt:0x0289], @"ubar",
[NSNumber numberWithInt:0x0989], @"ubengali",
[NSNumber numberWithInt:0x3128], @"ubopomofo",
[NSNumber numberWithInt:0x016D], @"ubreve",
[NSNumber numberWithInt:0x01D4], @"ucaron",
[NSNumber numberWithInt:0x24E4], @"ucircle",
[NSNumber numberWithInt:0x00FB], @"ucircumflex",
[NSNumber numberWithInt:0x1E77], @"ucircumflexbelow",
[NSNumber numberWithInt:0x0443], @"ucyrillic",
[NSNumber numberWithInt:0x0951], @"udattadeva",
[NSNumber numberWithInt:0x0171], @"udblacute",
[NSNumber numberWithInt:0x0215], @"udblgrave",
[NSNumber numberWithInt:0x0909], @"udeva",
[NSNumber numberWithInt:0x00FC], @"udieresis",
[NSNumber numberWithInt:0x01D8], @"udieresisacute",
[NSNumber numberWithInt:0x1E73], @"udieresisbelow",
[NSNumber numberWithInt:0x01DA], @"udieresiscaron",
[NSNumber numberWithInt:0x04F1], @"udieresiscyrillic",
[NSNumber numberWithInt:0x01DC], @"udieresisgrave",
[NSNumber numberWithInt:0x01D6], @"udieresismacron",
[NSNumber numberWithInt:0x1EE5], @"udotbelow",
[NSNumber numberWithInt:0x00F9], @"ugrave",
[NSNumber numberWithInt:0x0A89], @"ugujarati",
[NSNumber numberWithInt:0x0A09], @"ugurmukhi",
[NSNumber numberWithInt:0x3046], @"uhiragana",
[NSNumber numberWithInt:0x1EE7], @"uhookabove",
[NSNumber numberWithInt:0x01B0], @"uhorn",
[NSNumber numberWithInt:0x1EE9], @"uhornacute",
[NSNumber numberWithInt:0x1EF1], @"uhorndotbelow",
[NSNumber numberWithInt:0x1EEB], @"uhorngrave",
[NSNumber numberWithInt:0x1EED], @"uhornhookabove",
[NSNumber numberWithInt:0x1EEF], @"uhorntilde",
[NSNumber numberWithInt:0x0171], @"uhungarumlaut",
[NSNumber numberWithInt:0x04F3], @"uhungarumlautcyrillic",
[NSNumber numberWithInt:0x0217], @"uinvertedbreve",
[NSNumber numberWithInt:0x30A6], @"ukatakana",
[NSNumber numberWithInt:0xFF73], @"ukatakanahalfwidth",
[NSNumber numberWithInt:0x0479], @"ukcyrillic",
[NSNumber numberWithInt:0x315C], @"ukorean",
[NSNumber numberWithInt:0x016B], @"umacron",
[NSNumber numberWithInt:0x04EF], @"umacroncyrillic",
[NSNumber numberWithInt:0x1E7B], @"umacrondieresis",
[NSNumber numberWithInt:0x0A41], @"umatragurmukhi",
[NSNumber numberWithInt:0xFF55], @"umonospace",
[NSNumber numberWithInt:0x005F], @"underscore",
[NSNumber numberWithInt:0x2017], @"underscoredbl",
[NSNumber numberWithInt:0xFF3F], @"underscoremonospace",
[NSNumber numberWithInt:0xFE33], @"underscorevertical",
[NSNumber numberWithInt:0xFE4F], @"underscorewavy",
[NSNumber numberWithInt:0x222A], @"union",
[NSNumber numberWithInt:0x2200], @"universal",
[NSNumber numberWithInt:0x0173], @"uogonek",
[NSNumber numberWithInt:0x24B0], @"uparen",
[NSNumber numberWithInt:0x2580], @"upblock",
[NSNumber numberWithInt:0x05C4], @"upperdothebrew",
[NSNumber numberWithInt:0x03C5], @"upsilon",
[NSNumber numberWithInt:0x03CB], @"upsilondieresis",
[NSNumber numberWithInt:0x03B0], @"upsilondieresistonos",
[NSNumber numberWithInt:0x028A], @"upsilonlatin",
[NSNumber numberWithInt:0x03CD], @"upsilontonos",
[NSNumber numberWithInt:0x031D], @"uptackbelowcmb",
[NSNumber numberWithInt:0x02D4], @"uptackmod",
[NSNumber numberWithInt:0x0A73], @"uragurmukhi",
[NSNumber numberWithInt:0x016F], @"uring",
[NSNumber numberWithInt:0x045E], @"ushortcyrillic",
[NSNumber numberWithInt:0x3045], @"usmallhiragana",
[NSNumber numberWithInt:0x30A5], @"usmallkatakana",
[NSNumber numberWithInt:0xFF69], @"usmallkatakanahalfwidth",
[NSNumber numberWithInt:0x04AF], @"ustraightcyrillic",
[NSNumber numberWithInt:0x04B1], @"ustraightstrokecyrillic",
[NSNumber numberWithInt:0x0169], @"utilde",
[NSNumber numberWithInt:0x1E79], @"utildeacute",
[NSNumber numberWithInt:0x1E75], @"utildebelow",
[NSNumber numberWithInt:0x098A], @"uubengali",
[NSNumber numberWithInt:0x090A], @"uudeva",
[NSNumber numberWithInt:0x0A8A], @"uugujarati",
[NSNumber numberWithInt:0x0A0A], @"uugurmukhi",
[NSNumber numberWithInt:0x0A42], @"uumatragurmukhi",
[NSNumber numberWithInt:0x09C2], @"uuvowelsignbengali",
[NSNumber numberWithInt:0x0942], @"uuvowelsigndeva",
[NSNumber numberWithInt:0x0AC2], @"uuvowelsigngujarati",
[NSNumber numberWithInt:0x09C1], @"uvowelsignbengali",
[NSNumber numberWithInt:0x0941], @"uvowelsigndeva",
[NSNumber numberWithInt:0x0AC1], @"uvowelsigngujarati",
[NSNumber numberWithInt:0x0076], @"v",
[NSNumber numberWithInt:0x0935], @"vadeva",
[NSNumber numberWithInt:0x0AB5], @"vagujarati",
[NSNumber numberWithInt:0x0A35], @"vagurmukhi",
[NSNumber numberWithInt:0x30F7], @"vakatakana",
[NSNumber numberWithInt:0x05D5], @"vav",
[NSNumber numberWithInt:0xFB35], @"vavdagesh",
[NSNumber numberWithInt:0xFB35], @"vavdagesh65",
[NSNumber numberWithInt:0xFB35], @"vavdageshhebrew",
[NSNumber numberWithInt:0x05D5], @"vavhebrew",
[NSNumber numberWithInt:0xFB4B], @"vavholam",
[NSNumber numberWithInt:0xFB4B], @"vavholamhebrew",
[NSNumber numberWithInt:0x05F0], @"vavvavhebrew",
[NSNumber numberWithInt:0x05F1], @"vavyodhebrew",
[NSNumber numberWithInt:0x24E5], @"vcircle",
[NSNumber numberWithInt:0x1E7F], @"vdotbelow",
[NSNumber numberWithInt:0x0432], @"vecyrillic",
[NSNumber numberWithInt:0x06A4], @"veharabic",
[NSNumber numberWithInt:0xFB6B], @"vehfinalarabic",
[NSNumber numberWithInt:0xFB6C], @"vehinitialarabic",
[NSNumber numberWithInt:0xFB6D], @"vehmedialarabic",
[NSNumber numberWithInt:0x30F9], @"vekatakana",
[NSNumber numberWithInt:0x2640], @"venus",
[NSNumber numberWithInt:0x007C], @"verticalbar",
[NSNumber numberWithInt:0x030D], @"verticallineabovecmb",
[NSNumber numberWithInt:0x0329], @"verticallinebelowcmb",
[NSNumber numberWithInt:0x02CC], @"verticallinelowmod",
[NSNumber numberWithInt:0x02C8], @"verticallinemod",
[NSNumber numberWithInt:0x057E], @"vewarmenian",
[NSNumber numberWithInt:0x028B], @"vhook",
[NSNumber numberWithInt:0x30F8], @"vikatakana",
[NSNumber numberWithInt:0x09CD], @"viramabengali",
[NSNumber numberWithInt:0x094D], @"viramadeva",
[NSNumber numberWithInt:0x0ACD], @"viramagujarati",
[NSNumber numberWithInt:0x0983], @"visargabengali",
[NSNumber numberWithInt:0x0903], @"visargadeva",
[NSNumber numberWithInt:0x0A83], @"visargagujarati",
[NSNumber numberWithInt:0xFF56], @"vmonospace",
[NSNumber numberWithInt:0x0578], @"voarmenian",
[NSNumber numberWithInt:0x309E], @"voicediterationhiragana",
[NSNumber numberWithInt:0x30FE], @"voicediterationkatakana",
[NSNumber numberWithInt:0x309B], @"voicedmarkkana",
[NSNumber numberWithInt:0xFF9E], @"voicedmarkkanahalfwidth",
[NSNumber numberWithInt:0x30FA], @"vokatakana",
[NSNumber numberWithInt:0x24B1], @"vparen",
[NSNumber numberWithInt:0x1E7D], @"vtilde",
[NSNumber numberWithInt:0x028C], @"vturned",
[NSNumber numberWithInt:0x3094], @"vuhiragana",
[NSNumber numberWithInt:0x30F4], @"vukatakana",
[NSNumber numberWithInt:0x0077], @"w",
[NSNumber numberWithInt:0x1E83], @"wacute",
[NSNumber numberWithInt:0x3159], @"waekorean",
[NSNumber numberWithInt:0x308F], @"wahiragana",
[NSNumber numberWithInt:0x30EF], @"wakatakana",
[NSNumber numberWithInt:0xFF9C], @"wakatakanahalfwidth",
[NSNumber numberWithInt:0x3158], @"wakorean",
[NSNumber numberWithInt:0x308E], @"wasmallhiragana",
[NSNumber numberWithInt:0x30EE], @"wasmallkatakana",
[NSNumber numberWithInt:0x3357], @"wattosquare",
[NSNumber numberWithInt:0x301C], @"wavedash",
[NSNumber numberWithInt:0xFE34], @"wavyunderscorevertical",
[NSNumber numberWithInt:0x0648], @"wawarabic",
[NSNumber numberWithInt:0xFEEE], @"wawfinalarabic",
[NSNumber numberWithInt:0x0624], @"wawhamzaabovearabic",
[NSNumber numberWithInt:0xFE86], @"wawhamzaabovefinalarabic",
[NSNumber numberWithInt:0x33DD], @"wbsquare",
[NSNumber numberWithInt:0x24E6], @"wcircle",
[NSNumber numberWithInt:0x0175], @"wcircumflex",
[NSNumber numberWithInt:0x1E85], @"wdieresis",
[NSNumber numberWithInt:0x1E87], @"wdotaccent",
[NSNumber numberWithInt:0x1E89], @"wdotbelow",
[NSNumber numberWithInt:0x3091], @"wehiragana",
[NSNumber numberWithInt:0x2118], @"weierstrass",
[NSNumber numberWithInt:0x30F1], @"wekatakana",
[NSNumber numberWithInt:0x315E], @"wekorean",
[NSNumber numberWithInt:0x315D], @"weokorean",
[NSNumber numberWithInt:0x1E81], @"wgrave",
[NSNumber numberWithInt:0x25E6], @"whitebullet",
[NSNumber numberWithInt:0x25CB], @"whitecircle",
[NSNumber numberWithInt:0x25D9], @"whitecircleinverse",
[NSNumber numberWithInt:0x300E], @"whitecornerbracketleft",
[NSNumber numberWithInt:0xFE43], @"whitecornerbracketleftvertical",
[NSNumber numberWithInt:0x300F], @"whitecornerbracketright",
[NSNumber numberWithInt:0xFE44], @"whitecornerbracketrightvertical",
[NSNumber numberWithInt:0x25C7], @"whitediamond",
[NSNumber numberWithInt:0x25C8], @"whitediamondcontainingblacksmalldiamond",
[NSNumber numberWithInt:0x25BF], @"whitedownpointingsmalltriangle",
[NSNumber numberWithInt:0x25BD], @"whitedownpointingtriangle",
[NSNumber numberWithInt:0x25C3], @"whiteleftpointingsmalltriangle",
[NSNumber numberWithInt:0x25C1], @"whiteleftpointingtriangle",
[NSNumber numberWithInt:0x3016], @"whitelenticularbracketleft",
[NSNumber numberWithInt:0x3017], @"whitelenticularbracketright",
[NSNumber numberWithInt:0x25B9], @"whiterightpointingsmalltriangle",
[NSNumber numberWithInt:0x25B7], @"whiterightpointingtriangle",
[NSNumber numberWithInt:0x25AB], @"whitesmallsquare",
[NSNumber numberWithInt:0x263A], @"whitesmilingface",
[NSNumber numberWithInt:0x25A1], @"whitesquare",
[NSNumber numberWithInt:0x2606], @"whitestar",
[NSNumber numberWithInt:0x260F], @"whitetelephone",
[NSNumber numberWithInt:0x3018], @"whitetortoiseshellbracketleft",
[NSNumber numberWithInt:0x3019], @"whitetortoiseshellbracketright",
[NSNumber numberWithInt:0x25B5], @"whiteuppointingsmalltriangle",
[NSNumber numberWithInt:0x25B3], @"whiteuppointingtriangle",
[NSNumber numberWithInt:0x3090], @"wihiragana",
[NSNumber numberWithInt:0x30F0], @"wikatakana",
[NSNumber numberWithInt:0x315F], @"wikorean",
[NSNumber numberWithInt:0xFF57], @"wmonospace",
[NSNumber numberWithInt:0x3092], @"wohiragana",
[NSNumber numberWithInt:0x30F2], @"wokatakana",
[NSNumber numberWithInt:0xFF66], @"wokatakanahalfwidth",
[NSNumber numberWithInt:0x20A9], @"won",
[NSNumber numberWithInt:0xFFE6], @"wonmonospace",
[NSNumber numberWithInt:0x0E27], @"wowaenthai",
[NSNumber numberWithInt:0x24B2], @"wparen",
[NSNumber numberWithInt:0x1E98], @"wring",
[NSNumber numberWithInt:0x02B7], @"wsuperior",
[NSNumber numberWithInt:0x028D], @"wturned",
[NSNumber numberWithInt:0x01BF], @"wynn",
[NSNumber numberWithInt:0x0078], @"x",
[NSNumber numberWithInt:0x033D], @"xabovecmb",
[NSNumber numberWithInt:0x3112], @"xbopomofo",
[NSNumber numberWithInt:0x24E7], @"xcircle",
[NSNumber numberWithInt:0x1E8D], @"xdieresis",
[NSNumber numberWithInt:0x1E8B], @"xdotaccent",
[NSNumber numberWithInt:0x056D], @"xeharmenian",
[NSNumber numberWithInt:0x03BE], @"xi",
[NSNumber numberWithInt:0xFF58], @"xmonospace",
[NSNumber numberWithInt:0x24B3], @"xparen",
[NSNumber numberWithInt:0x02E3], @"xsuperior",
[NSNumber numberWithInt:0x0079], @"y",
[NSNumber numberWithInt:0x334E], @"yaadosquare",
[NSNumber numberWithInt:0x09AF], @"yabengali",
[NSNumber numberWithInt:0x00FD], @"yacute",
[NSNumber numberWithInt:0x092F], @"yadeva",
[NSNumber numberWithInt:0x3152], @"yaekorean",
[NSNumber numberWithInt:0x0AAF], @"yagujarati",
[NSNumber numberWithInt:0x0A2F], @"yagurmukhi",
[NSNumber numberWithInt:0x3084], @"yahiragana",
[NSNumber numberWithInt:0x30E4], @"yakatakana",
[NSNumber numberWithInt:0xFF94], @"yakatakanahalfwidth",
[NSNumber numberWithInt:0x3151], @"yakorean",
[NSNumber numberWithInt:0x0E4E], @"yamakkanthai",
[NSNumber numberWithInt:0x3083], @"yasmallhiragana",
[NSNumber numberWithInt:0x30E3], @"yasmallkatakana",
[NSNumber numberWithInt:0xFF6C], @"yasmallkatakanahalfwidth",
[NSNumber numberWithInt:0x0463], @"yatcyrillic",
[NSNumber numberWithInt:0x24E8], @"ycircle",
[NSNumber numberWithInt:0x0177], @"ycircumflex",
[NSNumber numberWithInt:0x00FF], @"ydieresis",
[NSNumber numberWithInt:0x1E8F], @"ydotaccent",
[NSNumber numberWithInt:0x1EF5], @"ydotbelow",
[NSNumber numberWithInt:0x064A], @"yeharabic",
[NSNumber numberWithInt:0x06D2], @"yehbarreearabic",
[NSNumber numberWithInt:0xFBAF], @"yehbarreefinalarabic",
[NSNumber numberWithInt:0xFEF2], @"yehfinalarabic",
[NSNumber numberWithInt:0x0626], @"yehhamzaabovearabic",
[NSNumber numberWithInt:0xFE8A], @"yehhamzaabovefinalarabic",
[NSNumber numberWithInt:0xFE8B], @"yehhamzaaboveinitialarabic",
[NSNumber numberWithInt:0xFE8C], @"yehhamzaabovemedialarabic",
[NSNumber numberWithInt:0xFEF3], @"yehinitialarabic",
[NSNumber numberWithInt:0xFEF4], @"yehmedialarabic",
[NSNumber numberWithInt:0xFCDD], @"yehmeeminitialarabic",
[NSNumber numberWithInt:0xFC58], @"yehmeemisolatedarabic",
[NSNumber numberWithInt:0xFC94], @"yehnoonfinalarabic",
[NSNumber numberWithInt:0x06D1], @"yehthreedotsbelowarabic",
[NSNumber numberWithInt:0x3156], @"yekorean",
[NSNumber numberWithInt:0x00A5], @"yen",
[NSNumber numberWithInt:0xFFE5], @"yenmonospace",
[NSNumber numberWithInt:0x3155], @"yeokorean",
[NSNumber numberWithInt:0x3186], @"yeorinhieuhkorean",
[NSNumber numberWithInt:0x05AA], @"yerahbenyomohebrew",
[NSNumber numberWithInt:0x05AA], @"yerahbenyomolefthebrew",
[NSNumber numberWithInt:0x044B], @"yericyrillic",
[NSNumber numberWithInt:0x04F9], @"yerudieresiscyrillic",
[NSNumber numberWithInt:0x3181], @"yesieungkorean",
[NSNumber numberWithInt:0x3183], @"yesieungpansioskorean",
[NSNumber numberWithInt:0x3182], @"yesieungsioskorean",
[NSNumber numberWithInt:0x059A], @"yetivhebrew",
[NSNumber numberWithInt:0x1EF3], @"ygrave",
[NSNumber numberWithInt:0x01B4], @"yhook",
[NSNumber numberWithInt:0x1EF7], @"yhookabove",
[NSNumber numberWithInt:0x0575], @"yiarmenian",
[NSNumber numberWithInt:0x0457], @"yicyrillic",
[NSNumber numberWithInt:0x3162], @"yikorean",
[NSNumber numberWithInt:0x262F], @"yinyang",
[NSNumber numberWithInt:0x0582], @"yiwnarmenian",
[NSNumber numberWithInt:0xFF59], @"ymonospace",
[NSNumber numberWithInt:0x05D9], @"yod",
[NSNumber numberWithInt:0xFB39], @"yoddagesh",
[NSNumber numberWithInt:0xFB39], @"yoddageshhebrew",
[NSNumber numberWithInt:0x05D9], @"yodhebrew",
[NSNumber numberWithInt:0x05F2], @"yodyodhebrew",
[NSNumber numberWithInt:0xFB1F], @"yodyodpatahhebrew",
[NSNumber numberWithInt:0x3088], @"yohiragana",
[NSNumber numberWithInt:0x3189], @"yoikorean",
[NSNumber numberWithInt:0x30E8], @"yokatakana",
[NSNumber numberWithInt:0xFF96], @"yokatakanahalfwidth",
[NSNumber numberWithInt:0x315B], @"yokorean",
[NSNumber numberWithInt:0x3087], @"yosmallhiragana",
[NSNumber numberWithInt:0x30E7], @"yosmallkatakana",
[NSNumber numberWithInt:0xFF6E], @"yosmallkatakanahalfwidth",
[NSNumber numberWithInt:0x03F3], @"yotgreek",
[NSNumber numberWithInt:0x3188], @"yoyaekorean",
[NSNumber numberWithInt:0x3187], @"yoyakorean",
[NSNumber numberWithInt:0x0E22], @"yoyakthai",
[NSNumber numberWithInt:0x0E0D], @"yoyingthai",
[NSNumber numberWithInt:0x24B4], @"yparen",
[NSNumber numberWithInt:0x037A], @"ypogegrammeni",
[NSNumber numberWithInt:0x0345], @"ypogegrammenigreekcmb",
[NSNumber numberWithInt:0x01A6], @"yr",
[NSNumber numberWithInt:0x1E99], @"yring",
[NSNumber numberWithInt:0x02B8], @"ysuperior",
[NSNumber numberWithInt:0x1EF9], @"ytilde",
[NSNumber numberWithInt:0x028E], @"yturned",
[NSNumber numberWithInt:0x3086], @"yuhiragana",
[NSNumber numberWithInt:0x318C], @"yuikorean",
[NSNumber numberWithInt:0x30E6], @"yukatakana",
[NSNumber numberWithInt:0xFF95], @"yukatakanahalfwidth",
[NSNumber numberWithInt:0x3160], @"yukorean",
[NSNumber numberWithInt:0x046B], @"yusbigcyrillic",
[NSNumber numberWithInt:0x046D], @"yusbigiotifiedcyrillic",
[NSNumber numberWithInt:0x0467], @"yuslittlecyrillic",
[NSNumber numberWithInt:0x0469], @"yuslittleiotifiedcyrillic",
[NSNumber numberWithInt:0x3085], @"yusmallhiragana",
[NSNumber numberWithInt:0x30E5], @"yusmallkatakana",
[NSNumber numberWithInt:0xFF6D], @"yusmallkatakanahalfwidth",
[NSNumber numberWithInt:0x318B], @"yuyekorean",
[NSNumber numberWithInt:0x318A], @"yuyeokorean",
[NSNumber numberWithInt:0x09DF], @"yyabengali",
[NSNumber numberWithInt:0x095F], @"yyadeva",
[NSNumber numberWithInt:0x007A], @"z",
[NSNumber numberWithInt:0x0566], @"zaarmenian",
[NSNumber numberWithInt:0x017A], @"zacute",
[NSNumber numberWithInt:0x095B], @"zadeva",
[NSNumber numberWithInt:0x0A5B], @"zagurmukhi",
[NSNumber numberWithInt:0x0638], @"zaharabic",
[NSNumber numberWithInt:0xFEC6], @"zahfinalarabic",
[NSNumber numberWithInt:0xFEC7], @"zahinitialarabic",
[NSNumber numberWithInt:0x3056], @"zahiragana",
[NSNumber numberWithInt:0xFEC8], @"zahmedialarabic",
[NSNumber numberWithInt:0x0632], @"zainarabic",
[NSNumber numberWithInt:0xFEB0], @"zainfinalarabic",
[NSNumber numberWithInt:0x30B6], @"zakatakana",
[NSNumber numberWithInt:0x0595], @"zaqefgadolhebrew",
[NSNumber numberWithInt:0x0594], @"zaqefqatanhebrew",
[NSNumber numberWithInt:0x0598], @"zarqahebrew",
[NSNumber numberWithInt:0x05D6], @"zayin",
[NSNumber numberWithInt:0xFB36], @"zayindagesh",
[NSNumber numberWithInt:0xFB36], @"zayindageshhebrew",
[NSNumber numberWithInt:0x05D6], @"zayinhebrew",
[NSNumber numberWithInt:0x3117], @"zbopomofo",
[NSNumber numberWithInt:0x017E], @"zcaron",
[NSNumber numberWithInt:0x24E9], @"zcircle",
[NSNumber numberWithInt:0x1E91], @"zcircumflex",
[NSNumber numberWithInt:0x0291], @"zcurl",
[NSNumber numberWithInt:0x017C], @"zdot",
[NSNumber numberWithInt:0x017C], @"zdotaccent",
[NSNumber numberWithInt:0x1E93], @"zdotbelow",
[NSNumber numberWithInt:0x0437], @"zecyrillic",
[NSNumber numberWithInt:0x0499], @"zedescendercyrillic",
[NSNumber numberWithInt:0x04DF], @"zedieresiscyrillic",
[NSNumber numberWithInt:0x305C], @"zehiragana",
[NSNumber numberWithInt:0x30BC], @"zekatakana",
[NSNumber numberWithInt:0x0030], @"zero",
[NSNumber numberWithInt:0x0660], @"zeroarabic",
[NSNumber numberWithInt:0x09E6], @"zerobengali",
[NSNumber numberWithInt:0x0966], @"zerodeva",
[NSNumber numberWithInt:0x0AE6], @"zerogujarati",
[NSNumber numberWithInt:0x0A66], @"zerogurmukhi",
[NSNumber numberWithInt:0x0660], @"zerohackarabic",
[NSNumber numberWithInt:0x2080], @"zeroinferior",
[NSNumber numberWithInt:0xFF10], @"zeromonospace",
[NSNumber numberWithInt:0xF730], @"zerooldstyle",
[NSNumber numberWithInt:0x06F0], @"zeropersian",
[NSNumber numberWithInt:0x2070], @"zerosuperior",
[NSNumber numberWithInt:0x0E50], @"zerothai",
[NSNumber numberWithInt:0xFEFF], @"zerowidthjoiner",
[NSNumber numberWithInt:0x200C], @"zerowidthnonjoiner",
[NSNumber numberWithInt:0x200B], @"zerowidthspace",
[NSNumber numberWithInt:0x03B6], @"zeta",
[NSNumber numberWithInt:0x3113], @"zhbopomofo",
[NSNumber numberWithInt:0x056A], @"zhearmenian",
[NSNumber numberWithInt:0x04C2], @"zhebrevecyrillic",
[NSNumber numberWithInt:0x0436], @"zhecyrillic",
[NSNumber numberWithInt:0x0497], @"zhedescendercyrillic",
[NSNumber numberWithInt:0x04DD], @"zhedieresiscyrillic",
[NSNumber numberWithInt:0x3058], @"zihiragana",
[NSNumber numberWithInt:0x30B8], @"zikatakana",
[NSNumber numberWithInt:0x05AE], @"zinorhebrew",
[NSNumber numberWithInt:0x1E95], @"zlinebelow",
[NSNumber numberWithInt:0xFF5A], @"zmonospace",
[NSNumber numberWithInt:0x305E], @"zohiragana",
[NSNumber numberWithInt:0x30BE], @"zokatakana",
[NSNumber numberWithInt:0x24B5], @"zparen",
[NSNumber numberWithInt:0x0290], @"zretroflexhook",
[NSNumber numberWithInt:0x01B6], @"zstroke",
[NSNumber numberWithInt:0x305A], @"zuhiragana",
[NSNumber numberWithInt:0x30BA], @"zukatakana",                   
                                              nil] retain];
	}
}


+ (NSMutableDictionary *)glyphDictionaryForEncoding:(BlioPDFEncoding)pdfEncoding {
    switch (pdfEncoding) {
        case kBlioPDFEncodingStandard:
            return [NSMutableDictionary dictionaryWithDictionary:blioStandardEncodingDict];
            break;
        case kBlioPDFEncodingMacRoman:
            return [NSMutableDictionary dictionaryWithDictionary:blioMacRomanEncodingDict];
            break;
        case kBlioPDFEncodingWin:
            return [NSMutableDictionary dictionaryWithDictionary:blioWinAnsiEncodingDict];
            break;
        default:
            return [NSMutableDictionary dictionary];
            break;
    }
}

@end

@implementation BlioPDFParsedPage

static void op_Tf (CGPDFScannerRef s, void *info) {
    //printf("(Tf)");
    BlioPDFParsedPage *parsedPage = info;
    const char *name;
    CGPDFReal number;
    
    if (!CGPDFScannerPopNumber(s, &number))
        return;
    
    [parsedPage setTfs:number];
    [parsedPage updateTextStateMatrix]; // Should be made inline
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    NSString *fontLookupName = [[parsedPage fontLookup] objectForKey:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    BlioPDFFont *font = [[[parsedPage fontList] dictionary] objectForKey:fontLookupName];
    //BlioPDFFont *font = [[[parsedPage fontList] dictionary] objectForKey:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    NSString *baseFont = @"<< font not found >>";
    
    if (font) {
        baseFont = [font baseFont];
        [parsedPage setCurrentFont:font];
    }
    //printf("Text content:\n%s", [parsedPage textContent] UTF8String]);
    //printf("[%s %f /%s (%d)]\n", [[font baseFont] UTF8String], number, name, [font fontEncoding]);
}

static void op_TJ(CGPDFScannerRef inScanner, void *info) {
    //printf("(TJ)");
    BlioPDFParsedPage *parsedPage = info;
    
    CGPDFArrayRef array;
    
    bool success = CGPDFScannerPopArray(inScanner, &array);
    
    for(size_t n = 0; n < CGPDFArrayGetCount(array); n ++)
    {
        if(n >= CGPDFArrayGetCount(array))
            continue;
        
        CGPDFStringRef string;
        success = CGPDFArrayGetString(array, n, &string);
        if(success)
        {
            size_t length = CGPDFStringGetLength(string);
            const unsigned char *bytes = CGPDFStringGetBytePtr(string);
            for (int i = 0; i < length; i++) {
                [parsedPage addCharWithChar:(unichar)(bytes[i])];
            }
        } else {
            CGPDFReal number;
            success = CGPDFArrayGetNumber(array, n, &number);
            if(success)
            {
                [parsedPage setTj:number];
            }
        }
    }
}

static void op_Tj(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tj)");
    BlioPDFParsedPage *parsedPage = info;
    
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        size_t length = CGPDFStringGetLength(string);
        const unsigned char *bytes = CGPDFStringGetBytePtr(string);
        for (int i = 0; i < length; i++) {
            [parsedPage addCharWithChar:(unichar)(bytes[i])];
        }
        [parsedPage setTj:0];
    }
}

static void op_Tc(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tc)");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) [parsedPage setTc:number];
    //printf("[%f]", parsedPage.Tc);
}

static void op_TL(CGPDFScannerRef inScanner, void *info) {
    //printf("(TL)");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) [parsedPage setTl:number];
    //printf("[%f]", parsedPage.Tl);
}

static void op_Tm(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tm)");
    BlioPDFParsedPage *parsedPage = info;
    
    CGPDFReal matrix[6];
    bool success;
    
    for (int i = 0; i < 6; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[5-i]);
    }
    if (success) {
        [parsedPage setTextLineMatrix:CGAffineTransformMake(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //printf("%s\n", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    }
}

static void op_Tr(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tr)");
    CGPDFInteger number;
    
    CGPDFScannerPopInteger(inScanner, &number);
    //printf("[%d]", (int)number);

}

static void op_Ts(CGPDFScannerRef inScanner, void *info) {
    //printf("(Ts)");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTs:number];
        [parsedPage updateTextStateMatrix];
    }
    //printf("[%f]", parsedPage.Ts);

}

static void op_Tw(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tw)");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) [parsedPage setTw:number];
    //printf("[%f]", parsedPage.Tw);

}

static void op_Tz(CGPDFScannerRef inScanner, void *info) {
    //printf("(Tz)");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTh:number];
        [parsedPage updateTextStateMatrix];
    }
    //printf("[%f]", parsedPage.Th);

}

static void op_Td(CGPDFScannerRef inScanner, void *info) {
    //printf("(Td)");
    BlioPDFParsedPage *parsedPage = info;
    
    CGPDFReal matrix[2];
    bool success;
    
    for (int i = 0; i < 2; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[1-i]);
    }
    if (success) {        
        [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], matrix[0], matrix[1])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //printf("%s", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    }
    
}

static void op_TD(CGPDFScannerRef inScanner, void *info) {
    //printf("(TD)");
    BlioPDFParsedPage *parsedPage = info;
    
    CGPDFReal matrix[2];
    bool success;
    
    for (int i = 0; i < 2; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[1-i]);
    }
    if (success) {
        [parsedPage setTl:-(matrix[1])];
        //printf("[%f]", parsedPage.Tl);
    
        [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], matrix[0], matrix[1])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    }
    
}

static void op_TSTAR(CGPDFScannerRef inScanner, void *info) {
    //printf("(T*)");
    BlioPDFParsedPage *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
}

static void op_SINGLEQUOTE(CGPDFScannerRef inScanner, void *info) {
    //printf("(')");
    BlioPDFParsedPage *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        size_t length = CGPDFStringGetLength(string);
        const unsigned char *bytes = CGPDFStringGetBytePtr(string);
        for (int i = 0; i < length; i++) {
            [parsedPage addCharWithChar:(unichar)(bytes[i])];
        }
        [parsedPage setTj:0];
    }
}

static void op_DOUBLEQUOTE(CGPDFScannerRef inScanner, void *info) {
    //printf("(\")");
    BlioPDFParsedPage *parsedPage = info;
    CGPDFReal number;
    
    bool success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) [parsedPage setTc:number];
    //printf("[%f]", parsedPage.Tc);
    
    success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) [parsedPage setTw:number];
    //printf("[%f]", parsedPage.Tw);
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    
    CGPDFStringRef string;
    
    success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        size_t length = CGPDFStringGetLength(string);
        const unsigned char *bytes = CGPDFStringGetBytePtr(string);
        for (int i = 0; i < length; i++) {
            [parsedPage addCharWithChar:(unichar)(bytes[i])];
        }
        [parsedPage setTj:0];
    }
}

static void op_BT(CGPDFScannerRef inScanner, void *info) {
    BlioPDFParsedPage *parsedPage = info;
    [parsedPage setTextMatrix:CGAffineTransformIdentity];
    [parsedPage setTextLineMatrix:CGAffineTransformIdentity];
    [parsedPage setTj:0];
}


static void mapPageFont(const char *key, CGPDFObjectRef object, void *info) {
    
    BlioPDFParsedPage *parsedPage = info;
    CGPDFDictionaryRef dict;
    
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict))
        return;
    
    NSString *fontId = [NSString stringWithCString:key encoding:NSASCIIStringEncoding];
    NSValue *uniqueFont = [NSValue valueWithPointer:dict];
    [[parsedPage fontLookup] setObject:uniqueFont forKey:fontId];
}
    

//@synthesize textRect, positionedStrings, wordRects, textContent; 
@synthesize positionedStrings;
@synthesize fontLookup, fontList, currentFont;
@synthesize textMatrix, textLineMatrix, textStateMatrix, Tj, Tl, Tc, Tw, Th, Ts, Tfs, userUnit, lastGlyphWidth;

- (void)dealloc {
    self.fontList = nil;
    self.positionedStrings = nil;
    //self.wordRects = nil;
    self.fontLookup = nil;
    //self.textContent = nil;
    self.currentFont = nil;
    
    if (nil != textBlocks) [textBlocks release];
    [super dealloc];
}

- (NSArray *)textBlocks {
    
    if (nil == textBlocks) {
        NSMutableArray *textBlocksArray = [NSMutableArray array];
                
        NSSortDescriptor *minYDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"minY" ascending:NO] autorelease];
        NSSortDescriptor *minXDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"minX" ascending:YES] autorelease];
        NSSortDescriptor *lineDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"lineNumber" ascending:YES] autorelease];
        
        NSArray *lineOrderingDescriptors = [NSArray arrayWithObjects:minYDescriptor, minXDescriptor, nil];
        NSArray *wordOrderingDescriptors = [NSArray arrayWithObjects:lineDescriptor, minXDescriptor, nil];
        
        CGFloat currentY = -1;
        CGFloat currentX = -1;
        NSInteger line = 0;
        
        for (BlioPDFPositionedString *positionedString in [positionedStrings sortedArrayUsingDescriptors:lineOrderingDescriptors]) {
            if (fabs(positionedString.minY - currentY) >= kBlioPDFTextMinLineSpacing) {
                line++;
            }
            positionedString.lineNumber = line;
            currentY = positionedString.minY;
        }
        
        line = 1;
        BlioPDFPositionedString *lastString = nil;
        
        for (BlioPDFPositionedString *positionedString in [positionedStrings sortedArrayUsingDescriptors:wordOrderingDescriptors]) {  
            
            BOOL prependSpace = NO;
            BOOL newLine = NO;
            
            BlioPDFPositionedString *adjustedString = [[BlioPDFPositionedString alloc] initWithString:positionedString.string];
            [adjustedString setBoundingRect:positionedString.boundingRect];
            unichar lastChar = [lastString.string characterAtIndex:[lastString.string length] - 1];
            
            if (nil == lastString) {
                currentX = positionedString.minX;
            } else if (positionedString.lineNumber != line) {
                newLine = YES;
                
                if ((lastChar != '-') && (lastChar != 32) && (![positionedString.string isEqualToString:@" "])) {
                    prependSpace = YES;
//                    adjustedString.string = [NSString stringWithFormat:@" %@", positionedString.string];
                }
                line = positionedString.lineNumber;
                currentX = positionedString.minX;
            }
            
            unichar firstChar = [positionedString.string characterAtIndex:0];
            //if (firstChar == 32) NSLog(@"SPACE:");
            //if (firstChar == 'w')
                //NSLog(@"WWW:");
//            CGFloat maxWidth;
//            CGFloat currentAverageCharWidth = CGRectGetWidth(positionedString.boundingRect) / (CGFloat)[positionedString.string length];
//            if (nil != lastString) {
//                CGFloat lastAverageCharWidth = CGRectGetWidth(lastString.boundingRect) / (CGFloat)[lastString.string length];
//                maxWidth = (currentAverageCharWidth < lastAverageCharWidth) ? currentAverageCharWidth : lastAverageCharWidth;
//            } else {
//                maxWidth = currentAverageCharWidth;
//            }
            
            if ((nil != lastString) && 
                (lastString.lineNumber == positionedString.lineNumber) &&
                (lastChar != 32) &&
                (firstChar != 32)) {
                
                CGFloat displacement = fabs(positionedString.minX - CGRectGetMaxX(lastString.boundingRect));
                
                CGFloat maxDisplacement;
                CGFloat lastWidth = positionedString.lastGlyphWidth;
                CGFloat currentWidth = CGRectGetWidth(positionedString.boundingRect);
                CGFloat spaceWidth = positionedString.spaceWidth;
                //printf("\n");
                
                
                // Prefer to compare to an actual space glyph width if possible
                if (spaceWidth > 0) {
                    maxDisplacement = spaceWidth * kBlioPDFTextMinWordSpaceGlyphRatio;
                    //NSLog(@"Using kBlioPDFTextMinWordSpaceGlyphRatio: %f vs %f", maxDisplacement, displacement);
                } else {
                    // Compare the 2 widths
                    if (lastWidth > 0) {
                        CGFloat ratio = lastWidth < currentWidth ? lastWidth/currentWidth : currentWidth/lastWidth;
                        if (ratio > 0.8f) {
                            //NSLog(@"Widths similar, using current width: %f instead of lastWidth: %f", currentWidth, lastWidth);
                            maxDisplacement = currentWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                        } else if (ratio < 0.4f) {
                            if (lastWidth > currentWidth) {
                                //NSLog(@"Widths VERY different (%f) , using larger lastWidth width: %f instead of currentWidth: %f", ratio, lastWidth, currentWidth);
                                maxDisplacement = lastWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                            } else {
                               // NSLog(@"Widths VERY different (%f) , using larger currentWidth width: %f instead of lastWidth: %f", ratio, currentWidth, lastWidth);
                                maxDisplacement = currentWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                            }
                        } else {
                            if (lastWidth < currentWidth) {
                                //NSLog(@"Widths a bit different (%f) , using smaller lastWidth width: %f instead of currentWidth: %f", ratio, lastWidth, currentWidth);
                                maxDisplacement = lastWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                            } else {
                                //NSLog(@"Widths a bit different (%f) , using smaller currentWidth width: %f instead of lastWidth: %f", ratio, currentWidth, lastWidth);
                                maxDisplacement = currentWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                            }
                        }
                    } else {
                        //NSLog(@"Rejected lastGlyphWidth: %f, using currentWidth: %f", lastWidth, currentWidth);
                        maxDisplacement = currentWidth * kBlioPDFTextMinWordNonSpaceGlyphRatio;
                    }
                    //NSLog(@"Using kBlioPDFTextMinWordNonSpaceGlyphRatio: %f vs %f", maxDisplacement, displacement);
                }
                
                if (displacement >= maxDisplacement) {
                    prependSpace = YES;
                    //NSLog(@"Prepend space YES");
                    //adjustedString.string = [NSString stringWithFormat:@" %@", positionedString.string];
                }
            }
            
            // Substitutions and filters
            // Should construct a character set to scan for these
            adjustedString.string = [adjustedString.string stringByReplacingOccurrencesOfString:@"ﬁ" withString:@"fi"];
            
            if ([adjustedString.string rangeOfCharacterFromSet:[[NSCharacterSet controlCharacterSet] invertedSet]].location == NSNotFound) {
                continue;
            } else if (([positionedString.string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]].location == NSNotFound) && 
                       (![positionedString.string isEqualToString:@" "])) {
                //NSLog(@"Dodgy whitespace");
                continue;
            }
            
            CGFloat minHeight;
            if (nil != lastString) {
                minHeight = (CGRectGetHeight(lastString.boundingRect) < CGRectGetHeight(positionedString.boundingRect)) ? CGRectGetHeight(lastString.boundingRect) : CGRectGetHeight(positionedString.boundingRect);
            } else {
                minHeight = CGRectGetHeight(positionedString.boundingRect);
            }
            
            UIEdgeInsets paddingInset = UIEdgeInsetsMake(-minHeight, -minHeight, -minHeight, -minHeight);
            
            BlioPDFPositionedString *containingBlock = nil;
            
            for (BlioPDFPositionedString *textBlock in textBlocksArray) {
                CGRect paddedBlockRect = UIEdgeInsetsInsetRect(textBlock.boundingRect, paddingInset);
                if (!CGRectIsNull(CGRectIntersection(paddedBlockRect, positionedString.boundingRect))) {
                    containingBlock = textBlock;
                    break;
                }
            }
            
            if (nil != containingBlock) {
                containingBlock.boundingRect = CGRectUnion(containingBlock.boundingRect, positionedString.boundingRect);
                lastChar = [containingBlock.string characterAtIndex:[containingBlock.string length] - 1];
                if (newLine && lastChar == '-') {
                    containingBlock.string = [NSString stringWithFormat:@"%@%@", [containingBlock.string substringToIndex:[containingBlock.string length] - 1], adjustedString.string];
                } else if (prependSpace && lastChar != 32) {
                    containingBlock.string = [NSString stringWithFormat:@"%@ %@", containingBlock.string, adjustedString.string];
                    //NSLog(@" Added [SPACE|%@] to existing block", adjustedString.string);
                } else {
                    containingBlock.string = [NSString stringWithFormat:@"%@%@", containingBlock.string, adjustedString.string];
                    //NSLog(@" Added [%@] to existing block", adjustedString.string);
                }
                
            } else {
                // Don't start a block with whitespace - just discard it
                if ([positionedString.string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]].location != NSNotFound) {
                    [textBlocksArray addObject:adjustedString];
                    //NSLog(@" Added [%@] to new block", adjustedString.string);
                }
            }
            
            lastString = positionedString;
            
            currentX = positionedString.maxX;
            //[text appendString:lastString.string];
            
            [adjustedString release];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioPDFDrawRectOfInterest" object:NSStringFromCGRect(positionedString.boundingRect)];
            
        }
        textBlocks = [[NSArray alloc] initWithArray:textBlocksArray];
    }
    
    return textBlocks;
    
    // Global substitutions
//    NSString *substitutedString;
//    substitutedString = [text stringByReplacingOccurrencesOfString:@"ﬁ" withString:@"fi"];
//    return substitutedString;
}

- (NSString *)textContent {
    NSString *textContent = nil;
    
    NSArray *textBlocksArray = [self textBlocks];
    NSInteger firstBlock = 0;
    NSInteger lastBlock = [textBlocksArray count] - 1;
    
    // Discard page number blocks at the end of page (only contains decimal digits)
    // To do this should also check for other representations of page numbers
    if (lastBlock >= 0) {
        BlioPDFPositionedString *lastTextBlock = [textBlocksArray objectAtIndex:lastBlock];
        if ([lastTextBlock.string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
            lastBlock--;
        }
    }
    
    for (int i = firstBlock; i <= lastBlock; i++) {
        if (textContent)
            textContent = [NSString stringWithFormat:@"%@\n\n%@", textContent, [(BlioPDFPositionedString *)[textBlocksArray objectAtIndex:i] string]];
        else
            textContent = [(BlioPDFPositionedString *)[textBlocksArray objectAtIndex:i] string];
    }
    
    return textContent;
}

- (CGRect)rectForWordAtPosition:(NSInteger)position {
    NSMutableString *text = [NSMutableString string];
    
    NSSortDescriptor *minYDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"minY" ascending:NO] autorelease];
    NSSortDescriptor *minXDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"minX" ascending:YES] autorelease];
    NSSortDescriptor *lineDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"lineNumber" ascending:YES] autorelease];
    
    NSArray *lineOrderingDescriptors = [NSArray arrayWithObjects:minYDescriptor, minXDescriptor, nil];
    NSArray *wordOrderingDescriptors = [NSArray arrayWithObjects:lineDescriptor, minXDescriptor, nil];
    
    CGFloat currentY = -1;
    CGFloat currentX = -1;
    NSInteger line = 0;
    
    for (BlioPDFPositionedString *positionedString in [positionedStrings sortedArrayUsingDescriptors:lineOrderingDescriptors]) {
        if (fabs(positionedString.minY - currentY) >= kBlioPDFTextMinLineSpacing) {
            line++;
        }
        positionedString.lineNumber = line;
        currentY = positionedString.minY;
    }
    
    line = 1;
    NSString *lastString = nil;
    NSInteger currentWordPosition = 0;
    NSMutableString *currentWord = nil;
    CGRect currentWordRect = CGRectZero;
    
    for (BlioPDFPositionedString *positionedString in [positionedStrings sortedArrayUsingDescriptors:wordOrderingDescriptors]) {    
        unichar lastChar = [lastString characterAtIndex:[lastString length] - 1];
        
        if (nil == lastString) {
            currentX = positionedString.minX;
        } else if (positionedString.lineNumber != line) {
            if (lastChar != '-') {
                [text appendString:@" "];
                currentWordPosition++;
                if (currentWordPosition > position) return currentWordRect;
                currentWord = nil;
            }
            
            line = positionedString.lineNumber;
            currentX = positionedString.minX;
        }
        
        if (lastChar == ' ') {
            currentWordPosition++;
            if (currentWordPosition > position) return currentWordRect;
            currentWord = nil;
        }
        
        CGFloat displacement = fabs(positionedString.minX - currentX);
        if (displacement >= kBlioPDFTextMinWordSpaceGlyphRatio) {
            [text appendString:@" "];
            currentWordPosition++;
            if (currentWordPosition > position) return currentWordRect;
            currentWord = nil;
        }
        
        lastString = positionedString.string;
        
        currentX = positionedString.maxX;
        
        if (nil == currentWord) {
            currentWord = [NSMutableString stringWithString:lastString];
            currentWordRect = positionedString.boundingRect;
        } else {
            [currentWord appendString:lastString];
            currentWordRect = CGRectUnion(currentWordRect, positionedString.boundingRect);
        }
    }
        
        return currentWordRect;
}

// TODO make this an inline function
- (void)updateTextStateMatrix {
    textStateMatrix = CGAffineTransformMake(Tfs*Th, 0, 0, Tfs, 0, Ts);
}

- (void)addCharWithChar:(unichar)characterCode {
    unichar decodedCharacter;
    CGFloat glyphWidth;
    
    CGAffineTransform textRenderingMatrix = CGAffineTransformConcat(textStateMatrix, textMatrix);
    NSInteger returnValue = [currentFont decodedCharacterForCharacter:characterCode];
    
    if (returnValue >= 0) {
        decodedCharacter = returnValue;
        glyphWidth = ([currentFont glyphWidthForCharacter:characterCode])/1000.0f;
    } else {
        decodedCharacter = [currentFont notdef];
        glyphWidth = ([currentFont glyphWidthForCharacter:[currentFont notdef]])/1000.0f;
    }
    
    CGFloat Tx, Gx;
    if (characterCode == 32) {
        Tx = ((glyphWidth - (Tj/1000.0f)) * Tfs + Tc + Tw) * Th;
//        Gx = (glyphWidth * Tfs + Tw) * Th;
    } else {
        Tx = ((glyphWidth - (Tj/1000.0f)) * Tfs + Tc) * Th;
//        Gx = (glyphWidth * Tfs) * Th;
    }
    Gx = (glyphWidth * Tfs) * Th;
    
    CGRect glyphRect = CGRectMake(- (Tj/1000.0f),0,Gx, Tfs * userUnit);
    CGRect displacementRect = CGRectMake(- (Tj/1000.0f),0,Tx, Tfs * userUnit);
    CGRect renderedGlyphRect = CGRectApplyAffineTransform(glyphRect, textRenderingMatrix);
    CGRect renderedDisplacementRect = CGRectApplyAffineTransform(displacementRect, textRenderingMatrix);
    
    if (CGRectContainsRect(cropRect, renderedGlyphRect)) {
        // This code gets called a lot - would be better if there were no autoreleased objects.
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        
        NSString *unicodeString = [currentFont stringForCharacterCode:characterCode withDecode:decodedCharacter];
        if (unicodeString) {
            BlioPDFPositionedString *newString = [[BlioPDFPositionedString alloc] initWithString:unicodeString];
            newString.boundingRect = renderedGlyphRect;
            newString.displacementRect = renderedDisplacementRect;
            newString.spaceWidth = ([currentFont spaceWidth] * Tfs * Th * userUnit) * textRenderingMatrix.a;
            if (lastGlyphWidth > 0) {
                newString.lastGlyphWidth = lastGlyphWidth * textRenderingMatrix.a;
            } else {
                newString.lastGlyphWidth = 0;
            }

            if (newString.lastGlyphWidth < 0) {
                NSLog(@"Negative last glyph width");
            }
            [positionedStrings addObject:newString];
            [newString release];
                
            lastGlyphWidth = Gx;
        }
        
        /*
        if (forceNewWord) {
            [wordRects addObject:NSStringFromCGRect(renderRect)];
        } else {
            NSInteger existingWordRectIndex = -1;
            CGRect wordRect;
            
            for (int i = 0; i < [wordRects count]; i++) {
                wordRect = CGRectFromString([wordRects objectAtIndex:i]);
                if (!CGRectIsNull(CGRectIntersection(wordRect, renderRect))) {
                    existingWordRectIndex = i;
                    break;
                }
            }
            if (existingWordRectIndex >= 0) {
                CGRect newWordRect = CGRectUnion(renderRect, wordRect);
                [wordRects replaceObjectAtIndex:existingWordRectIndex withObject:NSStringFromCGRect(newWordRect)];
            } else {
                [wordRects addObject:NSStringFromCGRect(renderRect)];
                [textContent appendFormat:@" "];
            }
            //textRect = CGRectEqualToRect(textRect, CGRectZero) ? renderRect : CGRectUnion(textRect, renderRect);
        }
        NSString *unicodeString = [currentFont stringForUnicode:decodedCharacter];
        [textContent appendFormat:@"%@", unicodeString];
        */
        [innerPool drain];
    }
    
    Tj = 0;
    CGAffineTransform offsetMatrix = CGAffineTransformMakeTranslation(Tx, 0);
    textMatrix = CGAffineTransformConcat(offsetMatrix, textMatrix);
    
}

- (id)initWithPage:(CGPDFPageRef)pageRef andFontList:(BlioPDFFontList *)newFontList {
    if ((self = [super init])) {
        //self.textRect = CGRectZero;
        self.positionedStrings = [NSMutableArray array];
        //self.wordRects = [NSMutableArray array];
        self.fontLookup = [NSMutableDictionary dictionary];
        self.fontList = newFontList;
        //self.textContent = [NSMutableString string];
        self.textMatrix = CGAffineTransformIdentity;
        self.textLineMatrix = CGAffineTransformIdentity;
        self.Th = 1;
        self.userUnit = 1.0f;
        self.lastGlyphWidth = -1;
        [self updateTextStateMatrix];
        
        cropRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
        CGPDFOperatorTableRef myTable = CGPDFOperatorTableCreate();
        
        CGPDFOperatorTableSetCallback(myTable, "Tf", &op_Tf);
        CGPDFOperatorTableSetCallback(myTable, "TJ", &op_TJ);
        CGPDFOperatorTableSetCallback(myTable, "Tj", &op_Tj);
        CGPDFOperatorTableSetCallback(myTable, "Td", &op_Td);
        CGPDFOperatorTableSetCallback(myTable, "Tc", &op_Tc);
        CGPDFOperatorTableSetCallback(myTable, "TD", &op_TD);
        CGPDFOperatorTableSetCallback(myTable, "T*", &op_TSTAR);
        CGPDFOperatorTableSetCallback(myTable, "Tc", &op_Tc);
        CGPDFOperatorTableSetCallback(myTable, "TL", &op_TL);
        CGPDFOperatorTableSetCallback(myTable, "Tm", &op_Tm);
        CGPDFOperatorTableSetCallback(myTable, "Ts", &op_Ts);
        CGPDFOperatorTableSetCallback(myTable, "Tr", &op_Tr);
        CGPDFOperatorTableSetCallback(myTable, "Tw", &op_Tw);
        CGPDFOperatorTableSetCallback(myTable, "Tz", &op_Tz);
        CGPDFOperatorTableSetCallback(myTable, "'", &op_SINGLEQUOTE);
        CGPDFOperatorTableSetCallback(myTable, "\"", &op_DOUBLEQUOTE);
        CGPDFOperatorTableSetCallback(myTable, "BT", &op_BT);
        
        CGPDFScannerRef myScanner;
        CGPDFContentStreamRef myContentStream;
        CGPDFDictionaryRef dict;
        
        CGPDFReal userUnitNumber;
        
        dict = CGPDFPageGetDictionary(pageRef);
        
        CGPDFDictionaryRef resourcesDict, pageFontsDict;
        //CGPDFDictionaryApplyFunction(dict, &logDictContents, @"pageDict");
        if (CGPDFDictionaryGetDictionary(dict, "Resources", &resourcesDict)) {
            //CGPDFDictionaryApplyFunction(resourcesDict, &logDictContents, @"resourcesDict");
            if (CGPDFDictionaryGetDictionary(resourcesDict, "Font", &pageFontsDict))
                CGPDFDictionaryApplyFunction(pageFontsDict, &mapPageFont, self);
        }
        if (CGPDFDictionaryGetNumber(dict, "UserUnit", &userUnitNumber)) {
            [self setUserUnit:userUnitNumber];
        }
        
        if (nil != pageRef) {
            myContentStream = CGPDFContentStreamCreateWithPage (pageRef);
            myScanner = CGPDFScannerCreate (myContentStream, myTable, self);
            CGPDFScannerScan (myScanner);
            CGPDFScannerRelease (myScanner);
            CGPDFContentStreamRelease (myContentStream);
        }
        
        CGPDFOperatorTableRelease(myTable);
    }
    return self;
}

- (void)setCurrentFont:(BlioPDFFont *)newFont {
    [newFont retain];
    [currentFont release];
    currentFont = newFont;
}

@end

@implementation BlioPDFPositionedString

@synthesize string, boundingRect, displacementRect, lineNumber, spaceWidth, lastGlyphWidth;

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}

- (id)init {
    return [self initWithString:nil];
}

- (id)initWithString:(NSString *)aString {
    if ((self = [super init])) {
        self.string = aString;
    }
    return self;
}

- (CGFloat)minY {
    return CGRectGetMinY(boundingRect);
}

- (CGFloat)minX {
    return CGRectGetMinX(boundingRect);
}

- (CGFloat)maxY {
    return CGRectGetMaxY(boundingRect);
}

- (CGFloat)maxX {
    return CGRectGetMaxX(boundingRect);
}

@end

@implementation BlioPDFDebugView

@synthesize fitTransform, interestRect, cropRect, mediaRect;

- (id)initWithFrame:(CGRect)newFrame {
    if ((self = [super initWithFrame:newFrame])) {
        self.userInteractionEnabled = NO;
        interestPath = CGPathCreateMutable();
        fitTransform = CGAffineTransformIdentity;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addRectOfInterest:) name:@"BlioPDFDrawRectOfInterest" object:nil];
    }
    return self;
}

- (void)dealloc {
    CGPathRelease(interestPath);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)addRectOfInterest:(NSNotification *)notification {
    CGPathAddRect(interestPath, NULL, CGRectApplyAffineTransform(CGRectFromString((NSString *)[notification object]), fitTransform));
    [self setNeedsDisplay];
}

- (void)clearAreasOfInterest {
    CGPathRelease(interestPath);
    interestPath = CGPathCreateMutable();
    interestRect = CGRectZero;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0f);

    CGContextSetLineWidth(ctx, 1.0f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
    CGContextStrokeRect(ctx, CGRectApplyAffineTransform(mediaRect, fitTransform));
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextStrokeRect(ctx, CGRectApplyAffineTransform(cropRect, fitTransform));
    CGContextSetStrokeColorWithColor(ctx, [UIColor yellowColor].CGColor);
    CGContextAddPath(ctx, interestPath);
    //CGContextStrokePath(ctx);
    CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5f);
    CGContextFillPath(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
    CGContextStrokeRect(ctx, CGRectApplyAffineTransform(interestRect, fitTransform));
}

@end


