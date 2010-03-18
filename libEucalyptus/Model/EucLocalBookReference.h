/*
 *  EucLocalBookReference.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 28/07/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>

@protocol EucLocalBookReference <NSObject> 
    
@property (nonatomic, readonly) CGFloat percentThroughBook;
@property (nonatomic, readonly) CGFloat percentPaginated;
@property (nonatomic, readonly) BOOL paginationIsComplete;

@end
