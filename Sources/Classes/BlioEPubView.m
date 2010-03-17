//
//  BlioEPubView.m
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubView.h"
#import "BlioEPubPaginateOperation.h"
#import "BlioBookmark.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucMenuItem.h>

@implementation BlioEPubView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucBUpeBook *aEPubBook = [[EucBUpeBook alloc] initWithPath:[aBook ePubPath]];
    if(nil == aEPubBook) {
        [self release];
        return nil;
    }
    
    aEPubBook.cacheDirectoryPath = [aBook.bookCacheDirectory stringByAppendingPathComponent:@"ePubPaginationIndexes"];
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds book:aEPubBook])) {
        self.allowsSelection = YES;
        self.selectorDelegate = self;
        if (animated) self.appearAtCoverThenOpen = YES;
    }
    [aEPubBook release];
    
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
    
    EucBookPageIndexPoint *eucIndexPoint = ((EucBUpeBook *)self.book).currentPageIndexPoint;
    ret.layoutPage = eucIndexPoint.source;
    ret.ePubParagraphId = eucIndexPoint.block;
    ret.ePubWordOffset = eucIndexPoint.word;
    ret.ePubHyphenOffset = eucIndexPoint.element;
        
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
    eucIndexPoint.source = bookmarkPoint.layoutPage;
    eucIndexPoint.block = bookmarkPoint.ePubParagraphId;
    eucIndexPoint.word = bookmarkPoint.ePubWordOffset;
    eucIndexPoint.element = bookmarkPoint.ePubHyphenOffset;
    
    [self goToIndexPoint:eucIndexPoint animated:animated];
    
    [eucIndexPoint release];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
    eucIndexPoint.source = bookmarkPoint.layoutPage;
    eucIndexPoint.block = bookmarkPoint.ePubParagraphId;
    eucIndexPoint.word = bookmarkPoint.ePubWordOffset;
    eucIndexPoint.element = bookmarkPoint.ePubHyphenOffset;
    
    NSInteger ret = [self pageNumberForIndexPoint:eucIndexPoint];
    
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
    BlioEPubPaginateOperation *preParseOp = [[BlioEPubPaginateOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

@end
