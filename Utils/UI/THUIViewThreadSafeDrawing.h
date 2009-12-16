//
//  THUIViewThreadSafeDrawing.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/02/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol THUIViewThreadSafeDrawing
@required
- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context;
@end
