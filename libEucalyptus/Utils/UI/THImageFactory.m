//
//  THImageFactory.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/02/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THImageFactory.h"


@implementation THImageFactory

@synthesize CGContext = _CGContext;
@synthesize scaleFactor = _scaleFactor;

- (id)initWithSize:(CGSize)size scaleFactor:(CGFloat)scaleFactor {
    if((self = [super init])) {
        _size = size;
        if(!scaleFactor) {
            UIScreen *screen = [UIScreen mainScreen];
            if([screen respondsToSelector:@selector(scale)]) {
                scaleFactor = [[UIScreen mainScreen] scale];
            } else {
                scaleFactor = 1.0f;
            }
        }
        _scaleFactor = scaleFactor;
        
        size_t width = (size_t)size.width * scaleFactor;
        size_t height = (size_t)size.height * scaleFactor;
        
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
            
            CGContextScaleCTM(_CGContext, scaleFactor, scaleFactor);
        } 
    }
    return self;
}

- (id)initWithSize:(CGSize)size {
    return [self initWithSize:size scaleFactor:1.0f];
}

- (void)dealloc
{
    CGContextRelease(_CGContext);
    CGColorSpaceRelease(_colorSpace);
    [_backingData release];
    
    [super dealloc];
}

- (CGImageRef)_copySnapshotCGImage
{
    CGContextFlush(_CGContext);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)_backingData);
    CGFloat width = _size.width * _scaleFactor;
    CGFloat height = _size.height * _scaleFactor;
    CGImageRef ret =  CGImageCreate(width, height, 8, 32, 4 * width, 
                                    _colorSpace, 
                                    kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, 
                                    dataProvider, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    return ret;
}

- (UIImage *)snapshotUIImage
{
    CGImageRef image = [self _copySnapshotCGImage];
    UIImage *ret;
    if(_scaleFactor && [UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
        ret = [UIImage imageWithCGImage:image scale:_scaleFactor orientation:UIImageOrientationUp];
    } else {
        ret = [UIImage imageWithCGImage:image];
    }
    CGImageRelease(image);
    return ret;
}

- (CGImageRef)snapshotCGImage
{
    return (CGImageRef)[(id)[self _copySnapshotCGImage] autorelease];
}

@end
