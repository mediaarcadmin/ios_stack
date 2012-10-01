//
//  BlioViewSettingsPopover.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettingsPopover.h"
#import "BlioViewSettingsContentsView.h"

@interface BlioViewSettingsPopover () <UIPopoverControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) BlioModalPopoverController *popoverController;

@end

@implementation BlioViewSettingsPopover

- (void)presentFromBarButtonItem:(UIBarButtonItem *)item
                       inToolbar:(UIToolbar *)toolbar
                        forEvent:(UIEvent *)event
{
    BlioViewSettingsContentsView *contentsView = self.contentsView;
    
    UIViewController *contentController = [[UIViewController alloc] init];
    if(contentController) {
        contentController.contentSizeForViewInPopover = contentsView.preferredSize;
        contentController.navigationItem.title = contentsView.navigationItemTitle;
        contentController.view = contentsView;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:contentController];
        if(navController) {
            navController.delegate = self;
            
            BlioModalPopoverController *popoverController = [[BlioModalPopoverController alloc] initWithContentViewController:navController];
            if(popoverController) {
                popoverController.delegate = self;
                self.popoverController = popoverController;

                [popoverController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                
                [popoverController release];
            }
            [navController release];
        }
        [contentController release];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popoverController = nil;
    [self.delegate viewSettingsInterfaceDidDismiss:self];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self.popoverController dismissPopoverAnimated:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.popoverController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.contentsView refreshSettings];
    
    [self.popoverController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Need to hide and show nav bar to workaround bug when rotating which hides the nav bar
    [(UINavigationController *)self.popoverController.contentViewController setNavigationBarHidden:YES];
    [(UINavigationController *)self.popoverController.contentViewController setNavigationBarHidden:NO];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.contentsView flashScrollIndicators];
}

/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [((BlioViewSettingsGeneralContentsView *)self.settingsContentsView) refreshSettings];
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
    fontSettingsController.navigationItem.title = NSLocalizedString(@"Font Options", "Title for Font Options Popover");
    
    [((UINavigationController *)self.contentViewController) pushViewController:fontSettingsController animated:YES];
    
    [fontSettingsController release];
    [aFontSettingsView release];
}


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([viewController.view isKindOfClass:[BlioViewSettingsGeneralContentsView class]]) {
        [((BlioViewSettingsGeneralContentsView *)viewController.view) refreshSettings];
    }
}
*/


@end
