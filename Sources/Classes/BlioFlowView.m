//
//  BlioFlowView.m
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowView.h"
#import "BlioFlowAnalyzeOperation.h"
#import "BlioFlowEucBook.h"
#import "BlioBookManager.h"
#import "BlioBookmark.h"
#import "BlioParagraphSource.h"
#import "BlioEPubBook.h"
#import "levenshtein_distance.h"
#import <libEucalyptus/EucBook.h>
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucHighlightRange.h>
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucCSSIntermediateDocument.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/EucOTFIndex.h>
#import <libEucalyptus/EucPageOptions.h>
#import <libEucalyptus/THPair.h>
#import "NSArray+BlioAdditions.h"

@interface BlioFlowView ()
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, retain) BlioBookmarkPoint *currentBookmarkPoint;
@property (nonatomic, retain) BlioBookmarkPoint *lastSavedPoint;
- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;

@property (nonatomic, retain) NSArray *fontSizes;

- (EucBookPageIndexPoint *)bookPageIndexPointForPercentage:(float)percentage;
- (NSString *)blioPageLabelForBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;

@end

@implementation BlioFlowView

@dynamic delegate; // Provided by BlioSelectableBookView superclass.

@synthesize bookID = _bookID;

@synthesize paragraphSource = _paragraphSource;

@synthesize currentBookmarkPoint = _currentBookmarkPoint;
@synthesize lastSavedPoint = _lastSavedPoint;

@synthesize fontSizes = _fontSizes;

+ (NSSet *)keyPathsForValuesAffectingFontSizeIndex
{
    return [NSSet setWithObject:@"eucBookView.fontPointSize"];
}

+ (BOOL)automaticallyNotifiesObserversOfFontSizeIndex
{
    return NO;
}

- (id)initWithFrame:(CGRect)frame
           delegate:(id<BlioBookViewDelegate>)aDelegate
             bookID:(NSManagedObjectID *)aBookID 
           animated:(BOOL)animated 
{
    if((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
        self.opaque = YES;
        self.bookID = aBookID;
        
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        _eucBook = [[bookManager checkOutEucBookForBookWithID:aBookID] retain];
        
        if(_eucBook) {            
            self.delegate = aDelegate;
            self.paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:aBookID];

            if([_eucBook isKindOfClass:[BlioFlowEucBook class]]) {
                BlioTextFlow *textFlow = [bookManager checkOutTextFlowForBookWithID:aBookID];
                _textFlowFlowTreeKind = (BlioTextFlowFlowTreeKind)(textFlow.flowTreeKind);
                [bookManager checkInTextFlowForBookWithID:aBookID];
            }            
            
            _fontSizes = [[self.delegate fontSizesForBlioBookView:self] retain];
            
            if((_eucBookView = [[EucBookView alloc] initWithFrame:self.bounds 
                                                             book:(EucEPubBook *)_eucBook
                                                   fontPointSizes:_fontSizes])) {
                _eucBookView.delegate = self;
                _eucBookView.allowsSelection = YES;
                _eucBookView.selectorDelegate = self;
                _eucBookView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _eucBookView.vibratesOnInvalidTurn = NO;
                                
                if (!animated) {
                    BlioBookmarkPoint *implicitPoint = [bookManager bookWithID:aBookID].implicitBookmarkPoint;
                    [self goToBookmarkPoint:implicitPoint animated:NO saveToHistory:NO];
                }
                
                [_eucBookView addObserver:self forKeyPath:@"currentPageIndexPoint" options:0 context:NULL];
                [_eucBookView addObserver:self forKeyPath:@"currentPageIndex" options:0 context:NULL];
                [_eucBookView addObserver:self forKeyPath:@"selector.trackingStage" options:0 context:NULL];

                [self addSubview:_eucBookView];
            }
			
        }
        
        if(!_eucBookView) {
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_eucBookView removeObserver:self forKeyPath:@"selector.trackingStage"];
    [_eucBookView removeObserver:self forKeyPath:@"currentPageIndex"];
    [_eucBookView removeObserver:self forKeyPath:@"currentPageIndexPoint"];
    [_eucBookView release];
     
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    if(_paragraphSource) {
        [_paragraphSource release];
        [bookManager checkInParagraphSourceForBookWithID:_bookID];   
    }
    if(_eucBook) {
        [_eucBook release];
        [bookManager checkInEucBookForBookWithID:_bookID];  
    }
    
    [_fontSizes release];
    
    [_bookID release];
	[_lastSavedPoint release]; _lastSavedPoint = nil;
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"currentPageIndex"] || 
       [keyPath isEqualToString:@"currentPageIndexPoint"]) {
        self.currentBookmarkPoint = [self bookmarkPointFromBookPageIndexPoint:_eucBookView.currentPageIndexPoint];
    } else if([keyPath isEqualToString:@"selector.trackingStage"]) {
        if(_eucBookView.selector.trackingStage == EucSelectorTrackingStageFirstSelection) {
            [self.delegate hideToolbars];
        }
    }
}

- (BOOL)wantsTouchesSniffed 
{
    return NO;
}

- (CGRect)firstPageRect
{
    return _eucBookView.contentRect;
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return _eucBookView;
}

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return [_eucBook bookmarkPointFromBookPageIndexPoint:indexPoint];
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBook bookPageIndexPointFromBookmarkPoint:bookmarkPoint];
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    [self pushCurrentBookmarkPoint];
	if (animated) {
		_suppressHistory = YES;
	}
    [_eucBookView goToUuid:uuid animated:animated];
}

- (NSString *)currentUuid
{
    return [_eucBookView previousNavPointUuid];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkPoint animated:animated saveToHistory:YES];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save
{
	if (save) {
		[self pushCurrentBookmarkPoint];
		if (animated) {
			_suppressHistory = YES;
		}
	} else {
		_suppressHistory = YES;
	}
    
    EucBookPageIndexPoint *eucIndexPoint;
    if([_eucBookView.book isKindOfClass:[BlioFlowEucBook class]] &&
       _textFlowFlowTreeKind == BlioTextFlowFlowTreeKindFlow &&
       bookmarkPoint.layoutPage == 1 && bookmarkPoint.blockOffset == 0 && 
       bookmarkPoint.wordOffset == 0 && bookmarkPoint.elementOffset == 0) {
        // This is the start of the book.  Leave the eucIndexPoint empty
        // so that we refer to the the cover.
        eucIndexPoint = [[[EucBookPageIndexPoint alloc] init] autorelease];
    } else {
        eucIndexPoint = [self bookPageIndexPointFromBookmarkPoint:bookmarkPoint];
    }
    
    [_eucBookView goToIndexPoint:eucIndexPoint animated:animated];
}

- (EucBookPageIndexPoint *)bookPageIndexPointForPercentage:(float)percentage
{
    EucBookPageIndexPoint *pageIndexPoint = nil;
    NSUInteger pageCount = _eucBookView.pageCount;
    if(pageCount != EucOTFIndexUndeterminedPageIndex) {
        NSUInteger pageIndex = roundf((pageCount - 1) * percentage);
        pageIndexPoint = [_eucBookView indexPointForPageIndex:pageIndex];
    } else {
        pageIndexPoint = [(id<EucBook>)_eucBook estimatedIndexPointForPercentage:percentage];
    }    
    return pageIndexPoint;
}

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage
{
    return [self bookmarkPointFromBookPageIndexPoint:[self bookPageIndexPointForPercentage:percentage]];
}

- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    float ret = 0.0f;
    NSUInteger pageCount = _eucBookView.pageCount;
    if(pageCount != 0) {
        if(pageCount == EucOTFIndexUndeterminedPageIndex) {
            ret = [(id<EucBook>)_eucBook estimatedPercentageForIndexPoint:_eucBookView.currentPageIndexPoint];
        } else {
            NSUInteger pageIndex = [_eucBookView pageIndexForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
            ret = (float)pageIndex / (float)pageCount;
        }
    }
    return ret;
}

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBookView displayPageNumberForPageIndex:[_eucBookView pageIndexForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]]];
}

- (BOOL)currentPageContainsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBookView currentPageContainsIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}

- (BlioBookmarkRange *)bookmarkRangeForCurrentPage
{
    EucBookPageIndexPointRange *visibleIndexPointRange = [_eucBookView visibleIndexPointRange];
    
    BlioBookmarkPoint *startPoint = [self bookmarkPointFromBookPageIndexPoint:visibleIndexPointRange.startPoint];
    BlioBookmarkPoint *endPoint = [self bookmarkPointFromBookPageIndexPoint:visibleIndexPointRange.endPoint];

    BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
    bookmarkRange.startPoint = startPoint;
    bookmarkRange.endPoint = endPoint;    
    
    return [bookmarkRange autorelease];
}

- (NSString *)pageLabelForPercentage:(float)percenatage
{
    return [self blioPageLabelForBookPageIndexPoint:[self bookPageIndexPointForPercentage:percenatage]];
}

- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self blioPageLabelForBookPageIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}

- (NSString *)blioPageLabelForBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    NSString *pageStr = nil;
    NSUInteger pageIndex = [_eucBookView pageIndexForIndexPoint:indexPoint];
    if(pageIndex != EucOTFIndexUndeterminedPageIndex) {
        pageStr = [_eucBookView displayPageNumberForPageIndex:[_eucBookView pageIndexForIndexPoint:indexPoint]];
    }
    
    NSString *chapterName = [_eucBookView presentationNameAndSubTitleForIndexPoint:indexPoint].first;
    
    NSString *pageLabel = nil;
    
    if (chapterName) {
        if (pageStr) {
            pageLabel = [NSString stringWithFormat:NSLocalizedString(@"Page %@ \u2013 %@",@"Page label with page number and chapter (flow view)"), pageStr, chapterName];
        } else {
            pageLabel = [NSString stringWithFormat:@"%@", chapterName];
        }
    } else {
        if (pageStr) {
            NSUInteger pageCount = _eucBookView.pageCount;
            if(pageCount != EucOTFIndexUndeterminedPageIndex) {
                pageLabel = [NSString stringWithFormat:NSLocalizedString(@"Page %@ of %lu",@"Page label X of Y (page number of page count) (flow view)"), pageStr, pageCount];
            } else {
                pageLabel = [NSString stringWithFormat:NSLocalizedString(@"Page %@",@"Page label X (page number, page count unknown) (flow view)"), pageStr];
            }
        } else {
            pageLabel = [[BlioBookManager sharedBookManager] bookWithID:self.bookID].title;
        }
    }     
    
    return pageLabel;
}

+ (NSArray *)preAvailabilityOperations 
{
    BlioFlowAnalyzeOperation *preParseOp = [[BlioFlowAnalyzeOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

- (BOOL)toolbarShowShouldBeSuppressed
{
    return _pageViewIsTurning || self.selector.tracking || self.selector.selectedRange;
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    [self highlightWordAtBookmarkPoint:bookmarkPoint saveToHistory:NO];
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint saveToHistory:(BOOL)save
{
   
	if (save) {
		[self pushCurrentBookmarkPoint];
	} else if (bookmarkPoint) {
		if (![self currentPageContainsBookmarkPoint:bookmarkPoint]) {
			[self pushCurrentBookmarkPoint];
		}
	}	
	_suppressHistory = YES;

	if (bookmarkPoint) {
		[_eucBookView highlightWordAtIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint] animated:YES];
	} else {
		[_eucBookView highlightWordAtIndexPoint:nil animated:YES];
		_suppressHistory = NO;
	}
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)blioRange animated:(BOOL)animated {
    [self highlightWordsInBookmarkRange:blioRange animated:animated saveToHistory:NO];
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)blioRange animated:(BOOL)animated saveToHistory:(BOOL)save
{
    if (save) {
		[self pushCurrentBookmarkPoint];
	} else if (blioRange) {
		if (![self currentPageContainsBookmarkPoint:blioRange.startPoint]) {
			[self pushCurrentBookmarkPoint];
		}
	}
	
	if (animated) {
		_suppressHistory = YES;
	}
	
	if (blioRange) {
		EucHighlightRange *eucRange = [[EucHighlightRange alloc] init];
		eucRange.startPoint = [self bookPageIndexPointFromBookmarkPoint:blioRange.startPoint];
		eucRange.endPoint = [self bookPageIndexPointFromBookmarkPoint:blioRange.endPoint];
		[_eucBookView highlightWordsInHighlightRange:eucRange animated:animated];
		[eucRange release];
	} else {
		[_eucBookView highlightWordAtIndexPoint:nil animated:YES];
		_suppressHistory = NO;
	}
}

- (UIImage *)dimPageImage
{
    UIImage *ret = nil;
    [_eucBookView abortAllAnimation];
    _eucBookView.dimQuotient = 1.0f;
    ret = _eucBookView.currentPageImage;
    _eucBookView.dimQuotient = 0.0f;
    return ret;
}

#pragma mark -
#pragma mark Back Button History

- (void)pushCurrentBookmarkPoint {
	BlioBookmarkPoint *bookmarkPoint = [self currentBookmarkPoint];
	
    if(!bookmarkPoint) {
        // We're at the start of a newly opened book.
        bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
        bookmarkPoint.layoutPage = 1;
    }
    
	if (self.lastSavedPoint) {
		if ([self.lastSavedPoint compare:bookmarkPoint] != NSOrderedSame) {
			[self.delegate pushBookmarkPoint:self.lastSavedPoint];
		}
	} else {
		[self.delegate pushBookmarkPoint:bookmarkPoint];
	}
	
	self.lastSavedPoint = nil;

}

#pragma mark -
#pragma mark EucBookView delegate methods

- (void)bookViewPageTurnWillBegin:(EucBookView *)bookView
{
    if(UIAccessibilityIsVoiceOverRunning == nil ||
       !UIAccessibilityIsVoiceOverRunning()) {
        [self.delegate hideToolbars];
    }

    _pageViewIsTurning = YES;
	if (!_suppressHistory) {
		self.lastSavedPoint = [self currentBookmarkPoint];
	}
}

- (void)bookViewPageTurnDidEnd:(EucBookView *)bookView
{
    _pageViewIsTurning = NO;
	
	if (!_suppressHistory) {
		[self pushCurrentBookmarkPoint];
	}
	
	_suppressHistory = NO;
    
    [self.delegate pageTurnDidComplete];
}

- (BOOL)bookViewToolbarsVisible:(EucBookView *)bookView
{
    return self.delegate.toolbarsVisible;
}

- (CGRect)bookViewNonToolbarRect:(EucBookView *)bookView
{
    return self.delegate.nonToolbarRect;
}

- (NSArray *)bookView:(EucBookView *)bookView highlightRangesFromPoint:(EucBookPageIndexPoint *)startPoint toPoint:(EucBookPageIndexPoint *)endPoint
{
    NSArray *ret = nil;
    
    BlioBookmarkRange *blioPageRange = [[BlioBookmarkRange alloc] init];
    blioPageRange.startPoint = [self bookmarkPointFromBookPageIndexPoint:startPoint];
    blioPageRange.endPoint = [self bookmarkPointFromBookPageIndexPoint:endPoint];
    NSArray *blioRanges = [self.delegate rangesToHighlightForRange:blioPageRange];
    [blioPageRange release];
    
    NSUInteger count = blioRanges.count;
    if(count) {
        NSMutableArray *eucRanges = [[NSMutableArray alloc] initWithCapacity:count];
        for(BlioBookmarkRange *blioRange in blioRanges) {
            EucHighlightRange *eucRange = [[EucHighlightRange alloc] init];
            eucRange.startPoint = [self bookPageIndexPointFromBookmarkPoint:blioRange.startPoint];
            eucRange.endPoint = [self bookPageIndexPointFromBookmarkPoint:blioRange.endPoint];
            eucRange.color = blioRange.color;
            [eucRanges addObject:eucRange];
            [eucRange release];
        }
        ret = [eucRanges autorelease];
     }
    
    return ret;
}

- (BOOL)bookView:(EucBookView *)bookView shouldHandleTapOnHyperlink:(NSURL *)link
{
    BOOL handled = NO;
    if([link.scheme isEqualToString:@"textflow"]) {
        NSString *internalURI = link.relativeString;
        
        if([_eucBook isKindOfClass:[BlioFlowEucBook class]]) {
            BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
            BlioTextFlow *textFlow = [bookManager checkOutTextFlowForBookWithID:self.bookID];
            BlioTextFlowReference *reference = [textFlow referenceForReferenceId:internalURI];
            [bookManager checkInTextFlowForBookWithID:self.bookID];
            
            if (reference) {
                BlioBookmarkPoint *bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
                bookmarkPoint.layoutPage = reference.pageIndex + 1;

                NSDictionary *idToIndexPoint = [(EucEPubBook *)_eucBook idToIndexPoint];
                
                NSArray *longKeys = [idToIndexPoint allKeys];
                NSMutableArray *shortKeys = [NSMutableArray arrayWithCapacity:[longKeys count]];
                for (NSString *longKey in longKeys) {
                    NSRange firstHash = [longKey rangeOfString:@"#"];
                    NSString *shortKey = longKey;
                    if ((firstHash.location != NSNotFound) && (firstHash.location < ([longKey length] - 1))) {
                        shortKey = [longKey substringFromIndex:firstHash.location + 1];
                    }
                    [shortKeys addObject:shortKey];
                }
                
                NSString *matchKey = [shortKeys longestComponentizedMatch:[reference referenceId] componentsSeperatedByString:@"/" forKeyPath:@"self"];
          
                if (matchKey) {
                    NSUInteger keyIndex = [shortKeys indexOfObject:matchKey];
                    [self goToUuid:[longKeys objectAtIndex:keyIndex] animated:YES];
                    handled = YES;
                } else {
                    // Handle failure cases by going straight to the page
                    [self goToBookmarkPoint:bookmarkPoint animated:YES];
                    handled = YES;
                }
            }
        }
    }
        
    return !handled;
}

- (void)toggleToolbarsIfNoSelection
{
    if(!self.selector.selectedRange) {
        [self.delegate toggleToolbars];
    }
}

- (void)bookView:(EucBookView *)bookView unhandledTapAtPoint:(CGPoint)point{
    if(!self.selector.selectedRange) {
        // Wait until the next event look cycle in case this is a click that causes something to be selected.
        [self performSelector:@selector(toggleToolbarsIfNoSelection) withObject:nil afterDelay:0];
    } 
}

#pragma mark -
#pragma mark BlioSelectableBookView overrides

- (EucSelector *)selector
{
    return _eucBookView.selector;
}

- (void)refreshHighlights 
{
    return [_eucBookView refreshHighlights];
}

- (BlioBookmarkRange *)bookmarkRangeFromIndexPointRange:(EucBookPageIndexPointRange *)indexPointRange
{
    BlioBookmarkPoint *startPoint = [self bookmarkPointFromBookPageIndexPoint:indexPointRange.startPoint];
    BlioBookmarkPoint *endPoint = [self bookmarkPointFromBookPageIndexPoint:indexPointRange.endPoint];
        
    BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
    bookmarkRange.startPoint = startPoint;
    bookmarkRange.endPoint = endPoint;    
    
    return [bookmarkRange autorelease];
}

- (BlioBookmarkRange *)bookmarkRangeFromHighlightRange:(EucHighlightRange *)range
{
    BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
    bookmarkRange.startPoint = [self bookmarkPointFromBookPageIndexPoint:range.startPoint];
    bookmarkRange.endPoint = [self bookmarkPointFromBookPageIndexPoint:range.endPoint];    
    bookmarkRange.color = range.color;
    return [bookmarkRange autorelease];
}


- (BlioBookmarkRange *)selectedRange 
{
    EucBookPageIndexPointRange *selectedRange = (EucBookPageIndexPointRange *)[super selectedRange];
        
    if(selectedRange) {
        return [self bookmarkRangeFromIndexPointRange:selectedRange];
    } else {
        EucBookPageIndexPoint *indexPoint = [_eucBookView currentPageIndexPoint];
        BlioBookmarkPoint *pagePoint = [self bookmarkPointFromBookPageIndexPoint:indexPoint];
        
        BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
        bookmarkRange.startPoint = pagePoint;
        bookmarkRange.endPoint = pagePoint;
        
        return [bookmarkRange autorelease];
    }
}

- (void)bookView:(EucBookView *)bookView didUpdateHighlightAtRange:(EucHighlightRange *)fromRange toRange:(EucHighlightRange *)toRange
{
    if([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)]) {
        [self.delegate updateHighlightAtRange:[self bookmarkRangeFromHighlightRange:fromRange]
                                      toRange:[self bookmarkRangeFromHighlightRange:toRange]
                                    withColor:toRange.color];
    }
}

- (UIColor *)eucSelector:(EucSelector *)selector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange
{
    [self.delegate hideToolbars];
    return [_eucBookView eucSelector:selector willBeginEditingHighlightWithRange:selectedRange];
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange
{
    return [_eucBookView eucSelector:selector didEndEditingHighlightWithRange:fromRange movedToRange:toRange];
}

#pragma mark -
#pragma mark Visual Properties

- (NSUInteger)fontSizeIndex
{
    CGFloat actualFontSize = _eucBookView.fontPointSize;
    CGFloat bestDifference = CGFLOAT_MAX;
    NSUInteger bestFontSizeIndex = 0;
    NSArray *fontSizeNumbers = _fontSizes;
    
    NSUInteger fontSizeCount = fontSizeNumbers.count;
    for(NSUInteger i = 0; i < fontSizeCount; ++i) {
        CGFloat thisDifference = fabsf(((NSNumber *)[fontSizeNumbers objectAtIndex:i]).floatValue - actualFontSize);
        if(thisDifference < bestDifference) {
            bestDifference = thisDifference;
            bestFontSizeIndex = i;
        }
    }
   return bestFontSizeIndex;
}

- (void)setFontSizeIndex:(NSUInteger)newSize
{
	[_eucBookView highlightWordAtIndexPoint:nil animated:YES];
    _eucBookView.fontPointSize = ((NSNumber *)[_fontSizes objectAtIndex:newSize]).integerValue;
}

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark
{
    return [_eucBookView setPageTexture:pageTexture isDark:isDark];
}


#pragma mark -
#pragma mark Accessibility/TTS interaction.

- (BOOL)isAccessibilityElement 
{
    if([self.delegate audioPlaying]) {
        return YES;
    } else {
        return [super isAccessibilityElement];
    }
}

- (CGRect)accessibilityFrame {
    if([self.delegate audioPlaying]) {
        return CGRectZero;
    } else {
        return [super accessibilityFrame];
    }
}

- (NSInteger)accessibilityElementCount {
    if([self.delegate audioPlaying]) {
        return 0;
    } else {
        return [super accessibilityElementCount];
    }
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    if([self.delegate audioPlaying]) {
        return nil;
    } else {
        return [super accessibilityElementAtIndex:index];
    }
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    if([self.delegate audioPlaying]) {
        return NSNotFound;
    } else {
        return [super indexOfAccessibilityElement:element];
    }
}

- (void)toolbarsWillHide
{
    [_eucBookView toolbarsWillHide];
}

- (void)toolbarsWillShow
{
    [_eucBookView toolbarsWillShow];
}

- (void)decrementPage
{
    [_eucBookView turnToPreviousPage];
}

- (void)incrementPage
{
    [_eucBookView turnToNextPage];
}

- (NSString *)fontName
{
    return _fontName;
}
- (void)setFontName:(NSString *)fontName
{
    if(!_fontName || ![fontName isEqualToString:_fontName]) {
        NSDictionary *oldPageOptions = _eucBookView.pageOptions;
        NSDictionary *fontMap = [NSDictionary dictionaryWithContentsOfURL:
                                 [[NSBundle mainBundle] URLForResource:@"FlowViewEucPageOptions"
                                                         withExtension:@"plist"]];
        
        NSDictionary *fontPageOptions = [fontMap objectForKey:fontName];
        if(fontPageOptions) {
            NSMutableDictionary *newPageOptions = oldPageOptions ? [oldPageOptions mutableCopy] : [[NSMutableDictionary alloc] init];
            [newPageOptions addEntriesFromDictionary:fontPageOptions];
            _eucBookView.pageOptions = newPageOptions;
            [newPageOptions release];
        } else {
            NSLog(@"Could not find font page options for font \"%@\" - ignoring", fontName);
        }
        
    }
}

- (BlioJustification)justification
{
    switch([[_eucBookView.pageOptions objectForKey:EucPageOptionsJustificationKey] integerValue]) {
        default:
        case EucJustificationOriginal:
            return kBlioJustificationOriginal;
        case EucJustificationOverrideToLeft:
            return kBlioJustificationLeft;
        case EucJustificationOverrideToFull:
            return kBlioJustificationFull;
    }
}

- (void)setJustification:(BlioJustification)justification;
{
    EucJustification eucJustification;
    switch(justification) {
        default:
        case kBlioJustificationOriginal:
            eucJustification = EucJustificationOriginal;
            break;
        case kBlioJustificationLeft:
            eucJustification = EucJustificationOverrideToLeft;
            break;
        case kBlioJustificationFull:
            eucJustification = EucJustificationOverrideToFull;
            break;
    }
    
    NSDictionary *oldPageOptions = _eucBookView.pageOptions;
    if(eucJustification != [[oldPageOptions objectForKey:EucPageOptionsJustificationKey] integerValue]) {
        NSMutableDictionary *newPageOptions = oldPageOptions ? [oldPageOptions mutableCopy] : [[NSMutableDictionary alloc] init];
        [newPageOptions setObject:[NSNumber numberWithInteger:eucJustification]
                           forKey:EucPageOptionsJustificationKey];
        _eucBookView.pageOptions = newPageOptions;
        [newPageOptions release];
    }
    
}

- (BlioTwoUp)twoUp
{
    return _eucBookView.twoUpLandscape ? kBlioTwoUpLandscape : kBlioTwoUpNever;
}

- (void)setTwoUp:(BlioTwoUp)twoUp;
{
    _eucBookView.twoUpLandscape = twoUp != kBlioTwoUpNever;
}

- (BOOL)shouldTapZoom
{
    return !_eucBookView.useContinuousReadingAccessibility;
}

- (void)setShouldTapZoom:(BOOL)shouldTapZoom
{
    _eucBookView.useContinuousReadingAccessibility = !shouldTapZoom;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [_eucBookView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [_eucBookView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


@end