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

@property (nonatomic, retain) BlioViewSettingsContentsView *contentsView;
@property (nonatomic, assign) id<BlioViewSettingsDelegate> viewSettingsDelegate;

@end

@implementation BlioViewSettingsPopover

@synthesize contentsView, viewSettingsDelegate;

- (void)dealloc {
    self.contentsView = nil;
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
        self.contentsView = aContentsView;
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
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [((BlioViewSettingsContentsView *)self.contentsView) refreshSettings];
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
    fontSettingsController.navigationItem.title = NSLocalizedString(@"Font & Size", "Title for Font & Size Settings Popover");
    
    [((UINavigationController *)self.contentViewController) pushViewController:fontSettingsController animated:YES];
    
    [aFontSettingsView release];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if(viewController.view == self.contentsView) {
        [self.contentsView refreshSettings];
    }
}

@end
