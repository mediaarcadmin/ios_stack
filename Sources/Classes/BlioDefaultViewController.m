    //
//  BlioDefaultViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 09/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioDefaultViewController.h"
#import <unistd.h>
#import "THNSDataAdditions.h"


@interface BlioDefaultViewController ()

@property (nonatomic, retain) UIImage *dynamicDefault;
@property (nonatomic, assign) UIInterfaceOrientation dynamicDefaultOrientation;

@property (nonatomic, retain) UIImageView *dynamicImageView;
@property (nonatomic, retain) UIImageView *nonDynamicImageView;

@property (nonatomic, assign) BOOL fadesBegun;

@end

@implementation BlioDefaultViewController

@synthesize dynamicDefault;
@synthesize dynamicDefaultOrientation;

@synthesize dynamicImageView;
@synthesize nonDynamicImageView;

@synthesize fadesBegun;

- (void)dealloc {
    dynamicDefault = nil;
    
    dynamicImageView = nil;
    nonDynamicImageView = nil;
    
    [super dealloc];
}

+ (NSString *)dynamicDefaultPngPathForOrientation:(UIInterfaceOrientation)orientation {
    NSString *tmpDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *orientationString;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        orientationString = @"Landscape";
    } else {
        orientationString = @"Portrait";
    }
    NSString *deviceString;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        deviceString = @"ipad";
    } else {
        deviceString = @"iphone";
    }
    NSString *scaleString = @"";
    UIScreen *mainScreen = [UIScreen mainScreen];
    if([mainScreen respondsToSelector:@selector(scale)]) {
        CGFloat scale = [mainScreen scale];
        if(scale != 1.0f) {
            scaleString = [NSString stringWithFormat:@"@%fx", (float)scale];
        }
    }
    
    return [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"BlioDynamicDefault-%@%@~%@.png", orientationString, scaleString, deviceString]];
}

+ (UIImage *)loadDynamicDefaultImageForOrientation:(UIInterfaceOrientation)orientation {
    NSString *dynamicDefaultPngPath = [self dynamicDefaultPngPathForOrientation:orientation];
    NSData *imageData = [NSData dataWithContentsOfFile:dynamicDefaultPngPath];
    
    // After loading the image data, but before decoding it, remove it from 
    // the filesystem in case the PNG is corrupt (in which case we might crash,
    // it seems, so we don't want to try the same one again the next time 
    // round!)
    unlink([dynamicDefaultPngPath fileSystemRepresentation]);
    
    UIImage *ret = nil;
    
    if(imageData) {
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            CGDataProviderRef pngProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
            if(pngProvider) {
                CGImageRef image = CGImageCreateWithPNGDataProvider(pngProvider, nil, false, kCGRenderingIntentDefault);
                if(image) {
                    ret = [UIImage imageWithCGImage:image
                                              scale:[[UIScreen mainScreen] scale] 
                                        orientation:UIImageOrientationUp];
                    CGImageRelease(image);
                }
                CGDataProviderRelease(pngProvider);
            }
        } else {
            ret = [UIImage imageWithData:imageData];
        }
    }
    
    return ret;
}

+ (void)saveDynamicDefaultImage:(UIImage *)image
{
    UIInterfaceOrientation orientation;
    if(image.size.height < image.size.width) {
        orientation = UIInterfaceOrientationLandscapeLeft;
    } else {
        orientation = UIInterfaceOrientationPortrait;
    }
    
    [UIImagePNGRepresentation(image) writeToMappedFile:[self dynamicDefaultPngPathForOrientation:orientation]];
} 

- (void)loadDynamicDefaults {
    if((self.dynamicDefault = [[self class] loadDynamicDefaultImageForOrientation:UIInterfaceOrientationPortrait])) {
        self.dynamicDefaultOrientation = UIInterfaceOrientationPortrait;
    } else if((self.dynamicDefault = [[self class] loadDynamicDefaultImageForOrientation:UIInterfaceOrientationLandscapeLeft])) {
        self.dynamicDefaultOrientation = UIInterfaceOrientationLandscapeLeft;
    }
}

- (UIImage *)dynamicDefaultImageForOrientation:(UIInterfaceOrientation)orientation {
    if(UIInterfaceOrientationIsLandscape(orientation) == UIInterfaceOrientationIsLandscape(dynamicDefaultOrientation)) {
        return dynamicDefault;
    } else {
        return nil;
    }
}

- (UIImage *)nonDynamicDefaultImageForOrientation:(UIInterfaceOrientation)orientation {
    NSString *basename = nil;
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        basename = [infoDict objectForKey:@"UILaunchImageFile~ipad"];
    }
    if(!basename) {
        basename = [infoDict objectForKey:@"UILaunchImageFile~iphone"];
    }
    if(!basename) {
        basename = [infoDict objectForKey:@"UILaunchImageFile"];
    }
    if(!basename) {
        basename = @"Default";
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            return [UIImage imageNamed:[basename stringByAppendingString:@"-Landscape.png"]];
        } else {
            return [UIImage imageNamed:[basename stringByAppendingString:@"-Portrait.png"]];
        }
    } else {
        return [UIImage imageNamed:[basename stringByAppendingString:@".png"]];
    }
}

- (void)setUpImageForOrientation:(UIInterfaceOrientation)orientation {
    if(!fadesBegun) {
        [self.dynamicImageView removeFromSuperview];
        self.dynamicImageView = nil;
        
        UIImage *image = [self dynamicDefaultImageForOrientation:orientation];
        if(image) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.contentMode = UIViewContentModeBottom;
            imageView.image = image;
            self.dynamicImageView = imageView;
            [self.view addSubview:imageView];
            [imageView release];
        }
        
        
        [self.nonDynamicImageView removeFromSuperview];
        self.nonDynamicImageView = nil;

        image = [self nonDynamicDefaultImageForOrientation:orientation];
        if(image) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.contentMode = UIViewContentModeBottom;
            imageView.image = image;
            self.nonDynamicImageView = imageView;
            [self.view addSubview:imageView];
            [imageView release];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    viewOnScreen = YES;
    [self setUpImageForOrientation:self.interfaceOrientation];
}

- (void)viewDidDisappear:(BOOL)animated {
    viewOnScreen = NO;
}

- (void)loadView {
    UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    mainView.backgroundColor = [UIColor clearColor];
    mainView.opaque = NO;
    self.view = mainView;
    [mainView release];
    [self loadDynamicDefaults];
}

- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailableDone {
    [self.nonDynamicImageView removeFromSuperview];
    self.nonDynamicImageView = nil;
    
    // Retained at the start of the animation.
    [self release];
    
    if(doAfterFadeDefaultBlock) {
        doAfterFadeDefaultBlock();
        [doAfterFadeDefaultBlock release];
        doAfterFadeDefaultBlock = nil;
    }
}


- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailableThenDo:(void(^)(void))doAfterwardsBlock
{
    // Fade and slightly zoom the default image, revealing the dynamic
    // image behind, if there is one.
    self.fadesBegun = YES;
    if(self.dynamicImageView) {
        doAfterFadeDefaultBlock = [doAfterwardsBlock copy];
        
        UIImageView *imageView = self.nonDynamicImageView;
        [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
        [UIView setAnimationDuration:1.0/5.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fadeOutDefaultImageIfDynamicImageAlsoAvailableDone)];
        imageView.alpha = 0;
        imageView.transform = CGAffineTransformScale(imageView.transform, 1.2f, 1.2f);
        [UIView commitAnimations];
        [self retain];    
    } else {
        doAfterwardsBlock();
    }
}

- (void)fadeOutCompletlyDone {
    [self.nonDynamicImageView removeFromSuperview];
    self.nonDynamicImageView = nil;

    [self.dynamicImageView removeFromSuperview];
    self.dynamicImageView = nil;
    
    [self.view removeFromSuperview];
    self.view = nil;

    // Retained at the start of the animation.
    [self release];
    
    if(doAfterFadeOutCompletlyBlock) {
        doAfterFadeOutCompletlyBlock();
        [doAfterFadeOutCompletlyBlock release];
        doAfterFadeOutCompletlyBlock = nil;
    }
}

- (void)fadeOutCompletlyThenDo:(void(^)(void))doAfterwardsBlock {
    self.fadesBegun = YES;
    doAfterFadeOutCompletlyBlock = [doAfterwardsBlock copy];
    if(self.dynamicImageView) {
        // Fade the dynamic image (don't zoom it - idea is that the UI behind
        // it will be similar to it).
        // The default image should already have been removed by 
        // -fadeOutDefaultImageIfDynamicImageAlsoAvailable, above.
        UIImageView *imageView = self.dynamicImageView;
        [UIView beginAnimations:@"FadeOutDynamicDefault" context:nil];
        [UIView setAnimationDuration:1.0/3.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fadeOutCompletlyDone)];
        imageView.alpha = 0;
        [UIView commitAnimations];
        [self retain];
    } else {
        // Fade and slightly zoom the default image, revealing the UI.
        UIImageView *imageView = self.nonDynamicImageView;
        [UIView beginAnimations:@"FadeOutDynamicDefault" context:nil];
        [UIView setAnimationDuration:1.0/5.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fadeOutCompletlyDone)];
        imageView.alpha = 0;
        imageView.transform = CGAffineTransformScale(imageView.transform, 1.2f, 1.2f);
        [UIView commitAnimations];
        [self retain];        
    }
    if([UIViewController respondsToSelector:@selector(attemptRotationToDeviceOrientation)]) {
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(viewOnScreen) {
        [self setUpImageForOrientation:self.interfaceOrientation];
    }
}

@end
