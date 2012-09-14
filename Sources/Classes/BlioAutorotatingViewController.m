//
//  BlioAutorotatingViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 12/09/2012.
//
//

#import "BlioAutorotatingViewController.h"

static NSArray *sPlistDefinedOrientations = nil;
static UIInterfaceOrientationMask sPlistDefinedOrientationMask = 0;

static void EnsureRotationControlInitialized()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *plistOrientations = nil;
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            plistOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations~ipad"];
        }
        if(!plistOrientations) {
            plistOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
        }
        
        NSMutableArray *buildPlistDefinedOrientations = [NSMutableArray array];
        for(NSString *orientationString in plistOrientations) {
            if([orientationString isEqualToString:@"UIInterfaceOrientationPortrait"]) {
                [buildPlistDefinedOrientations addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait]];
                sPlistDefinedOrientationMask |= UIInterfaceOrientationMaskPortrait;
            } else if([orientationString isEqualToString: @"UIInterfaceOrientationPortraitUpsideDown"]) {
                [buildPlistDefinedOrientations addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortraitUpsideDown]];
                sPlistDefinedOrientationMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
            } else if([orientationString isEqualToString:  @"UIInterfaceOrientationLandscapeLeft"]) {
                [buildPlistDefinedOrientations addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft]];
                sPlistDefinedOrientationMask |= UIInterfaceOrientationMaskLandscapeLeft;
            } else if([orientationString isEqualToString: @"UIInterfaceOrientationLandscapeRight"]) {
                [buildPlistDefinedOrientations addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight]];
                sPlistDefinedOrientationMask |= UIInterfaceOrientationMaskLandscapeRight;
            }
        }
        
        sPlistDefinedOrientations = [buildPlistDefinedOrientations retain];
    });
}


#pragma mark - iOS 5 and below.

static BOOL BlioAutorotatingViewControllerShouldAutorotateToInterfaceOrientation(UIInterfaceOrientation toInterfaceOrientation)
{
    return [sPlistDefinedOrientations containsObject:[NSNumber numberWithInteger:toInterfaceOrientation]];
}

#pragma mark - iOS 6 and above.

static BOOL BlioAutorotatingViewControllerShouldAutorotate(void)
{
    return YES;
}

static UIInterfaceOrientationMask BlioAutorotatingViewControllerSupportedInterfaceOrientations(void)
{
    return sPlistDefinedOrientationMask;
}


@implementation BlioAutorotatingViewController

+ (void)initialize
{
    if(self == [BlioAutorotatingViewController class]) {
        EnsureRotationControlInitialized();
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return BlioAutorotatingViewControllerShouldAutorotateToInterfaceOrientation(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return BlioAutorotatingViewControllerShouldAutorotate();
}

- (NSUInteger)supportedInterfaceOrientations
{
    return BlioAutorotatingViewControllerSupportedInterfaceOrientations();
}

@end


@implementation BlioAutorotatingTableViewController

+ (void)initialize
{
    if(self == [BlioAutorotatingTableViewController class]) {
        EnsureRotationControlInitialized();
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return BlioAutorotatingViewControllerShouldAutorotateToInterfaceOrientation(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return BlioAutorotatingViewControllerShouldAutorotate();
}

- (NSUInteger)supportedInterfaceOrientations
{
    return BlioAutorotatingViewControllerSupportedInterfaceOrientations();
}

@end

@implementation BlioAutorotatingNavigationController

+ (void)initialize
{
    if(self == [BlioAutorotatingNavigationController class]) {
        EnsureRotationControlInitialized();
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return BlioAutorotatingViewControllerShouldAutorotateToInterfaceOrientation(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return BlioAutorotatingViewControllerShouldAutorotate();
}

- (NSUInteger)supportedInterfaceOrientations
{
    return BlioAutorotatingViewControllerSupportedInterfaceOrientations();
}

@end



