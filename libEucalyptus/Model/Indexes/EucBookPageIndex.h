//
//  BookPageIndex.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucBookPageIndexPoint;
@protocol EucBook;

@interface EucBookPageIndex : NSObject {
    id<EucBook> _book;
    NSUInteger _pointSize;
    
    int _fd;
    BOOL _isFinal;
    
    NSUInteger _lastPageNumber;
    off_t _lastOffset;
}

+ (id)bookPageIndexForIndexInBook:(id<EucBook>)path forPointSize:(NSUInteger)pointSize;

@property (nonatomic, readonly) id<EucBook> book;
@property (nonatomic, readonly) NSUInteger pointSize;

@property (nonatomic, readonly) NSUInteger lastPageNumber;
@property (nonatomic, readonly) BOOL isFinal;

- (EucBookPageIndexPoint *)indexPointForPage:(NSUInteger)pageNumber;
- (NSUInteger)pageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (void)closeIndex;

- (NSComparisonResult)compare:(EucBookPageIndex *)rhs;

@end
