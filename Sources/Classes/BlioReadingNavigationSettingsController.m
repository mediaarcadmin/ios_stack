//
//  BlioTapZoomSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 10/23/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioReadingNavigationSettingsController.h"
#import "BlioAppSettingsConstants.h"

@implementation BlioReadingNavigationSettingsController

@synthesize pbTableView;


#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Reading Navigation",@"\"Reading Navigation\" view controller title.");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
#endif
	}
	return self;
}

- (void)loadView
{	
	// create and configure the table view
	pbTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	pbTableView.delegate = self;
	pbTableView.dataSource = self;
	pbTableView.autoresizesSubviews = YES;
	self.view = pbTableView;

}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	CGFloat viewHeight = self.tableView.contentSize.height;
	NSLog(@"viewHeight: %f",viewHeight);
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);	
	
}

#pragma mark -
#pragma mark View lifecycle

// TODO landscape layout
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
        return YES;
}

#pragma mark UITableViewDataSource Methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	switch (section)
	{
		case 0:
		{
			title = NSLocalizedString(@"Set to have a single tap in fixed view zoom to the next block of text, rather than advance to the next page.",@"\"Tap behavior text\" table header in Navigation Settings View");
			break;
		}
	}
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kCellHeight; 
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *ListCellIdentifier = @"UITableViewCelldentifier";
	UITableViewCell *cell;
	
	cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
	}
	
	switch (indexPath.section)
	{
		case 0:
		{
			cell.textLabel.text = NSLocalizedString(@"Tap Zooms To Block","\"Tap Zooms To Block\" cell label");
			UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(200.0f, 9.0f, 80.0f, 28.0f)];
			[cell addSubview:switchView];
			if ( [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey] == YES ) 
				[switchView setOn:YES animated:NO];
			else 
				// This is the initial value.
				[switchView setOn:NO animated:NO];
			[switchView addTarget:self action:@selector(changeTapZooms:) forControlEvents:UIControlEventValueChanged];
			[switchView release];
			break;
		}
	}
	
	return cell;
}

#pragma mark Event handlers


- (void)changeTapZooms:(UIControl*)sender {
	if ( ((UISwitch*)sender).on )
		  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBlioTapZoomsDefaultsKey];
	else
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kBlioTapZoomsDefaultsKey];
	
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[pbTableView release];
    [super dealloc];
}


@end

