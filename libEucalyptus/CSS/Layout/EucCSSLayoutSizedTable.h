//
//  EucCSSLayoutSizedTable.h
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

#import "EucCSSLayoutSizedContainer.h"

@class EucCSSLayoutTableWrapper;

@interface EucCSSLayoutSizedTable: EucCSSLayoutSizedContainer {
    EucCSSLayoutTableWrapper *_tableWrapper;
    
    NSMutableDictionary *_cellMap;
    CFMutableDictionaryRef _sizedContainers;
    
    
    NSUInteger _columnCount;
    NSUInteger _rowCount;
    
    CGFloat *_columnMinWidths;
    CGFloat *_columnMaxWidths;
    //EucCSSLayoutSizedContainer ***_cellContainers;
}

- (id)initWithTableWrapper:(EucCSSLayoutTableWrapper *)tableWrapper
               scaleFactor:(CGFloat)scaleFactor;

@end
