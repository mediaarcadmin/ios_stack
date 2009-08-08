//
//  EucEPubPageLayoutController.h
//  Eucalyptus
//
//  Created by James Montgomerie on 29/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucPageLayoutController.h"

@class EucEPubBook, EucBookPageIndex;
@protocol EucBookReader;

@interface EucEPubPageLayoutController : NSObject <EucPageLayoutController> {
    CGFloat _fontPointSize;
    
    EucEPubBook *_book;
    EucBookPageIndex *_bookIndex;
    id<EucBookReader> _bookReader;
    
    NSArray *_bookIndexes;
    NSArray *_availablePointSizes;
    
    NSUInteger _globalPageCount;   
    
    UIImage *_paperImage;
}

@end
