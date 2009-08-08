//
//  THUIViewThreadSafeDrawing.h
//  Eucalyptus
//
//  Created by James Montgomerie on 20/02/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol THUIViewThreadSafeDrawing
@required
- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context;
@end
