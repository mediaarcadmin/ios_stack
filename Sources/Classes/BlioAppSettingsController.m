//
//  BlioAppSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAppSettingsController.h"
#import "BlioReadingVoiceSettingsViewController.h"
#import "BlioWebToolSettingsController.h"
#import "BlioReadingNavigationSettingsController.h"
#import "BlioAboutSettingsController.h"
#import "BlioHelpSettingsController.h"
#import "BlioMyAccountViewController.h"
#import "BlioStoreManager.h"

@implementation BlioAppSettingsController


- (BlioAppSettingsController*)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = @"App Settings";
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
    }
    return self;
}

-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		[self.tableView reloadData];
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	}
}

- (void)loadView {
	[super loadView];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
												   initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button")
												   style:UIBarButtonItemStyleDone 
												   target:self
												   action:@selector(dismissSettingsView:)]
												  autorelease];		
	}
}

- (void) dismissSettingsView: (id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	CGFloat viewHeight = self.tableView.contentSize.height;
	NSLog(@"viewHeight: %f",viewHeight);
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);
	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
        return YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) 
		return 2;
	return 1;
}
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	switch (section)
	{
		case 0:
		{
			title = NSLocalizedString(@"Reading",@"\"Reading settings\" table header in Application Settings View");
			break;
		}
	}
	return title;
}
*/
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
	switch ( [indexPath section] ) {
		case 0:
			switch ([indexPath row])
			{
				case 0:
					[cell.textLabel setText:@"Voice"];
					break;
//				case 1:
//					[cell.textLabel setText:@"Navigation"];
//					break;
				case 1:
					[cell.textLabel setText:@"Web Tools"];
					break;
			}
			break;
		case 1:
			if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
				cell.textLabel.text = [NSString stringWithFormat:@"My Account: %@",[[BlioStoreManager sharedInstance] usernameForSourceID:BlioBookSourceOnlineStore]];
				//			 cell.textLabel.text = [NSString stringWithFormat:@"Logged in as %@",[[BlioStoreManager sharedInstance] usernameForSourceID:BlioBookSourceOnlineStore]];
			}
			else {
//				cell.textLabel.textAlignment = UITextAlignmentCenter;
//				cell.accessoryType = UITableViewCellAccessoryNone;
//				cell.textLabel.text = @"Login";
				cell.textLabel.text = @"My Account";
			}
			break;
		case 2:
			[cell.textLabel setText:@"Help"];
			break;
		case 3:
			[cell.textLabel setText:@"About"];
			break;
		default:
			break;
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioReadingVoiceSettingsViewController *audioController;
	BlioWebToolSettingsController *webToolController;
//	BlioReadingNavigationSettingsController *readingnavController;
	BlioHelpSettingsController *helpController;
	BlioAboutSettingsController *aboutController;
	BlioMyAccountViewController *myAccountController;
	switch ( [indexPath section] ) {
		case 0:
			switch (indexPath.row)
			{
				case 0:
					audioController = [[BlioReadingVoiceSettingsViewController alloc] init];
					[self.navigationController pushViewController:audioController animated:YES];
					[audioController release];
					break;
//				case 1:
//					readingnavController = [[BlioReadingNavigationSettingsController alloc] init];
//					[self.navigationController pushViewController:readingnavController animated:YES];
//					[readingnavController release];
//					break;
				case 1:
					webToolController = [[BlioWebToolSettingsController alloc] init];
					[self.navigationController pushViewController:webToolController animated:YES];
					[webToolController release];
					break;
			}
			break;
		case 1:
			if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
				myAccountController = [[BlioMyAccountViewController alloc] init];
				[self.navigationController pushViewController:myAccountController animated:YES];
				[myAccountController release];
			}
			else {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
				[[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 2:
			helpController = [[BlioHelpSettingsController alloc] init];
			[self.navigationController pushViewController:helpController animated:YES];
			[helpController release];
			break;
		case 3:
			aboutController = [[BlioAboutSettingsController alloc] init];
			[self.navigationController pushViewController:aboutController animated:YES];
			[aboutController release];
			break;
		default:
			break;
	}
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


@end

