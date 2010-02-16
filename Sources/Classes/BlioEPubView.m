//
//  BlioEPubView.m
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubView.h"
#import "BlioBookmark.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucEPubPageLayoutController.h>
#import <libEucalyptus/EucMenuItem.h>

@implementation BlioEPubView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucEPubBook *aEPubBook = [[EucEPubBook alloc] initWithPath:[aBook bookPath]];
    if(nil == aEPubBook) {
        [self release];
        return nil;
    }
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds book:aEPubBook])) {
        self.allowsSelection = YES;
        self.highlighterDelegate = self;
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

- (NSString *)_bookUuidFromEPubBook:(EucEPubBook *)book forLayoutPageNumber:(NSInteger)currentPage 
{
    // Check for suffix, because the UUIDs also include the filename
    // that the anchor is in (in ePub, multiple XHTML files can
    // be in one book).
    NSInteger bestPageNumber = 0;
    NSString *bestPageUuid = nil;
    for(NSString *prospectiveUuid in book.allUuids) {
        NSRange markerRange = [prospectiveUuid rangeOfString:@"#bliopage" options:NSBackwardsSearch];
        if(markerRange.location != NSNotFound) {
            NSUInteger startsAt = markerRange.location + markerRange.length;
            if(startsAt < prospectiveUuid.length) {
                NSString *pageNumberString = [prospectiveUuid substringFromIndex:markerRange.location + markerRange.length];
                NSInteger prospectivePageNumber = [pageNumberString integerValue];
                if(prospectivePageNumber <= currentPage && 
                   prospectivePageNumber > bestPageNumber) {
                    bestPageNumber = prospectivePageNumber;
                    bestPageUuid = prospectiveUuid;
                }
            }
        }
    }
    return bestPageUuid;
}


- (NSInteger)_bestLayoutPageNumber
{
    // Wow, this is pretty horrible.
    // The idea is to find either the first layout page anchor that falls
    // on the currently displayed page or, if there are none on the currently
    // displayed page, the most recent one.
    
    EucEPubBook *book = (EucEPubBook *)self.book;

    NSInteger currentPageNumber = self.pageNumber;
    NSString *bestUuid = nil;
    NSUInteger bestUuidOffset = 0;
    NSInteger bestEPubPageNumber = 0;
    
    for(NSString *prospectiveUuid in book.allUuids) {
        NSRange markerRange = [prospectiveUuid rangeOfString:@"#bliopage" options:NSBackwardsSearch];
        if(markerRange.location != NSNotFound) {
            NSUInteger thisByteOffset = [book byteOffsetForUuid:prospectiveUuid];
            
            if(bestEPubPageNumber == currentPageNumber) {
                if(bestUuidOffset > thisByteOffset && 
                   [_pageLayoutController pageNumberForSectionUuid:prospectiveUuid] == currentPageNumber) {
                    bestUuidOffset = thisByteOffset;
                    bestUuid = prospectiveUuid;
                }
            } else {
                if(bestUuidOffset < thisByteOffset) {
                    NSInteger prospectiveEPubPageNumber = [_pageLayoutController pageNumberForSectionUuid:prospectiveUuid];
                    if(prospectiveEPubPageNumber <= currentPageNumber && 
                       prospectiveEPubPageNumber > bestEPubPageNumber) {
                        bestEPubPageNumber = prospectiveEPubPageNumber;
                        bestUuidOffset = thisByteOffset;
                        bestUuid = prospectiveUuid;
                    }
                }
            }
        }
    }
    
    NSInteger bestPageNumber = 0;
    if(bestUuid) {
        NSRange markerRange = [bestUuid rangeOfString:@"#bliopage" options:NSBackwardsSearch];
        NSUInteger startsAt = markerRange.location + markerRange.length;
        if(startsAt < bestUuid.length) {
            NSString *pageNumberString = [bestUuid substringFromIndex:markerRange.location + markerRange.length];
            bestPageNumber = [pageNumberString integerValue];
        }
    }
    
    return bestPageNumber;
}

- (BlioBookmarkAbsolutePoint *)pageBookmarkPoint
{
    BlioBookmarkAbsolutePoint *ret = [[BlioBookmarkAbsolutePoint alloc] init];
    
    EucBookPageIndexPoint *eucIndexPoint = ((EucEPubBook *)self.book).currentPageIndexPoint;
    ret.ePubParagraphId = eucIndexPoint.startOfParagraphByteOffset;
    ret.ePubWordOffset = eucIndexPoint.startOfPageParagraphWordOffset;
    ret.ePubHyphenOffset = eucIndexPoint.startOfPageWordHyphenOffset;
    
    ret.layoutPage = [self _bestLayoutPageNumber];
    
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    if(bookmarkPoint.layoutPage && !bookmarkPoint.ePubWordOffset) {
        NSString *bestPageUuid = [self _bookUuidFromEPubBook:((EucEPubBook *)self.book)
                                         forLayoutPageNumber:bookmarkPoint.layoutPage];
        if(bestPageUuid) {
            return [self goToUuid:bestPageUuid animated:animated];
        }
    }
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
    eucIndexPoint.startOfParagraphByteOffset = bookmarkPoint.ePubParagraphId;
    eucIndexPoint.startOfPageParagraphWordOffset = bookmarkPoint.ePubWordOffset;
    eucIndexPoint.startOfPageWordHyphenOffset = bookmarkPoint.ePubHyphenOffset;
    
    [self goToIndexPoint:eucIndexPoint animated:animated];
    
    [eucIndexPoint release];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    if(bookmarkPoint.layoutPage && !bookmarkPoint.ePubWordOffset) {
        NSString *bestPageUuid = [self _bookUuidFromEPubBook:((EucEPubBook *)self.book)
                                         forLayoutPageNumber:bookmarkPoint.layoutPage];
        if(bestPageUuid) {
            return [self pageNumberForUuid:bestPageUuid];
        }
    }
    EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
    eucIndexPoint.startOfParagraphByteOffset = bookmarkPoint.ePubParagraphId;
    eucIndexPoint.startOfPageParagraphWordOffset = bookmarkPoint.ePubWordOffset;
    eucIndexPoint.startOfPageWordHyphenOffset = bookmarkPoint.ePubHyphenOffset;
    
    NSInteger ret = [self pageNumberForIndexPoint:eucIndexPoint];
    
    [eucIndexPoint release];
    
    return ret;
}


- (NSArray *)menuItemsForEucHighlighter:(EucHighlighter *)hilighter
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

@end
