//
//  EucBookView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 17/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBookView.h"

#import "EucConfiguration.h"
#import "EucPageTurningView.h"
#import "EucPageLayoutController.h"
#import "EucBook.h"
#import "EucBookReference.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookTitleView.h"
#import "EucPageTextView.h"
#import "EucSelector.h"
#import "EucSelectorRange.h"
#import "EucHighlightRange.h"

#import "THUIDeviceAdditions.h"
#import "THUIViewAdditions.h"
#import "THRoundRectView.h"
#import "THCopyWithCoder.h"
#import "THAlertViewWithUserInfo.h"
#import "THScalableSlider.h"
#import "THGeometryUtils.h"
#import "THPair.h"
#import "THRegex.h"
#import "THLog.h"

#import <QuartzCore/QuartzCore.h>


#define kBookFontPointSizeDefaultsKey @"EucBookFontPointSize"

@interface EucBookView ()
- (void)_redisplayCurrentPage;
- (void)_goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;
- (void)_removeTemporaryHighlights;
- (THPair *)_pageViewAndIndexPointRangeForBookPageNumber:(NSInteger)pageNumber;
- (NSInteger)_sliderByteToPage:(float)byte;
- (float)_pageToSliderByte:(NSInteger)page;
- (void)_updateSliderByteToPageRatio;
- (void)_updatePageNumberLabel;
- (NSArray *)_highlightRangesForIndexPointRange:(THPair *)range;

@property (nonatomic, retain) UIImage *pageTexture;
@property (nonatomic, assign) BOOL pageTextureIsDark;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger pageCount;

@end


@implementation EucBookView

@synthesize delegate = _delegate;
@synthesize book = _book;

@synthesize allowsSelection = _allowsSelection;
@synthesize selector = _selector;
@synthesize selectorDelegate = _selectorDelegate;

@synthesize pageTexture = _pageTexture;
@synthesize pageTextureIsDark = _pageTextureIsDark;

@synthesize undimAfterAppearance = _undimAfterAppearance;
@synthesize appearAtCoverThenOpen = _appearAtCoverThenOpen;

@synthesize contentsDataSource = _pageLayoutController;

@synthesize pageNumber = _pageNumber;
@synthesize pageCount = _pageCount;

@synthesize pageTurningView = _pageTurningView;

- (id)initWithFrame:(CGRect)frame book:(EucBookReference<EucBook> *)book 
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = YES;
        
        _book = [book retain];
        
        CGFloat desiredPointSize = [[NSUserDefaults standardUserDefaults] floatForKey:kBookFontPointSizeDefaultsKey];
        if(desiredPointSize == 0) {
            desiredPointSize = [[EucConfiguration objectForKey:EucConfigurationDefaultFontSizeKey] floatValue];
        }
        
        /* if(!_bookIndex.isFinal) {
         [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(_bookPaginationProgress:)
         name:BookPaginationProgressNotification
         object:nil];            
         [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(_bookPaginationComplete:)
         name:BookPaginationCompleteNotification
         object:nil];
         }       */ 
        
        _pageLayoutController = [[[_book pageLayoutControllerClass] alloc] initWithBook:_book 
                                                                               pageSize:self.bounds.size
                                                                          fontPointSize:desiredPointSize];  
         
        self.opaque = YES;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc
{
    [self _removeTemporaryHighlights];
    [_temporaryHighlightRange release];

    if(_selector) {
        [_selector removeObserver:self forKeyPath:@"tracking"];
        [_selector detatch];
        [_selector release];
    }
    
    [_book release];
    
    [_pageTexture release];
    [_pageTurningView release];
    [_pageLayoutController release];
    
    [_pageSlider release];
    [_pageNumberLabel release];
    [_pageSliderTrackingInfoView release];   
    
    [super dealloc];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if(!self.window) {
        _pageTurningView = [[EucPageTurningView alloc] initWithFrame:self.bounds];
        _pageTurningView.delegate = self;
        _pageTurningView.viewDataSource = self;
        _pageTurningView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        UIImage *pageTexture = self.pageTexture;
        if(!pageTexture) {
            pageTexture = [[UIImage imageNamed:@"BookPaper.png"] retain];
            self.pageTexture = pageTexture;
        }
        [_pageTurningView setPageTexture:pageTexture isDark:self.pageTextureIsDark];
        [self addSubview:_pageTurningView];
        
        EucBookPageIndexPoint *indexPoint;
        if(_appearAtCoverThenOpen) {
            indexPoint = [[[EucBookPageIndexPoint alloc] init] autorelease];
        } else {
            indexPoint = [_book currentPageIndexPoint];
        }
        
        NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:indexPoint];
        THPair *currentPageViewAndIndexPointRange = [self _pageViewAndIndexPointRangeForBookPageNumber:pageNumber];
        _pageTurningView.currentPageView = currentPageViewAndIndexPointRange.first;
        
        self.pageCount = _pageLayoutController.globalPageCount;
        self.pageNumber = pageNumber;

        [_pageSlider setScaledValue:[self _pageToSliderByte:pageNumber] animated:NO];
        [self _updatePageNumberLabel];
        
        _pageTurningView.dimQuotient = _dimQuotient;        
    } 
    if(_selector) {
        [_selector removeObserver:self
                       forKeyPath:@"tracking"];
        [_selector detatch];
        [_selector release];
        _selector = nil;
    }
}

- (void)didMoveToWindow
{
    if(self.window) {
        if(self.appearAtCoverThenOpen) {
            EucBookPageIndexPoint *indexPoint = [_book currentPageIndexPoint];
            [self _goToPageNumber:[_pageLayoutController pageNumberForIndexPoint:indexPoint] animated:YES];
            self.appearAtCoverThenOpen = NO;
        } 
        if(self.undimAfterAppearance) {
            self.undimAfterAppearance = NO;
            NSNumber *timeNow = [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()];
            [self performSelector:@selector(updateDimQuotientForTimeAfterAppearance:) withObject:timeNow afterDelay:1.0/30.0];
        }  
        
        // We crewate this even if allowsSelection is NO, because it's also 
        // used to perform temporary highlighting.
        _selector = [[EucSelector alloc] init];
        _selector.shouldSniffTouches = self.allowsSelection;
        [_selector attachToView:self];
        [_selector addObserver:self
                       forKeyPath:@"tracking"
                          options:0
                          context:NULL];
        _selector.dataSource = self;
        _selector.delegate = self.selectorDelegate ?: self;
    } else {
        [_pageTurningView removeFromSuperview];
        [_pageTurningView release];
        _pageTurningView = nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize newSize = self.bounds.size;
    if(!CGSizeEqualToSize(newSize, _pageLayoutController.pageSize)) {
        if(_selector.tracking) {
            [_selector setSelectedRange:nil];
        }        
        _pageLayoutController.pageSize = newSize;
        [self _redisplayCurrentPage];
    }
}

- (void)setSelectorDelegate:(id<EucSelectorDelegate>)delegate
{
    if(self.selector) {
        self.selector.delegate = delegate;
    }
    _selectorDelegate = delegate;
}

- (void)updateDimQuotientForTimeAfterAppearance:(NSNumber *)appearanceTime
{
    CFAbsoluteTime duration = 1;
    CFAbsoluteTime start = [appearanceTime doubleValue];
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    
    CFAbsoluteTime elapsed = (now - start) / duration;
    
    if(elapsed > 1) {
        self.dimQuotient = 0.0f;
    } else {
        self.dimQuotient = (cosf(((CGFloat)M_PI) * ((CGFloat)elapsed)) + 1.0f) * 0.5f;
        [self performSelector:@selector(updateDimQuotientForTimeAfterAppearance:) withObject:appearanceTime afterDelay:1.0/30.0];
    }
}

- (void)stopAnimation
{
    _pageTurningView.animating = NO;
}

#pragma mark -
#pragma mark Properties

- (CGFloat)fontPointSize
{
    return _pageLayoutController.fontPointSize;
}

- (void)setFontPointSize:(CGFloat)fontPointSize
{
    [_pageLayoutController setFontPointSize:fontPointSize];
    [[NSUserDefaults standardUserDefaults] setFloat:_pageLayoutController.fontPointSize forKey:kBookFontPointSizeDefaultsKey];
    [self _redisplayCurrentPage];
    self.pageCount = _pageLayoutController.globalPageCount;
}

- (CGFloat)dimQuotient
{
    return _dimQuotient;
}

- (void)setDimQuotient:(CGFloat)dimQuotient 
{
    _dimQuotient = dimQuotient;
    _pageTurningView.dimQuotient = dimQuotient;  
}

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark
{
    if(self.pageTexture != pageTexture || self.pageTextureIsDark != isDark) {
        self.pageTexture = pageTexture;
        self.pageTextureIsDark = isDark;
        [_pageTurningView setPageTexture:pageTexture isDark:isDark];
        [_pageTurningView setNeedsDraw];
    }
}

- (UIImage *)currentPageImage
{
    return [_pageTurningView screenshot];
}

- (CGRect)contentRect
{
    return [(EucPageView *)[_pageTurningView currentPageView] contentRect];
}

#pragma mark -
#pragma mark Highlighting

- (void)_removeTemporaryHighlights
{
    [_selector removeTemporaryHighlight];
}

- (void)_displayTemporaryHighlightsAnimated:(BOOL)animated
{
    [_selector temporarilyHighlightSelectorRange:[_temporaryHighlightRange selectorRange]
                                        animated:animated];
}

- (void)highlightWordAtIndexPoint:(EucBookPageIndexPoint *)indexPoint animated:(BOOL)animated
{
    EucHighlightRange *highlightRange = nil;
    if(indexPoint) {
        highlightRange = [[EucHighlightRange alloc] init];
        highlightRange.startPoint = indexPoint;
        highlightRange.endPoint = indexPoint;
    }
    [self highlightWordsInHighlightRange:highlightRange animated:animated];
    [highlightRange release];
}

- (void)highlightWordsInHighlightRange:(EucHighlightRange *)highlightRange animated:(BOOL)animated
{
    if(!highlightRange) {
        [_temporaryHighlightRange release];
        _temporaryHighlightRange = nil;
        [self _removeTemporaryHighlights];
    } else {
        if(![_temporaryHighlightRange isEqual:highlightRange]) {
            [_temporaryHighlightRange release];
            _temporaryHighlightRange = [highlightRange retain];
                        
            if(!_temporaryHighlightingDisabled) {
                EucPageView *currentPageView = (EucPageView *)(_pageTurningView.currentPageView);
                CALayer *pageLayer = currentPageView.layer;
                THPair *indexPointRange = [pageLayer valueForKey:@"EucBookViewIndexPointRange"];
                EucHighlightRange *pageRange = [[EucHighlightRange alloc] init];
                pageRange.startPoint = indexPointRange.first;
                pageRange.endPoint = indexPointRange.second;
                
                NSInteger newPageNumber = self.pageNumber;
                if(![pageRange intersects:_temporaryHighlightRange] || 
                   [pageRange.endPoint isEqual:_temporaryHighlightRange.startPoint]) { 
                    // Or clause because highlight ranges are inclusive, but the
                    // ranges stored in EucBookViewIndexPointRange are exclusive
                    // of the end point...
                    newPageNumber = [_pageLayoutController pageNumberForIndexPoint:highlightRange.startPoint];
                }
                if(newPageNumber != self.pageNumber) {
                    [self _removeTemporaryHighlights];
                    [self _goToPageNumber:newPageNumber animated:animated];
                    if(!animated) {
                        [self _displayTemporaryHighlightsAnimated:animated];
                    }
                } else {
                    [self _displayTemporaryHighlightsAnimated:animated];
                }
                [pageRange release];
            }
        }
    }
    
}

#pragma mark -
#pragma mark Navigation

- (void)_goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated
{
    if(_pageTurningView) {
        [_pageTurningView setNeedsDisplay];
        
        NSInteger oldPageNumber = self.pageNumber;
        
        THPair *newPageViewAndIndexPoint = [self _pageViewAndIndexPointRangeForBookPageNumber:pageNumber];
        
        EucPageView *newPageView = newPageViewAndIndexPoint.first;
        THPair *newPageIndexPointRange = newPageViewAndIndexPoint.second;        
        
        if(!_dontSaveIndexPoints) {
            [_book setCurrentPageIndexPoint:newPageIndexPointRange.first];
        }

        if(animated && oldPageNumber != pageNumber) {
            NSInteger count = oldPageNumber - pageNumber;
            if(count < 0) {
                count = -count;
            }
            [_pageTurningView turnToPageView:newPageView forwards:oldPageNumber < pageNumber pageCount:count onLeft:NO];
        } else {
            _pageTurningView.currentPageView = newPageView;
            [_pageTurningView setNeedsDraw];
            
            [self pageTurningView:_pageTurningView didTurnToView:newPageView];
        }
        
        // Preemptive, to make the animation run at the same time as the 
        // page turning view's animation.
        [_pageSlider setScaledValue:[self _pageToSliderByte:pageNumber] animated:animated];
    } else {
        [_book setCurrentPageIndexPoint:[_pageLayoutController indexPointForPageNumber:pageNumber]];
    }
}

- (CGRect)accessibilityFrame
{
    CGRect bounds;
    if([self.delegate respondsToSelector:@selector(bookViewNonToolbarRect:)]) {
        bounds = [self.delegate bookViewNonToolbarRect:self];
    } else {
        bounds = self.bounds;
    }
    return [self convertRect:bounds toView:nil];
}

- (NSString *)accessibilityLabel
{
    return NSLocalizedString(@"Book Page", "Accessibility label for libEucalyptus page view");
}

- (NSString *)accessibilityHint
{
    return NSLocalizedString(@"Double tap to read page with VoiceOver.", "Accessibility label for libEucalyptus page view");
}

- (BOOL)isAccessibilityElement
{
    if([self.delegate respondsToSelector:@selector(bookViewToolbarsVisible:)]) {
        return [self.delegate bookViewToolbarsVisible:self];
    } else {
        return NO;
    }
}

- (NSInteger)accessibilityElementCount
{
    if(!self.isAccessibilityElement) {
        return [super accessibilityElementCount];
    } else {
        return 0;
    }
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    if(!self.isAccessibilityElement) {
        return [super accessibilityElementAtIndex:index];
    } else {
        return nil;
    }
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    if(!self.isAccessibilityElement) {
        return [super indexOfAccessibilityElement:element];
    } else {
        return 0;
    }
}

- (void)_redisplayCurrentPage
{
    if(_pageTurningView) {
        _dontSaveIndexPoints = YES;
        [self _goToPageNumber:[_pageLayoutController pageNumberForIndexPoint:[_book currentPageIndexPoint]] animated:NO];
        _dontSaveIndexPoints = NO;
    }
}    

- (void)goToPageNumber:(NSInteger)newPageNumber animated:(BOOL)animated
{
    [self _goToPageNumber:newPageNumber animated:animated];
}

- (void)goToIndexPoint:(EucBookPageIndexPoint *)indexPoint animated:(BOOL)animated;
{
    [self _goToPageNumber:[_pageLayoutController pageNumberForIndexPoint:indexPoint]
                 animated:animated];
}

- (NSInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return [_pageLayoutController pageNumberForIndexPoint:indexPoint];
}

- (NSInteger)pageNumberForUuid:(NSString *)uuid
{
    return [_pageLayoutController pageNumberForSectionUuid:uuid];
}

- (void)_goToPageNumberSavingJump:(NSInteger)newPageNumber animated:(BOOL)animated
{
    NSInteger currentPageNumber = self.pageNumber;
    _savedJumpPage = currentPageNumber;
    _directionalJumpCount = newPageNumber > currentPageNumber ? 1 : -1;
    _jumpShouldBeSaved = YES;
    [self goToPageNumber:newPageNumber animated:animated];
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    [self _goToPageNumberSavingJump:[_pageLayoutController pageNumberForSectionUuid:uuid] animated:animated];
}

- (void)jumpForwards
{    
    if(_directionalJumpCount == -1) {
        // If the last page turn we did was a jump on the opposite direction,
        // jump back to the position we used to be at.
        [self _goToPageNumber:_savedJumpPage animated:YES];
        return;
    }  
    
    // Only save the 'jump back' page if it is not multiple times in a row that
    // the button has been hit.
    NSInteger jumpCount = _directionalJumpCount;
    
    NSInteger currentPageNumber = self.pageNumber;
    NSInteger newPageNumber = [_pageLayoutController nextSectionPageNumberForPageNumber:currentPageNumber];
    
    if(newPageNumber != currentPageNumber) {
        [self _goToPageNumber:newPageNumber animated:YES];
        // Save our previous position so that we can jump back to it if the user
        // taps the next section button.
        ++jumpCount;
        _directionalJumpCount = jumpCount;
        if(jumpCount == 1) {
            _savedJumpPage = currentPageNumber;
        }     
        _jumpShouldBeSaved = YES;
    }
}

- (void)jumpBackwards
{
    if(_directionalJumpCount == 1) {
        // If the last page turn we did was a jump on the opposite direction,
        // jump back to the position we used to be at.
        [self _goToPageNumber:_savedJumpPage animated:YES];
        return;
    }
    
    // Only save the 'jump back' page if it is not multiple times in a row that
    // the button has been hit.
    NSInteger jumpCount = _directionalJumpCount;
    
    // This is much harder than skipping forwards, because we don't just want
    // to go the previous section, we want to go the start of the /current/
    // section if we're not in the first page.
    NSInteger currentPageNumber = self.pageNumber;
    
    NSInteger newPageNumber = [_pageLayoutController previousSectionPageNumberForPageNumber:currentPageNumber];
    
    if(newPageNumber != currentPageNumber) {
        [self _goToPageNumber:newPageNumber animated:YES];
        // Save our previous position so that we can jump back to it if the user
        // taps the next section button.
        --jumpCount;
        _directionalJumpCount = jumpCount;
        if(jumpCount == -1) {
            _savedJumpPage = currentPageNumber;
        }     
        _jumpShouldBeSaved = YES;
    }
}

#pragma mark -
#pragma mark PageView Handling

- (NSArray *)_highlightRectsForRange:(EucHighlightRange *)highlightRange inPageView:(EucPageView *)pageView
{                
    NSArray *ret = nil;
    
    UIView<EucPageTextView> *pageTextView = pageView.pageTextView;
    NSArray *blockIds = [pageTextView blockIdentifiers];
    NSUInteger blockIdsCount = blockIds.count;
    if(blockIdsCount) {
        THPair *pageIndexPointRange = [pageView.layer valueForKey:@"EucBookViewIndexPointRange"];

        EucBookPageIndexPoint *startPoint = highlightRange.startPoint;
        EucBookPageIndexPoint *pageStartPoint = pageIndexPointRange.first;
        if([startPoint compare:pageStartPoint] == NSOrderedAscending) {
            startPoint = pageStartPoint;
        }
        id startBlockId = [NSNumber numberWithUnsignedInt:startPoint.block];
        id startElementId = [NSNumber numberWithUnsignedInt:startPoint.word];

        id endBlockId;
        id endElementId;
                         
        EucBookPageIndexPoint *endPoint = highlightRange.endPoint;
        EucBookPageIndexPoint *pageEndPoint = pageIndexPointRange.second;
        if([endPoint compare:pageEndPoint] != NSOrderedAscending) {
            endBlockId = [blockIds lastObject];
            endElementId = [[pageTextView identifiersForElementsOfBlockWithIdentifier:endBlockId] lastObject];
        } else {
            endBlockId = [NSNumber numberWithUnsignedInt:endPoint.block];
            endElementId = [NSNumber numberWithUnsignedInt:endPoint.word];
        }
    
        NSMutableArray *nonCoalescedRects = [[NSMutableArray alloc] init];    
        NSUInteger blockIdIndex = 0;
        
        BOOL isFirstBlock;
        if([[blockIds objectAtIndex:0] compare:startBlockId] == NSOrderedDescending) {
            // The real first block was before the first block we have seen.
            isFirstBlock = NO;
        } else {
            while(blockIdIndex < blockIdsCount &&
                  [[blockIds objectAtIndex:blockIdIndex] compare:startBlockId] == NSOrderedAscending) {
                ++blockIdIndex;
            }
            isFirstBlock = YES;
        }

        BOOL isLastBlock = NO;
        while(!isLastBlock && blockIdIndex < blockIdsCount) {
            id blockId = [blockIds objectAtIndex:blockIdIndex];
            
            NSArray *elementIds = [pageTextView identifiersForElementsOfBlockWithIdentifier:blockId];
            NSUInteger elementIdCount = elementIds.count;
            NSUInteger elementIdIndex = 0;
            
            isLastBlock = ([blockId compare:endBlockId] == NSOrderedSame);
            
            id elementId;
            if(isFirstBlock) {
                if(elementIdCount) {
                    while([[elementIds objectAtIndex:elementIdIndex] compare:startElementId] == NSOrderedAscending) {
                        ++elementIdIndex;
                    }
                }
                isFirstBlock = NO;
            }
            
            if(elementIdCount) {
                do {
                    elementId = [elementIds objectAtIndex:elementIdIndex];
                    [nonCoalescedRects addObjectsFromArray:[pageTextView rectsForElementWithIdentifier:elementId
                                                                                 ofBlockWithIdentifier:blockId]];
                    ++elementIdIndex;
                } while (isLastBlock ? 
                         ([elementId compare:endElementId] < NSOrderedSame) : 
                         elementIdIndex < elementIdCount);
            }
            ++blockIdIndex;
        }
        
        ret = [EucSelector coalescedLineRectsForElementRects:nonCoalescedRects];
        [nonCoalescedRects release];
    }
    
    return ret;
}

typedef enum {
    EucBookViewHighlightSurroundingPageFlagsNone     = 0x0,
    EucBookViewHighlightSurroundingPageFlagsPrevious = 0x1,
    EucBookViewHighlightSurroundingPageFlagsNext     = 0x2,
} EucBookViewHighlightSurroundingPageFlags;

- (EucBookViewHighlightSurroundingPageFlags)_applyHighlightLayersToPageView:(EucPageView *)pageView 
                                                         refreshingFromBook:(BOOL)refreshingFromBook    
{
    EucBookViewHighlightSurroundingPageFlags ret = EucBookViewHighlightSurroundingPageFlagsNone;
    
    CALayer *pageLayer = pageView.layer;
    THPair *indexPointRange = [pageLayer valueForKey:@"EucBookViewIndexPointRange"];
    
    NSMutableArray *highlightLayersToReuse = nil;
    NSArray *currentSublayers = [pageLayer sublayers];
    NSUInteger currentSublayersCount = currentSublayers.count;
    if(currentSublayersCount) {
        highlightLayersToReuse = [[NSMutableArray alloc] initWithCapacity:currentSublayersCount];
        for(CALayer *layer in currentSublayers) {
            if([layer.name isEqualToString:@"EucBookViewHighlight"]) {
                [highlightLayersToReuse addObject:layer];
            }
        }
    }
    
    NSArray *oldHighlightRanges = [pageLayer valueForKey:@"EucBookViewHighlightRanges"];

    NSUInteger reuseCount = highlightLayersToReuse.count;
    NSUInteger reuseIndex = 0;
    
    NSArray *newHighlightRanges;
    if(!refreshingFromBook && oldHighlightRanges) {
        newHighlightRanges = oldHighlightRanges;
    } else {
        newHighlightRanges = [self _highlightRangesForIndexPointRange:indexPointRange];
    }
    if(newHighlightRanges) {
        UIView *pageTextView = pageView.pageTextView;
        for(EucHighlightRange *highlightRange in newHighlightRanges) {
            if(!_rangeBeingEdited || ![highlightRange intersects:_rangeBeingEdited]) {                 
                CGColorRef color = [highlightRange.color colorWithAlphaComponent:0.3f].CGColor;
                NSArray *rects = [self _highlightRectsForRange:highlightRange inPageView:pageView];
                for(NSValue *rectValue in rects) {
                    CGRect rect  = CGRectIntegral([pageTextView convertRect:rectValue.CGRectValue toView:pageView]);
                    if(reuseIndex < reuseCount) {
                        CALayer *layer = [highlightLayersToReuse objectAtIndex:reuseIndex++];
                        layer.backgroundColor = color;
                        layer.frame = rect;
                    } else {
                        CALayer *layer = [[CALayer alloc] init];
                        layer.name = @"EucBookViewHighlight";
                        layer.cornerRadius = 4;
                        layer.backgroundColor = color;
                        layer.frame = rect;
                        [pageLayer addSublayer:layer]; 
                        [layer release];
                    }
                }
            }      
        }
    }
    
    if(highlightLayersToReuse) {
        // Remove any unused highlight layers.
        while(reuseIndex < reuseCount) {
            [[highlightLayersToReuse objectAtIndex:reuseIndex++] removeFromSuperlayer];
        }
        [highlightLayersToReuse release];
    }
    
    if(oldHighlightRanges.count) {
        EucHighlightRange *firstRange = [oldHighlightRanges objectAtIndex:0];
        if([firstRange.startPoint compare:indexPointRange.first] == NSOrderedAscending) {
            ret |= EucBookViewHighlightSurroundingPageFlagsPrevious;
        }
        EucHighlightRange *lastRange = [oldHighlightRanges lastObject];
        if([(EucBookPageIndexPoint *)(indexPointRange.second) compare:lastRange.endPoint] == NSOrderedAscending) {
            ret |= EucBookViewHighlightSurroundingPageFlagsNext;
        }
        
    } 
    if(newHighlightRanges != oldHighlightRanges) {
        if(newHighlightRanges.count) {
            EucHighlightRange *firstRange = [newHighlightRanges objectAtIndex:0];
            if([firstRange.startPoint compare:indexPointRange.first] == NSOrderedAscending) {
                ret |= EucBookViewHighlightSurroundingPageFlagsPrevious;
            }
            EucHighlightRange *lastRange = [newHighlightRanges lastObject];
            if([(EucBookPageIndexPoint *)(indexPointRange.second) compare:lastRange.endPoint] == NSOrderedAscending) {
                ret |= EucBookViewHighlightSurroundingPageFlagsNext;
            }
        }
        [pageLayer setValue:newHighlightRanges forKey:@"EucBookViewHighlightRanges"];
    }
    
    return ret;
}

- (THPair *)_pageViewAndIndexPointRangeForBookPageNumber:(NSInteger)pageNumber
{          
    THPair *ret = [_pageLayoutController viewAndIndexPointRangeForPageNumber:pageNumber];
    EucPageView *pageView = (EucPageView *)ret.first;
    pageView.delegate = self;
    [pageView.layer setValue:ret.second forKey:@"EucBookViewIndexPointRange"];
    [self _applyHighlightLayersToPageView:pageView refreshingFromBook:YES];
    return ret;
}

#pragma mark Hyperlinks

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex) {
        UIApplication *application = [UIApplication sharedApplication];
        [application performSelector:@selector(openURL:) withObject:((THAlertViewWithUserInfo *)alertView).userInfo afterDelay:0.5];
    }
}

- (void)_hyperlinkTapped:(NSURL *)url
{
    if(url) {
        NSString *absolute = url.absoluteString;
        EucBookPageIndexPoint *indexPoint = nil;
        if([_book respondsToSelector:@selector(indexPointForId:)]) {
            indexPoint = [_book indexPointForId:absolute];
        }
        if(indexPoint) {
            // This is an internal link - jump to the specified section.
            [self goToIndexPoint:indexPoint animated:YES];
        } else {
            NSString *message = nil;
            
            // See if our delegate wants to handle the link.
            if(![_delegate respondsToSelector:@selector(bookView:shouldHandleTapOnHyperlink:)] ||
               [_delegate bookView:self shouldHandleTapOnHyperlink:url]) {
                NSString *scheme = [url scheme];
                if([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame) {
                    if([absolute matchPOSIXRegex:@"(itunes|phobos).*\\.com" flags:REG_EXTENDED | REG_ICASE]) {
                        if([absolute matchPOSIXRegex:@"(viewsoftware|[/]app[/])" flags:REG_EXTENDED | REG_ICASE]) {
                            message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped points to an app in the App Store.\n\nDo you want to switch to the App Store to view it now?", @"Message for sheet in book view askng if the user wants to open a clicked app hyperlink in the App Store"), url.host];
                        } else {
                            message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped will open iTunes.\n\nDo you want to switch to iTunes now?", @"Message for sheet in book view asking if the user wants to open a clicked URL hyperlink in iTunes"), url.host];
                        }
                    } else {
                        message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped points to a page at “%@”, on the Internet.\n\nDo you want to switch to Safari to view it now?", @"Message for sheet in book view askng if the user wants to open a clicked URL hyperlink in Safari"), url.host];
                    }
                } else if([scheme caseInsensitiveCompare:@"mailto"] == NSOrderedSame) {
                    message = [NSString stringWithFormat:NSLocalizedString(@"Do you want to switch to the Mail application to write an email to “%@” now?", @"Message for sheet in book view askng if the user wants to open a clicked mailto hyperlink in Mail"), url.resourceSpecifier];
                } 
                
                if(message) {
                    THAlertViewWithUserInfo *alertView = [[THAlertViewWithUserInfo alloc] initWithTitle:nil
                                                                                                message:message
                                                                                               delegate:self
                                                                                      cancelButtonTitle:NSLocalizedString(@"Don’t Switch", @"Button to cancel opening of a clicked hyperlink") 
                                                                                      otherButtonTitles:NSLocalizedString(@"Switch", @"Button to confirm opening of a clicked hyperlink"), nil];
                    alertView.userInfo = url;
                    [alertView show];
                    [alertView release];
                }
            }
        }
    }
}


- (void)pageView:(EucPageView *)pageTextView didReceiveTapOnHyperlinkWithURL:(NSURL *)url
{
    /*if(_touch) {
        // Stop tracking the touch - we don't want to show/hide the toolbar on a
        // tap if it was on a hyperlink.
        [_touch release];
        _touch = nil;
    }*/
    THLog(@"EucBookView received tap on hyperlink: %@", url);
    [self _hyperlinkTapped:url];
}

#pragma mark -
#pragma mark PageTurningView Callbacks

#pragma mark View supply

- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView previousViewForView:(UIView *)view
{
    THPair *pageIndexPointRange = [view.layer valueForKey:@"EucBookViewIndexPointRange"];
    EucBookPageIndexPoint *pageIndexPoint = pageIndexPointRange.first;
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    if(pageNumber > 1) {
        THPair *newPageViewAndIndexPointRange = [self _pageViewAndIndexPointRangeForBookPageNumber:pageNumber - 1];
        if(newPageViewAndIndexPointRange) {
            return newPageViewAndIndexPointRange.first;
        }
    }
    return nil;
}

- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView nextViewForView:(UIView *)view
{
    THPair *pageIndexPointRange = [view.layer valueForKey:@"EucBookViewIndexPointRange"];
    EucBookPageIndexPoint *pageIndexPoint = pageIndexPointRange.first;
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    THPair *newPageViewAndIndexPointRange = [self _pageViewAndIndexPointRangeForBookPageNumber:pageNumber + 1];
    if(newPageViewAndIndexPointRange) {
        return newPageViewAndIndexPointRange.first;
    } else {
        return nil;
    }
}

#pragma mark Scaling

static void LineFromCGPointsCGRectIntersectionPoints(CGPoint points[2], CGRect bounds, CGPoint returnedPoints[2]) 
{
    // Y = mX + n;
    // X = (Y - n) / m;
    CGPoint lineVector = CGPointMake(points[1].x - points[0].x, points[1].y - points[0].y);
    CGFloat lineXMultiplier = lineVector.y / lineVector.x;
    CGFloat lineConstantYAddition = points[0].y - (points[0].x * lineXMultiplier);
    
    CGPoint lineRectEdgeIntersections[4];
    lineRectEdgeIntersections[0] = CGPointMake(0, lineConstantYAddition);
    lineRectEdgeIntersections[1] = CGPointMake(bounds.size.width, lineXMultiplier * bounds.size.width + lineConstantYAddition);
    lineRectEdgeIntersections[2] = CGPointMake(-lineConstantYAddition / lineXMultiplier, 0);
    lineRectEdgeIntersections[3] = CGPointMake((bounds.size.height - lineConstantYAddition) / lineXMultiplier, bounds.size.height);
    
    for(NSInteger i = 0, j = 0; i < 4 && j < 2; ++i) {
        if(lineRectEdgeIntersections[i].x >= 0 && lineRectEdgeIntersections[i].x <= bounds.size.width &&
           lineRectEdgeIntersections[i].y >= 0 && lineRectEdgeIntersections[i].y <= bounds.size.height) {
            returnedPoints[j++] = lineRectEdgeIntersections[i];
        }
    }    
}


- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView 
          scaledViewForView:(UIView *)view 
             pinchStartedAt:(CGPoint[])pinchStartedAt 
                 pinchNowAt:(CGPoint[])pinchNowAt 
          currentScaledView:(UIView *)currentScaledView
{
    [self _removeTemporaryHighlights];
    
    CFAbsoluteTime start = 0;
    if(THWillLog()) {
        start = CFAbsoluteTimeGetCurrent();   
    }
    
    UIView *ret = nil;
    
    if(!_scaleUnderway) {
        _scaleUnderway = YES;
        _scaleStartPointSize = _pageLayoutController.fontPointSize;
        _scaleCurrentPointSize = _pageLayoutController.fontPointSize;
    }
    
    CGRect bounds = view.bounds;
    
    // We base the scale on the percentage of the screen "taken up"
    // by the initial pinch, and the percentage of the screen "taken up"
    
    CGFloat startLineLength = CGPointDistance(pinchStartedAt[0], pinchStartedAt[1]);
    CGFloat nowLineLength = CGPointDistance(pinchNowAt[0], pinchNowAt[1]);
    
    CGPoint startLineBoundsIntersectionPoints[2];
    LineFromCGPointsCGRectIntersectionPoints(pinchStartedAt, bounds, startLineBoundsIntersectionPoints);
    CGFloat startLineMaxLength = CGPointDistance(startLineBoundsIntersectionPoints[0], startLineBoundsIntersectionPoints[1]);
    
    CGPoint nowLineBoundsIntersectionPoints[2];
    LineFromCGPointsCGRectIntersectionPoints(pinchNowAt, bounds, nowLineBoundsIntersectionPoints);
    CGFloat nowLineMaxLength = CGPointDistance(nowLineBoundsIntersectionPoints[0], nowLineBoundsIntersectionPoints[1]);
    
    
    CGFloat startLinePercentage = startLineLength / startLineMaxLength;
    CGFloat nowLinePercentage = nowLineLength / nowLineMaxLength;
    
    NSArray *availablePointSizes = _pageLayoutController.availablePointSizes;
    CGFloat minPointSize = [[availablePointSizes objectAtIndex:0] doubleValue];
    CGFloat maxPointSize = [[availablePointSizes lastObject] doubleValue];
    
    CGFloat scaledPointSize;
    if(nowLinePercentage < startLinePercentage) {
        minPointSize -= (maxPointSize - minPointSize) / availablePointSizes.count; 
        //NSLog(@"min: %f", minPointSize);
        scaledPointSize = minPointSize + ((nowLinePercentage / startLinePercentage) * (_scaleStartPointSize - minPointSize));
    } else {
        maxPointSize += (maxPointSize - minPointSize) / availablePointSizes.count; 
        //NSLog(@"max: %f", maxPointSize);
        scaledPointSize = _scaleStartPointSize + (((nowLinePercentage - startLinePercentage) / (1 - nowLinePercentage)) * (maxPointSize - _scaleStartPointSize));
    }
    CGFloat difference = CGFLOAT_MAX;
    CGFloat foundSize = _scaleCurrentPointSize;
    for(NSNumber *sizeNumber in availablePointSizes) {
        CGFloat thisSize = [sizeNumber doubleValue];
        CGFloat thisDifference = fabsf(thisSize - scaledPointSize);
        if(thisDifference < difference) {
            difference = thisDifference;
            foundSize = thisSize;
        }
    }
    if(foundSize != _scaleCurrentPointSize) {
        THPair *oldIndexPointRange = [view.layer valueForKey:@"EucBookViewIndexPointRange"];
        [_pageLayoutController setFontPointSize:foundSize];
        NSInteger newPageNumber = [_pageLayoutController pageNumberForIndexPoint:oldIndexPointRange.first];
        THPair *viewAndIndexPointRange = [self _pageViewAndIndexPointRangeForBookPageNumber:newPageNumber];
        ret = viewAndIndexPointRange.first;
                
        _scaleCurrentPointSize = foundSize;
        
        if(THWillLog()) {
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            ++_scaleCount;
            _accumulatedScaleTime += (end - start);
            
            if(fmodf(_scaleCount, 20.0) == 0) {
                THLog(@"Scale generation rate: %f scaled views/s", (_scaleCount / _accumulatedScaleTime))
            }            
        }
    }
    
    return ret;
}

#pragma mark Status callbacks

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didTurnToView:(UIView *)view
{
    THPair *pageIndexPointRange = [view.layer valueForKey:@"EucBookViewIndexPointRange"];
    EucBookPageIndexPoint *pageIndexPoint = pageIndexPointRange.first;
    
    if(!_dontSaveIndexPoints) {
        [_book setCurrentPageIndexPoint:pageIndexPoint];
    }
    if(!_jumpShouldBeSaved) {
        _directionalJumpCount = 0;
    } else {
        _jumpShouldBeSaved = NO;
    }

    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    self.pageNumber = pageNumber; 
    
    self.selector.selectedRange = nil;
    
    [_pageSlider setScaledValue:[self _pageToSliderByte:pageNumber] animated:NO];
    [self _updatePageNumberLabel];  
}

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didScaleToView:(UIView *)view
{
    _scaleUnderway = NO;
    _scaleStartPointSize = 0;
    _scaleCurrentPointSize = 0;
    
    [[NSUserDefaults standardUserDefaults] setFloat:_pageLayoutController.fontPointSize forKey:kBookFontPointSizeDefaultsKey];
    
    THPair *pageIndexPointRange = [view.layer valueForKey:@"EucBookViewIndexPointRange"];
    EucBookPageIndexPoint *pageIndexPoint = pageIndexPointRange.first;
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    self.pageNumber = pageNumber;
    self.pageCount = _pageLayoutController.globalPageCount;
    
    [self _updateSliderByteToPageRatio];
    [_pageSlider setScaledValue:[self _pageToSliderByte:pageNumber] animated:NO];
    [self _updatePageNumberLabel];
}

- (void)pageTurningViewWillBeginAnimating:(EucPageTurningView *)pageTurningView
{
    if([_delegate respondsToSelector:@selector(bookViewPageTurnWillBegin:)]) {
        [_delegate bookViewPageTurnWillBegin:self];
    }
    
    _selector.selectionDisabled = YES;
    
    _temporaryHighlightingDisabled = YES;
    
    [self _removeTemporaryHighlights];    
}

- (void)pageTurningViewDidEndAnimation:(EucPageTurningView *)pageTurningView
{
    _selector.selectionDisabled = NO;
    
    _temporaryHighlightingDisabled = NO;
    
    if(_temporaryHighlightRange) {
        EucPageView *currentPageView = (EucPageView *)(_pageTurningView.currentPageView);
        CALayer *pageLayer = currentPageView.layer;
        THPair *indexPointRange = [pageLayer valueForKey:@"EucBookViewIndexPointRange"];
        EucHighlightRange *pageRange = [[EucHighlightRange alloc] init];
        pageRange.startPoint = indexPointRange.first;
        pageRange.endPoint = indexPointRange.second;
        
        if([pageRange intersects:_temporaryHighlightRange] && 
           ![pageRange.endPoint isEqual:_temporaryHighlightRange.startPoint]) { 
            // And clause because highlight ranges are inclusive, but the
            // ranges stored in EucBookViewIndexPointRange are exclusive
            // of the end point...
            [self _displayTemporaryHighlightsAnimated:YES];
        }
        [pageRange release];
    }

    if([_delegate respondsToSelector:@selector(bookViewPageTurnDidEnd:)]) {
        [_delegate bookViewPageTurnDidEnd:self];
    }    
}

- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView viewEdgeIsRigid:(UIView *)view
{
    return [_pageLayoutController viewShouldBeRigid:view];
}


#pragma mark -
#pragma mark Selector

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector
{
    return self.currentPageImage;
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector
{
    EucPageView *pageView = (EucPageView *)(_pageTurningView.currentPageView);
    return [pageView.pageTextView blockIdentifiers];
}

- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)id
{
    EucPageView *pageView = (EucPageView *)(_pageTurningView.currentPageView);
    return [pageView convertRect:[pageView.pageTextView frameOfBlockWithIdentifier:id] fromView:pageView.pageTextView];    
}

- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)id;
{
    EucPageView *pageView = (EucPageView *)(_pageTurningView.currentPageView);
    return [pageView.pageTextView identifiersForElementsOfBlockWithIdentifier:id];
}

- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;
{
    EucPageView *pageView = (EucPageView *)(_pageTurningView.currentPageView);
    UIView<EucPageTextView> *pageTextView = pageView.pageTextView;
    
    NSArray *rects = [pageTextView rectsForElementWithIdentifier:elementId
                                           ofBlockWithIdentifier:blockId];
    NSUInteger rectsCount = rects.count;
    if(rectsCount) {
        NSMutableArray *ret = [NSMutableArray arrayWithCapacity:rectsCount];
        for(NSValue *rect in rects) {
            [ret addObject:[NSValue valueWithCGRect:[pageView convertRect:[rect CGRectValue] fromView:pageTextView]]];
        }
        return ret;
    }
    return nil;
}

- (NSString *)eucSelector:(EucSelector *)selector accessibilityLabelForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;
{
    EucPageView *pageView = (EucPageView *)(_pageTurningView.currentPageView);
    UIView<EucPageTextView> *pageTextView = pageView.pageTextView;
    return [pageTextView accessibilityLabelForElementWithIdentifier:elementId
                                              ofBlockWithIdentifier:blockId];
}

- (NSArray *)_highlightRangesForIndexPointRange:(THPair *)indexPointRange
{
    NSArray *ret = nil;
    
    id<EucBookViewDelegate> delegate = self.delegate;
    if([delegate respondsToSelector:@selector(bookView:highlightRangesFromPoint:toPoint:)]) {
        NSArray *eucRanges = [delegate bookView:self
                       highlightRangesFromPoint:indexPointRange.first
                                        toPoint:indexPointRange.second];
        if(eucRanges.count) {
            ret = eucRanges;
        }
    }    
    
    return ret;
}

- (NSArray *)highlightRangesForEucSelector:(EucSelector *)selector
{
    NSArray *selectorRanges = nil;

    NSArray *eucRanges = [_pageTurningView.currentPageView.layer valueForKey:@"EucBookViewHighlightRanges"];
    if(eucRanges.count) {
        selectorRanges = [eucRanges valueForKey:@"selectorRange"];
    }

    return selectorRanges;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == _selector &&
       [keyPath isEqualToString:@"tracking"]) {
        _pageTurningView.userInteractionEnabled = !((EucSelector *)object).isTracking;
    }
}

- (UIColor *)eucSelector:(EucSelector *)selector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange
{    
    UIColor *ret = nil;
    for(EucHighlightRange *highlightRange in [_pageTurningView.currentPageView.layer valueForKey:@"EucBookViewHighlightRanges"]) {
        if([[highlightRange selectorRange] isEqual:selectedRange]) {
            NSParameterAssert(!_rangeBeingEdited);
            ret = [highlightRange.color colorWithAlphaComponent:0.3f];
            _rangeBeingEdited = [highlightRange copy];
            break;
        }
    }
    
    [self refreshHighlights];
    
    return ret;
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange
{
    if(toRange && ![fromRange isEqual:toRange]) {
        NSParameterAssert([[_rangeBeingEdited selectorRange] isEqual:fromRange]);
        EucHighlightRange *fromHighlightRange = _rangeBeingEdited;
        EucHighlightRange *toHighlightRange = [_rangeBeingEdited copy];
        
        toHighlightRange.startPoint.block = [toRange.startBlockId integerValue];
        toHighlightRange.startPoint.word = [toRange.startElementId integerValue];
        toHighlightRange.startPoint.element = 0;
        
        toHighlightRange.endPoint.block = [toRange.endBlockId integerValue];
        toHighlightRange.endPoint.word = [toRange.endElementId integerValue];
        toHighlightRange.endPoint.element = 0;
        
        if([self.delegate respondsToSelector:@selector(bookView:didUpdateHighlightAtRange:toRange:)]) {
            [self.delegate bookView:self didUpdateHighlightAtRange:fromHighlightRange toRange:toHighlightRange];
        }
        
        [toHighlightRange release];
    }
    
    [_rangeBeingEdited release];
    _rangeBeingEdited = nil;

    self.selector.selectedRange = nil;
    [self refreshHighlights];
}

- (void)refreshHighlights
{
    EucPageView *currentPageView = (EucPageView *)(_pageTurningView.currentPageView);

    if(_rangeBeingEdited) {  
        // We know that only the current page can be viewed, so only update it.
        [self _applyHighlightLayersToPageView:currentPageView refreshingFromBook:NO];
        [_pageTurningView refreshView:currentPageView];
    } else {
        EucBookViewHighlightSurroundingPageFlags surroundingPageFlags = [self _applyHighlightLayersToPageView:currentPageView refreshingFromBook:YES];
        [_pageTurningView refreshView:currentPageView];
        
        if(surroundingPageFlags != EucBookViewHighlightSurroundingPageFlagsNone) {
            NSArray *pageViews = _pageTurningView.pageViews;
            NSUInteger indexOfCurrentPage = [pageViews indexOfObject:currentPageView];
            
            if((surroundingPageFlags & EucBookViewHighlightSurroundingPageFlagsPrevious) == EucBookViewHighlightSurroundingPageFlagsPrevious &&
               indexOfCurrentPage >= 1) {
                EucPageView *pageView = [pageViews objectAtIndex:indexOfCurrentPage-1];
                [self _applyHighlightLayersToPageView:pageView refreshingFromBook:YES];
                [_pageTurningView refreshView:pageView];
            }
            if((surroundingPageFlags & EucBookViewHighlightSurroundingPageFlagsNext) == EucBookViewHighlightSurroundingPageFlagsNext &&
               indexOfCurrentPage < (pageViews.count - 1)) {
                EucPageView *pageView = [pageViews objectAtIndex:indexOfCurrentPage+1];
                [self _applyHighlightLayersToPageView:pageView refreshingFromBook:YES];
                [_pageTurningView refreshView:pageView];
            }
        }
    }
    [_pageTurningView drawView];
}

#pragma mark -
#pragma mark Toolbar

- (void)_addButtonToView:(UIView *)view 
          withImageNamed:(NSString *)name 
             centerPoint:(CGPoint)centerPoint 
                  target:(id)target
                  action:(SEL)action
                   title:(NSString *)title
{
    UIButton *button;
    button = [[UIButton alloc] init];
    button.showsTouchWhenHighlighted = YES;
    UIImage *image = [UIImage imageNamed:name];
    [button setImage:image forState:UIControlStateNormal];
    [button sizeToFit];
    CGSize boundsSize = button.bounds.size;
    if((((NSInteger)boundsSize.width) % 2) == 1) {
        centerPoint.x += 0.5;
    }
    if((((NSInteger)boundsSize.height) % 2) == 1) {
        centerPoint.y += 0.5;
    }
    button.center = centerPoint;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [button setAccessibilityLabel:title];
    
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
    
    [button release];    
}

- (UIToolbar *)bookNavigationToolbar
{
    CGRect bounds = [self bounds];

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;
    
    [toolbar sizeToFit];
    CGFloat toolbarMarginHeight = 12.0f;
    CGFloat toolbarNonMarginHeight = [toolbar frame].size.height - 2.0f * toolbarMarginHeight;
    
    CGFloat toolbarHeight = floorf(toolbarMarginHeight * 3.0f + 2.0f * toolbarNonMarginHeight);
    [toolbar setFrame:CGRectMake(bounds.origin.x,
                                 bounds.origin.y + bounds.size.height - toolbarHeight,
                                 bounds.size.width,
                                 toolbarHeight)];
    [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
    
    CGRect toolbarBounds = toolbar.bounds;
    CGFloat centerY = floorf(toolbarMarginHeight * 2.0f + toolbarNonMarginHeight * 1.5f);
    
    UIFont *pageNumberFont = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] + 1];
    _pageNumberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _pageNumberLabel.font = pageNumberFont;
    _pageNumberLabel.textAlignment = UITextAlignmentCenter;
    _pageNumberLabel.adjustsFontSizeToFitWidth = YES;
    
    _pageNumberLabel.backgroundColor = [UIColor clearColor];
    _pageNumberLabel.textColor = [UIColor whiteColor];
    _pageNumberLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    _pageNumberLabel.shadowOffset = CGSizeMake(0, -1);
    
    _pageNumberLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGRect pageNumberFrame = _pageNumberLabel.frame;
    pageNumberFrame.size.width = ceilf(toolbarBounds.size.width / 3.0f);
    pageNumberFrame.size.height = ceilf(toolbarBounds.size.height / 3.0f);
    if(!((NSUInteger)pageNumberFrame.size.width % 2) == 0) {
        --pageNumberFrame.size.width;
    }
    if(!((NSUInteger)pageNumberFrame.size.height % 2) == 0) {
        --pageNumberFrame.size.height;
    }
    _pageNumberLabel.frame = pageNumberFrame;
    _pageNumberLabel.center = CGPointMake(toolbarBounds.size.width * 0.5f, centerY);
    [toolbar addSubview:_pageNumberLabel];
    
    /*[self _addButtonToView:toolbar 
     withImageNamed:@"UIBarButtonBugButton.png" 
     centerPoint:CGPointMake(floorf(toolbarBounds.size.width * 0.075f), centerY)
     target:self
     action:@selector(_bugButtonTapped)];
     */
    [self _addButtonToView:toolbar 
            withImageNamed:@"UIBarButtonSystemItemRewind.png" 
               centerPoint:CGPointMake(floorf(toolbarBounds.size.width * 0.3f), centerY)
                    target:self
                    action:@selector(jumpBackwards)
                     title:@"Jump Backwards"];
    
    /*
     [self _addButtonToView:toolbar 
     withImageNamed:@"UIBarButtonSystemItemTrash.png" 
     centerPoint:CGPointMake(ceilf(toolbarBounds.size.width * 0.935f) , centerY)
     target:self
     action:@selector(_trashButtonTapped)];
     */
    
    _pageSlider = [[THScalableSlider alloc] initWithFrame:toolbarBounds];
    _pageSlider.backgroundColor = [UIColor clearColor];	
    _pageSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
    leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:0];
    [_pageSlider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
    
    UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
    if([[UIDevice currentDevice] compareSystemVersion:@"3.2"] >= NSOrderedSame) {
        // Work around a bug in 3.2 (+?) where the cap is used as a right cap in
        // the image when it's used in a slider.
        rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:rightCapImage.size.width - 1 topCapHeight:0];
    } else {
        rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    }
    [_pageSlider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
    
    UIImage *thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob.png"];
    [_pageSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [_pageSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
    
    [_pageSlider addTarget:self action:@selector(_pageSliderSlid:) forControlEvents:UIControlEventValueChanged];
    
    CGRect pageSliderFrame = CGRectZero;
    pageSliderFrame.size.width = toolbarBounds.size.width - 18;
    pageSliderFrame.size.height = thumbImage.size.height + 8;
    _pageSlider.frame = pageSliderFrame;
    
    _pageSlider.center = CGPointMake(toolbarBounds.size.width / 2.0f, toolbarMarginHeight + toolbarNonMarginHeight * 0.5f);
    
    pageSliderFrame = _pageSlider.frame;

    UIScreen *mainScreen = [UIScreen mainScreen];
    
    UIProgressView *behindSlider = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    CGRect behindSliderFrame = behindSlider.frame;
    if([mainScreen respondsToSelector:@selector(scale)] && mainScreen.scale == 2.0f) {
        behindSliderFrame.size.width = pageSliderFrame.size.width - 2;
    } else {
        behindSliderFrame.size.width = pageSliderFrame.size.width - 4;
    }
    behindSlider.frame = behindSliderFrame;
    behindSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    behindSlider.contentMode = UIViewContentModeRedraw; // Seems strange that thi is necessary - without it, the view is just stretched on resize.
    behindSlider.isAccessibilityElement = NO;
    
    CGPoint pageSliderCenter = _pageSlider.center;
    if([mainScreen respondsToSelector:@selector(scale)] && mainScreen.scale == 2.0f) {
        pageSliderCenter.y += 1.5f;
    } else {
        pageSliderCenter.y += 1.5f;
    }
    behindSlider.center = pageSliderCenter;
    
    [toolbar addSubview:behindSlider];
    [behindSlider release];
    
    [toolbar addSubview:_pageSlider];
    
    _pageSlider.minimumValue = 0;
    _pageSlider.maximumValue = [_pageLayoutController globalPageCount] - 1;
    //_pageSlider.maximumValue = NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + _book.bytesInReadableSections + _book.licenceAppendix.bytesInReadableSections;
    _pageSlider.scaledValue = self.pageNumber;
    
    [_pageSlider layoutSubviews];
    
    //if(_bookIndex.isFinal) {
    _paginationIsComplete = YES;
    //}
    [self _updateSliderByteToPageRatio];    
    [self _updatePageNumberLabel];

    [self _addButtonToView:toolbar 
            withImageNamed:@"UIBarButtonSystemItemFastForward.png" 
               centerPoint:CGPointMake(ceilf(toolbarBounds.size.width * 0.7f), centerY)
                    target:self
                    action:@selector(jumpForwards)
                     title:@"Jump Forwards"];    
    
    return toolbar;
}    


- (void)_updatePageNumberLabel
{
    if(_pageNumberLabel) {
        float sliderByte = _pageSlider.scaledValue;
        NSInteger pageNumber;
        if(_pageSliderIsTracking) {
            pageNumber = [self _sliderByteToPage:sliderByte];
        } else {
            pageNumber = self.pageNumber;
        }
        _pageNumberLabel.text = [_pageLayoutController pageDescriptionForPageNumber:pageNumber];
        
        if(_pageSliderIsTracking) {
            // If the slider is tracking, we'll place a HUD view showing chapter
            // and page information about the drag point.
            
            const CGFloat margin = 6.0f;
            const CGFloat width = 184.0f;
            
            UILabel *pageSliderNumberLabel = nil;
            UILabel *pageSliderChapterLabel = nil;
            if(!_pageSliderTrackingInfoView) {
                pageSliderChapterLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                pageSliderChapterLabel.backgroundColor = [UIColor clearColor];
                pageSliderChapterLabel.textColor = [UIColor whiteColor];
                pageSliderChapterLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
                pageSliderChapterLabel.shadowOffset = CGSizeMake(0, -1);
                pageSliderChapterLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] * (1.0f + (1.0f / 3.0f))];
                pageSliderChapterLabel.textAlignment = UITextAlignmentCenter;
                pageSliderChapterLabel.tag = 1;
                
                pageSliderChapterLabel.text = @"Hg";
                
                [pageSliderChapterLabel sizeToFit];
                CGRect pageSliderChapterLabelFrame = pageSliderChapterLabel.frame;
                pageSliderChapterLabelFrame.size.width = width - 2 * margin;
                pageSliderChapterLabelFrame.origin.x = margin;
                pageSliderChapterLabelFrame.origin.y = margin;
                pageSliderChapterLabel.frame = pageSliderChapterLabelFrame;
                pageSliderChapterLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                
                pageSliderNumberLabel = [pageSliderChapterLabel copyWithCoder];
                pageSliderNumberLabel.tag = 2;
                
                CGRect pageSliderNumberLabelFrame = pageSliderNumberLabel.frame;
                pageSliderNumberLabelFrame.origin.y += pageSliderChapterLabelFrame.size.height;
                pageSliderNumberLabel.frame = pageSliderNumberLabelFrame;
                
                _pageSliderTrackingInfoView = [[THRoundRectView alloc] initWithFrame:CGRectMake(0, 0, width, 2 * margin + pageSliderChapterLabelFrame.size.height + pageSliderNumberLabelFrame.size.height)];
                _pageSliderTrackingInfoView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
                ((THRoundRectView *)_pageSliderTrackingInfoView).cornerRadius = 10.0f;
                
                [_pageSliderTrackingInfoView addSubview:pageSliderChapterLabel];
                [_pageSliderTrackingInfoView addSubview:pageSliderNumberLabel];
                
                [_pageTurningView addSubview:_pageSliderTrackingInfoView];
                [_pageSliderTrackingInfoView centerInSuperview];
                
                [pageSliderChapterLabel release];
                [pageSliderNumberLabel release];
            } else {
                pageSliderChapterLabel = (UILabel *)[_pageSliderTrackingInfoView viewWithTag:1];
                pageSliderNumberLabel = (UILabel *)[_pageSliderTrackingInfoView viewWithTag:2];
            }
            
            NSString *chapterTitle = [_pageLayoutController presentationNameAndSubTitleForSectionUuid:[_pageLayoutController sectionUuidForPageNumber:pageNumber]].first;
            
            pageSliderChapterLabel.text = chapterTitle;
            pageSliderNumberLabel.text = _pageNumberLabel.text;
            
            // Nicely size the view to accomodate longer names;
            CGRect viewBounds = _pageTurningView.bounds;
            CGSize allowedSize = viewBounds.size;
            allowedSize.width -= 12 * margin;
            
            CGFloat pageSliderChapterLabelWantsWidth = [pageSliderChapterLabel sizeThatFits:allowedSize].width;
            CGFloat pageSliderNumberLabelWantsWidth = [pageSliderNumberLabel sizeThatFits:allowedSize].width;
            
            CGRect frame = _pageSliderTrackingInfoView.frame;
            frame.size.width = MAX(pageSliderNumberLabelWantsWidth, pageSliderChapterLabelWantsWidth) + 4 * margin;
            frame.size.width = MAX(width, frame.size.width);
            frame.size.width = MIN(allowedSize.width + 4 * margin, frame.size.width);
            frame.origin.x = floorf((viewBounds.size.width - frame.size.width) / 2);
            _pageSliderTrackingInfoView.frame = frame;
            
            if(!chapterTitle) {
                // If there's no title, we center the "X of X" vertically
                [pageSliderNumberLabel centerInSuperview];
            } else {
                // Otherwise, place it below the chapter title.
                CGRect pageSliderNumberLabelFrame = pageSliderNumberLabel.frame;
                CGRect pageSliderChapterLabelFrame = pageSliderChapterLabel.frame;
                CGFloat wantedOriginY = pageSliderChapterLabelFrame.origin.y + pageSliderChapterLabelFrame.size.height;
                if(pageSliderNumberLabelFrame.origin.y != wantedOriginY) {
                    pageSliderNumberLabelFrame.origin.y = wantedOriginY;
                    pageSliderNumberLabel.frame = pageSliderNumberLabelFrame;
                }
            }
        } else {
            // The slider is not dragging, remove the HUD display if it's there.
            if(_pageSliderTrackingInfoView) {
                [_pageSliderTrackingInfoView removeFromSuperview];
                [_pageSliderTrackingInfoView release];
                _pageSliderTrackingInfoView = nil;
            }
        }
    }
}


- (void)_pageSliderSlid:(THScalableSlider *)sender
{
    if(!sender.isTracking) {
        if(!_pageSliderIsTracking) {
            _pageSliderIsTracking = YES; // We get a non-tracking event as the
            // first event of a drag too, so ignore 
            // it.
        } else {
            // After delay so that the UI gets redrawn with the slider knob in its
            // final position and the page number label updated before we begin
            // the process of setting the page (which takes long enough that if
            // we do it here, there's a noticable delay in the UI updating).
            _pageSliderIsTracking = NO;
            float sliderByte = sender.scaledValue;
            [_pageSlider setScaledValue:[self _pageToSliderByte:[self _sliderByteToPage:sliderByte]] animated:NO]; // To avoid jerkiness later.
            [self performSelector:@selector(_afterPageSliderSlid:) withObject:sender afterDelay:0];
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        }
    } else {
        [self _updatePageNumberLabel];
    }
}


- (void)_afterPageSliderSlid:(THScalableSlider *)sender
{
    [self _goToPageNumberSavingJump:[self _sliderByteToPage:sender.scaledValue] animated:YES];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

#pragma mark Rework below to allow pagination again!

- (void)_updateSliderByteToPageRatio
{
    _sliderByteToPageRatio = 1;
    _pageSlider.maximumValue = [_pageLayoutController globalPageCount] - 1;
    _pageSlider.maximumAvailable = [_pageLayoutController globalPageCount];
    /*
     if(_paginationIsComplete) {
     _sliderByteToPageRatio = (CGFloat)(NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + _book.bytesInReadableSections + _book.licenceAppendix.bytesInReadableSections) / 
     (CGFloat)(1 + _bookIndex.lastPageNumber + _licenceAppendixIndex.lastPageNumber);
     _pageSlider.maximumAvailable = -1;
     } else {
     _sliderByteToPageRatio = (CGFloat)(NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + (_bookIndex.lastOffset - _book.firstSection.startOffset)  + _book.licenceAppendix.bytesInReadableSections) / 
     (CGFloat)(1 + _bookIndex.lastPageNumber + _licenceAppendixIndex.lastPageNumber);
     _pageSlider.maximumAvailable =  [self _pageToSliderByte:_bookIndex.lastPageNumber];
     }*/
}

- (NSInteger)_sliderByteToPage:(float)byte
{
    NSInteger page = (NSInteger)floorf(byte / _sliderByteToPageRatio);
    //page -= 1;
    page += 1;
    return page;
}

- (float)_pageToSliderByte:(NSInteger)page
{
    //page += 1;
    page -= 1;
    return ceilf((float)page * _sliderByteToPageRatio);
}

- (void)_bookPaginationComplete:(NSNotification *)notification
{
    _paginationIsComplete = YES;
    
    [self _updateSliderByteToPageRatio];
    [self _updatePageNumberLabel];
    
    //NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    //[defaultCenter removeObserver:self name:BookPaginationProgressNotification object:nil];
    //   [defaultCenter removeObserver:self name:BookPaginationCompleteNotification object:nil];                
}

- (void)_bookPaginationProgress:(NSNotification *)notification
{
    [self _updateSliderByteToPageRatio];
    [self _updatePageNumberLabel];
}

@end
