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
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucMenuItem.h>

@implementation BlioFlowView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucBUpeLocalBookReference<EucBook> *eucBook = nil;
    
    if([aBook textFlowFilename]) {
        eucBook = [[BlioFlowEucBook alloc] initWithBlioBook:aBook];
    } else if([aBook epubFilename]) {
        eucBook = [[EucBUpeBook alloc] initWithPath:[aBook ePubPath]];
    }
    
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
    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
        EucBookPageIndexPoint *eucIndexPoint = ((EucBUpeBook *)self.book).currentPageIndexPoint;
        ret.layoutPage = eucIndexPoint.source;
        ret.blockOffset = eucIndexPoint.block;
        ret.wordOffset = eucIndexPoint.word;
        ret.elementOffset = eucIndexPoint.element;
    } else {
        ret.layoutPage = 1;
    }
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = bookmarkPoint.layoutPage;
        eucIndexPoint.block = bookmarkPoint.blockOffset;
        eucIndexPoint.word = bookmarkPoint.wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
        
        [self goToIndexPoint:eucIndexPoint animated:animated];
        
        [eucIndexPoint release];
    }
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    NSInteger ret = 0;
    if(![self.book isKindOfClass:[BlioFlowEucBook class]]) {
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = bookmarkPoint.layoutPage;
        eucIndexPoint.block = bookmarkPoint.blockOffset;
        eucIndexPoint.word = bookmarkPoint.wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
        
        ret = [self pageNumberForIndexPoint:eucIndexPoint];
        
        [eucIndexPoint release];
    }
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
