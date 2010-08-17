//
//  EucBUpePageLayoutController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucConfiguration.h"

#import "EucBUpePageLayoutController.h"
#import "EucBUpeBook.h"
#import "EucBUpePageTextView.h"

#import "EucBookIndex.h"
#import "EucBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "EucFilteredBookPageIndex.h"
#import "EucPageView.h"
#import "EucChapterNameFormatting.h"

#import "THPair.h"
#import "THLog.h"
#import "THNSStringAdditions.h"

#import "VCTitleCase.h"

#import <pthread.h>

@implementation EucBUpePageLayoutController

@synthesize book = _book;
@synthesize pageSize = _pageSize;
@synthesize fontPointSize = _fontPointSize;
@synthesize globalPageCount = _globalPageCount;

- (id)initWithBook:(id<EucBook>)book 
          pageSize:(CGSize)pageSize
     fontPointSize:(CGFloat)pointSize
{
    if((self = [super init])) {
        _book = [book retain];
        _pageSize = pageSize;
        _bookIndex = [[_book bookIndex] retain];
        _bookIndex.pageSize = pageSize;
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
    NSUInteger bestIndex = NSUIntegerMax;
    CGFloat bestSize = CGFLOAT_MAX;
    CGFloat difference = CGFLOAT_MAX;
    
    NSUInteger index = 0;
    for(NSNumber *indexPointSize in _bookIndex.pageIndexPointSizes) {
        CGFloat size = [indexPointSize floatValue];
        CGFloat thisDifference = fabsf(pointSize - size);
        if(thisDifference < difference) {
            difference = thisDifference;
            bestIndex = index;
            bestSize = size;
        }
        ++index;
    }
    
    if(bestIndex != NSUIntegerMax) {
        _fontPointSize = bestSize;  
        [_currentBookPageIndex release];
        _currentBookPageIndex = [[_bookIndex.pageIndexes objectAtIndex:bestIndex] retain];
        _globalPageCount = _currentBookPageIndex.filteredLastPageNumber;
    }
}

- (void)setPageSize:(CGSize)pageSize
{
    if(!CGSizeEqualToSize(pageSize, _pageSize)) {
        _pageSize = pageSize;
        [_bookIndex setPageSize:pageSize];
        [self setFontPointSize:_fontPointSize];
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
        if([[_book indexPointForId:identifier] compare:pageIndexPoint] != NSOrderedAscending) {
            break;
        } else {
            lastSection = identifier;
        }
    }
    return lastSection;
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)uuid
{
    NSString *lastName = nil;
    for(THPair *navPoint in _book.navPoints) {
        NSString *identifier = navPoint.second;
        if([identifier isEqualToString:uuid]) {
            lastName = navPoint.first;
            break;
        }
    }
    return [lastName splitAndFormattedChapterName];
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


- (EucBookPageIndexPoint *)indexPointForPageNumber:(NSUInteger)pageNumber
{
    return [_currentBookPageIndex filteredIndexPointForPage:pageNumber];
}

- (THPair *)viewAndIndexPointRangeForPageNumber:(NSUInteger)pageNumber 
{
    THPair *ret = nil;
    if(pageNumber >= 1 && pageNumber <= _globalPageCount) {
        THPair *indexPointRange = [_currentBookPageIndex filteredIndexPointRangeForPage:pageNumber];
        EucBookPageIndexPoint *indexPoint = indexPointRange.first;
        
        CGRect frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
        EucPageView *pageView = [[self class] blankPageViewWithFrame:frame
                                                        forPointSize:_fontPointSize];
        pageView.titleLinePosition = EucPageViewTitleLinePositionTop;
        pageView.titleLineContents = EucPageViewTitleLineContentsTitleAndPageNumber;
        pageView.pageNumberString = [self displayPageNumberForPageNumber:pageNumber];
        pageView.title = _book.title;
        BOOL fullBleed = NO;
        if([_book respondsToSelector:@selector(fullBleedPageForIndexPoint:)]) {
            fullBleed = [_book fullBleedPageForIndexPoint:indexPoint];
            pageView.fullBleed = fullBleed;
        }
        
        [(EucBUpePageTextView *)pageView.pageTextView layoutPageFromPoint:indexPoint
                                                                   inBook:_book
                                                             centerOnPage:fullBleed];

        ret = [THPair pairWithFirst:pageView second:indexPointRange];
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

+ (EucPageView *)blankPageViewWithFrame:(CGRect)frame
                           forPointSize:(CGFloat)pointSize
{    
    NSString *fontFamily = [EucConfiguration objectForKey:EucConfigurationDefaultFontFamilyKey];
    return [[[EucPageView alloc] initWithFrame:frame
                                     pointSize:pointSize 
                                     titleFont:fontFamily
    titleFontStyleFlags:THStringRendererFontStyleFlagItalic
                                pageNumberFont:fontFamily
                      pageNumberFontStyleFlags:THStringRendererFontStyleFlagRegular
                                titlePointSize:pointSize
                                 textViewClass:[EucBUpePageTextView class]] autorelease];
}

- (BOOL)viewShouldBeRigid:(UIView *)view
{
    return [(EucPageView *)view pageNumberString] != nil;
}

@end
