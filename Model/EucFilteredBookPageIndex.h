//
//  EucFilteredBookPageIndex.h
//  libEucalyptus
//
//  Created by James Montgomerie on 28/09/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBookPageIndex.h"

@interface EucFilteredBookPageIndex : EucBookPageIndex {
    NSArray *_filteredByteRanges;
    NSRange *_filteredPageRanges;
    NSUInteger _filteredPageRangeCount;
    NSUInteger _filteredPageCount;
}

// NSArray of NSValues of NSRanges.
@property (nonatomic, assign) NSArray *filteredByteRanges;

@property (nonatomic, readonly) NSUInteger filteredLastPageNumber;

- (EucBookPageIndexPoint *)filteredIndexPointForPage:(NSUInteger)pageNumber;
- (NSUInteger)filteredPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (NSUInteger)filteredPageForByteOffset:(NSUInteger)byteOffset;

@end
