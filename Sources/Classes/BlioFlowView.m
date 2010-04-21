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
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucCSSIntermediateDocument.h>

@interface BlioFlowView ()
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;
@end

@implementation BlioFlowView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

@synthesize paragraphSource = _paragraphSource;


- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucBUpeBook *eucBook = nil;
    
    if([aBook textFlowFilename]) {
        eucBook = [[BlioFlowEucBook alloc] initWithBlioBook:aBook];
    } else if([aBook epubFilename]) {
        eucBook = [[EucBUpeBook alloc] initWithPath:[aBook ePubPath]];
    }
    
    if(!eucBook) {
        [self release];
        return nil;
    }

    [eucBook setPersistsPositionAutomatically:NO];
    [eucBook setCacheDirectoryPath:[aBook.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusPageIndexes"]];
    
    self.paragraphSource = aBook.paragraphSource;

    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds book:eucBook])) {
        self.allowsSelection = YES;
        self.selectorDelegate = self;
        [self goToBookmarkPoint:aBook.implicitBookmarkPoint animated:NO];
        if (animated) self.appearAtCoverThenOpen = YES;
    }
    [eucBook release];
    
    return self;
}

- (void)dealloc
{
    [_paragraphSource release];
    [super dealloc];
}

- (BOOL)wantsTouchesSniffed {
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
    
    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
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
    
    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
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
    return [self bookmarkPointFromBookPageIndexPoint:[self.book currentPageIndexPoint]];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    [self goToIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint] animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self pageNumberForIndexPoint:[self bookPageIndexPointFromBookmarkPoint:bookmarkPoint]];
}

- (NSArray *)menuItemsForEucSelector:(EucSelector *)hilighter
{
    EucMenuItem *highlightItem = [[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Highlight", "\"Hilight\" option in popup menu in layout view")                                                              
                                                             action:@selector(highlight:)];
    EucMenuItem *addNoteItem = [[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu in layout view")                                                    
                                                           action:@selector(addNote:)];
    EucMenuItem *copyItem = [[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu in layout view")
                                                        action:@selector(copy:)];
    EucMenuItem *showWebToolsItem = [[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", "\"Tools\" option in popup menu in layout view")
                                                                action:@selector(showWebTools:)];
    
    NSArray *ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, copyItem, showWebToolsItem, nil];
    
    [highlightItem release];
    [addNoteItem release];
    [copyItem release];
    [showWebToolsItem release];
    
    return ret;
}

+ (NSArray *)preAvailabilityOperations {
    BlioFlowPaginateOperation *preParseOp = [[BlioFlowPaginateOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

@end
