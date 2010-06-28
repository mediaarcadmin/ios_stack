//
//  THUIImageAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THUIImageAdditions.h"
//#import "THImageFactory.h"
#import "THLog.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (THAdditions)

// Modified from technote QA1509
/*
static CGContextRef CreateGrayscaleBitmapContext (CGImageRef inImage)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = pixelsWide;
    bitmapByteCount     = bitmapBytesPerRow * pixelsHigh;
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceGray();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaNone);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

- (id)imageByMappingIntensityToAlpha
{   
    UIImage *ret = nil;
    CGImageRef inImage = [self CGImage];
    // Create the bitmap context
    CGContextRef cgctx = CreateGrayscaleBitmapContext(inImage);
    if (cgctx != NULL)
    {
        // Get image width, height. We'll use the entire image.
        size_t w = CGImageGetWidth(inImage);
        size_t h = CGImageGetHeight(inImage);
        CGRect rect = {{0,0},{w,h}};
        
        // Draw the image to the bitmap context. Once we draw, the memory
        // allocated for the context for rendering will then contain the
        // raw image data in the specified color space.
        CGContextDrawImage(cgctx, rect, inImage);
        
        // Now we can get a pointer to the image data associated with the bitmap
        // context.
        uint8_t *grayscaleData = CGBitmapContextGetData (cgctx);
        if (grayscaleData != NULL)
        {
            size_t totalSize = w * h;
            
            CFMutableDataRef newBitmapData = CFDataCreateMutable(NULL, 4 * totalSize);
            
            uint8_t *newBitmapPointer = CFDataGetMutableBytePtr(newBitmapData);
            for(int i = 0; i < totalSize; ++i) {
                *newBitmapPointer++ = 0x00;
                *newBitmapPointer++ = 0x00;
                *newBitmapPointer++ = 0x00;  
                *newBitmapPointer++ = 0xFF - grayscaleData[i];
            }

            CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(newBitmapData);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGImageRef newImageRef = CGImageCreate(w, h, 8, 32, 4 * w, 
                                                   colorSpace, 
                                                   kCGBitmapByteOrderDefault | kCGImageAlphaLast, 
                                                   dataProvider, NULL, YES, kCGRenderingIntentDefault);
            ret = [UIImage imageWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
            CGColorSpaceRelease(colorSpace);
            CGDataProviderRelease(dataProvider);
            CFRelease(newBitmapData);
        }
        
        // When finished, release the context
        CGContextRelease(cgctx);
        // Free image data memory for the context
        if (grayscaleData)
        {
            free(grayscaleData);
        }
    }
    
    //THImageFactory *imageFactory = [[THImageFactory alloc] initWithSize:[ret size]];
    //CGContextDrawImage(imageFactory.CGContext, CGRectMake(0, 0, ret.size.width, ret.size.height), [ret CGImage]);    
    //NSData *pngData = UIImagePNGRepresentation([imageFactory snapshotUIImage]);
    //[pngData writeToFile:[NSString stringWithFormat:@"/tmp/%d.png", rand()] atomically:NO];
    //[imageFactory release];
     
    return ret;
}
*/
+ (UIImage *)imageWithString:(NSString *)string // What we want an image of.
                        font:(UIFont *)font     // The font we'd like it in.
                        size:(CGSize)size       // Size of the desired image.
                       color:(UIColor *)color
{
    CGFloat scaleFactor;
    UIScreen *mainScreen = [UIScreen mainScreen];
    if([mainScreen respondsToSelector:@selector(scale)]) {
        scaleFactor = [mainScreen scale];
        size.width *= scaleFactor;
        size.height *= scaleFactor;
    } else {
        scaleFactor = 1;
    }
    
    // Create a context to render into.
    UIGraphicsBeginImageContext(size);
    
    // Work out what size of font will give us a rendering of the string
    // that will fit in an image of the desired size. 
    
    // We do this by measuring the string at the given font size and working 
    // out the ratio scale to it by to get the desired size of image.
   
    // Measure the string size.
    CGSize stringSize = [string sizeWithFont:font];
    
    // Work out what it should be scaled by to get the desired size.
    CGFloat xRatio = size.width / stringSize.width;
    CGFloat yRatio = size.height / stringSize.height;
    CGFloat ratio = MIN(xRatio, yRatio);
    
    // Work out the point size that'll give us the desired image size, and
    // create a UIFont that size.
    CGFloat oldFontSize = font.pointSize;
    CGFloat newFontSize = floorf(oldFontSize * ratio); 

    font = [font fontWithSize:newFontSize];

    // What size is the string with this new font?
    stringSize = [string sizeWithFont:font];
    
    // Work out where the origin of the drawn string should be to get it in 
    // the centre of the image.
    CGPoint textOrigin = CGPointMake((size.width - stringSize.width) / 2, 
                                     (size.height - stringSize.height) / 2);
    
    // Draw the string into out image.
    [string drawAtPoint:textOrigin withFont:font];

    // We actualy don't have the scaling right, because the rendered
    // string probably doesn't actually fill the entire pixel area of the 
    // box we were given or its size.  We'll use what we just drew
    // to work out the /real/ size we need to draw at to fill the image.
    
    // First, we work out what area the drawn string /actually/ covered.
    
    // First, get a raw bitmap of what we've drawn.
    CGImageRef maskImage = [UIGraphicsGetImageFromCurrentImageContext() 
                                CGImage];
    CFDataRef imageData = CGDataProviderCopyData(
                              CGImageGetDataProvider(maskImage));
    uint8_t *bitmap = (uint8_t *)CFDataGetBytePtr(imageData);
    size_t rowBytes = CGImageGetBytesPerRow(maskImage);
    
    // Now, go through the pixels one-by-one working out the area in which the
    // image is not still blank.
    size_t minx = size.width, maxx = 0, miny = size.height, maxy = 0;
    uint32_t *rowBase = (uint32_t *)bitmap;
    for(size_t y = 0; y < size.height; ++y, rowBase += rowBytes / sizeof(uint32_t)) {
        uint32_t *component = rowBase;
        for(size_t x = 0; x < size.width; ++x, component += 1) {    
            if(*component != 0) {
                if(x < minx) {
                    minx = x;
                } else if(x > maxx) {
                    maxx = x;
                }
                if(y < miny) {
                    miny = y;
                } else if(y > maxy) {
                    maxy = y;
                }
            }
        }
    }
    CFRelease(imageData); // We're done with this data now.
    
    // Put the area we just found into a CGRect.
    CGRect boundingBox =
        CGRectMake(minx, miny, maxx - minx + 1, maxy - miny + 1);
    
    // We're going to have to move string we're drawing as well as scale it,
    // so we work out how the origin we used to draw the string relates to the 
    // 'real' origin of the filled area.
    CGPoint goodBoundingBoxOrigin = 
        CGPointMake((size.width - boundingBox.size.width) / 2,
                    (size.height - boundingBox.size.height) / 2);
    CGFloat textOriginXDiff = goodBoundingBoxOrigin.x - boundingBox.origin.x;
    CGFloat textOriginYDiff = goodBoundingBoxOrigin.y - boundingBox.origin.y;
    
    // Work out how much we'll need to scale by to fill the entire image.
    xRatio = size.width / boundingBox.size.width;
    yRatio = size.height / boundingBox.size.height;
    ratio = MIN(xRatio, yRatio);
    
    // Now, work out the font size we really need based on our scaling ratio.
    // newFontSize is still holding the size we used to draw with.
    oldFontSize = newFontSize;
    newFontSize = floorf(oldFontSize * ratio); 
    ratio = newFontSize / oldFontSize;
    font = [font fontWithSize:newFontSize];
    
    // Work out where to place the string.
    // We offset the origin by the difference between the string-drawing origin 
    // and the 'real' image origin we measured above, scaled up to the new size.
    stringSize = [string sizeWithFont:font];
    textOrigin = CGPointMake((size.width - stringSize.width) / 2, 
                             (size.height - stringSize.height) / 2);    
    textOrigin.x += textOriginXDiff * ratio;
    textOrigin.y += textOriginYDiff * ratio;
    
    // Clear the context to remove our old, too-small, rendering.
    CGContextClearRect(UIGraphicsGetCurrentContext(), 
                       CGRectMake(0, 0, size.width, size.height));
    
    // Draw the string again, in the right place, at the right size this time!
    [color set];
    [string drawAtPoint:textOrigin withFont:font];
    
    // We're done!  Grab the image and return it! 
    // (Don't forget to end the image context first though!)
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(scaleFactor != 1) {
        retImage = [UIImage imageWithCGImage:[retImage CGImage]
                                       scale:scaleFactor 
                                 orientation:retImage.imageOrientation];
    }
    
    return retImage;
}

+ (UIImage *)imageWithString:(NSString *)string // What we want an image of.
                        font:(UIFont *)font     // The font we'd like it in.
                        size:(CGSize)size       // Size of the desired image.
{
    return [self imageWithString:string font:font size:size color:[UIColor blackColor]];
}

- (UIImage *)midpointStretchableImage
{
    CGSize imageSize = [self size];
    return [self stretchableImageWithLeftCapWidth:floorf(imageSize.width / 2)
                                     topCapHeight:floorf(imageSize.height / 2)];
}

+ (UIImage *)midpointStretchableImageNamed:(NSString *)name
{
    return [[UIImage imageNamed:name] midpointStretchableImage];
}

+ (UIImage *)stretchableImageNamed:(NSString *)name leftCapWidth:(CGFloat)leftCapWidth topCapHeight:(CGFloat)topCapHeight
{
    return [[UIImage imageNamed:name] stretchableImageWithLeftCapWidth:leftCapWidth
                                                             topCapHeight:topCapHeight];
}

+ (UIImage *)imageWithView:(UIView *)view
{
    CGRect bounds = [view bounds];
    if(UIGraphicsBeginImageContextWithOptions) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(bounds.size);
    }
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
