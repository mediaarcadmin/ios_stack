//
//  BlioPaidBooksSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 7/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioPaidBooksSettingsController.h"
#import "BlioAppSettingsConstants.h"

@implementation BlioPaidBooksSettingsController

@synthesize pbTableView;


#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Paid Books",@"\"Paid Books\" view controller title.");
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
//		}
//#endif
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
			title = NSLocalizedString(@"You may register up to five devices for reading books purchased from the Blio book store.",@"\"Registration\" table header in Paid Books Settings View");
			break;
		}
		//case 1:
		//{
			//	title = NSLocalizedString(@"You may register up to two devices for reading textbooks purchased from the Blio book store.",@"\"Textbook registration\" table header in Paid Books Settings View");
		//	break;
		//}
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
			cell.textLabel.text = NSLocalizedString(@"Register Device","\"Register Device\" cell label");
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDeviceRegisteredDefaultsKey] == 1 )
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			else 
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			break;
		}
		//case 1:
		//{
			//	cell.textLabel.text = NSLocalizedString(@"Register Textbook-Reading Device","\"Register Textbook Device\" cell label");
			//if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioTextbookDeviceRegisteredDefaultsKey] == 1 )
			//	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			//else 
			//	[cell setAccessoryType:UITableViewCellAccessoryNone];
			//	break;
		//}
	}
	
	return cell;
}

#pragma mark UITableViewDelegate Methods and helpers

- (void)deselect:(id)sender
{
	[pbTableView deselectRowAtIndexPath:[pbTableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)newIndexPath 
{
	if ([[tableView cellForRowAtIndexPath:newIndexPath] accessoryType] == UITableViewCellAccessoryCheckmark) {
		[[tableView cellForRowAtIndexPath:newIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
		[[NSUserDefaults standardUserDefaults] setInteger:-1 forKey:kBlioDeviceRegisteredDefaultsKey];
	}
	else {
		[[tableView cellForRowAtIndexPath:newIndexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kBlioDeviceRegisteredDefaultsKey];
	}
	[self performSelector:@selector(deselect:) withObject:nil afterDelay:0.0];
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
    [super dealloc];
}


@end

