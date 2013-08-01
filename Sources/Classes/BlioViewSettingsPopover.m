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
        if([contentController respondsToSelector:@selector(setPreferredContentSize:)]) {
            contentController.preferredContentSize = contentsView.preferredSize;
        }
        if([contentController respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            contentController.edgesForExtendedLayout = UIRectEdgeNone;
        }
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

@end
