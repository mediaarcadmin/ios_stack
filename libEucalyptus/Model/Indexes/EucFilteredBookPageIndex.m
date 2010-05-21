//
//  EucFilteredBookPageIndex.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/09/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucFilteredBookPageIndex.h"
#import "THPair.h"

@implementation EucFilteredBookPageIndex
/*
@synthesize filteredByteRanges = _filteredByteRanges;
*/
- (void)dealloc
{
    [_filteredByteRanges release];
    free(_filteredPageRanges);
    
    [super dealloc];
}
/*
- (void)setFilteredByteRanges:(NSArray *)filteredByteRanges
{
    if(filteredByteRanges != _filteredByteRanges) {
        [_filteredByteRanges release];
        _filteredByteRanges = [filteredByteRanges retain];
        
        free(_filteredPageRanges);
        _filteredPageRangeCount = 0;
        _filteredPageCount = 0;
        _filteredPageRanges = malloc(sizeof(NSRange) * filteredByteRanges.count);

        off_t lastOffset = self.lastOffset;
        for(NSValue *value in filteredByteRanges) {
            NSRange byteRange = [value rangeValue];
            NSRange pageRange;
            pageRange.location = [self pageForByteOffset:byteRange.location];
            if(byteRange.location + byteRange.length > lastOffset) {
                // Special case - we want to filter to after the last page.
                // The +1 is because location + length gives the /next/ page,
                // which is one-past-the-end (i.e. it does not exist).  If we
                // don't add 1, we filter only /up to/ the last page.
                pageRange.length = self.lastPageNumber - pageRange.location + 1; 
            } else {
                pageRange.length = [self pageForByteOffset:byteRange.location + byteRange.length - 1] - pageRange.location;
            }
            if(pageRange.length > 0) {
                _filteredPageCount += pageRange.length;
                _filteredPageRanges[_filteredPageRangeCount++] = pageRange;
            }
        }
    }
}*/
                        
- (NSUInteger)filteredLastPageNumber
{
    return [self lastPageNumber] - _filteredPageCount;
}

- (NSUInteger)_pageToFilteredPage:(NSUInteger)pageNumber;
{
    if(_filteredByteRanges) {
        NSUInteger toSubtract = 0;
        for(int i = 0; 
            i < _filteredPageRangeCount &&
            pageNumber >= _filteredPageRanges[i].location; 
            ++i) {
            NSRange filter =  _filteredPageRanges[i];
            if(filter.location + filter.length >= pageNumber) {
                toSubtract += pageNumber - filter.location;
            } else {
                toSubtract += filter.length;
            }
        }
        return pageNumber - toSubtract;
    } else {
        return pageNumber;
    }
}

- (NSUInteger)_filteredPageToPage:(NSUInteger)pageNumber
{
    if(_filteredByteRanges) {
        NSUInteger toAdd = 0;
        for(int i = 0; 
            i < _filteredPageRangeCount &&
            pageNumber + toAdd >= _filteredPageRanges[i].location; 
            ++i) {
            toAdd += _filteredPageRanges[i].length;
        }
        return pageNumber + toAdd;
    } else {
        return pageNumber;
    }
}

- (EucBookPageIndexPoint *)filteredIndexPointForPage:(NSUInteger)pageNumber
{
    return [self indexPointForPage:[self _filteredPageToPage:pageNumber]];
}

- (THPair *)filteredIndexPointRangeForPage:(NSUInteger)pageNumber
{
    EucBookPageIndexPoint *start = [self indexPointForPage:[self _filteredPageToPage:pageNumber]];
    
    NSUInteger endPageNumber = pageNumber + 1;
    EucBookPageIndexPoint *end;
    if(endPageNumber <= self.filteredLastPageNumber) {
        end = [self indexPointForPage:[self _filteredPageToPage:endPageNumber]];
    } else {
        end = nil;
    }
        
    return [THPair pairWithFirst:start second:end];
}

- (NSUInteger)filteredPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return [self _pageToFilteredPage:[self pageForIndexPoint:indexPoint]];
}



@end
