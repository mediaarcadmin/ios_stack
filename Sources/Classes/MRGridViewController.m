//
//  MRGridViewController.m
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

#import "MRGridViewController.h"


@implementation MRGridViewController
@synthesize gridView = _gridView;
@synthesize scrollView;

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight|
								  UIViewAutoresizingFlexibleWidth);
	self.view.autoresizesSubviews = YES;
	
	MRGridView* myGridView = [[MRGridView alloc]initWithFrame:[[self view] bounds]];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		myGridView.backgroundColor = [UIColor blackColor];
	}
	else {
		myGridView.backgroundColor = [UIColor whiteColor];
	}
#else
	myGridView.backgroundColor = [UIColor whiteColor];
#endif
	myGridView.autoresizingMask = (UIViewAutoresizingFlexibleHeight|
								   UIViewAutoresizingFlexibleWidth);
	
	myGridView.gridDelegate = self;
	myGridView.gridDataSource = self;
	self.gridView = myGridView;
	
	[[self view] addSubview: myGridView];
	[myGridView release];
	
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.gridView reloadData]; 
}

#pragma mark - 
#pragma mark MRGridViewDataSource methods

-(MRGridViewCell*)gridView:(MRGridView*)gridView cellForGridIndex: (NSInteger)index{
	static NSString* cellIdentifier = @"MRGridViewCell";
	MRGridViewCell* gridCell = [gridView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (gridCell == nil)
		gridCell = [[[MRGridViewCell alloc]initWithFrame:[gridView frameForCellAtGridIndex: index] reuseIdentifier:cellIdentifier] autorelease];
	return gridCell;
}

-(NSInteger)numberOfItemsInGridView:(MRGridView*)gridView{
	return 0;
}
-(BOOL) gridView:(MRGridView*)gridView canMoveCellAtIndex:(NSInteger)index {
	return YES;
}
-(void) gridView:(MRGridView*)gridView moveCellAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex{
	//no implementation here, must subclass to implement this function
}
-(void) gridView:(MRGridView*)gridView finishedMovingCellToIndex:(NSInteger)toIndex {

}
-(void) gridView:(MRGridView*)gridView commitEditingStyle:(MRGridViewCellEditingStyle)editingStyle forIndex:(NSInteger)index {

}

#pragma mark - 
#pragma mark MRGridViewDelegate methods

- (void)gridView:(MRGridView *)gridView didSelectCellAtIndex:(NSInteger)index{
	//TODO: highlight selected cell?
}

#pragma mark - 
#pragma mark UIViewController methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.gridView rearrangeCells];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.gridView setEditing:editing animated:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(NSString*)contentDescriptionForCellAtIndex:(NSInteger)index {
	// abstract method
	return nil;
	
}
- (void)dealloc {
	self.gridView = nil;
	self.scrollView = nil;
    [super dealloc];
}


@end
