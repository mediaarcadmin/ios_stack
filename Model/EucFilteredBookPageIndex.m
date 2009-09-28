//
//  EucFilteredBookPageIndex.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/09/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucFilteredBookPageIndex.h"


@implementation EucFilteredBookPageIndex

@synthesize filteredByteRanges = _filteredByteRanges;

- (void)dealloc
{
    [_filteredByteRanges release];
    free(_filteredPageRanges);
    
    [super dealloc];
}

- (void)setFilteredByteRanges:(NSArray *)filteredByteRanges
{
    if(filteredByteRanges != _filteredByteRanges) {
        [_filteredByteRanges release];
        _filteredByteRanges = [filteredByteRanges retain];
        
        free(_filteredPageRanges);
        _filteredPageRangeCount = 0;
        _filteredPageCount = 0;
        _filteredPageRanges = malloc(sizeof(NSRange) * filteredByteRanges.count);

        for(NSValue *value in filteredByteRanges) {
            NSRange byteRange = [value rangeValue];
            NSRange pageRange;
            pageRange.location = [super pageForByteOffset:byteRange.location];
            pageRange.length = [super pageForByteOffset:byteRange.location + byteRange.length - 1] - pageRange.location;
            if(pageRange.length > 0) {
                _filteredPageCount += pageRange.length;
                _filteredPageRanges[_filteredPageRangeCount++] = pageRange;
            }
        }
    }
}
                        
- (NSUInteger)filteredLastPageNumber
{
    return [super lastPageNumber] - _filteredPageCount;
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
    return [super indexPointForPage:[self _filteredPageToPage:pageNumber]];
}

- (NSUInteger)filteredPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return [self _pageToFilteredPage:[super pageForIndexPoint:indexPoint]];
}

- (NSUInteger)filteredPageForByteOffset:(NSUInteger)byteOffset
{
    return [self _pageToFilteredPage:[super pageForByteOffset:byteOffset]];
}

@end
