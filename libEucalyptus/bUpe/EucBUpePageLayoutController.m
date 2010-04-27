//
//  EucBUpePageLayoutController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBUpePageLayoutController.h"
#import "EucBUpeBook.h"
#import "EucBUpePageTextView.h"

#import "EucBookIndex.h"
#import "EucBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "EucFilteredBookPageIndex.h"
#import "EucPageView.h"

#import "THPair.h"
#import "THLog.h"
#import "THNSStringAdditions.h"

#import "VCTitleCase.h"

#import <pthread.h>

@implementation EucBUpePageLayoutController

@synthesize book = _book;
@synthesize fontPointSize = _fontPointSize;
@synthesize globalPageCount = _globalPageCount;

- (id)initWithBook:(EucBUpeBook *)book fontPointSize:(CGFloat)pointSize
{
    if((self = [super init])) {
        _book = [book retain];   
        _bookIndex = [[_book bookIndex] retain];
        [self setFontPointSize:pointSize];        
    }
    return self;
}

- (void)dealloc
{
    [_book release];
    [_currentBookPageIndex release];
    [_bookIndex release];
    
    [super dealloc];
}

- (NSArray *)availablePointSizes
{
    return _bookIndex.pageIndexPointSizes;
}

- (void)setFontPointSize:(CGFloat)pointSize
{
    CGFloat difference = CGFLOAT_MAX;
    EucFilteredBookPageIndex *foundIndex = nil;
    for(EucFilteredBookPageIndex *index in _bookIndex.pageIndexes) {
        CGFloat thisDifference = fabsf(index.pointSize - pointSize);
        if(thisDifference < difference) {
            difference = thisDifference;
            foundIndex = index;
        }
    }
    if(foundIndex != _currentBookPageIndex) {
        [_currentBookPageIndex release];
        _currentBookPageIndex = [foundIndex retain];
        _fontPointSize = _currentBookPageIndex.pointSize;  
        _globalPageCount = _currentBookPageIndex.filteredLastPageNumber;
    }
}

- (NSString *)pageDescriptionForPageNumber:(NSUInteger)pageNumber
{
    NSString *text = nil;
    if(pageNumber == 1) {
        text = NSLocalizedString(@"Cover", @"Page number display below page slider");
    } else {
        text = [NSString stringWithFormat:NSLocalizedString(@"%ld of %ld", @"Page number display below page slider"), (long)pageNumber-1, (long)_globalPageCount-1];
    }
    return text;
}

- (NSString *)displayPageNumberForPageNumber:(NSUInteger)pageNumber
{
    NSString *text = nil;
    if(pageNumber > 1) {
        text = [NSString stringWithFormat:@"%ld", (long)pageNumber-1];
    }
    return text;
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)pageNumber
{
    NSString *lastSection = nil;
    EucBookPageIndexPoint *pageIndexPoint = [_currentBookPageIndex filteredIndexPointForPage:pageNumber+1];
    for(THPair *navPoint in _book.navPoints) {
        NSString *identifier = navPoint.second;
        if([[_book indexPointForId:identifier] compare:pageIndexPoint] != NSOrderedDescending) {
            break;
        } else {
            lastSection = identifier;
        }
    }
    return lastSection;
}

- (NSString *)sectionNameForPageNumber:(NSUInteger)pageNumber
{
    NSString *lastName = nil;
    EucBookPageIndexPoint *pageIndexPoint = [_currentBookPageIndex filteredIndexPointForPage:pageNumber+1];
    for(THPair *navPoint in _book.navPoints) {
        NSString *identifier = navPoint.second;
        if([[_book indexPointForId:identifier] compare:pageIndexPoint] != NSOrderedDescending) {
            break;
        } else {
            lastName = navPoint.first;
        }
    }
    return lastName;
}

- (NSString *)nameForSectionUuid:(NSString *)uuid
{
    for(THPair *navPoint in _book.navPoints) {
        NSString *identifier = navPoint.second;
        if([identifier compare:uuid] == NSOrderedSame) {
            return navPoint.first;
        }
    }
    return nil;
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)uuid
{
    return [THPair pairWithFirst:[[[[self nameForSectionUuid:uuid] lowercaseString] titlecaseString] stringWithSmartQuotes] second:nil];
}

- (NSArray *)sectionUuids
{
    NSMutableArray *ret = [NSMutableArray array];
    
    for(THPair *section in _book.navPoints) {
        [ret addObject:section.second];
    }
    
    return ret;    
}

- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber
{
    NSUInteger previousPageNumber = 1;
    return previousPageNumber;
}

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber
{    
    NSUInteger nextPageNumber = _globalPageCount;
    return nextPageNumber;
}

- (NSUInteger)pageNumberForSectionUuid:(NSString *)uuid
{
    return [_currentBookPageIndex pageForIndexPoint:[_book indexPointForId:uuid]];
}

- (THPair *)viewAndIndexPointForPageNumber:(NSUInteger)pageNumber 
                           withPageTexture:(UIImage *)pageTexture 
                                    isDark:(BOOL)dark
{
    THPair *ret = nil;
    if(pageNumber >= 1 && pageNumber <= _globalPageCount) {
        EucBookPageIndexPoint *indexPoint = [_currentBookPageIndex filteredIndexPointForPage:pageNumber];
        EucPageView *pageView = [[self class] blankPageViewForPointSize:_currentBookPageIndex.pointSize 
                                                        withPageTexture:pageTexture];
        pageView.titleLinePosition = EucPageViewTitleLinePositionTop;
        pageView.titleLineContents = EucPageViewTitleLineContentsTitleAndPageNumber;
        pageView.bookTextView.backgroundIsDark = dark;
        pageView.pageNumber = [self displayPageNumberForPageNumber:pageNumber];
        pageView.title = _book.title;
        if([_book respondsToSelector:@selector(fullBleedPageForIndexPoint:)]) {
            pageView.fullBleed = [_book fullBleedPageForIndexPoint:indexPoint];
        }
        
        [pageView.bookTextView layoutPageFromPoint:indexPoint
                                            inBook:_book];

        ret = [THPair pairWithFirst:pageView second:indexPoint];
    } 
    
    THLog(@"Returning page %ld, %@", (long)pageNumber, ret);
    
    return ret;
}

- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    NSUInteger ret = [_currentBookPageIndex filteredPageForIndexPoint:indexPoint];
    if(ret == 0) {
        ret = 1;
    }
    
    THLog(@"Looked up page number %ld for index point %@", (long)ret, indexPoint);
    
    return ret;
}

+ (EucPageView *)blankPageViewForPointSize:(CGFloat)pointSize withPageTexture:(UIImage *)pageTexture
{
    if(!pageTexture) {
        static UIImage *sPaperImage = nil;
        if(!sPaperImage) {
            sPaperImage = [[UIImage imageNamed:@"BookPaperWhite.png"] retain];
        }
        pageTexture = sPaperImage;
    }
    
    return [[[EucPageView alloc] initWithPointSize:pointSize 
                                         titleFont:@"Georgia" 
                               titleFontStyleFlags:THStringRendererFontStyleFlagItalic
                                    pageNumberFont:@"Georgia"
                          pageNumberFontStyleFlags:THStringRendererFontStyleFlagRegular
                                    titlePointSize:pointSize
                                       pageTexture:pageTexture
                                     textViewClass:[EucBUpePageTextView class]] autorelease];
}

- (BOOL)viewShouldBeRigid:(UIView *)view
{
    return [(EucPageView *)view pageNumber] != nil;
}

@end
