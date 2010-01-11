//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"

//static void logDictContents(const char *key, CGPDFObjectRef object, void *info) {
//    NSString *dict = info;
//    if (dict == nil) dict = @"Dictionary";
//    
//    printf("%s: %s [%d]\n", [dict UTF8String], key, CGPDFObjectGetType(object));
//}

typedef enum {
    kBlioPDFEncodingStandard = 0,
    kBlioPDFEncodingMacRoman = 1,
    kBlioPDFEncodingWin = 2
} BlioPDFEncoding;

@interface BlioPDFFont : NSObject {
    NSString *baseFont;
    NSString *type;
    NSString *encoding;
    BOOL isEmbedded;
    NSInteger firstChar;
    NSInteger lastChar;
    NSInteger widths[256];
    NSMutableDictionary *glyphs;
}

@property (nonatomic, retain) NSString *baseFont;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *encoding;
@property (nonatomic) BOOL isEmbedded;
@property (nonatomic) NSInteger firstChar;
@property (nonatomic) NSInteger lastChar;
@property (nonatomic, retain) NSMutableDictionary *glyphs;

- (id)initWithBaseFont:(NSString *)baseFontName type:(NSString *)fontType encoding:(NSString *)fontEncoding isEmbedded:(BOOL)isFontEmbedded;
- (BOOL)isEqualToFont:(BlioPDFFont *)font;
- (void)setWidths:(NSArray *)widthsArray;
- (void)setGlyphLookup:(unichar)glyphCode atIndex:(NSUInteger)glyphIndex;
- (void)setGlyphName:(NSString *)name atIndex:(NSUInteger)glyphIndex;
- (CGSize)displacementForGlyph:(unichar)glyph;
- (unichar)characterForGlyph:(unichar)glyph;
+ (unichar)characterForGlyphName:(NSString *)name encoding:(BlioPDFEncoding)pdfEncoding;

@end

@interface BlioPDFFontList : NSObject {
    NSMutableDictionary *dictionary;
}

@property (nonatomic, retain) NSMutableDictionary *dictionary;

- (void)addFontsFromPage:(CGPDFPageRef)pageRef;

@end

@interface BlioPDFParsedPage : NSObject {
    CGRect cropRect;
    CGRect textRect;
    NSMutableString *textContent;
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
}

@property (nonatomic) CGRect textRect;
@property (nonatomic, retain) NSMutableString * textContent;
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

- (id)initWithPage:(CGPDFPageRef)pageRef andFontList:(BlioPDFFontList*)newFontList;
- (void)updateTextStateMatrix;
- (void)addGlyphsWithString:(NSString *)glyphString;

@end

@interface BlioFastCATiledLayer : CATiledLayer
@end

static const CGFloat kBlioLayoutMaxZoom = 54.0f; // That's just showing off!
static const CGFloat kBlioLayoutShadow = 16.0f;
static const NSUInteger kBlioLayoutMaxViews = 5;

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
}

@property(nonatomic) CGRect pageRect;

@end

@interface BlioPDFBackgroundLayerDelegate : NSObject {
    CGRect pageRect;
}

@property(nonatomic) CGRect pageRect;

@end

@interface BlioPDFDrawingView : UIView {
    CGPDFPageRef page;
    id layoutView;
    BlioFastCATiledLayer *tiledLayer;
    CALayer *backgroundLayer;
    BlioFastCATiledLayer *shadowLayer;
    BlioPDFTiledLayerDelegate *tiledLayerDelegate;
    BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
    BlioPDFShadowLayerDelegate *shadowLayerDelegate;
}

@property (nonatomic, assign) id layoutView;
@property (nonatomic, retain) BlioFastCATiledLayer *tiledLayer;
@property (nonatomic, retain) CALayer *backgroundLayer;
@property (nonatomic, retain) BlioFastCATiledLayer *shadowLayer;
@property (nonatomic, retain) BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
@property (nonatomic, retain) BlioPDFTiledLayerDelegate *tiledLayerDelegate;
@property (nonatomic, retain) BlioPDFShadowLayerDelegate *shadowLayerDelegate;
@property (nonatomic) CGPDFPageRef page;

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage;

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

- (void)loadPage:(int)pageIndex current:(BOOL)current blank:(BOOL)blank;
- (void)loadPage:(int)pageIndex current:(BOOL)current blank:(BOOL)blank forceReload:(BOOL)reload;
- (BlioPDFDebugView *)debugView;
- (void)setDebugView:(BlioPDFDebugView *)newView;

- (void)jumpToUuid:(NSString *)uuid;
@property (nonatomic, assign) NSInteger pageNumber;
- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@end

@interface BlioPDFScrollView : UIScrollView <UIScrollViewDelegate> {
    BlioPDFDrawingView *view;
    CGRect currentTextRect;
    CGPDFPageRef page;
}

@property (nonatomic, retain) BlioPDFDrawingView *view;
@property (nonatomic) CGRect currentTextRect;
@property (nonatomic) CGPDFPageRef page;

- (id)initWithView:(BlioPDFDrawingView *)view andPageRef:(CGPDFPageRef)newPage;
- (void)setBlank:(BOOL)blank;
- (void)setCover:(BOOL)cover;
- (void)zoomToContents;

@end

@implementation BlioLayoutView





- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    return [self jumpToUuid:uuid];
}

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated
{
    return [self setPageNumber:pageNumber animated:animated];
}




@synthesize scrollView, pageViews, navigationController, currentPageView, tiltScroller, fonts, scrollToPageInProgress;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    self.scrollView = nil;
    self.pageViews = nil;
    self.navigationController = nil;
    self.debugView = nil;
    self.currentPageView = nil;
    self.fonts = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {
    NSURL *pdfURL = [NSURL fileURLWithPath:path];
    pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    
    if (NULL == pdf) return nil;
    
    if ((self = [super initWithFrame:CGRectMake(0,0,320,480)])) {
        // Initialization code
        self.clearsContextBeforeDrawing = NO; // Performance optimisation;
        self.scrollToPageInProgress = NO;

        NSInteger pageCount = CGPDFDocumentGetNumberOfPages(pdf);
        
        UIScrollView *aScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width * pageCount, aScrollView.frame.size.height);
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.showsHorizontalScrollIndicator = NO;
        aScrollView.showsVerticalScrollIndicator = NO;
        aScrollView.scrollsToTop = NO;
        aScrollView.delegate = self;
        [self addSubview:aScrollView];
        self.scrollView = aScrollView;
        [aScrollView release];
        
        NSMutableArray *pageViewArray = [[NSMutableArray alloc] initWithCapacity:kBlioLayoutMaxViews];
        self.pageViews = pageViewArray;
        [pageViewArray release];
        
        visiblePageIndex = 0;
        [self loadPage:0 current:YES blank:NO];
        [self loadPage:1 current:NO blank:NO];
        
        [self performSelectorInBackground:@selector(parseFonts) withObject:nil];
        /*
        CGPDFDictionaryRef dict = CGPDFDocumentGetInfo(pdf);
        CGPDFDictionaryApplyFunction(dict, &logDictContents, @"documentDict");
        
        NSEnumerator *enumerator = [[fonts dictionary] objectEnumerator];
        BlioPDFFont *font;
        
        while ((font = [enumerator nextObject])) {
            NSLog(@"%@", [font baseFont]);
            NSLog(@"      type: %@", [font type]);
            NSLog(@"  encoding: %@", [font encoding]);
            NSLog(@"  embedded: %@", [font isEmbedded] ? @"YES" : @"NO");
         
        }
         */
        
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
    [tiltScroller setScrollView:self.currentPageView];
}

- (id)getCurrentScrollView {
    return [pageViews objectAtIndex:visiblePageIndex];
}

- (BlioPDFDebugView *)debugView {
    return debugView;
}

- (void)setDebugView:(BlioPDFDebugView *)newView {
    [newView retain];
    [debugView release];
    debugView = newView;
}

- (void)displayDebugRect:(CGRect)rect forPage:(NSInteger)pageNumber {
    if (nil == self.debugView) {
        BlioPDFDebugView *aView  = [[BlioPDFDebugView alloc] initWithFrame:CGRectZero];
        aView.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:aView];
        self.debugView = aView;
        [aView release];
    }
    CGRect frame = self.scrollView.frame;
    
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdf, pageNumber);
    CGRect cropRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    CGRect mediaRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    frame.origin = CGPointZero;
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(pageRef, kCGPDFCropBox, insetBounds, 0, true);
    
    frame.origin.x = frame.size.width * ([self pageNumber] - 1);
    frame.origin.y = 0;
    [self.debugView setFrame:frame];
    [self.debugView setFitTransform:fitTransform];
    [self.debugView setCropRect:cropRect];
    [self.debugView setMediaRect:mediaRect];
    [self.debugView clearAreasOfInterest];
    [self.debugView setInterestRect:rect];
    [self.debugView setNeedsDisplay];
    [self.scrollView bringSubviewToFront:self.debugView];
}

- (void)parsePage:(NSInteger)pageNumber {
    //NSLog(@"Start parse");
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdf, pageNumber);
    //[self displayDebugRect:CGRectZero forPage:pageNumber];
    BlioPDFParsedPage *parsedPage = [[BlioPDFParsedPage alloc] initWithPage:pageRef andFontList:self.fonts];
    //NSLog(@"Page text: %@", [parsedPage textContent]);
    //NSLog(@"Text rect: %@", NSStringFromCGRect([parsedPage textRect]));
    [self.currentPageView setCurrentTextRect:[parsedPage textRect]];
    //[self.debugView setInterestRect:[parsedPage textRect]];
    //[self.debugView setNeedsDisplay];
    [parsedPage release];
    //NSLog(@"End parse");
}

#pragma mark -
#pragma mark BlioBookView Protocol Methods

- (void)jumpToUuid:(NSString *)uuid {

}

- (NSInteger)pageNumber {
    return visiblePageIndex + 1;
}

- (void)setPageNumber:(NSInteger)pageNumber {
    [self setPageNumber:pageNumber animated:NO];
}


- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated {
    NSInteger pageIndex = pageNumber - 1;
    CFTimeInterval delayScroll = 0.2f;
    BOOL zoomIn = NO;
    
    if ([self.currentPageView zoomScale] > 1.0f) {
        [self.currentPageView setZoomScale:1.0f animated:animated];
        delayScroll = 0.3f;
        zoomIn = YES;
    }
    
    if (pageIndex != visiblePageIndex) {
        [self loadPage:pageIndex current:YES blank:NO];
        if (!animated) [self loadPage:pageIndex - 1 current:NO blank:NO];
        if (!animated) [self loadPage:pageIndex + 1 current:NO blank:NO];
        
        visiblePageIndex = pageIndex;        
    }
    
    if (animated) self.scrollToPageInProgress = YES;
    CGRect targetRect = self.currentPageView.frame;
    BOOL willAnimate = animated;
    NSMethodSignature * mySignature = [BlioLayoutView instanceMethodSignatureForSelector:@selector(delayedScrollRectToVisible:animated:zoom:)];
    NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
    [myInvocation setTarget:self];    
    [myInvocation setSelector:@selector(delayedScrollRectToVisible:animated:zoom:)];
    [myInvocation setArgument:&targetRect atIndex:2];  
    [myInvocation setArgument:&willAnimate atIndex:3];
    [myInvocation setArgument:&zoomIn atIndex:4];
    [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:delayScroll];
    //[self.scrollView scrollRectToVisible:self.currentPageView.frame animated:animated];
}

- (void)delayedScrollRectToVisible:(CGRect)rect animated:(BOOL)animated zoom:(BOOL)zoom {
    self.currentPageView = nil;
    [self.scrollView scrollRectToVisible:rect animated:animated];
    if (zoom) [self performSelector:@selector(zoomCurrentViewToContents) withObject:nil afterDelay:0.5f];
}

- (void)zoomCurrentViewToContents {
    if (nil != self.currentPageView)
        if (!CGRectEqualToRect([self.currentPageView currentTextRect], CGRectZero))
            [self.currentPageView zoomToContents];
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
    return self;
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

- (NSString *)displayPageNumberForPageNumber:(NSInteger)pageNumber
{
  return [NSString stringWithFormat:@"%d", pageNumber];
}

- (NSInteger)pageCount {
    return CGPDFDocumentGetNumberOfPages(pdf);
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
    [self.scrollView setScrollEnabled:NO];
}

- (void)layoutZoomEnded:(NSNotification *)notification {
    [self.scrollView setScrollEnabled:YES];
}


- (void)loadPage:(int)pageIndex current:(BOOL)current blank:(BOOL)blank {
    [self loadPage:pageIndex current:current blank:blank forceReload:NO];
}
    
- (void)loadPage:(int)pageIndex current:(BOOL)current blank:(BOOL)blank forceReload:(BOOL)reload {

    if (pageIndex < 0) return;
    if (pageIndex >= CGPDFDocumentGetNumberOfPages (pdf)) return;
	
    BlioPDFScrollView *pageView = nil;
    NSUInteger pageNumber = pageIndex + 1;
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, pageNumber);
    
    NSUInteger furthestPageIndex = 0;
    NSUInteger furthestPageDifference = 0;
    
    // First, see if we have it cached and determine the furthest away page
    NSInteger viewCacheCount = [self.pageViews count];
    for(NSInteger i = 0; i < viewCacheCount; ++i) {
        BlioPDFScrollView *cachedPageView = [self.pageViews objectAtIndex:i];
        NSUInteger cachedPageNumber = CGPDFPageGetPageNumber([(BlioPDFDrawingView *)[cachedPageView view] page]);
        if(cachedPageNumber == pageNumber) {
            pageView = cachedPageView;
            break;
        } else {
            NSInteger pageDifference = abs(pageNumber - cachedPageNumber);
            if (pageDifference > furthestPageDifference) {
                furthestPageDifference = pageDifference;
                furthestPageIndex = i;
            }
        }
    }
    
    // Not found in cache, so we need to create it.
    CGRect newFrame;
    
    if(nil == pageView || reload) {
        if (viewCacheCount < kBlioLayoutMaxViews) {
            BlioPDFDrawingView *pdfView = [[BlioPDFDrawingView alloc] initWithFrame:self.scrollView.bounds andPageRef:pdfPageRef];
            pageView = [[BlioPDFScrollView alloc] initWithView:pdfView andPageRef:pdfPageRef];
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
            [(BlioPDFDrawingView *)[pageView view] setPage:pdfPageRef];
        }
        
        newFrame = self.scrollView.frame;
        newFrame.origin.x = newFrame.size.width * pageIndex;
        newFrame.origin.y = 0;
        [pageView setFrame:newFrame];
        [self.scrollView addSubview:pageView];
    }
    
    if (current) {
        self.currentPageView = pageView;
        [pageView setCurrentTextRect:CGRectZero];
    }
    
    [pageView setBlank:blank];
    [pageView setCover:(pageIndex == 0)];
}

#pragma mark -
#pragma mark Container UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger currentPageIndex = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (currentPageIndex != visiblePageIndex) {
        visiblePageIndex = currentPageIndex;
        
        [self loadPage:currentPageIndex current:YES blank:NO];
        if (!self.scrollToPageInProgress) {
            [self loadPage:currentPageIndex - 1 current:NO blank:NO];
            [self loadPage:currentPageIndex + 1 current:NO blank:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioBookViewPageHasChanged" object:[NSNumber numberWithInt:currentPageIndex+1]];
        }
        
        if (tiltScroller) {
            [tiltScroller setScrollView:self.currentPageView];
        }
    }
}

- (void)updateAfterScroll {
    [self parsePage:visiblePageIndex+1];
    
    if (self.scrollToPageInProgress) {
        self.scrollToPageInProgress = NO;
        CGFloat pageWidth = self.scrollView.frame.size.width;
        NSInteger currentPageIndex = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        
        [self loadPage:currentPageIndex current:YES blank:NO forceReload:YES];
        [self loadPage:currentPageIndex - 1 current:NO blank:NO forceReload:YES];
        [self loadPage:currentPageIndex + 1 current:NO blank:NO forceReload:YES];      
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioBookViewPageHasChanged" object:[NSNumber numberWithInt:currentPageIndex+1]];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self updateAfterScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAfterScroll];
}

@end

@implementation BlioPDFScrollView

@synthesize view, currentTextRect, page;        

- (void)dealloc {
    CGPDFPageRelease(page);
    self.view = nil;
    [super dealloc];
}

- (void)setBlank:(BOOL)blank {
    if (blank) {
        [[self.view tiledLayer] setDelegate:nil];  
        [[self.view shadowLayer] setDelegate:nil];  
    } else {
        [[self.view tiledLayer] setDelegate:[self.view tiledLayerDelegate]];
        [[self.view shadowLayer] setDelegate:[self.view shadowLayerDelegate]];
    }
}

- (void)setCover:(BOOL)cover {
    [[self.view tiledLayerDelegate] setCover:cover];
}

- (id)initWithView:(BlioPDFDrawingView *)newView andPageRef:(CGPDFPageRef)newPage {
    NSAssert1(kBlioLayoutMaxViews >= 3, @"Error: kBlioLayoutMaxViews is %d. This must be 3 or greater.", kBlioLayoutMaxViews);

	self = [super initWithFrame:newView.frame];
	if(self != nil) {
        page = newPage;
        CGPDFPageRetain(page);
        currentTextRect = CGRectZero;
        
        [self addSubview:newView];
        [newView setFrame:newView.bounds];
        self.view = newView;
        self.multipleTouchEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bounces = NO;
        self.clipsToBounds = NO;
        self.directionalLockEnabled = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        self.minimumZoomScale = 1.0f;
        self.maximumZoomScale = kBlioLayoutMaxZoom;
        self.contentSize = newView.bounds.size;
    }
    return self;
}

- (void)setPage:(CGPDFPageRef)newPage {
    CGPDFPageRetain(newPage);
    CGPDFPageRelease(page);
    page = newPage;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    // RENDER DEBUG NSLog(@"zoom level after: %f", scale);
    if (scale == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomEnded" object:nil userInfo:nil];
        scrollView.scrollEnabled = NO;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomInProgress" object:nil userInfo:nil];
        scrollView.scrollEnabled = YES;
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.view;
}


- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    // get any touch
    UITouch * t = [touches anyObject];
    if( [t tapCount]>1 ) {
        CGPoint point = [t locationInView:self];
        [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(zoomAtPointAfterDelay:) userInfo:NSStringFromCGPoint(point) repeats:NO];
        return NO;
    }
    return YES;
}

- (void)zoomToContents {
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(self.page, kCGPDFCropBox, insetBounds, 0, true);
    
    CGRect paddedTextRect = UIEdgeInsetsInsetRect(self.currentTextRect, UIEdgeInsetsMake(-6, -6, -6, -2));
    CGRect fitTextRect = CGRectApplyAffineTransform(paddedTextRect, fitTransform);
    CGFloat widthFactor = self.bounds.size.width / fitTextRect.size.width;
    CGFloat rounded = round(widthFactor * 10)/10.0f;
    fitTextRect.size.width = self.bounds.size.width / rounded;
    // RENDER DEBUG NSLog(@"widthFactor: %f", widthFactor);
    //[self zoomToRect:CGRectIntegral(fitTextRect) animated:YES];
    [self zoomToRect:fitTextRect animated:YES];
    [self setDirectionalLockEnabled:YES];    
}

- (void)zoomAtPoint:(CGPoint)point {
    if (self.zoomScale > 1.0f) {
        [self setZoomScale:1.0f animated:YES];
        [self setDirectionalLockEnabled:NO];
    } else {
        if (CGRectEqualToRect(self.currentTextRect, CGRectZero)) {
            CGFloat width  = self.contentSize.width  / 2.75f;
            CGFloat height = self.contentSize.height / 2.75f;
            CGFloat midX = (point.x / CGRectGetWidth(self.bounds)) * self.contentSize.width;
            CGFloat midY = self.contentSize.height - ((point.y / CGRectGetHeight(self.bounds)) * self.contentSize.height);
            CGRect targetRect = CGRectMake(midX - width/2.0f, midY - height/2.0f, width, height);
            [self zoomToRect:CGRectIntegral(targetRect) animated:YES];
            [self setDirectionalLockEnabled:NO];
        } else {
            [self zoomToContents];
        }
    }
}

- (void)zoomAtPointAfterDelay:(NSTimer *)timer {
    NSString *pointString = [timer userInfo];
    CGPoint point = CGPointZero;
    if (pointString) point = CGPointFromString(pointString);
    [self zoomAtPoint:point];
}

@end


@implementation BlioPDFDrawingView

@synthesize layoutView, tiledLayer, shadowLayer, backgroundLayer, tiledLayerDelegate, backgroundLayerDelegate, shadowLayerDelegate, page;

- (void)dealloc {
    CGPDFPageRelease(page);
    self.layoutView = nil;
    [self.tiledLayer setDelegate:nil];
    [self.backgroundLayer setDelegate:nil];
    [self.shadowLayer setDelegate:nil];
    self.tiledLayerDelegate = nil;
    self.backgroundLayerDelegate = nil;
    self.shadowLayerDelegate = nil;
    self.tiledLayer = nil;
    self.backgroundLayer = nil;
    self.shadowLayer = nil;
	[super dealloc];
}

- (void)configureLayers {
    self.tiledLayer = [BlioFastCATiledLayer layer];
    
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    
    CGRect fittedPageRect = CGRectApplyAffineTransform(pageRect, fitTransform);     
    
    int w = pageRect.size.width;
    int h = pageRect.size.height;
    
    int levels = 1;
    while (w > 1 && h > 1) {
        levels++;
        w = w >> 1;
        h = h >> 1;
    }
    
    tiledLayer.levelsOfDetail = levels;
    tiledLayer.levelsOfDetailBias = levels;
    tiledLayer.tileSize = CGSizeMake(1024, 1024);
    
    CGRect origBounds = self.bounds;
    CGRect newBounds = self.bounds;
    
    newBounds.size.width = origBounds.size.width*2;
    insetBounds.origin.x += floor((newBounds.size.width - origBounds.size.width)/2.0f);
    
    tiledLayer.bounds = newBounds;
    fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    
    BlioPDFTiledLayerDelegate *aTileDelegate = [[BlioPDFTiledLayerDelegate alloc] init];
    [aTileDelegate setPage:page];
    [aTileDelegate setFitTransform:fitTransform];
    tiledLayer.delegate = aTileDelegate;
    self.tiledLayerDelegate = aTileDelegate;
    [aTileDelegate release];
    
    tiledLayer.position = CGPointMake(self.layer.bounds.size.width/2.0f, self.layer.bounds.size.height/2.0f);  
    
    // transform the super layer so things draw 'right side up'
    CATransform3D superTransform = CATransform3DMakeTranslation(0.0f, self.bounds.size.height, 0.0f);
    self.layer.transform = CATransform3DScale(superTransform, 1.0, -1.0f, 1.0f);
    [self.layer addSublayer:tiledLayer];
    
    [tiledLayer setNeedsDisplay];
    
    self.backgroundLayer = [CALayer layer];
    BlioPDFBackgroundLayerDelegate *aBackgroundDelegate = [[BlioPDFBackgroundLayerDelegate alloc] init];
    [aBackgroundDelegate setPageRect:fittedPageRect];
    backgroundLayer.delegate = aBackgroundDelegate;
    self.backgroundLayerDelegate = aBackgroundDelegate;
    [aBackgroundDelegate release];
    
    backgroundLayer.bounds = self.bounds;
    backgroundLayer.position = tiledLayer.position;
    [self.layer insertSublayer:backgroundLayer below:tiledLayer];
    [backgroundLayer setNeedsDisplay];
    
    self.shadowLayer = [BlioFastCATiledLayer layer];
    BlioPDFShadowLayerDelegate *aShadowDelegate = [[BlioPDFShadowLayerDelegate alloc] init];
    [aShadowDelegate setPageRect:fittedPageRect];
    shadowLayer.delegate = aShadowDelegate;
    shadowLayer.levelsOfDetail = 1;
    shadowLayer.tileSize = CGSizeMake(1024, 1024);
    self.shadowLayerDelegate = aShadowDelegate;
    [aShadowDelegate release];
    
    shadowLayer.bounds = self.bounds;
    shadowLayer.position = tiledLayer.position;
    [self.layer insertSublayer:shadowLayer below:tiledLayer];
    [shadowLayer setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage {
	self = [super initWithFrame:frame];
	if(self != nil) {
        page = newPage;
        CGPDFPageRetain(page);
        
        self.backgroundColor = [UIColor clearColor];
        
        [self configureLayers];
	}
	return self;
}

- (void)setPage:(CGPDFPageRef)newPage {
    CGRect currentPageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect newPageRect = CGPDFPageGetBoxRect(newPage, kCGPDFCropBox);
    
    CGPDFPageRetain(newPage);
    CGPDFPageRelease(page);
    page = newPage;
    
    if (!CGRectEqualToRect(currentPageRect, newPageRect)) {
        [tiledLayer setDelegate:nil];
        [backgroundLayer setDelegate:nil];
        [shadowLayer setDelegate:nil];
        [tiledLayer removeFromSuperlayer];
        [backgroundLayer removeFromSuperlayer];
        [shadowLayer removeFromSuperlayer];
        self.tiledLayerDelegate = nil;
        self.backgroundLayerDelegate = nil;
        self.shadowLayerDelegate = nil;
        
        [self configureLayers];
    } else {
        [[tiledLayer delegate] setPage:page];
        
        // Force the tiled layers to discard their tile caches
        [tiledLayer setContents:nil];
        [tiledLayer setNeedsDisplay];
        [shadowLayer setContents:nil];
        [shadowLayer setNeedsDisplay];
    }
}

@end


@implementation BlioPDFTiledLayerDelegate

@synthesize page, fitTransform, cover;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    //NSLog(@"drawing page %d", CGPDFPageGetPageNumber(page));
    CGContextConcatCTM(ctx, fitTransform);
    // RENDER DEBUG NSLog(@"currentCTM: %@", NSStringFromCGAffineTransform(CGContextGetCTM(ctx)));
    CGContextClipToRect(ctx, pageRect);
    if (page) CGContextDrawPDFPage(ctx, page);
    if (cover) [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:self];
}

- (void)setPage:(CGPDFPageRef)newPage {
    page = newPage;
    pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
}

@end

@implementation BlioPDFBackgroundLayerDelegate

@synthesize pageRect;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    //NSLog(@"drawing page background");
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, pageRect);
    //NSLog(@"fittedPageRect is %@", NSStringFromCGRect(pageRect));    
}

@end

@implementation BlioPDFShadowLayerDelegate

@synthesize pageRect;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    //NSLog(@"drawing page shadow");
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, (kBlioLayoutShadow/2.0f)), kBlioLayoutShadow, [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, pageRect);
}

@end

@implementation BlioFastCATiledLayer

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

static void parseFont(const char *key, CGPDFObjectRef object, void *info) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    bool isEmbedded;
    const char *name;
    BlioPDFFont *font;
    BlioPDFFontList *fonts;
    CGPDFDictionaryRef dict, descriptor;
    NSString *baseFont, *fontType, *encoding;
    
    fonts = info;
    
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict))
        return;
    
    baseFont = @"<< none >>";
    if (CGPDFDictionaryGetName(dict, "BaseFont", &name))
        baseFont = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    fontType = @"<< unknown >>";
    if (CGPDFDictionaryGetName(dict, "Subtype", &name))
        fontType = [NSString stringWithCString: name encoding:NSASCIIStringEncoding];
	
    isEmbedded = false;
    if (CGPDFDictionaryGetDictionary(dict, "FontDescriptor", &descriptor)) {
        if (CGPDFDictionaryGetObject(descriptor, "FontFile", &object)
            || CGPDFDictionaryGetObject(descriptor, "FontFile2", &object)
            || CGPDFDictionaryGetObject(descriptor, "FontFile3", &object)) {
            isEmbedded = true;
        }
    }
    
    CGPDFDictionaryRef encodingDict;
    encoding = @"<< font-specific >>";
    if (CGPDFDictionaryGetName(dict, "Encoding", &name)) {
        encoding = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    }        
    
    font = [[BlioPDFFont alloc] initWithBaseFont:baseFont type:fontType
                                       encoding:encoding isEmbedded:isEmbedded];
    
    if (CGPDFDictionaryGetDictionary(dict, "Encoding", &encodingDict)) {
        //CGPDFDictionaryApplyFunction(encodingDict, &logDictContents, @"encodingDict");
        CGPDFArrayRef diffArray;
        //NSLog(@"Glyphs before: %@", [font.glyphs description]);
        if (CGPDFDictionaryGetArray(encodingDict, "Differences", &diffArray)) {
            int arraySize = CGPDFArrayGetCount(diffArray);
            int glyphIndex = 0;
            for(int n = 0; n < arraySize; n++) {
                if (n >= arraySize) continue;
                CGPDFInteger startIndex;
                
                if (!CGPDFArrayGetInteger(diffArray, n, &startIndex)) {
                    if (CGPDFArrayGetName(diffArray, n, &name)) {
                        NSString *glyphName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
                        //unichar glyphCode = [BlioPDFFont characterForGlyphName:glyphName encoding:kBlioPDFEncodingStandard];
                        //[font setGlyphLookup:glyphCode atIndex:glyphIndex];
                        [font setGlyphName:glyphName atIndex:glyphIndex];
                        glyphIndex++;
                    }
                } else {
                    glyphIndex = startIndex;
                }
            }
            
            
        }
        //NSLog(@"Glyphs after: %@", [font.glyphs description]);
        
    }
    
    
    CGPDFInteger firstChar;
    if (CGPDFDictionaryGetInteger(dict, "FirstChar", &firstChar))
        [font setFirstChar:(NSUInteger)firstChar];
    
    CGPDFInteger lastChar;
    if (CGPDFDictionaryGetInteger(dict, "LastChar", &lastChar))
        [font setLastChar:(NSUInteger)lastChar];
    
    CGPDFArrayRef widths;
    if (CGPDFDictionaryGetArray(dict, "Widths", &widths)) {
        int arraySize = CGPDFArrayGetCount(widths);
        NSMutableArray *widthsArray = [NSMutableArray array];
        
        for(int n = 0; n < arraySize; n++) {
            if (n >= arraySize) continue;
            CGPDFInteger width;
            if (CGPDFArrayGetInteger(widths, n, &width))
                [widthsArray addObject:[NSNumber numberWithInt:(int)width]];
        }
        [font setWidths:widthsArray];
    }
    
    [[fonts dictionary] setObject:font forKey:baseFont];
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

@synthesize baseFont, type, encoding, isEmbedded, firstChar, lastChar, glyphs;


- (id)initWithBaseFont:(NSString *)baseFontName type:(NSString *)fontType
              encoding:(NSString *)fontEncoding isEmbedded:(BOOL)isFontEmbedded {
    
    if ((self = [super init])) {
        self.baseFont = baseFontName;
        self.type = fontType;
        self.encoding = fontEncoding;
        self.isEmbedded = isFontEmbedded;
        self.firstChar = 0;
        self.lastChar = 255;
        
        if (true) {// should check encoding or base encoding
            self.glyphs = [NSMutableDictionary dictionaryWithDictionary:blioStandardEncodingDict];
        }
    }
    
    return self;
}

- (void)dealloc {
    self.baseFont = nil;
    self.type = nil;
    self.encoding = nil;
    self.glyphs = nil;
    [super dealloc];
}

- (NSString *)name {
    return baseFont;
}

- (BOOL)isEqualToFont:(BlioPDFFont *)font {
    return [baseFont isEqualToString:[font name]];
}

- (void)setWidths:(NSArray *)widthsArray {
    for (int i = self.firstChar; i <= self.lastChar; i++) {
        if (i < 256) widths[i] = [[widthsArray objectAtIndex:(i - self.firstChar)] integerValue];
    }
}

- (void)setGlyphName:(NSString *)name atIndex:(NSUInteger)glyphIndex {    
    [self.glyphs removeObjectForKey:name];
    [self.glyphs setObject:[NSNumber numberWithInt:glyphIndex] forKey:name];
}

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

- (void)setGlyphLookup:(unichar)glyphCode atIndex:(NSUInteger)glyphIndex {
    if (glyphIndex > 255) {
        NSLog(@"Unexpectedly high glyphIndex (%d) for %C", glyphIndex, glyphCode);
    } else {
        //lookup[glyphIndex] = glyphCode;
    }
}

- (CGSize)displacementForGlyph:(unichar)glyph {
    if (glyph < 256) {
        NSInteger width = widths[glyph];
        if (width == 0) {
            // RENDER DEBUG NSLog(@"unichar not in widths: %C [%d]", glyph, glyph);
            width = 300;
        }
        return CGSizeMake(width,300);
    } else {
        //NSLog(@"unichar outside bounds: %C [%d]", glyph, glyph);
        return CGSizeMake(280,300);
    }
}

- (unichar)characterForGlyph:(unichar)glyph {
    return glyph;
}

+ (void)initialize {
	if(self == [BlioPDFFont class]) {
		blioStandardEncodingDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:0101], @"A",
                                     [NSNumber numberWithInt:0341], @"AE",
                                     [NSNumber numberWithInt:0], @"Aacute",
                                     [NSNumber numberWithInt:0], @"Acircumflex",
                                     [NSNumber numberWithInt:0], @"Adieresis",
                                     [NSNumber numberWithInt:0], @"Agrave",
                                     [NSNumber numberWithInt:0], @"Aring",
                                     [NSNumber numberWithInt:0], @"Atilde",
                                     [NSNumber numberWithInt:0102], @"B",
                                     [NSNumber numberWithInt:0103], @"C",
                                     [NSNumber numberWithInt:0], @"Ccedilla",
                                     [NSNumber numberWithInt:0104], @"D",
                                     [NSNumber numberWithInt:0105], @"E",
                                     [NSNumber numberWithInt:0], @"Eacute", 
                                     [NSNumber numberWithInt:0], @"Ecircumflex", 
                                     [NSNumber numberWithInt:0], @"Edieresis", 
                                     [NSNumber numberWithInt:0], @"Egrave", 
                                     [NSNumber numberWithInt:0], @"Eth", 
                                     [NSNumber numberWithInt:0], @"Euro", 
                                     [NSNumber numberWithInt:0106], @"F",
                                     [NSNumber numberWithInt:0107], @"G",
                                     [NSNumber numberWithInt:0110], @"H",
                                     [NSNumber numberWithInt:0111], @"I",
                                     [NSNumber numberWithInt:0], @"Iacute",
                                     [NSNumber numberWithInt:0], @"Icircumflex",
                                     [NSNumber numberWithInt:0], @"Idieresis",
                                     [NSNumber numberWithInt:0], @"Igrave",
                                     [NSNumber numberWithInt:0112], @"J",
                                     [NSNumber numberWithInt:0113], @"K",
                                     [NSNumber numberWithInt:0114], @"L",
                                     [NSNumber numberWithInt:0350], @"Lslash",
                                     [NSNumber numberWithInt:0115], @"M",
                                     [NSNumber numberWithInt:0116], @"N",
                                     [NSNumber numberWithInt:0], @"Ntilde",
                                     [NSNumber numberWithInt:0117], @"O",
                                     [NSNumber numberWithInt:0352], @"OE",
                                     [NSNumber numberWithInt:0], @"Oacute",
                                     [NSNumber numberWithInt:0], @"Ocircumflex",
                                     [NSNumber numberWithInt:0], @"Odieresis",
                                     [NSNumber numberWithInt:0], @"Ograve",
                                     [NSNumber numberWithInt:0351], @"Oslash",
                                     [NSNumber numberWithInt:0], @"Otilde",
                                     [NSNumber numberWithInt:0120], @"P",
                                     [NSNumber numberWithInt:0121], @"Q",
                                     [NSNumber numberWithInt:0122], @"R",
                                     [NSNumber numberWithInt:0123], @"S",
                                     [NSNumber numberWithInt:0], @"Scaron",
                                     [NSNumber numberWithInt:0124], @"T",
                                     [NSNumber numberWithInt:0], @"Thorn",
                                     [NSNumber numberWithInt:0125], @"U",
                                     [NSNumber numberWithInt:0], @"Uacute",
                                     [NSNumber numberWithInt:0], @"Ucircumflex",
                                     [NSNumber numberWithInt:0], @"Udieresis",
                                     [NSNumber numberWithInt:0], @"Ugrave",
                                     [NSNumber numberWithInt:0126], @"V",
                                     [NSNumber numberWithInt:0127], @"W",
                                     [NSNumber numberWithInt:0130], @"X",
                                     [NSNumber numberWithInt:0131], @"Y",
                                     [NSNumber numberWithInt:0], @"Yacute",
                                     [NSNumber numberWithInt:0], @"Ydieresis",
                                     [NSNumber numberWithInt:0132], @"Z",
                                     [NSNumber numberWithInt:0], @"Zcaron",
                                     [NSNumber numberWithInt:0141], @"a",
                                     [NSNumber numberWithInt:0], @"aacute",
                                     [NSNumber numberWithInt:0], @"acircumflex",
                                     [NSNumber numberWithInt:0302], @"acute",
                                     [NSNumber numberWithInt:0], @"adieresis",
                                     [NSNumber numberWithInt:0361], @"ae",
                                     [NSNumber numberWithInt:046], @"ampersand",
                                     [NSNumber numberWithInt:0], @"aring",
                                     [NSNumber numberWithInt:0136], @"asciicircum",
                                     [NSNumber numberWithInt:0176], @"asciitilde",
                                     [NSNumber numberWithInt:052], @"asterisk",
                                     [NSNumber numberWithInt:0100], @"at",
                                     [NSNumber numberWithInt:0], @"atilde",
                                     [NSNumber numberWithInt:0142], @"b",
                                     [NSNumber numberWithInt:0134], @"backslash",
                                     [NSNumber numberWithInt:0174], @"bar",
                                     [NSNumber numberWithInt:0173], @"braceleft",
                                     [NSNumber numberWithInt:0175], @"braceright",
                                     [NSNumber numberWithInt:0133], @"bracketleft",
                                     [NSNumber numberWithInt:0135], @"bracketright",
                                     [NSNumber numberWithInt:0306], @"breve",
                                     [NSNumber numberWithInt:0], @"brokenbar",
                                     [NSNumber numberWithInt:0267], @"bullet",
                                     [NSNumber numberWithInt:0143], @"c",
                                     [NSNumber numberWithInt:0317], @"caron",
                                     [NSNumber numberWithInt:0], @"ccedilla",
                                     [NSNumber numberWithInt:0313], @"cedilla",
                                     [NSNumber numberWithInt:0242], @"cent",
                                     [NSNumber numberWithInt:0303], @"circumflex",
                                     [NSNumber numberWithInt:073], @"colon",
                                     [NSNumber numberWithInt:054], @"comma",
                                     [NSNumber numberWithInt:0], @"copyright",
                                     [NSNumber numberWithInt:0250], @"currency",
                                     [NSNumber numberWithInt:0144], @"d",
                                     [NSNumber numberWithInt:0262], @"dagger",
                                     [NSNumber numberWithInt:0263], @"daggerdbl",
                                     [NSNumber numberWithInt:0], @"degree",
                                     [NSNumber numberWithInt:0310], @"dieresis",
                                     [NSNumber numberWithInt:0], @"divide",
                                     [NSNumber numberWithInt:044], @"dollar",
                                     [NSNumber numberWithInt:0307], @"dotaccent",
                                     [NSNumber numberWithInt:0365], @"dotlessi",
                                     [NSNumber numberWithInt:0145], @"e",
                                     [NSNumber numberWithInt:0], @"eacute",
                                     [NSNumber numberWithInt:0], @"ecircumflex",
                                     [NSNumber numberWithInt:0], @"edieresis",
                                     [NSNumber numberWithInt:0], @"egrave",
                                     [NSNumber numberWithInt:070], @"eight",
                                     [NSNumber numberWithInt:0274], @"ellipsis",
                                     [NSNumber numberWithInt:0320], @"emdash",
                                     [NSNumber numberWithInt:0261], @"endash",
                                     [NSNumber numberWithInt:075], @"equal",
                                     [NSNumber numberWithInt:0], @"eth",
                                     [NSNumber numberWithInt:041], @"exclam",
                                     [NSNumber numberWithInt:0241], @"exclamdown",
                                     [NSNumber numberWithInt:0146], @"f",
                                     [NSNumber numberWithInt:0256], @"fi",
                                     [NSNumber numberWithInt:065], @"five",
                                     [NSNumber numberWithInt:0257], @"fl",
                                     [NSNumber numberWithInt:0246], @"florin",
                                     [NSNumber numberWithInt:064], @"four",
                                     [NSNumber numberWithInt:0244], @"fraction",
                                     [NSNumber numberWithInt:0147], @"g",
                                     [NSNumber numberWithInt:0373], @"germandbls",
                                     [NSNumber numberWithInt:0301], @"grave",
                                     [NSNumber numberWithInt:076], @"greater",
                                     [NSNumber numberWithInt:0253], @"guillemotleft",
                                     [NSNumber numberWithInt:0273], @"guillemotright",
                                     [NSNumber numberWithInt:0254], @"guilsinglleft",
                                     [NSNumber numberWithInt:0255], @"guilsinglright",
                                     [NSNumber numberWithInt:0150], @"h",
                                     [NSNumber numberWithInt:0315], @"hungarumlaut",
                                     [NSNumber numberWithInt:055], @"hyphen",
                                     [NSNumber numberWithInt:0151], @"i",
                                     [NSNumber numberWithInt:0], @"iacute",
                                     [NSNumber numberWithInt:0], @"icircumflex",
                                     [NSNumber numberWithInt:0], @"idieresis",
                                     [NSNumber numberWithInt:0], @"igrave",
                                     [NSNumber numberWithInt:0152], @"j",
                                     [NSNumber numberWithInt:0153], @"k",
                                     [NSNumber numberWithInt:0154], @"l",
                                     [NSNumber numberWithInt:074], @"less",
                                     [NSNumber numberWithInt:0], @"logicalnot",
                                     [NSNumber numberWithInt:0370], @"lslash",
                                     [NSNumber numberWithInt:0155], @"m",
                                     [NSNumber numberWithInt:0305], @"macron",
                                     [NSNumber numberWithInt:0], @"minus",
                                     [NSNumber numberWithInt:0], @"mu",
                                     [NSNumber numberWithInt:0], @"multiply",
                                     [NSNumber numberWithInt:0156], @"n",
                                     [NSNumber numberWithInt:071], @"nine",
                                     [NSNumber numberWithInt:0], @"ntilde",
                                     [NSNumber numberWithInt:043], @"numbersign",
                                     [NSNumber numberWithInt:0157], @"o",
                                     [NSNumber numberWithInt:0], @"oacute",
                                     [NSNumber numberWithInt:0], @"ocircumflex",
                                     [NSNumber numberWithInt:0], @"odieresis",
                                     [NSNumber numberWithInt:0372], @"oe",
                                     [NSNumber numberWithInt:0316], @"ogonek",
                                     [NSNumber numberWithInt:0], @"ograve",
                                     [NSNumber numberWithInt:061], @"one",
                                     [NSNumber numberWithInt:0], @"onehalf",
                                     [NSNumber numberWithInt:0], @"onequarter",
                                     [NSNumber numberWithInt:0], @"onesuperior",
                                     [NSNumber numberWithInt:0343], @"ordfeminine",
                                     [NSNumber numberWithInt:0353], @"ordmasculine",
                                     [NSNumber numberWithInt:0371], @"oslash",
                                     [NSNumber numberWithInt:0], @"otilde",
                                     [NSNumber numberWithInt:0160], @"p",
                                     [NSNumber numberWithInt:0266], @"paragraph",
                                     [NSNumber numberWithInt:050], @"parenleft",
                                     [NSNumber numberWithInt:051], @"parenright",
                                     [NSNumber numberWithInt:045], @"percent",
                                     [NSNumber numberWithInt:056], @"period",
                                     [NSNumber numberWithInt:0264], @"periodcentered",
                                     [NSNumber numberWithInt:0275], @"perthousand",
                                     [NSNumber numberWithInt:053], @"plus",
                                     [NSNumber numberWithInt:0], @"plusminus",
                                     [NSNumber numberWithInt:0161], @"q",
                                     [NSNumber numberWithInt:077], @"question",
                                     [NSNumber numberWithInt:0277], @"questiondown",
                                     [NSNumber numberWithInt:042], @"quotedbl",
                                     [NSNumber numberWithInt:0271], @"quotedblbase",
                                     [NSNumber numberWithInt:0252], @"quotedblleft",
                                     [NSNumber numberWithInt:0272], @"quotedblright",
                                     [NSNumber numberWithInt:0140], @"quoteleft",
                                     [NSNumber numberWithInt:047], @"quoteright",
                                     [NSNumber numberWithInt:0270], @"quotesinglbase",
                                     [NSNumber numberWithInt:0251], @"quotesingle",
                                     [NSNumber numberWithInt:0162], @"r",
                                     [NSNumber numberWithInt:0], @"registered",
                                     [NSNumber numberWithInt:0312], @"ring",
                                     [NSNumber numberWithInt:0163], @"s",
                                     [NSNumber numberWithInt:0], @"scaron",
                                     [NSNumber numberWithInt:0247], @"section",
                                     [NSNumber numberWithInt:073], @"semicolon",
                                     [NSNumber numberWithInt:067], @"seven",
                                     [NSNumber numberWithInt:066], @"six",
                                     [NSNumber numberWithInt:057], @"slash",
                                     [NSNumber numberWithInt:040], @"space",
                                     [NSNumber numberWithInt:0243], @"sterling",
                                     [NSNumber numberWithInt:0164], @"t",
                                     [NSNumber numberWithInt:0], @"thorn",
                                     [NSNumber numberWithInt:063], @"three",
                                     [NSNumber numberWithInt:0], @"threequarters",
                                     [NSNumber numberWithInt:0], @"threesuperior",
                                     [NSNumber numberWithInt:0304], @"tilde",
                                     [NSNumber numberWithInt:0], @"trademark",
                                     [NSNumber numberWithInt:062], @"two",
                                     [NSNumber numberWithInt:0], @"twosuperior",
                                     [NSNumber numberWithInt:0165], @"u",
                                     [NSNumber numberWithInt:0], @"uacute",
                                     [NSNumber numberWithInt:0], @"ucircumflex",
                                     [NSNumber numberWithInt:0], @"udieresis",
                                     [NSNumber numberWithInt:0], @"ugrave",
                                     [NSNumber numberWithInt:0137], @"underscore",
                                     [NSNumber numberWithInt:0166], @"v",
                                     [NSNumber numberWithInt:0167], @"w",
                                     [NSNumber numberWithInt:0170], @"x",
                                     [NSNumber numberWithInt:0171], @"y",
                                     [NSNumber numberWithInt:0], @"yacute",
                                     [NSNumber numberWithInt:0], @"ydieresis",
                                     [NSNumber numberWithInt:0245], @"yen",
                                     [NSNumber numberWithInt:0172], @"z",
                                     [NSNumber numberWithInt:0], @"zcaron2",
                                     [NSNumber numberWithInt:060], @"zero",
                                     nil] retain];
	}
}

+ (unichar)characterForGlyphName:(NSString *)name encoding:(BlioPDFEncoding)pdfEncoding {
    NSNumber *unicharValue;
    switch (pdfEncoding) {
        default: // Standard
            unicharValue = [blioStandardEncodingDict valueForKey:name];
            break;
    }
    
    if (unicharValue) 
        return [unicharValue intValue];
    else
        return 0;
}

@end

@implementation BlioPDFParsedPage

static void op_MP (CGPDFScannerRef s, void *info) {
    //NSLog(@"op_MP");
}

static void op_DP (CGPDFScannerRef s, void *info) {
    //NSLog(@"op_DP");
}

static void op_BMC (CGPDFScannerRef s, void *info) {
    //NSLog(@"op_BMC");
}

static void op_BDC (CGPDFScannerRef s, void *info) {
    //NSLog(@"op_BDC");
}

static void op_EMC (CGPDFScannerRef s, void *info) {
    //NSLog(@"op_EMC");
}

static void op_Tf (CGPDFScannerRef s, void *info) {
    //printf("(Tf)");
    BlioPDFParsedPage *parsedPage = info;
    const char *name;
    CGPDFReal number;
    
    if (!CGPDFScannerPopNumber(s, &number))
        return;
    
    [parsedPage setTfs:number];
    [parsedPage updateTextStateMatrix];
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    NSString *fontLookupName = [[parsedPage fontLookup] objectForKey:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    BlioPDFFont *font = [[[parsedPage fontList] dictionary] objectForKey:fontLookupName];
    NSString *baseFont = @"<< font not found >>";
    
    if (font) {
        baseFont = [font baseFont];
        [parsedPage setCurrentFont:font];
    }
    
    //printf("[%s %f /%s]", [baseFont UTF8String], number, name);
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
            NSString *data = (NSString *)CGPDFStringCopyTextString(string);
            [parsedPage addGlyphsWithString:data];
            //printf("[%s]", [data UTF8String]);
            [data release];
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
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
        [parsedPage addGlyphsWithString:data];
        //printf("[%s]", [data UTF8String]);
        [data release];
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
        [[parsedPage textContent] appendString:@"\n"];
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
        [[parsedPage textContent] appendString:@"\n"];
        //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    }
    
}

static void op_TSTAR(CGPDFScannerRef inScanner, void *info) {
    //printf("(T*)");
    BlioPDFParsedPage *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    [[parsedPage textContent] appendString:@"\n"];
    //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
}

static void op_SINGLEQUOTE(CGPDFScannerRef inScanner, void *info) {
    //printf("(')");
    BlioPDFParsedPage *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    [[parsedPage textContent] appendString:@"\n"];
    //printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
        [parsedPage addGlyphsWithString:data];
        //printf("[%s]", [data UTF8String]);
        [data release];
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
    [[parsedPage textContent] appendString:@"\n"];
    printf("[%s]", [NSStringFromCGAffineTransform(parsedPage.textMatrix) UTF8String]);
    
    CGPDFStringRef string;
    
    success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
        [parsedPage addGlyphsWithString:data];
        //printf("[%s]", [data UTF8String]);
        [data release];
        [parsedPage setTj:0];
    }
}

static void op_BT(CGPDFScannerRef inScanner, void *info) {
    BlioPDFParsedPage *parsedPage = info;
    [parsedPage setTextMatrix:CGAffineTransformIdentity];
    [parsedPage setTextLineMatrix:CGAffineTransformIdentity];
    [parsedPage setTj:0];
    //printf("BEGIN TEXT OBJECT\n");
}

static void op_ET(CGPDFScannerRef inScanner, void *info) {
    //printf("END TEXT OBJECT\n");
}

static void mapPageFont(const char *key, CGPDFObjectRef object, void *info) {
    
    BlioPDFParsedPage *parsedPage = info;
    CGPDFDictionaryRef dict;
    const char *name;
    
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict))
        return;
    
    NSString *fontId = [NSString stringWithCString:key encoding:NSASCIIStringEncoding];
    
    NSString *baseFont = @"<< none >>";
    if (CGPDFDictionaryGetName(dict, "BaseFont", &name))
        baseFont = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    
    [[parsedPage fontLookup] setObject:baseFont forKey:fontId];
}

@synthesize textRect, textContent; 
@synthesize fontLookup, fontList, currentFont;
@synthesize textMatrix, textLineMatrix, textStateMatrix, Tj, Tl, Tc, Tw, Th, Ts, Tfs, userUnit;

- (void)dealloc {
    self.fontList = nil;
    self.fontLookup = nil;
    self.textContent = nil;
    self.currentFont = nil;
    [super dealloc];
}

- (void)updateTextStateMatrix {
    textStateMatrix = CGAffineTransformMake(Tfs*Th, 0, 0, Tfs, 0, Ts);
}

- (void)addGlyphsWithString:(NSString *)glyphString {
    for (int i = 0; i < [glyphString length]; i++) {
        unichar glyph = [glyphString characterAtIndex:i];
        CGAffineTransform textRenderingMatrix = CGAffineTransformConcat(textStateMatrix, textMatrix);
        unichar character = [currentFont characterForGlyph:glyph];
        CGSize glyphDisplacement = [currentFont displacementForGlyph:character];
        
        CGFloat Tx, Gx;
        if (character == ' ') {
            Tx = ((glyphDisplacement.width/1000 - (Tj/1000)) * Tfs + Tc + Tw) * Th;
            Gx = ((glyphDisplacement.width/1000) * Tfs + Tw) * Th;
        } else {
            Tx = ((glyphDisplacement.width/1000 - (Tj/1000)) * Tfs + Tc) * Th;
            Gx = ((glyphDisplacement.width/1000) * Tfs) * Th;
        }
        Tj = 0;
        CGAffineTransform offsetMatrix = CGAffineTransformMakeTranslation(Tx, 0);
        
        CGRect glyphRect = CGRectMake(0,0,Gx, Tfs * userUnit);
        CGRect renderRect = CGRectApplyAffineTransform(glyphRect, textRenderingMatrix);
        if (CGRectContainsRect(cropRect, renderRect)) {
            textRect = CGRectEqualToRect(textRect, CGRectZero) ? renderRect : CGRectUnion(textRect, renderRect);
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"BlioPDFDrawRectOfInterest" object:NSStringFromCGRect(renderRect)];
            [textContent appendFormat:@"%C", character];
        }
        
        textMatrix = CGAffineTransformConcat(offsetMatrix, textMatrix);
    }
}

- (id)initWithPage:(CGPDFPageRef)pageRef andFontList:(BlioPDFFontList *)newFontList {
    if ((self = [super init])) {
        self.textRect = CGRectZero;
        self.fontLookup = [NSMutableDictionary dictionary];
        self.fontList = newFontList;
        self.textContent = [NSMutableString string];
        self.textMatrix = CGAffineTransformIdentity;
        self.textLineMatrix = CGAffineTransformIdentity;
        self.Th = 1;
        self.userUnit = 1.0f;
        [self updateTextStateMatrix];
        
        cropRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
        CGPDFOperatorTableRef myTable = CGPDFOperatorTableCreate();
        
        CGPDFOperatorTableSetCallback (myTable, "MP", &op_MP);
        CGPDFOperatorTableSetCallback (myTable, "DP", &op_DP);
        CGPDFOperatorTableSetCallback (myTable, "BMC", &op_BMC);
        CGPDFOperatorTableSetCallback (myTable, "BDC", &op_BDC);
        CGPDFOperatorTableSetCallback (myTable, "EMC", &op_EMC);
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
        CGPDFOperatorTableSetCallback(myTable, "ET", &op_ET);
        
        CGPDFScannerRef myScanner;
        CGPDFContentStreamRef myContentStream;
        CGPDFDictionaryRef dict, resourcesDict, pageFontsDict;
        
        CGPDFReal userUnitNumber;
        
        dict = CGPDFPageGetDictionary(pageRef);
        //CGPDFDictionaryApplyFunction(dict, &logDictContents, @"pageDict");
        if (CGPDFDictionaryGetDictionary(dict, "Resources", &resourcesDict)) {
            //CGPDFDictionaryApplyFunction(resourcesDict, &logDictContents, @"resourcesDict");
            if (CGPDFDictionaryGetDictionary(resourcesDict, "Font", &pageFontsDict))
                CGPDFDictionaryApplyFunction(pageFontsDict, &mapPageFont, self);
        }
        if (CGPDFDictionaryGetNumber(dict, "UserUnit", &userUnitNumber)) {
            [self setUserUnit:userUnitNumber];
        }
        
        // DEBUG STATMENTS
        /*
         CGPDFDictionaryRef viewportDict;
         CGPDFArrayRef viewportsArray;
        CGPDFStreamRef contentsStream;
        if (CGPDFDictionaryGetStream(dict, "Contents", &contentsStream)) {
            CGPDFDictionaryRef contentsDict = CGPDFStreamGetDictionary(contentsStream);
            CGPDFDictionaryApplyFunction(contentsDict, &logDictContents, @"contentsDict");
        }
        if (CGPDFDictionaryGetArray(dict, "VP", &viewportsArray)) {
            for(size_t n = 0; n < CGPDFArrayGetCount(viewportsArray); n++) {
                if (n >= CGPDFArrayGetCount(viewportsArray)) continue;
                CGPDFArrayGetDictionary(viewportsArray, n, &viewportDict);
                CGPDFObjectRef object;
                CGPDFDictionaryGetObject(viewportDict, "BBox", &object);
                NSLog(@"Viewport BBox of type: %d", CGPDFObjectGetType(object));
                        
            }
        }
         */
        // END DEBUG STATEMENTS
        
        myContentStream = CGPDFContentStreamCreateWithPage (pageRef);
        myScanner = CGPDFScannerCreate (myContentStream, myTable, self);
        CGPDFScannerScan (myScanner);
        CGPDFScannerRelease (myScanner);
        CGPDFContentStreamRelease (myContentStream);
        
        CGPDFOperatorTableRelease(myTable);
    }
    return self;
}

@end

@implementation BlioPDFDebugView

@synthesize fitTransform, interestRect, cropRect, mediaRect;

- (id)initWithFrame:(CGRect)newFrame {
    if ((self = [super initWithFrame:newFrame])) {
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
    CGContextStrokePath(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
    CGContextStrokeRect(ctx, CGRectApplyAffineTransform(interestRect, fitTransform));
}

@end


