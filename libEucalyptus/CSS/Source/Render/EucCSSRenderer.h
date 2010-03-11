//
//  EucCSSRenderer.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EucCSSRenderer : NSObject {
    CGContextRef _cgContext;
}

@property (nonatomic, assign) CGContextRef cgContext;

- (void)render:(id)layoutEntity;

@end
