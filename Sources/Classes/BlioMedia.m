//
//  BlioMedia.m
//  StackApp
//
//  Created by Arnold Chien on 6/10/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <libEucalyptus/THStringRenderer.h>
#import "BlioMedia.h"

@implementation BlioMedia

@dynamic libraryPosition;
@dynamic processingState;
@dynamic sourceID;
@dynamic sourceSpecificID;
@dynamic title;
@dynamic titleSortable;
@dynamic transactionType;
@dynamic progress;
@dynamic siteNum;
@dynamic userNum;

- (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *bookPath = [docsPath stringByAppendingPathComponent:[self valueForKey:@"uuid"]];
    return bookPath;
}

- (NSString *)tempDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *bookPath = [docsPath stringByAppendingPathComponent:[self valueForKey:@"uuid"]];
    return bookPath;
}

- (NSString *)fullPathOfFileSystemItemAtPath:(NSString *)path {
    return [self.cacheDirectory stringByAppendingPathComponent:path];
}

- (NSData *)dataFromFileSystemAtPath:(NSString *)path {
    NSData *data = nil;
    NSString *filePath = [self fullPathOfFileSystemItemAtPath:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        NSLog(@"Error whilst retrieving data from the filesystem. No file exists at path %@", path);
    else
        data = [NSData dataWithContentsOfMappedFile:filePath];
    
    return data;
}

- (UIImage *)missingCoverImageOfSize:(CGSize)size {
    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIImage *missingCover = [UIImage imageNamed:@"booktexture-nocover.png"];
    [missingCover drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    NSString *titleString = [self title];
    NSUInteger maxTitleLength = 100;
    if ([titleString length] > maxTitleLength) {
        titleString = [NSString stringWithFormat:@"%@\u2026", [titleString substringToIndex:maxTitleLength]];
    }
    
    THStringRenderer *renderer = [THStringRenderer stringRendererWithFontName:@"Linux Libertine O"];
    
    CGSize fullSize = [[UIScreen mainScreen] bounds].size;
    CGFloat pointSize = roundf(fullSize.height / 8.0f);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(size.width / fullSize.width, size.height / fullSize.height);
    
    UIEdgeInsets titleInsets = UIEdgeInsetsMake(fullSize.height * 0.2f, fullSize.width * 0.2f, fullSize.height * 0.2f, fullSize.width * 0.1f);
    CGRect titleRect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, fullSize.width, fullSize.height), titleInsets);
    
    BOOL fits = NO;
    
    NSUInteger flags = THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter;
    
    while (!fits && pointSize >= 2) {
        CGSize size = [renderer sizeForString:titleString pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
        if ((size.height <= titleRect.size.height) && (size.width <= titleRect.size.width)) {
            fits = YES;
        } else {
            pointSize -= 1.0f;
        }
    }
    
    CGContextConcatCTM(ctx, scaleTransform);
    CGContextClipToRect(ctx, titleRect); // if title won't fit at 2 points it gets clipped
    
    CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.919 green:0.888 blue:0.862 alpha:0.8f].CGColor);
    CGContextBeginTransparencyLayer(ctx, NULL);
    CGContextSetShadow(ctx, CGSizeMake(0, -1*scaleTransform.d), 0);
    [renderer drawString:titleString inContext:ctx atPoint:titleRect.origin pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
    CGContextEndTransparencyLayer(ctx);
    
    CGContextSetRGBFillColor(ctx, 0.9f, 0.9f, 1, 0.8f);
    [renderer drawString:titleString inContext:ctx atPoint:titleRect.origin pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
    
    UIImage *aCoverImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    return aCoverImage;
}

- (UIImage *)coverImage:(NSData*) imageData {
    //NSData *imageData = [self manifestDataForKey:BlioManifestCoverKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        return aCoverImage;
    } else {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        return [self missingCoverImageOfSize:CGSizeMake(screenSize.width, screenSize.height)];
    }
}

- (NSString*)getPixelSpecificKeyForGrid {
     CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	return [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
}

- (BOOL)hasAppropriateCoverThumbForGrid:(NSData*)imageData {
    /*
    CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
	*/
    //NSString * pixelSpecificKey = [self getPixelSpecificKeyForGrid:scaleFactor];
    //NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
	if (aCoverImage)
        return YES;
	return NO;
}

- (UIImage *)coverThumbForGrid:(NSData*)imageData {
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
    /*
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
    */
    //NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        if(scaleFactor != 1.0f) {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
        } else {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage];
        }
        return aCoverImage;
    } else {
        CGFloat targetThumbWidth = kBlioCoverGridThumbWidthPhone;
        CGFloat targetThumbHeight = kBlioCoverGridThumbHeightPhone;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            targetThumbWidth = kBlioCoverGridThumbWidthPad;
            targetThumbHeight = kBlioCoverGridThumbHeightPad;
        }
        return [self missingCoverImageOfSize:CGSizeMake(targetThumbWidth, targetThumbHeight)];
    }
    return [UIImage imageWithData:imageData];
}

- (NSString*)getPixelSpecificKeyForList {
    CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	return [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
}

- (BOOL)hasAppropriateCoverThumbForList:(NSData*)imageData {
    /*
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    */
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
	if (aCoverImage)
        return YES;
	return NO;
}

- (UIImage *)coverThumbForList:(NSData*)imageData {
	
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
    /*
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;
    
	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;
    
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
    
    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    */
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        if(scaleFactor != 1.0f) {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
        } else {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage];
        }
        return aCoverImage;
    } else {
        CGFloat targetThumbWidth = kBlioCoverListThumbWidth;
        CGFloat targetThumbHeight = kBlioCoverListThumbHeight;
        //return [self missingCoverImageOfSize:CGSizeMake(targetThumbWidth, targetThumbHeight)];
        return [self missingCoverImageOfSize:CGSizeMake(targetThumbWidth, targetThumbHeight)];
    }
}

@end
