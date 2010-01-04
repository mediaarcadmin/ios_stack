//
//  BlioAppAppDelegate.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioAppAppDelegate.h"
#import "BlioLibraryViewController.h"

static NSString * const kBlioInBookViewDefaultsKey = @"inBookView";

@interface BlioAppAppDelegate (private)
- (NSString *)dynamicDefaultPngPath;
@end

@implementation BlioAppAppDelegate

@synthesize window;
@synthesize navigationController;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Override point for customization after app launch   
	//[window addSubview:[navigationController view]];

    
    NSString *dynamicDefaultPngPath = [self dynamicDefaultPngPath];
    NSData *imageData = [NSData dataWithContentsOfFile:dynamicDefaultPngPath];
    
    // After loading the image data, but before decoding it, remove it from 
    // the filesystem in case the PNG is corrupt.
    unlink([dynamicDefaultPngPath fileSystemRepresentation]);
    
    if(!imageData) {
        imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LibraryGridViewController.png"]];
    }
    
    UIImage *dynamicDefaultImage = [UIImage imageWithData:imageData];
    if(!dynamicDefaultImage) {
        NSLog(@"Could not load dynamic default.png");
    } else {
        window.backgroundColor = [UIColor colorWithPatternImage:dynamicDefaultImage];
    }
    
    imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Default.png"]];
    UIImageView *realDefaultImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    [window addSubview:realDefaultImageView];
    
    [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
    [UIView setAnimationDuration:1.0/5.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    realDefaultImageView.alpha = 0;
    realDefaultImageView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    [UIView commitAnimations];
    
    [window makeKeyAndVisible];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:kBlioInBookViewDefaultsKey]) {
        //_mainTabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
        [application setStatusBarHidden:YES animated:YES];
    } else {
        [application setStatusBarHidden:NO animated:YES];
        [application setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [self performSelector:@selector(delayedApplicationDidFinishLaunching:) withObject:application afterDelay:0];
     
}

- (void)delayedApplicationDidFinishLaunching:(UIApplication *)application {
    [window addSubview:[navigationController view]];
    [window sendSubviewToBack:[navigationController view]];
    window.backgroundColor = [UIColor blackColor];
}

- (NSString *)dynamicDefaultPngPath {
    NSString *tmpDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [tmpDir stringByAppendingPathComponent:@".BlioDynamicDefault.png"];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

@end

