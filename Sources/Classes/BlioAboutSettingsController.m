//
//  BlioAboutSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 7/30/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioAboutSettingsController.h"
#import "BlioAppSettingsConstants.h"
#import "BlioEULATextController.h"
#import "BlioVersionController.h"

@implementation BlioAboutSettingsController

@synthesize aboutTableView;

#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"About",@"\"About\" view controller title.");
	}
	return self;
}

- (void)loadView
{	
	// create and configure the table view
	aboutTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	aboutTableView.delegate = self;
	aboutTableView.dataSource = self;
	aboutTableView.autoresizesSubviews = YES;
	self.view = aboutTableView;
}

#pragma mark -
#pragma mark View lifecycle

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
	return 2;
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
			cell.textLabel.text = NSLocalizedString(@"Version","\"Version and Credits\" cell label");	
			break;
		}
		case 1:
		{
			cell.textLabel.text = NSLocalizedString(@"Legal","\"Licenses\" cell label");
			break;
		}	
	}
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	return cell;
}

#pragma mark UITableViewDelegate Methods and helpers


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath 
{
	BlioEULATextController *eulaController;
	BlioVersionController *versionController;
	switch ( [indexPath section] ) {
		case 0:
			versionController = [[BlioVersionController alloc] init];
			[self.navigationController pushViewController:versionController animated:YES];
			[versionController release];
			break;
		case 1:
			eulaController = [[BlioEULATextController alloc] init];
			[self.navigationController pushViewController:eulaController animated:YES];
			[eulaController release];
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


- (void)dealloc {
	[aboutTableView release];
    [super dealloc];
}


@end

