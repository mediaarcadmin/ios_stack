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
#import "BlioBookmark.h"
#import "BlioParagraphSource.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucHighlightRange.h>
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucCSSIntermediateDocument.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/THPair.h>

@interface BlioFlowView ()
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, assign) NSInteger pageNumber;
- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;
@end

@implementation BlioFlowView

@synthesize paragraphSource = _paragraphSource;
@synthesize delegate = _delegate;

@synthesize pageCount = _pageCount;
@synthesize pageNumber = _pageNumber;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated 
{
    if((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        EucBUpeBook *eucBook = nil;
        
        self.opaque = YES;
        
        if([aBook textFlowFilename]) {
            eucBook = [[BlioFlowEucBook alloc] initWithBlioBook:aBook];
            eucBook.persistsPositionAutomatically = NO;
            eucBook.cacheDirectoryPath = [aBook.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusCache"];
        } else {
            eucBook = [aBook.ePubBook retain];
        }
        
        if(eucBook) {
            self.paragraphSource = aBook.paragraphSource;

            if((_eucBookView = [[EucBookView alloc] initWithFrame:self.bounds book:eucBook])) {
                _eucBookView.delegate = self;
                _eucBookView.allowsSelection = YES;
                _eucBookView.selectorDelegate = self;
                if(animated) {
                    _eucBookView.appearAtCoverThenOpen = YES;
                }
                [self goToBookmarkPoint:aBook.implicitBookmarkPoint animated:NO];
                
                [_eucBookView addObserver:self forKeyPath:@"pageCount" options:NSKeyValueObservingOptionInitial context:NULL];
                [_eucBookView addObserver:self forKeyPath:@"pageNumber" options:NSKeyValueObservingOptionInitial context:NULL];
                
                [self addSubview:_eucBookView];
            }
            [eucBook release];
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
    [_paragraphSource release];
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
    return [[UIScreen mainScreen] bounds];
}

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    
    EucBookPageIndexPoint *eucIndexPoint = [indexPoint copy];
    
    // EucIndexPoint words start with word 0 == before the first word,
    // but Blio thinks that the first word is at 0.  This is a bit lossy,
    // but there's not much else we can do.
    if(eucIndexPoint.word == 0) {
        eucIndexPoint.element = 0;
    } else {
        eucIndexPoint.word -= 1;
    }
    
    if(![_eucBookView.book isKindOfClass:[BlioFlowEucBook class]]) {
        ret.layoutPage = eucIndexPoint.source;
        ret.blockOffset = eucIndexPoint.block;
        ret.wordOffset = eucIndexPoint.word;
        ret.elementOffset = eucIndexPoint.element;
    } else {
        if(eucIndexPoint.source == 0) {
            // This is the cover section.
            ret.layoutPage = 1;
            ret.blockOffset = 0;
            ret.wordOffset = 0;
            ret.elementOffset = 0;
        } else {
            NSUInteger indexes[2] = { eucIndexPoint.source - 1, [EucCSSIntermediateDocument documentTreeNodeKeyForKey:eucIndexPoint.block]};
            NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];                         
            BlioBookmarkPoint *bookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:indexPath wordOffset:eucIndexPoint.word];
            [indexPath release];
            
            ret.layoutPage = bookmarkPoint.layoutPage;
            ret.blockOffset = bookmarkPoint.blockOffset;
            ret.wordOffset = bookmarkPoint.wordOffset;
            ret.elementOffset = eucIndexPoint.element;
        }
    }
    
    [eucIndexPoint release];
    
    return [ret autorelease];    
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
    
    if(![_eucBookView.book isKindOfClass:[BlioFlowEucBook class]]) {
        eucIndexPoint.source = bookmarkPoint.layoutPage;
        eucIndexPoint.block = bookmarkPoint.blockOffset;
        eucIndexPoint.word = bookmarkPoint.wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
    } else {
        NSIndexPath *paragraphID = nil;
        uint32_t wordOffset = 0;
        
        if(bookmarkPoint.layoutPage == 1 && bookmarkPoint.blockOffset == 0 && bookmarkPoint.wordOffset == 0 && bookmarkPoint.elementOffset == 0) {
            // This is the start of the book.  Leave the eucIndexPoint empty
            // so that we refer to the the cover.
        } else {
            [self.paragraphSource bookmarkPoint:bookmarkPoint
                                  toParagraphID:&paragraphID 
                                     wordOffset:&wordOffset];
            eucIndexPoint.source = [paragraphID indexAtPosition:0] + 1;
            eucIndexPoint.block = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:[paragraphID indexAtPosition:1]];
            eucIndexPoint.word = wordOffset;
            eucIndexPoint.element = bookmarkPoint.elementOffset;
        }
    }    
    
    // EucIndexPoint words start with word 0 == before the first word,
    // but Blio thinks that the first word is at 0.  This is a bit lossy,
    // but there's not much else we can do.    
    eucIndexPoint.word += 1;
    
    return [eucIndexPoint autorelease];        
}

- (BlioBookmarkPoint *)currentBookmarkPoint
{
    return [self bookmarkPointFromBookPageIndexPoint:[_eucBookView.book currentPageIndexPoint]];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    [_eucBookView goToIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint] animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [_eucBookView pageNumberForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    return [_eucBookView goToUuid:uuid animated:animated];
}

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;
{
    return [_eucBookView goToPageNumber:pageNumber animated:animated];
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
            ret = [NSString stringWithFormat:@"Page %@ - %@", pageStr, chapter.first];
        } else {
            ret = [NSString stringWithFormat:@"%@", chapter.first];
        }
    } else {
        if (pageStr) {
            ret = [NSString stringWithFormat:@"Page %@ of %lu", pageStr, (unsigned long)self.pageCount];
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
    return _pageViewIsTurning;
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    [_eucBookView highlightWordAtIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}


#pragma mark -
#pragma mark EucBookView delegate methods

- (void)bookViewPageTurnWillBegin:(EucBookView *)bookView
{
    _pageViewIsTurning = YES;
}

- (void)bookViewPageTurnDidEnd:(EucBookView *)bookView
{
    _pageViewIsTurning = NO;
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

@end
