    //
//  BlioViewSettingsPopover.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettingsPopover.h"
#import "BlioViewSettingsContentsView.h"
#import "BlioViewSettingsFontAndSizeContentsView.h"

@interface BlioViewSettingsPopover()

@property (nonatomic, retain) BlioViewSettingsContentsView *settingsContentsView;
@property (nonatomic, assign) id<BlioViewSettingsDelegate> viewSettingsDelegate;

@end

@implementation BlioViewSettingsPopover

@synthesize settingsContentsView, viewSettingsDelegate;

- (void)dealloc {
    self.settingsContentsView = nil;
    [super dealloc];
}

- (id)initWithDelegate:(id)newDelegate {
    
    BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:newDelegate];
    UIViewController *contentController = [[UIViewController alloc] init];
    contentController.contentSizeForViewInPopover = CGSizeMake(360, [aContentsView contentsHeight]);
    contentController.view = aContentsView;
    contentController.navigationItem.title = NSLocalizedString(@"Reading Settings", "Title for Reading Settings Popover");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:contentController];
    navController.delegate = self;
    
    if ((self = [super initWithContentViewController:navController])) {
        // Custom initialization
        self.settingsContentsView = aContentsView;
        self.delegate = self;
        self.viewSettingsDelegate = newDelegate;
    }
    
    [aContentsView release];
    [contentController release];
    [navController release];

    return self;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self.viewSettingsDelegate viewSettingsDidDismiss:self];
    
    self.settingsContentsView.delegate = nil;
    self.settingsContentsView  = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [((BlioViewSettingsContentsView *)self.settingsContentsView) refreshSettings];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    // Need to hide and show nav bar to workaround bug when rotating which hides the nav bar
    [(UINavigationController *)self.contentViewController setNavigationBarHidden:YES];
    [(UINavigationController *)self.contentViewController setNavigationBarHidden:NO];
}

- (void)pushFontSettings
{
    BlioViewSettingsFontAndSizeContentsView *aFontSettingsView = [[BlioViewSettingsFontAndSizeContentsView alloc] initWithDelegate:self.viewSettingsDelegate];
    
    UIViewController *fontSettingsController = [[UIViewController alloc] init];
    fontSettingsController.contentSizeForViewInPopover = ((UINavigationController *)self.contentViewController).topViewController.contentSizeForViewInPopover;
    fontSettingsController.view = aFontSettingsView;
    fontSettingsController.navigationItem.title = NSLocalizedString(@"Typography", "Title for Typography Settings Popover");
    
    [((UINavigationController *)self.contentViewController) pushViewController:fontSettingsController animated:YES];
    
    [fontSettingsController release];
    [aFontSettingsView release];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([viewController.view isKindOfClass:[BlioViewSettingsContentsView class]]) {
        [((BlioViewSettingsContentsView *)viewController.view) refreshSettings];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([viewController.view isKindOfClass:[BlioViewSettingsFontAndSizeContentsView class]]) {
        [((BlioViewSettingsFontAndSizeContentsView *)viewController.view) flashScrollIndicators];
    }
}

@end
