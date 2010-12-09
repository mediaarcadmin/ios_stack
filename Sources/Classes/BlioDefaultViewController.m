    //
//  BlioDefaultViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 09/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioDefaultViewController.h"
#import <unistd.h>


@implementation BlioDefaultViewController


- (NSString *)dynamicDefaultPngPathForOrientation:(UIInterfaceOrientation)orientation {
    NSString *tmpDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [tmpDir stringByAppendingPathComponent:@"BlioDynamicDefault-%@.png"];
}

- (UIImage *)dynamicDefaultImageForOrientation:(UIInterfaceOrientation)orientation {
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
    UIImage *image = [self dynamicDefaultImageForOrientation:orientation];
    if(!image) {
        image = [self nonDynamicDefaultImageForOrientation:orientation];
    }
    [((UIImageView *)self.view) setImage:image];
}

- (void)viewWillAppear:(BOOL)animated {
    viewOnScreen = YES;
    [self setUpImageForOrientation:self.interfaceOrientation];
}

- (void)viewDidDisappear:(BOOL)animated {
    viewOnScreen = NO;
}

- (void)loadView {
    UIImageView *realDefaultImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    realDefaultImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleHeight;
    realDefaultImageView.contentMode = UIViewContentModeBottom;
    self.view = realDefaultImageView; 
    [realDefaultImageView release];            
}

- (void)fadeDone {
    [[self view] removeFromSuperview];
    [self release];
}

- (void)fadeOutDefaultImage {
    [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
    [UIView setAnimationDuration:1.0/5.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(fadeDone)];
    self.view.alpha = 0;
    self.view.transform = CGAffineTransformScale(self.view.transform, 1.2f, 1.2f);
    [UIView commitAnimations];
    [self retain];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(viewOnScreen) {
        [self setUpImageForOrientation:self.interfaceOrientation];
    }
}

@end
