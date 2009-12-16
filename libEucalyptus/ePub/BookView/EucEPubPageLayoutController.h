//
//  EucEPubPageLayoutController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 29/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucPageLayoutController.h"

@class EucEPubBook, EucFilteredBookPageIndex;
@protocol EucBookReader;

@interface EucEPubPageLayoutController : NSObject <EucPageLayoutController> {
    CGFloat _fontPointSize;
    
    EucEPubBook *_book;
    EucFilteredBookPageIndex *_bookIndex;
    id<EucBookReader> _bookReader;
    
    NSArray *_bookIndexes;
    NSArray *_availablePointSizes;
    
    NSUInteger _globalPageCount;   
}

@end
