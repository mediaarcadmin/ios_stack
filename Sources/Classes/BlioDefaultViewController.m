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
        deviceString = @"Pad";
    } else {
        deviceString = @"Phone";
    }
    
    return [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"BlioDynamicDefault-%@-%@.png", deviceString, orientationString]];
}

+ (UIImage *)loadDynamicDefaultImageForOrientation:(UIInterfaceOrientation)orientation {
    NSString *dynamicDefaultPngPath = [self dynamicDefaultPngPathForOrientation:orientation];
    NSData *imageData = [NSData dataWithContentsOfFile:dynamicDefaultPngPath];
    
    // After loading the image data, but before decoding it, remove it from 
    // the filesystem in case the PNG is corrupt (in which case we might crash,
    // it seems, so we don't want to try the same one again the next time 
    // round!)
    unlink([dynamicDefaultPngPath fileSystemRepresentation]);
    
    if(imageData) {
        return [UIImage imageWithData:imageData];
    }
    return nil;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            return [UIImage imageNamed:@"Default-Landscape.png"];
        } else {
            return [UIImage imageNamed:@"Default-Portrait.png"];
        }
    } else {
        return [UIImage imageNamed:@"Default.png"];
    }
}

- (void)setUpImageForOrientation:(UIInterfaceOrientation)orientation {
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
    [self loadDynamicDefaults];
}

- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailableDone {
    [self.nonDynamicImageView removeFromSuperview];
    self.nonDynamicImageView = nil;
    
    // Retained at the start of the animation.
    [self release];
}

- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailable  {
    self.fadesBegun = YES;
    if(self.dynamicImageView) {
        UIImageView *imageView = self.nonDynamicImageView;
        UIWindow *window = self.view.window;
        CGPoint windowCenter = [window convertPoint:imageView.center fromView:imageView];
        [imageView removeFromSuperview];
        imageView.center = windowCenter;
        if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            imageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        } else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        [window addSubview:imageView];
        
        [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
        [UIView setAnimationDuration:1.0/5.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fadeOutDefaultImageIfDynamicImageAlsoAvailableDone)];
        imageView.alpha = 0;
        imageView.transform = CGAffineTransformScale(imageView.transform, 1.2f, 1.2f);
        [UIView commitAnimations];
        [self retain];    
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
}

- (void)fadeOutCompletly {
    self.fadesBegun = YES;
    if(self.dynamicImageView) {
        UIImageView *imageView = self.dynamicImageView;
        UIWindow *window = self.view.window;
        CGPoint windowCenter = [window convertPoint:imageView.center fromView:imageView];
        [imageView removeFromSuperview];
        imageView.center = windowCenter;
        if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            imageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        } else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        [window addSubview:imageView];
        
        [UIView beginAnimations:@"FadeOutDynamicDefault" context:nil];
        [UIView setAnimationDuration:1.0/3.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fadeOutCompletlyDone)];
        imageView.alpha = 0;
        //imageView.transform = CGAffineTransformScale(self.dynamicImageView.transform, 1.2f, 1.2f);
        [UIView commitAnimations];
        [self retain];
    } else {
        UIImageView *imageView = self.nonDynamicImageView;
        UIWindow *window = self.view.window;
        CGPoint windowCenter = [window convertPoint:imageView.center fromView:imageView];
        [imageView removeFromSuperview];
        imageView.center = windowCenter;
        if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            imageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        } else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        [window addSubview:imageView];        

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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(fadesBegun) {
        return NO;
    } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        return NO;
    }
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(viewOnScreen) {
        [self setUpImageForOrientation:self.interfaceOrientation];
    }
}

@end
