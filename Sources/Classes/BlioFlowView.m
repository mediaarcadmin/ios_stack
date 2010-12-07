//
//  BlioFlowView.m
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowView.h"
#import "BlioFlowPaginateOperation.h"
#import "BlioFlowEucBook.h"
#import "BlioBookManager.h"
#import "BlioBookmark.h"
#import "BlioParagraphSource.h"
#import "levenshtein_distance.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucHighlightRange.h>
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucCSSIntermediateDocument.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/THPair.h>
#import "NSArray+BlioAdditions.h"

@interface BlioFlowView ()
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, retain) BlioBookmarkPoint *lastSavedPoint;
- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;
@end

@implementation BlioFlowView

@synthesize bookID = _bookID;

@synthesize paragraphSource = _paragraphSource;
@synthesize delegate = _delegate;

@synthesize pageCount = _pageCount;
@synthesize pageNumber = _pageNumber;
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
            
            if((_eucBookView = [[EucBookView alloc] initWithFrame:self.bounds book:_eucBook])) {
                _eucBookView.delegate = self;
                _eucBookView.allowsSelection = YES;
                _eucBookView.selectorDelegate = self;
                _eucBookView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _eucBookView.vibratesOnInvalidTurn = NO;
                
                if (!animated) {
                    [self goToBookmarkPoint:[bookManager bookWithID:bookID].implicitBookmarkPoint animated:NO saveToHistory:NO];
                }
                
                [_eucBookView addObserver:self forKeyPath:@"pageCount" options:NSKeyValueObservingOptionInitial context:NULL];
                [_eucBookView addObserver:self forKeyPath:@"pageNumber" options:NSKeyValueObservingOptionInitial context:NULL];
                
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
    [_eucBookView removeObserver:self forKeyPath:@"pageCount"];
    [_eucBookView removeObserver:self forKeyPath:@"pageNumber"];
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
    if([keyPath isEqualToString:@"pageNumber"]) {
        self.pageNumber = _eucBookView.pageNumber;
    } else { //if([keyPath isEqualToString:@"pageCount"] ) {
        self.pageCount = _eucBookView.pageCount;
    }
}


- (BOOL)wantsTouchesSniffed 
{
    return YES;
}

- (CGRect)firstPageRect
{
    return _eucBookView.contentRect;
}

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return [_eucBook bookmarkPointFromBookPageIndexPoint:indexPoint];
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBook bookPageIndexPointFromBookmarkPoint:bookmarkPoint];
}

- (BlioBookmarkPoint *)currentBookmarkPoint
{
    return [self bookmarkPointFromBookPageIndexPoint:[_eucBookView.book currentPageIndexPoint]];
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

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBookView pageNumberForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    [self pushCurrentBookmarkPoint];
	if (animated) {
		_suppressHistory = YES;
	}
    [_eucBookView goToUuid:uuid animated:animated];
}

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated saveToHistory:(BOOL)save;
{
	if (save) {
		[self pushCurrentBookmarkPoint];
		if (animated) {
			_suppressHistory = YES;
		}
	} else {
		_suppressHistory = YES;
	}
    [_eucBookView goToPageNumber:pageNumber animated:animated];
}

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;
{
    [self goToPageNumber:pageNumber animated:animated saveToHistory:YES];
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return _eucBookView.contentsDataSource;
}

- (NSString *)pageLabelForPageNumber:(NSInteger)page 
{
    NSString *ret = nil;
    
    id<EucBookContentsTableViewControllerDataSource> contentsSource = self.contentsDataSource;
    NSString* section = [contentsSource sectionUuidForPageNumber:page];
    THPair* chapter = [contentsSource presentationNameAndSubTitleForSectionUuid:section];
    NSString* pageStr = [contentsSource displayPageNumberForPageNumber:page];
    
    if (section && chapter.first) {
        if (pageStr) {
            ret = [NSString stringWithFormat:NSLocalizedString(@"Page %@ \u2013 %@",@"Page label with page number and chapter"), pageStr, chapter.first];
        } else {
            ret = [NSString stringWithFormat:@"%@", chapter.first];
        }
    } else {
        if (pageStr) {
            ret = [NSString stringWithFormat:NSLocalizedString(@"Page %@ of %lu",@"Page label X of Y (page number of page count) in BlioFlowView"), pageStr, (unsigned long)self.pageCount];
        } else {
            ret = [_eucBookView.book title];
        }
    } // of no section name
    
    return ret;
}

+ (NSArray *)preAvailabilityOperations 
{
    BlioFlowPaginateOperation *preParseOp = [[BlioFlowPaginateOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

- (BOOL)toolbarShowShouldBeSuppressed
{
    return _pageViewIsTurning || self.selector.tracking;
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    [self highlightWordAtBookmarkPoint:bookmarkPoint saveToHistory:NO];
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint saveToHistory:(BOOL)save;
{
   
	if (save) {
		[self pushCurrentBookmarkPoint];
	} else if (bookmarkPoint) {
		NSInteger currentPage = [self pageNumber];
        NSInteger bookmarkedPage = [self pageNumberForBookmarkPoint:bookmarkPoint];
		if (currentPage != bookmarkedPage) {
			[self pushCurrentBookmarkPoint];
		}
	}	
	_suppressHistory = YES;

	if (bookmarkPoint) {
		[_eucBookView highlightWordAtIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint] animated:YES];
	} else {
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
		NSInteger currentPage = [self pageNumber];
        NSInteger bookmarkedPage = [self pageNumberForBookmarkPoint:blioRange.startPoint];
		if (currentPage != bookmarkedPage) {
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
		_suppressHistory = NO;
	}
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
    [_delegate cancelPendingToolbarShow];
    [_delegate hideToolbars];

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
    [_delegate cancelPendingToolbarShow];

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
    [_delegate cancelPendingToolbarShow];
    return [_eucBookView eucSelector:selector willBeginEditingHighlightWithRange:selectedRange];
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange
{
    [_delegate cancelPendingToolbarShow];
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