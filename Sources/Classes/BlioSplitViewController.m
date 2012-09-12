    //
//  BlioSplitViewController.m
//
//  Created by Don Shin on 6/25/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioSplitViewController.h"

@implementation BlioSplitViewController

@synthesize delegate = _delegate;
@synthesize splitView;
- (id)init
{
	self = [super init];
	if (self)
	{

	}
	return self;
}
- (void) setViewControllers:(NSArray *)newArray {
    if (_viewControllers != newArray) {
        if (_viewControllers != nil) [_viewControllers release];
        _viewControllers = [NSArray arrayWithArray:newArray];
        [_viewControllers retain];

		UIView * view1 = [(UIViewController*)[self.viewControllers objectAtIndex:0] view];
		UIView * view2 = [(UIViewController*)[self.viewControllers objectAtIndex:1] view];
		[self.view addSubview:view1];
		[self.view addSubview:view2];
		self.splitView.view1 = view1;
		self.splitView.view2 = view2;
		[self.view bringSubviewToFront:view1];
		[splitView layoutSubviews];
    }


}
- (NSArray *)viewControllers {
	return _viewControllers;
}



// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	BlioSplitView * newView = [[BlioSplitView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	newView.backgroundColor = [UIColor blackColor];
	self.view = newView;
	self.splitView = newView;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [newView release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.view layoutSubviews];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.viewControllers = nil;
	self.splitView = nil;
    [super dealloc];
}


@end
