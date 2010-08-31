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

@end

@implementation BlioViewSettingsPopover

@synthesize contentsView;

- (void)dealloc {
    self.contentsView = nil;
    [super dealloc];
}

- (id)initWithDelegate:(id)newDelegate {
    
    BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:newDelegate];
    UIViewController *contentController = [[UIViewController alloc] init];
    contentController.view = aContentsView;
    
    if ((self = [super initWithContentViewController:contentController])) {
        // Custom initialization
        self.contentsView = aContentsView;
        self.contentViewController = contentController;
    }
    
    [aContentsView release];
    [contentController release];

    return self;
}

@end
