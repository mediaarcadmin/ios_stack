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
#import "BlioBUpeBook.h"
#import "levenshtein_distance.h"
#import <libEucalyptus/EucBook.h>
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucHighlightRange.h>
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucCSSIntermediateDocument.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/EucOTFIndex.h>
#import <libEucalyptus/THPair.h>
#import "NSArray+BlioAdditions.h"

@interface BlioFlowView ()
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, retain) BlioBookmarkPoint *currentBookmarkPoint;
@property (nonatomic, retain) BlioBookmarkPoint *lastSavedPoint;
- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;
@end

@implementation BlioFlowView

@dynamic delegate; // Provided by BlioSelectableBookView superclass.

@synthesize bookID = _bookID;

@synthesize paragraphSource = _paragraphSource;

@synthesize currentBookmarkPoint = _currentBookmarkPoint;
@synthesize lastSavedPoint = _lastSavedPoint;

- (id)initWithFrame:(CGRect)frame
             bookID:(NSManagedObjectID *)bookID 
           animated:(BOOL)animated 
{
    if((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
        self.opaque = YES;
        self.bookID = bookID;
        
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        _eucBook = [[bookManager checkOutEucBookForBookWithID:bookID] retain];
        
        if(_eucBook) {            
            self.paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:bookID];

            if([_eucBook isKindOfClass:[BlioFlowEucBook class]]) {
                BlioTextFlow *textFlow = [bookManager checkOutTextFlowForBookWithID:bookID];
                _textFlowFlowTreeKind = textFlow.flowTreeKind;
                [bookManager checkInTextFlowForBookWithID:bookID];
            }            
            
            if((_eucBookView = [[EucBookView alloc] initWithFrame:self.bounds book:(EucBUpeBook *)_eucBook])) {
                _eucBookView.delegate = self;
                _eucBookView.allowsSelection = YES;
                _eucBookView.selectorDelegate = self;
                _eucBookView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _eucBookView.vibratesOnInvalidTurn = NO;
                
                if (!animated) {
                    [self goToBookmarkPoint:[bookManager bookWithID:bookID].implicitBookmarkPoint animated:NO saveToHistory:NO];
                }
                
                [_eucBookView addObserver:self forKeyPath:@"pageCount" options:NSKeyValueObservingOptionInitial context:NULL];
                [_eucBookView addObserver:self forKeyPath:@"currentPageIndexPoint" options:NSKeyValueObservingOptionInitial context:NULL];
                
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
    
    [_bookID release];
	[_lastSavedPoint release]; _lastSavedPoint = nil;
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"currentPageIndexPoint"]) {
        self.currentBookmarkPoint = [self bookmarkPointFromBookPageIndexPoint:_eucBookView.currentPageIndexPoint];
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

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage
{
    EucBookPageIndexPoint *pageIndexPoint = nil;
    NSUInteger pageCount = _eucBookView.pageCount;
    if(pageCount != EucOTFIndexUndeterminedPageIndex) {
        NSUInteger pageIndex = roundf((pageCount - 1) * percentage);
        pageIndexPoint = [_eucBookView indexPointForPageIndex:pageIndex];
    } else {
        pageIndexPoint = [(id<EucBook>)_eucBook estimatedIndexPointForPercentage:percentage];
    }    
    return [self bookmarkPointFromBookPageIndexPoint:pageIndexPoint];
}

- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    float ret = 0.0f;
    NSUInteger pageCount = _eucBookView.pageCount;
    if(pageCount != 0) {
        if(pageCount == EucOTFIndexUndeterminedPageIndex) {
            ret = [(id<EucBook>)_eucBook estimatedPercentageForIndexPoint:_eucBookView.currentPageIndexPoint];
        } else {
            NSUInteger pageIndex = _eucBookView.currentPageIndex;
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

- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBookView presentationNameAndSubTitleForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]].first;
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

                NSDictionary *idToIndexPoint = [(EucBUpeBook *)_eucBook idToIndexPoint];
                
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

- (void)bookView:(EucBookView *)bookView unhandledTapAtPoint:(CGPoint)point
{
    [self.delegate toggleToolbars];
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

- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    indexPoint.source = [_eucBookView.book currentPageIndexPoint].source;
    
    indexPoint.block = [range.startBlockId unsignedIntValue];
    indexPoint.word = [range.startElementId unsignedIntValue];
    BlioBookmarkPoint *startPoint = [self bookmarkPointFromBookPageIndexPoint:indexPoint];
    
    indexPoint.block = [range.endBlockId unsignedIntValue];
    indexPoint.word = [range.endElementId unsignedIntValue];
    BlioBookmarkPoint *endPoint = [self bookmarkPointFromBookPageIndexPoint:indexPoint];
    
    [indexPoint release];
    
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
    EucSelectorRange *selectedRange = [self.selector selectedRange];
        
    if(selectedRange) {        
        return [self bookmarkRangeFromSelectorRange:selectedRange];
    } else {
        EucBookPageIndexPoint *indexPoint = [_eucBookView.book currentPageIndexPoint];
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

- (CGFloat)fontPointSize
{
    return _eucBookView.fontPointSize;
}

- (void)setFontPointSize:(CGFloat)fontPointSize
{
	[_eucBookView highlightWordAtIndexPoint:nil animated:YES];
    _eucBookView.fontPointSize = fontPointSize;
}

- (UIImage *)pageTexture
{
    return _eucBookView.pageTexture;
}

- (BOOL)pageTextureIsDark
{
    return _eucBookView.pageTextureIsDark;
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

@end