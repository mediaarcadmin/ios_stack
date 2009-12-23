//
//  MockBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioMockBook.h"

static const int kBlioMockBookThumbWidth = 53;
static const int kBlioMockBookThumbHeight = 76;

@implementation BlioMockBook

@synthesize title;
@synthesize author;
@synthesize coverPath;
@synthesize bookPath;
@synthesize pdfPath;
@synthesize progress;
@synthesize proportionateSize;

- (void)dealloc {
  self.title = nil;
  self.author = nil;
  self.coverPath = nil;
  self.bookPath = nil;
  self.pdfPath = nil;
  [coverThumb release];
  [super dealloc];
}

- (UIImage *)coverImage {
  NSData *imageData = [NSData dataWithContentsOfMappedFile:self.coverPath];
  return [UIImage imageWithData:imageData];
}

- (CGAffineTransform)transformForOrientation:(CGSize)newSize orientation:(UIImageOrientation)orientation {
  CGAffineTransform transform = CGAffineTransformIdentity;
  
  switch (orientation) {
    case UIImageOrientationDown:           // EXIF = 3
    case UIImageOrientationDownMirrored:   // EXIF = 4
      transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
      
    case UIImageOrientationLeft:           // EXIF = 6
    case UIImageOrientationLeftMirrored:   // EXIF = 5
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformRotate(transform, M_PI_2);
      break;
      
    case UIImageOrientationRight:          // EXIF = 8
    case UIImageOrientationRightMirrored:  // EXIF = 7
      transform = CGAffineTransformTranslate(transform, 0, newSize.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;
    default:
      break;
  }
  
  switch (orientation) {
    case UIImageOrientationUpMirrored:     // EXIF = 2
    case UIImageOrientationDownMirrored:   // EXIF = 4
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
      
    case UIImageOrientationLeftMirrored:   // EXIF = 5
    case UIImageOrientationRightMirrored:  // EXIF = 7
      transform = CGAffineTransformTranslate(transform, newSize.height, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
    default:
      break;
  }
  
  return transform;
}

- (UIImage *)coverThumb {
  if (coverThumb == nil) {
    // Attempt to retrieve from disk cache
    NSString *encodedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.coverPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:encodedPath]) {
      NSData *coverThumbData = [NSData dataWithContentsOfMappedFile:encodedPath];
      coverThumb = [[UIImage alloc ]initWithData:coverThumbData];
      [coverThumb retain];
    }
    
    if (coverThumb == nil) { 
      UIImage *cover = [self coverImage];
      
      CGSize newSize = CGSizeMake(kBlioMockBookThumbWidth, kBlioMockBookThumbHeight);
      CGAffineTransform transform = [self transformForOrientation:newSize orientation:cover.imageOrientation];
      
      CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
      CGImageRef imageRef = cover.CGImage;
      
      CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                  newRect.size.width,
                                                  newRect.size.height,
                                                  8,
                                                  0,
                                                  CGImageGetColorSpace(imageRef),
                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
      // Rotate and/or flip the image if required by its orientation
      CGContextConcatCTM(bitmap, transform);
      
      // Set the quality level to use when rescaling
      CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
      
      // Draw into the context; this scales the image
      CGContextDrawImage(bitmap, newRect, imageRef);
      
      // Get the resized image from the context and a UIImage
      CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
      UIImage *newThumb = [UIImage imageWithCGImage:newImageRef];
      
      // Clean up
      CGContextRelease(bitmap);
      CGImageRelease(newImageRef);
      
      [newThumb retain];
      coverThumb = newThumb;
         
      NSData *pngImage = UIImagePNGRepresentation(coverThumb);
      NSString *dir = [encodedPath stringByDeletingLastPathComponent];
      [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:NULL error:NULL];
      [pngImage writeToFile:encodedPath atomically:YES];
    }
  }
  return coverThumb;
}

@end


