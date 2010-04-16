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

@end

@implementation BlioFlowView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

@synthesize paragraphSource = _paragraphSource;


- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucBUpeLocalBookReference<EucBook> *eucBook = nil;
    
    if([aBook textFlowFilename]) {
        eucBook = [[BlioFlowEucBook alloc] initWithBlioBook:aBook];
    } else if([aBook epubFilename]) {
        eucBook = [[EucBUpeBook alloc] initWithPath:[aBook ePubPath]];
    }
    
    self.paragraphSource = aBook.paragraphSource;
    
    if(!eucBook) {
        [self release];
        return nil;
    }
        
    [eucBook setCacheDirectoryPath:[aBook.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusPageIndexes"]];
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds book:eucBook])) {
        self.allowsSelection = YES;
        self.selectorDelegate = self;
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

- (BlioBookmarkAbsolutePoint *)pageBookmarkPoint
{
    BlioBookmarkAbsolutePoint *ret = [[BlioBookmarkAbsolutePoint alloc] init];
    EucBookPageIndexPoint *eucIndexPoint = ((EucBUpeBook *)self.book).currentPageIndexPoint;
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
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
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
        [self.paragraphSource bookmarkPoint:[BlioBookmarkPoint bookmarkPointWithAbsolutePoint:bookmarkPoint]
                              toParagraphID:&paragraphID 
                                 wordOffset:&wordOffset];
        eucIndexPoint.source = [paragraphID indexAtPosition:0] + 1;
        eucIndexPoint.block = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:[paragraphID indexAtPosition:1]];
        eucIndexPoint.word = wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
        
        if(eucIndexPoint.source == 1 && eucIndexPoint.block == 0 && eucIndexPoint.word == 0 && eucIndexPoint.element == 0) {
            eucIndexPoint.source = 0;
        }
    }    
    
    [self goToIndexPoint:eucIndexPoint animated:animated];
    
    [eucIndexPoint release];    
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    NSInteger ret = 0;
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];

    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
        eucIndexPoint.source = bookmarkPoint.layoutPage;
        eucIndexPoint.block = bookmarkPoint.blockOffset;
        eucIndexPoint.word = bookmarkPoint.wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
    } else {
        NSIndexPath *paragraphID = nil;
        uint32_t wordOffset = 0;
        [self.paragraphSource bookmarkPoint:[BlioBookmarkPoint bookmarkPointWithAbsolutePoint:bookmarkPoint]
                              toParagraphID:&paragraphID 
                                 wordOffset:&wordOffset];
        eucIndexPoint.source = [paragraphID indexAtPosition:0] + 1;
        eucIndexPoint.block = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:[paragraphID indexAtPosition:1]];
        eucIndexPoint.word = wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
        
        if(eucIndexPoint.source == 1 && eucIndexPoint.block == 0 && eucIndexPoint.word == 0 && eucIndexPoint.element == 0) {
            eucIndexPoint.source = 0;
        }
    }
    
    ret = [self pageNumberForIndexPoint:eucIndexPoint];
    
    [eucIndexPoint release];
    
    return ret;
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
