//
//  BlioAppAppDelegate.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <libEucalyptus/EucSharedHyphenator.h>
#import <pthread.h>
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
    realDefaultImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    CGRect defaultFrame = realDefaultImageView.frame;
    defaultFrame.origin.y = CGRectGetHeight(window.bounds) - CGRectGetHeight(defaultFrame);
    [realDefaultImageView setFrame:defaultFrame];
    
    [window addSubview:realDefaultImageView];
    [window makeKeyAndVisible];
        
    [self performSelector:@selector(delayedApplicationDidFinishLaunching:) withObject:application afterDelay:0];
}

static void *background_init_thread(void * arg) {
    initialise_shared_hyphenator();
    return NULL;
}

- (void)performBackgroundInitialisation {    
    // Initialising the hyphenator is expensive, so we start it as early as possible
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    struct sched_param param = {0};
    int ret = pthread_attr_getschedparam(&attr, &param);
    if(ret != 0) {
        NSLog(@"pthread_attr_getschedparam returned %ld", (long)ret);
    }
    param.sched_priority = sched_get_priority_min(SCHED_RR);
    ret = pthread_attr_setschedparam(&attr, &param);
    if(ret != 0) {
        NSLog(@"pthread_attr_setschedparam returned %ld", (long)ret);
    }
    
    pthread_t hit;
    ret = pthread_create(&hit, &attr, background_init_thread, NULL);
    if(ret != 0) {
        NSLog(@"pthread_create returned %ld", (long)ret);
    }
    
    ret = pthread_attr_destroy(&attr);
    if(ret != 0) {
        NSLog(@"pthread_attr_destroy returned %ld", (long)ret);
    }    
}

- (void)switchStatusBar
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)delayedApplicationDidFinishLaunching:(UIApplication *)application {
    [self performBackgroundInitialisation];
    
    [window addSubview:[navigationController view]];
    [window sendSubviewToBack:[navigationController view]];
    window.backgroundColor = [UIColor blackColor];
    
    [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
    [UIView setAnimationDuration:1.0/5.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDelegate:realDefaultImageView];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    realDefaultImageView.alpha = 0;
    realDefaultImageView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    [UIView commitAnimations];    
    
    [realDefaultImageView release];
    realDefaultImageView = nil;
    
    [self performSelector:@selector(switchStatusBar) withObject:nil afterDelay:0];
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

