//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"
#import "BlioBookmark.h"
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucSelectorRange.h>

static const CGFloat kBlioPDFBlockMinimumWidth = 50;
static const CGFloat kBlioPDFBlockInsetX = 6;
static const CGFloat kBlioPDFBlockInsetY = 10;
static const CGFloat kBlioPDFShadowShrinkScale = 2;
static const CGFloat kBlioPDFGoToZoomScale = 0.7f;

@interface BlioLayoutHighlightsOperation : NSOperation {
    NSInteger pageNumber;
    BlioPDFPageView *view;
    BlioBookmarkRange *excludedBookmark;
    NSArray *highlightRanges;
    BlioTextFlow *textFlow;
}

- (id)initWithPage:(NSInteger)aPageNumber view:(BlioPDFPageView *)view exclusion:(BlioBookmarkRange *)excludedBookmark highlights:(NSArray *)highlightRanges textFlow:(BlioTextFlow *)aTextFlow;

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, retain) BlioPDFPageView *view;
@property (nonatomic, retain) BlioBookmarkRange *excludedBookmark;
@property (nonatomic, retain) NSArray *highlightRanges;
@property (nonatomic, retain) BlioTextFlow *textFlow;

@end

@interface BlioFastCATiledLayer : CATiledLayer
@end

static const CGFloat kBlioLayoutMaxZoom = 54.0f;
static const CGFloat kBlioLayoutShadow = 16.0f;
static const NSUInteger kBlioLayoutMaxViews = 6; // Must be at least 6 for the go to animations to look right

@interface BlioLayoutViewColoredRect : NSObject {
    CGRect rect;
    UIColor *color;
}

@property (nonatomic) CGRect rect;
@property (nonatomic, retain) UIColor *color;

@end

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
    CGAffineTransform fitTransform;
    CGAffineTransform viewTransform;
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
@property (nonatomic, readonly) CGAffineTransform fitTransform;
@property (nonatomic, readonly) CGAffineTransform viewTransform;

- (id)initWithFrame:(CGRect)frame document:(CGPDFDocumentRef)aDocument page:(NSInteger)aPageNumber;
- (void)setPageNumber:(NSInteger)pageNumber;
- (void)setHighlights:(NSArray *)newHighlights;
- (CGPDFPageRef)page;

@end

@interface BlioLayoutView(private)

- (BlioPDFPageView *)loadPage:(int)newPageNumber current:(BOOL)current preload:(BOOL)preload;
- (BlioPDFPageView *)loadPage:(int)newPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload;
- (BlioPDFPageView *)loadPage:(int)aPageNumber current:(BOOL)current preload:(BOOL)preload forceReload:(BOOL)reload preserve:(NSArray *)preservedPages;
- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) CGFloat lastZoomScale;

@end

@interface BlioPDFContainerScrollView : UIScrollView {
    NSInteger pageCount;
    EucSelector *selector;
    NSTimer *doubleTapBeginTimer;
    NSTimer *doubleTapEndTimer;
    id<BlioBookDelegate> bookDelegate;
}

@property (nonatomic) NSInteger pageCount;
@property (nonatomic, assign) EucSelector *selector;
@property (nonatomic, retain) NSTimer *doubleTapBeginTimer;
@property (nonatomic, retain) NSTimer *doubleTapEndTimer;
@property (nonatomic, assign) id<BlioBookDelegate> bookDelegate;

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
- (void)setHighlights:(NSArray *)newHighlights;

@end

@implementation BlioLayoutView


@synthesize delegate, book, scrollView, containerView, pageViews, currentPageView, tiltScroller, fonts, parsedPage, scrollToPageInProgress, disableScrollUpdating, pageNumber, pageCount, selector, lastHighlightColor, fetchHighlightsQueue;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    
    [self.fetchHighlightsQueue cancelAllOperations];
    self.fetchHighlightsQueue = nil;
    
    self.delegate = nil;
    self.book = nil;
    self.scrollView = nil;
    self.containerView = nil;
    self.pageViews = nil;
    self.currentPageView = nil;
    self.fonts = nil;
    self.lastHighlightColor = nil;
    
    [self.selector removeObserver:self forKeyPath:@"tracking"];
    [self.selector detatchFromView];
    self.selector = nil;

    [super dealloc];
}

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
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
        aScrollView.scrollsToTop = NO;
        aScrollView.delegate = self;
        aScrollView.pageCount = pageCount;
        aScrollView.canCancelContentTouches = NO;
        [self addSubview:aScrollView];
        self.scrollView = aScrollView;
        [aScrollView release];
        
        UIView *aView = [[UIView alloc] initWithFrame:self.bounds];
        [self.scrollView addSubview:aView];
        aView.backgroundColor = [UIColor clearColor];
        aView.autoresizesSubviews = YES;
        aView.userInteractionEnabled = YES;
        self.containerView = aView;
        self.containerView.clipsToBounds = NO;
        [aView release];
        
        EucSelector *aSelector = [[EucSelector alloc] init];
        [aSelector setShouldSniffTouches:NO];
        aSelector.dataSource = self;
        aSelector.delegate =  self;
        self.selector = aSelector;
        [aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
        [self.scrollView setSelector:aSelector];
        [aSelector release];
        
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
        
        NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
        self.fetchHighlightsQueue = aQueue;
        [aQueue release];
        
        [self.book textFlow]; // start text flow parsing in the background
        // Register for when the textFlow is done so we can refresh highlights
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFlowIsReady:) name:@"BlioTextFlowReady" object:nil];
        
    }
    return self;
}

- (BOOL)wantsTouchesSniffed {
    return NO;
}

- (void)setDelegate:(id<BlioBookDelegate>)newDelegate {
    delegate = newDelegate;
    [self.scrollView setBookDelegate:newDelegate];
}

- (void)setTiltScroller:(MSTiltScroller*)ts {
    tiltScroller = ts;
    [tiltScroller setScrollView:self.scrollView];
}

#pragma mark -
#pragma mark Highlights

- (void)displayHighlightsForPage:(NSInteger)aPageNumber inView:(BlioPDFPageView *)view excluding:(BlioBookmarkRange *)excludedBookmark {    
    
    NSArray *highlightRanges = [self.delegate rangesToHighlightForLayoutPage:aPageNumber];
    
    BlioLayoutHighlightsOperation *anOperation = [[BlioLayoutHighlightsOperation alloc] initWithPage:aPageNumber view:view exclusion:excludedBookmark highlights:highlightRanges textFlow:[self.book textFlow]];
    [self.fetchHighlightsQueue cancelAllOperations];
    [self.fetchHighlightsQueue addOperation:anOperation];
    [anOperation release];
}

- (void)refreshHighlights {
    EucSelectorRange *selectedRange = [self.selector selectedRange];
    
    if (nil != selectedRange) {
        for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
            EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
            if ([selectedRange isEqual:range]) {
                [self displayHighlightsForPage:self.pageNumber inView:self.currentPageView excluding:highlightRange];
                return;
            }
        }
    } else {
        [self displayHighlightsForPage:self.pageNumber inView:self.currentPageView excluding:nil];
    }
}

- (void)textFlowIsReady:(NSNotification *)notification {
    [self refreshHighlights];
}

#pragma mark -
#pragma mark Selector

- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range {
    NSInteger pageIndex = self.pageNumber - 1;
    
    EucSelectorRange *selectorRange = [[EucSelectorRange alloc] init];
    selectorRange.startBlockId = [BlioTextFlowParagraph paragraphIDForPageIndex:pageIndex paragraphIndex:range.startPoint.paragraphOffset];
    selectorRange.startElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.startPoint.wordOffset];
    selectorRange.endBlockId = [BlioTextFlowParagraph paragraphIDForPageIndex:pageIndex paragraphIndex:range.endPoint.paragraphOffset];
    selectorRange.endElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.endPoint.wordOffset];
    
    return [selectorRange autorelease];
}

- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range {
    NSInteger currentPage = self.pageNumber;
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = currentPage;
    startPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:range.startBlockId];
    startPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.startElementId];
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = currentPage;
    endPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:range.endBlockId];
    endPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.endElementId];
    
    BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
    bookmarkRange.startPoint = startPoint;
    bookmarkRange.endPoint = endPoint;
        
    [startPoint release];
    [endPoint release];
    
    return [bookmarkRange autorelease];
}

- (NSArray *)bookmarkRangesForCurrentPage {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSUInteger maxOffset = [pageParagraphs count];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = self.pageNumber;
    startPoint.paragraphOffset = 0;
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = self.pageNumber;
    endPoint.paragraphOffset = maxOffset;
    
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = startPoint;
    range.endPoint = endPoint;
    
    NSArray *highlightRanges = [self.delegate rangesToHighlightForRange:range];
    
    [startPoint release];
    [endPoint release];
    [range release];
    
    return [NSArray arrayWithArray:highlightRanges];
}

- (NSArray *)highlightRangesForEucSelector:(EucSelector *)aSelector {
       
    NSMutableArray *selectorRanges = [NSMutableArray array];
    
    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        [selectorRanges addObject:range];
    }
    
    return [NSArray arrayWithArray:selectorRanges];
}

- (UIColor *)eucSelector:(EucSelector *)aSelector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange {
    
    
    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        if ([selectedRange isEqual:range]) {
            [self displayHighlightsForPage:self.pageNumber inView:self.currentPageView excluding:highlightRange];
            return [highlightRange.color colorWithAlphaComponent:0.3f];
        }
    }
    
    return nil;
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange {
    
    if ((nil != toRange) && ![fromRange isEqual:toRange]) {
    
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:fromRange];
        BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:toRange];

        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:nil];
        
    }
    
    // Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSMutableArray *identifiers = [NSMutableArray array];
    for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
        [identifiers addObject:[paragraph paragraphID]];
    }
    return identifiers;
}

- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)paragraphID {
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        CGRect blockRect = [[pageParagraphs objectAtIndex:currentIndex] rect];
        CGAffineTransform viewTransform = [[self.currentPageView view] viewTransform];
        pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
    }
    
    return pageRect;
}

- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)paragraphID; {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        NSMutableArray *identifiers = [NSMutableArray array];
        for (BlioTextFlowPositionedWord *word in [[pageParagraphs objectAtIndex:currentIndex] words]) {
            [identifiers addObject:[word wordID]];
        }
        return identifiers;
    } else {
        return [NSArray array];
    }
}

- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)wordID ofBlockWithIdentifier:(id)paragraphID {    
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        NSArray *words = [[pageParagraphs objectAtIndex:currentIndex] words];
        NSInteger offset = [wordID integerValue];
        if (offset < [words count]) {
            CGRect wordRect = [[words objectAtIndex:offset] rect];
            CGAffineTransform viewTransform = [[self.currentPageView view] viewTransform];
            pageRect = CGRectApplyAffineTransform(wordRect, viewTransform);
        }
    }
    
    return [NSArray arrayWithObject:[NSValue valueWithCGRect:pageRect]];
}

- (NSArray *)colorMenuItems {    
    EucMenuItem *yellowItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorYellow:)] autorelease];
    yellowItem.color = [UIColor yellowColor];
    
    EucMenuItem *redItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorRed:)] autorelease];
    redItem.color = [UIColor redColor];
    
    EucMenuItem *blueItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorBlue:)] autorelease];
    blueItem.color = [UIColor blueColor];
    
    EucMenuItem *greenItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorGreen:)] autorelease];
    greenItem.color = [UIColor greenColor];
    
    NSArray *ret = [NSArray arrayWithObjects:yellowItem, redItem, blueItem, greenItem, nil];
        
    return ret;
}

- (NSArray *)highlightMenuItemsWithCopy:(BOOL)copy {
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu in layout view")                                                    
                                                            action:@selector(addNote:)] autorelease];
    
    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu in layout view")
                                                         action:@selector(copy:)] autorelease];
    
    EucMenuItem *colorItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Color", "\"Color\" option in popup menu in layout view")
                                                          action:@selector(showColorMenu:)] autorelease];
    
    EucMenuItem *removeItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", "\"Remove Highlight\" option in popup menu in layout view")
                                                           action:@selector(removeHighlight:)] autorelease];

    NSArray *ret;
    if (copy)
        ret = [NSArray arrayWithObjects:removeItem, addNoteItem, copyItem, colorItem, nil];
    else
        ret = [NSArray arrayWithObjects:removeItem, addNoteItem, colorItem, nil];

    return ret;
}

- (NSArray *)rootMenuItemsWithCopy:(BOOL)copy {
    EucMenuItem *highlightItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Highlight", "\"Hilight\" option in popup menu in layout view")                                                              
                                                              action:@selector(highlight:)] autorelease];
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu in layout view")                                                    
                                                            action:@selector(addNote:)] autorelease];
    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu in layout view")
                                                         action:@selector(copy:)] autorelease];
    EucMenuItem *showWebToolsItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", "\"Tools\" option in popup menu in layout view")
                                                                 action:@selector(showWebTools:)] autorelease];
    
    NSArray *ret;
    if (copy)
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, copyItem, showWebToolsItem, nil];
    else
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, showWebToolsItem, nil];
    
    return ret;
}

- (NSArray *)menuItemsForEucSelector:(EucSelector *)hilighter {
    if ([self.selector selectedRangeIsHighlight])
        return [self highlightMenuItemsWithCopy:YES];
    else
        return [self rootMenuItemsWithCopy:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if((object == self.selector) && ([keyPath isEqualToString:@"tracking"])) {
        if (((EucSelector *)object).isTracking) {
            [self.delegate hideToolbars];
            self.scrollView.scrollEnabled = NO;
        } else {
            self.scrollView.scrollEnabled = YES;
        }
    }
}

- (BlioBookmarkRange *)selectedRange {
    EucSelectorRange *highlighterRange = [self.selector selectedRange];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];;

    if (nil != highlighterRange) {        
        NSInteger startPageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:[highlighterRange startBlockId]];
        NSInteger endPageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:[highlighterRange endBlockId]];
        NSInteger startParagraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:[highlighterRange startBlockId]];
        NSInteger endParagraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:[highlighterRange endBlockId]];
        NSInteger startWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange startElementId]];
        NSInteger endWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange endElementId]];
        
        
        [startPoint setLayoutPage:startPageIndex + 1];
        [startPoint setParagraphOffset:startParagraphOffset];
        [startPoint setWordOffset:startWordOffset];
        
        [endPoint setLayoutPage:endPageIndex + 1];
        [endPoint setParagraphOffset:endParagraphOffset];
        [endPoint setWordOffset:endWordOffset];
    } else {
        [startPoint setLayoutPage:self.pageNumber];
        [endPoint setLayoutPage:self.pageNumber];
    }
    
    
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    [range setStartPoint:startPoint];
    [range setEndPoint:endPoint];
    
    [startPoint release];
    [endPoint release];
    
    return [range autorelease];
}

#pragma mark -
#pragma mark Selector Menu Responder Actions 

- (void)addHighlightWithColor:(UIColor *)color {
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
        
        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:color];
        
        // Deselect, this will fire the endEditing highlight callback which refreshes
        [self.selector setSelectedRange:nil];

    } else {
        
        if ([self.delegate respondsToSelector:@selector(addHighlightWithColor:)])
            [self.delegate addHighlightWithColor:color];
        
        // Set this to nil now because the refresh depends on it
        [self.selector setSelectedRange:nil];
        [self refreshHighlights];
    }
    
    self.lastHighlightColor = color;
}

- (void)highlightColorYellow:(id)sender {
    [self addHighlightWithColor:[UIColor yellowColor]];
}

- (void)highlightColorRed:(id)sender {
    [self addHighlightWithColor:[UIColor redColor]];
}

- (void)highlightColorBlue:(id)sender {
    [self addHighlightWithColor:[UIColor blueColor]];
}

- (void)highlightColorGreen:(id)sender {
    [self addHighlightWithColor:[UIColor greenColor]];
}

- (void)highlight:(id)sender {
    [self addHighlightWithColor:self.lastHighlightColor];
}

- (void)showColorMenu:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self colorMenuItems]];
}

- (void)removeHighlight:(id)sender {
    BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];

    if ([self.delegate respondsToSelector:@selector(removeHighlightAtRange:)])
        [self.delegate removeHighlightAtRange:highlightRange];
    
    // Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)addNote:(id)sender {
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        if ([self.delegate respondsToSelector:@selector(updateHighlightNoteAtRange:withColor:)])
            [self.delegate updateHighlightNoteAtRange:highlightRange withColor:nil];
    } else {
        if ([self.delegate respondsToSelector:@selector(addHighlightNoteWithColor:)])
            [self.delegate addHighlightNoteWithColor:self.lastHighlightColor];
    }
    
    // TODO - this probably doesn't want to deselect yet in case the note is cancelled
    // Or the selection could be saved and reinstated
    // Or we could just not bother but it might be annoying
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)copy:(id)sender {
    NSInteger currentPage = self.pageNumber;
    
    EucSelectorRange *selectorRange = [self.selector selectedRange];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = currentPage;
    startPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:selectorRange.startBlockId];
    startPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:selectorRange.startElementId];

    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = currentPage;
    endPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:selectorRange.endBlockId];
    endPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:selectorRange.endElementId];
    
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = startPoint;
    range.endPoint = endPoint;
    
    [startPoint release];
    [endPoint release];
    
    NSMutableArray *allWordStrings = [NSMutableArray array];
    NSInteger pageIndex = currentPage - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    
    for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
        for (BlioTextFlowPositionedWord *word in [paragraph words]) {
            if ((range.startPoint.layoutPage < currentPage) &&
                (paragraph.paragraphIndex <= range.endPoint.paragraphOffset) &&
                (word.wordIndex <= range.endPoint.wordOffset)) {
                
                [allWordStrings addObject:[word string]];
                
            } else if ((range.endPoint.layoutPage > currentPage) &&
                       (paragraph.paragraphIndex >= range.startPoint.paragraphOffset) &&
                       (word.wordIndex >= range.startPoint.wordOffset)) {
                
                [allWordStrings addObject:[word string]];
                
            } else if ((range.startPoint.layoutPage == currentPage) &&
                       (paragraph.paragraphIndex == range.startPoint.paragraphOffset) &&
                       (word.wordIndex >= range.startPoint.wordOffset)) {
                
                if ((paragraph.paragraphIndex == range.endPoint.paragraphOffset) &&
                    (word.wordIndex <= range.endPoint.wordOffset)) {
                    [allWordStrings addObject:[word string]];
                } else if (paragraph.paragraphIndex < range.endPoint.paragraphOffset) {
                    [allWordStrings addObject:[word string]];
                }
                    
            } else if ((range.startPoint.layoutPage == currentPage) &&
                       (paragraph.paragraphIndex > range.startPoint.paragraphOffset)) {
                
                if ((paragraph.paragraphIndex == range.endPoint.paragraphOffset) &&
                    (word.wordIndex <= range.endPoint.wordOffset)) {
                    [allWordStrings addObject:[word string]];
                } else if (paragraph.paragraphIndex < range.endPoint.paragraphOffset) {
                    [allWordStrings addObject:[word string]];
                }
                
            }
        }
    }

    [range release];

    [[UIPasteboard generalPasteboard] setStrings:[NSArray arrayWithObject:[allWordStrings componentsJoinedByString:@" "]]];
    
    if ([self.selector selectedRangeIsHighlight])
        [self.selector changeActiveMenuItemsTo:[self highlightMenuItemsWithCopy:NO]];
    else
        [self.selector changeActiveMenuItemsTo:[self rootMenuItemsWithCopy:NO]];
    
}

- (void)showWebTools:(id)sender {
    NSLog(@"Web Tools!");
}

- (UIColor *)lastHighlightColor {
    if (nil == lastHighlightColor) {
        lastHighlightColor = [UIColor yellowColor];
        [lastHighlightColor retain];
    }
    
    return lastHighlightColor;
}

#pragma mark -
#pragma mark TTS

- (id)getCurrentParagraphId {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];

    if (![pageParagraphs count])
        return nil;
    else
        return [[pageParagraphs objectAtIndex:0] paragraphID];
}

- (uint32_t)getCurrentWordOffset {
    return 0;
}

- (id)paragraphIdForParagraphAfterParagraphWithId:(id)paragraphID {    
    if (!paragraphID) {
        NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:0];
        
        if (![pageParagraphs count])
            return nil;
        else
            return (id)[[pageParagraphs objectAtIndex:0] paragraphID];
    } else {

        NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
        NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
        NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
        
            if (++currentIndex < [pageParagraphs count]) {
                return (id)[[pageParagraphs objectAtIndex:currentIndex] paragraphID];
            } else {
                while (++pageIndex < ([self pageCount])) {
                    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
                    if ([pageParagraphs count])
                        return (id)[[pageParagraphs objectAtIndex:0] paragraphID];
                }
            }
        
    }
    return nil;
}

- (NSArray *)paragraphWordsForParagraphWithId:(id)paragraphID {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex)
        return [[pageParagraphs objectAtIndex:currentIndex] wordsArray];
    else
        return nil;
    
}

- (void)highlightWordAtParagraphId:(id)paragraphID wordOffset:(uint32_t)wordOffset {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        BlioTextFlowParagraph *currentParagraph = [pageParagraphs objectAtIndex:currentIndex];
        NSInteger targetPageNumber = ++pageIndex;
        if ((self.pageNumber != targetPageNumber) && !self.disableScrollUpdating) {
            [self goToPageNumber:targetPageNumber animated:YES];
        }
        
        NSArray *words = [currentParagraph words];
        if ([words count] > wordOffset) {
            BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
            [self.selector temporarilyHighlightElementWithIdentfier:[word wordID] inBlockWithIdentifier:paragraphID animated:YES];
        }
                                                   
    }

}

#pragma mark -
#pragma mark BlioBookView Protocol Methods

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    return;
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
            NSLog(@"WARNING: more than 3 pages found to preserve during go to animation: %@", [pagesToPreserve description]); 
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

- (BlioBookmarkAbsolutePoint *)pageBookmarkPoint
{
    BlioBookmarkAbsolutePoint *ret = [[BlioBookmarkAbsolutePoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    [self goToPageNumber:bookmarkPoint.layoutPage animated:animated];
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self goToPageNumber:bookmarkRange.startPoint.layoutPage animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    return bookmarkPoint.layoutPage;
}

- (NSInteger)pageNumberForBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
    return bookmarkRange.startPoint.layoutPage;
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
                }
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
    
    if (current) {
        self.currentPageView = pageView;
        //NSLog(@"attached to view");
        [self.selector attachToView:pageView];
        [self displayHighlightsForPage:aPageNumber inView:pageView excluding:nil];
    }
    
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
    //[self.currentPageView renderSharpPageAtScale:self.scrollView.zoomScale];
    //[self renderSharpPageAtScale:self.scrollView.zoomScale];
    if([self.selector isTracking])
        [self.selector redisplaySelectedRange]; 
    [self.selector setShouldHideMenu:NO];
    
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

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
////    [self.currentPageView hideSharpPage];
////    [self hideSharpPage];
//}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        //[self.currentPageView renderSharpPageAtScale:aScrollView.zoomScale];
//        [self renderSharpPageAtScale:aScrollView.zoomScale];
        [self.selector setShouldHideMenu:NO];
    }
    if (tiltScroller) [tiltScroller resetAngle];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    [self.selector setShouldHideMenu:YES];

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
    [self.selector setShouldHideMenu:NO];
//    [self.currentPageView renderSharpPageAtScale:self.scrollView.zoomScale];
//    [self renderSharpPageAtScale:self.scrollView.zoomScale];
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
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    CGPoint point = CGPointFromString(pointString);
    CGPoint pointInView = [self.currentPageView convertPoint:point fromView:self];
    NSInteger pageIndex = self.pageNumber - 1;
    
    self.disableScrollUpdating = YES;
    NSArray *paragraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    
    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowParagraph *targetParagraph = nil;
    CGAffineTransform viewTransform = [[self.currentPageView view] viewTransform];
    
    if ([paragraphs count]) {        
        for (BlioTextFlowParagraph *paragraph in paragraphs) {
            CGRect blockRect = [paragraph rect];
            CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
            if (CGRectContainsPoint(pageRect, pointInView)) {
                targetParagraph = paragraph;
                break;
            }
        }
    }
    
    if (nil != targetParagraph) {            
        CGRect targetRect = CGRectApplyAffineTransform([targetParagraph rect], viewTransform);
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
        CGFloat pageWidth = self.scrollView.frame.size.width * zoomScale; 
        CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
        
        CGRect pageRect = CGRectApplyAffineTransform([[[self.currentPageView view] shadowLayerDelegate] pageRect], CATransform3DGetAffineTransform([[[self.currentPageView view] shadowLayer] transform]));
        CGFloat maxYOffset = ((CGRectGetMaxY(pageRect) * zoomScale) - self.scrollView.frame.size.height) / zoomScale;
        CGFloat yDiff = targetRect.origin.y - maxYOffset;
        
        if (yDiff > 0) {
            targetRect.origin.y -= yDiff;
            targetRect.size.height += yDiff;
        }
        //CGFloat minYOffset = CGPointApplyAffineTransform(CGPointZero, viewTransform).y;
        //CGFloat maxYOffset = self.scrollView.frame.size.height - minYOffset;
        CGPoint newContentOffset = CGPointMake(round(viewOrigin.x + targetRect.origin.x * zoomScale), round(viewOrigin.y + targetRect.origin.y * zoomScale));
        
        //if (newContentOffset.y > (112* zoomScale)) {
//            newContentOffset.y = 112 * zoomScale;
//        } else if (newContentOffset.y < (minYOffset * zoomScale)) {
//            newContentOffset.y = minYOffset * zoomScale;
//        }
        //newContentOffset.y = 112 * zoomScale;
        //newContentOffset.y = 62.5 * zoomScale;

        CGPoint currentContentOffset = [self.scrollView contentOffset];
        
        if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
            [self.scrollView setContentOffset:newContentOffset];
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
            return;
        }
    }
    
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

- (void)setHighlights:(NSArray *)newHighlights {
    [self.view setHighlights:newHighlights];
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

@synthesize pageCount, selector, doubleTapBeginTimer, doubleTapEndTimer, bookDelegate;

- (void)dealloc {
    self.selector = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    self.bookDelegate = nil;
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    
    UITouch * t = [touches anyObject];
    if( [t tapCount]>1 ) {
        CGPoint point = [t locationInView:(UIView *)self.delegate];
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomAtPoint:)])
            [(NSObject *)self.delegate performSelector:@selector(zoomAtPoint:) withObject:NSStringFromCGPoint(point)];
    } else {
        self.doubleTapBeginTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(delayedTouchesBegan:) userInfo:touches repeats:NO];
    }
}

- (void)delayedTouchesBegan:(NSTimer *)timer {
    NSSet *touches = (NSSet *)[timer userInfo];
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.selector touchesBegan:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (nil != self.doubleTapBeginTimer) {
        NSSet *beganTouches = (NSSet *)[self.doubleTapBeginTimer userInfo];
        [self.selector touchesBegan:beganTouches];
        [self.doubleTapBeginTimer invalidate];
        self.doubleTapBeginTimer = nil;
    }
    
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
          
    [self.selector touchesMoved:touches];
          
    if ([self.selector trackingStage] != EucSelectorTrackingStageNone) {
        [self setScrollEnabled:NO];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    
    [self setScrollEnabled:YES];
    
    if (![self.selector isTracking]) {
        UITouch * t = [touches anyObject];
        if( [t tapCount] == 1 ) {
            self.doubleTapEndTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(delayedTouchesEnded:) userInfo:touches repeats:NO];
        }
    }
    
    // This must always be sent to the selector to ensure state consistency
    [self.selector touchesEnded:touches];
}

- (void)delayedTouchesEnded:(NSTimer *)timer {
    [self.doubleTapEndTimer invalidate];
    [self.bookDelegate toggleToolbars];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    [self setScrollEnabled:YES];
    [self.selector touchesCancelled:touches];
}
    
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

- (CGAffineTransform)fitTransform {
    if (CGAffineTransformIsIdentity(fitTransform)) {
        CGFloat inset = -kBlioLayoutShadow;
        CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
        fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    }
    return fitTransform;
}

- (CGAffineTransform)viewTransform {
    if (CGAffineTransformIsIdentity(viewTransform)) {
        viewTransform = CGAffineTransformConcat(self.textFlowTransform, self.fitTransform);
    }
    return viewTransform;
}

- (void)configureLayers {
    self.tiledLayer = [BlioFastCATiledLayer layer];
    
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    
//    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    //CGPDFPageRef firstPage = CGPDFDocumentGetPage(document, 1);
    //CGAffineTransform firstTransform = CGPDFPageGetDrawingTransform(firstPage, kCGPDFArtBox, insetBounds, 0, true);
    //CGAffineTransform highlightsTransform = fitTransform;
    CGRect fittedPageRect = CGRectApplyAffineTransform(pageRect, self.fitTransform);     
    
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
    [aHighlightDelegate setFitTransform:self.fitTransform];
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
        fitTransform = CGAffineTransformIdentity;
        viewTransform = CGAffineTransformIdentity;
        
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
    fitTransform = CGAffineTransformIdentity;
    viewTransform = CGAffineTransformIdentity;
    
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

- (void)setHighlights:(NSArray *)newHighlights {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    [highlightLayerDelegate setHighlights:newHighlights];
    [highlightLayer setNeedsDisplay];
    
    [CATransaction commit];
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
    
    //CGContextSetRGBFillColor(ctx, 1, 1, 0, 0.3f);
//    CGFloat dash[2]={0.5f,1.5f};
//    CGContextSetLineDash (ctx, 0, dash, 2);
    
    CGContextConcatCTM(ctx, fitTransform);
        
    for (BlioLayoutViewColoredRect *coloredRect in self.highlights) {
        UIColor *highlightColor = [coloredRect color];
        CGContextSetFillColorWithColor(ctx, [highlightColor colorWithAlphaComponent:0.3f].CGColor);
        //CGContextSetStrokeColorWithColor(ctx, [highlightColor colorWithAlphaComponent:1.0f].CGColor);
        //CGContextSetLineWidth(ctx, 1.0f);
        
        CGRect highlightRect = [coloredRect rect];
        CGRect adjustedRect = CGRectApplyAffineTransform(highlightRect, highlightsTransform);
        //CGContextClearRect(ctx, CGRectInset(adjustedRect, -1, -1));
        CGContextFillRect(ctx, adjustedRect);
        //CGContextStrokeRect(ctx, adjustedRect);
    }
}

@end

@implementation BlioFastCATiledLayer

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutViewColoredRect

@synthesize rect, color;

- (void)dealloc {
    self.color = nil;
    [super dealloc];
}

@end

@implementation BlioLayoutHighlightsOperation

@synthesize pageNumber, view, excludedBookmark, highlightRanges, textFlow;

- (void)dealloc {
    self.view = nil;
    self.excludedBookmark = nil;
    self.highlightRanges = nil;
    self.textFlow = nil;
    [super dealloc];
}

- (id)initWithPage:(NSInteger)aPageNumber view:(BlioPDFPageView *)aView exclusion:(BlioBookmarkRange *)aExcludedBookmark highlights:(NSArray *)aHighlightRanges textFlow:(BlioTextFlow *)aTextFlow {
    if((self = [super init])) {
        
        self.pageNumber = aPageNumber;
        self.view = aView;
        self.excludedBookmark = aExcludedBookmark;
        self.highlightRanges = aHighlightRanges;
        self.textFlow = aTextFlow;
    }
    
    return self;
}

- (void)main {
    if ([self isCancelled]) return;
        
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [self.textFlow paragraphsForPageAtIndex:pageIndex];
    
    if ([self isCancelled]) return;
    
    NSMutableArray *allHighlights = [NSMutableArray array];
    for (BlioBookmarkRange *highlightRange in self.highlightRanges) {
        if ([self isCancelled]) return;
        
        if (![highlightRange isEqual:self.excludedBookmark]) {
            
            NSMutableArray *highlightRects = [NSMutableArray array];
            
            for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
                if ([self isCancelled]) return;
                
                for (BlioTextFlowPositionedWord *word in [paragraph words]) {
                    if ((highlightRange.startPoint.layoutPage < self.pageNumber) &&
                        (paragraph.paragraphIndex <= highlightRange.endPoint.paragraphOffset) &&
                        (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.endPoint.layoutPage > self.pageNumber) &&
                               (paragraph.paragraphIndex >= highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.startPoint.layoutPage == self.pageNumber) &&
                               (paragraph.paragraphIndex == highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                        
                    } else if ((highlightRange.startPoint.layoutPage == self.pageNumber) &&
                               (paragraph.paragraphIndex > highlightRange.startPoint.paragraphOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                    }
                }
            }
            
            if ([self isCancelled]) return;
            NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
            
            for (NSValue *rectValue in coalescedRects) {
                BlioLayoutViewColoredRect *coloredRect = [[BlioLayoutViewColoredRect alloc] init];
                coloredRect.color = highlightRange.color;
                coloredRect.rect = [rectValue CGRectValue];
                [allHighlights addObject:coloredRect];
                [coloredRect release];
            }
        }
        
    }
    if ([self isCancelled]) return;
    [self.view performSelectorOnMainThread:@selector(setHighlights:) withObject:allHighlights waitUntilDone:NO];
    
    [pool drain];
}

@end

