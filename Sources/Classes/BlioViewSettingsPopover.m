    //
//  BlioViewSettingsPopover.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettingsPopover.h"
#import "BlioViewSettingsContentsView.h"

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
    contentController.contentSizeForViewInPopover = CGSizeMake(320, [aContentsView contentsHeight]);
    contentController.view = aContentsView;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:contentController];
    contentController.navigationItem.title = NSLocalizedString(@"Visual Options", "Title for View Settings Popover");
    
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
    [self.viewSettingsDelegate dismissViewSettings:self];
}

@end
