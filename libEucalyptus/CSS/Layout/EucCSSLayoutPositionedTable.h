//
//  EucCSSLayoutPositionedTable.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutSizedTable;

@interface EucCSSLayoutPositionedTable : EucCSSLayoutPositionedContainer {
    EucCSSLayoutSizedTable *_sizedTable;
}

- (id)initWithSizedTable:(EucCSSLayoutSizedTable *)sizedTable;
    
- (void)positionInFrame:(CGRect)frame
 afterInternalPageBreak:(BOOL)afterInternalPageBreak;

@end
