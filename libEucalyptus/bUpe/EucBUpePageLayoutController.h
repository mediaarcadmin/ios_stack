//
//  EucBUpePageLayoutController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucPageLayoutController.h"

@class EucBUpeBook, EucFilteredBookPageIndex;

@interface EucBUpePageLayoutController : NSObject <EucPageLayoutController> {
    CGFloat _fontPointSize;
        
    EucBUpeBook *_book;
    EucFilteredBookPageIndex *_bookIndex;
        
    NSArray *_bookIndexes;
    NSArray *_availablePointSizes;
    
    NSUInteger _globalPageCount;   
}



@end
