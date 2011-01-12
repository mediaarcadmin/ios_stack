//
//  EucCSSLayoutPositionedTableCell.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutSizedTableCell;

@interface EucCSSLayoutPositionedTableCell : EucCSSLayoutPositionedContainer {
    EucCSSLayoutSizedTableCell *_sizedTableCell;
    
    CGFloat _extraPaddingTop;
    CGFloat _extraPaddingBottom;
}

@property (nonatomic, retain, readonly) EucCSSLayoutSizedTableCell *sizedTableCell;

@property (nonatomic, assign) CGFloat extraPaddingTop;
@property (nonatomic, assign) CGFloat extraPaddingBottom;

- (id)initWithSizedTableCell:(EucCSSLayoutSizedTableCell *)sizedTableCell;

@end
