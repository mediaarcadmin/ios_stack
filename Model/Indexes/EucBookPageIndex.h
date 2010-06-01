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
    NSUInteger _pointSize;
    
    int _fd;
    BOOL _isFinal;
    
    NSUInteger _lastPageNumber;
    off_t _lastOffset;
}

+ (id)bookPageIndexAtPath:(NSString *)path;
@property (nonatomic, readonly) NSUInteger lastPageNumber;

- (EucBookPageIndexPoint *)indexPointForPage:(NSUInteger)pageNumber;
- (NSUInteger)pageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

@end
