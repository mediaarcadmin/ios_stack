//
//  EucBUpePageLayoutController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucPageLayoutController.h"

@class EucBUpeBook, EucBookIndex, EucFilteredBookPageIndex;

@interface EucBUpePageLayoutController : NSObject <EucPageLayoutController> {
    CGFloat _fontPointSize;
        
    EucBUpeBook *_book;
    CGSize _pageSize;
    EucBookIndex *_bookIndex;
    EucFilteredBookPageIndex *_currentBookPageIndex;

    NSUInteger _globalPageCount;   
}

@end
