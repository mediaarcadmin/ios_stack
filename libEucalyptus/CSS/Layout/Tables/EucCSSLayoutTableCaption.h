//
//  EucCSSLayoutTableCaption.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@class EucCSSLayoutSizedBlock;

@interface EucCSSLayoutTableCaption : EucCSSLayoutTableBox {}

- (EucCSSLayoutSizedBlock *)sizedContentsWithScaleFactor:(CGFloat)scaleFactor;

@end
