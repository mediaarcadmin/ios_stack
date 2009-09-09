//
//  THImageFactory.m
//  Eucalyptus
//
//  Created by James Montgomerie on 20/02/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "THImageFactory.h"


@implementation THImageFactory

@synthesize CGContext = _CGContext;

- (id)initWithSize:(CGSize)size {
    if((self = [super init])) {
        _size = size;
        size_t width = (size_t)size.width;
        size_t height = (size_t)size.height;

        if((_backingData = [[NSMutableData alloc] initWithLength:4 * width * height])) {
            if((_colorSpace = CGColorSpaceCreateDeviceRGB())) {
                _CGContext =  CGBitmapContextCreate([_backingData mutableBytes],
                                                    width, height,
                                                    8,
                                                    4 * width,
                                                    _colorSpace,
                                                    kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
            }
        }
        if(!_CGContext) {
            [self release];
            self = nil;
        } else {
            CGContextSetFillColorSpace(_CGContext, _colorSpace);
            CGContextSetStrokeColorSpace(_CGContext, _colorSpace);   
        } 
    }
    return self;
}

- (void)dealloc
{
    CGContextRelease(_CGContext);
    CGColorSpaceRelease(_colorSpace);
    [_backingData release];
    
    [super dealloc];
}

- (CGImageRef)_newSnapshotCGImage
{
    CGContextFlush(_CGContext);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)_backingData);
    CGImageRef ret =  CGImageCreate(_size.width, _size.height, 8, 32, 4 * _size.width, 
                                    _colorSpace, 
                                    kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, 
                                    dataProvider, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    return ret;
}

- (UIImage *)snapshotUIImage
{
    CGImageRef image = [self _newSnapshotCGImage];
    UIImage *ret = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    return ret;
}

- (CGImageRef)snapshotCGImage
{
    return (CGImageRef)[(id)[self _newSnapshotCGImage] autorelease];
}

@end
