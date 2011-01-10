//
//  EucCSSLayoutTableCell.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutTableBox.h"

@class EucCSSLayoutSizedContainer;

@interface EucCSSLayoutTableCell : EucCSSLayoutTableBox {
    EucCSSIntermediateDocumentNode *_stopBeforeNode;
}

@property (nonatomic, assign, readonly) NSUInteger columnSpan;
@property (nonatomic, assign, readonly) NSUInteger rowSpan;

- (EucCSSLayoutSizedContainer *)sizedContentsWithScaleFactor:(CGFloat)scaleFactor;

@end
