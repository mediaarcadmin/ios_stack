//
//  THImageFactory.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/02/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THImageFactory : NSObject {
    CGSize _size;
    NSMutableData *_backingData;
    CGColorSpaceRef _colorSpace;
    CGContextRef _CGContext;
}

@property (nonatomic, readonly) CGContextRef CGContext;

- (id)initWithSize:(CGSize)size;
- (CGImageRef)snapshotCGImage;
- (UIImage *)snapshotUIImage;

@end
