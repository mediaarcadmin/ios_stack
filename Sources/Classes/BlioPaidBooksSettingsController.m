//
//  BlioPaidBooksSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 7/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioPaidBooksSettingsController.h"
#import "BlioAppSettingsConstants.h"
#import "BlioStoreManager.h"
#import "BlioDrmManager.h"
#import "BlioAlertManager.h"

@implementation BlioPaidBooksSettingsController

@synthesize pbTableView, activityIndicator, registrationOn, drmSessionManager;;


#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Device Registration",@"\"Device Registration\" view controller title.");
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
//		}
//#endif
	}
	return self;
}

- (BlioDrmSessionManager*)drmSessionManager {
	if ( !drmSessionManager ) 
		[self setDrmSessionManager:[[BlioDrmSessionManager alloc] initWithBookID:nil]];
	return drmSessionManager;
}

- (void)loadView
{	
	// create and configure the table view
	pbTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	pbTableView.delegate = self;
	pbTableView.dataSource = self;
	pbTableView.autoresizesSubviews = YES;
	self.view = pbTableView;
	
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activityIndicator setCenter:CGPointMake(300.0f, 20.0f)];
	[self.navigationController.navigationBar addSubview:activityIndicator];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	BlioDeviceRegisteredStatus status = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDeviceRegisteredDefaultsKey];
	if ( status == BlioDeviceRegisteredStatusRegistered ) {
		if ( !self.registrationOn ) {
			if ( ![[BlioDrmManager getDrmManager] leaveDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]] ) {
				// TODO: alert
				NSLog(@"Display alert: didn't leave domain");
			}
		}
	}
	else if ( self.registrationOn ) {
		if (![[BlioDrmManager getDrmManager] joinDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] domainName:@"novel"] ) {
			// TODO: alert
			NSLog(@"Display alert: didn't join domain");
		}
	}	
	[activityIndicator stopAnimating];
}
*/ 

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
			title = NSLocalizedString(@"You may register up to five devices for reading books purchased from the Blio book store.",@"\"Registration text\" table header in Paid Books Settings View");
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
			cell.textLabel.text = NSLocalizedString(@"Registration","\"Registration\" cell label");
			UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(200.0f, 9.0f, 80.0f, 28.0f)];
			[switchView setTag:997];
			[cell addSubview:switchView];
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDeviceRegisteredDefaultsKey] == BlioDeviceRegisteredStatusRegistered ) {
				[switchView setOn:YES animated:NO];
				self.registrationOn = YES;
			}
			else {
				[switchView setOn:NO animated:NO];
				self.registrationOn = NO;
			}
			[switchView addTarget:self action:@selector(changeRegistration:) forControlEvents:UIControlEventValueChanged];
			[switchView release];
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

#pragma mark Event handlers


- (void)changeRegistration:(UIControl*)sender {
	//self.registrationOn = !self.registrationOn;
	
	sender.enabled = NO;
	[activityIndicator startAnimating];  // thread issue...
	if ( [(UISwitch*)sender isOn] ) {
		if ( ![self.drmSessionManager joinDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] domainName:@"novel"] ) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to register device. Please try again later.",@"Alert message shown when device registration fails.")
										delegate:self 
							   cancelButtonTitle:nil
							   otherButtonTitles:@"OK", nil];
		}
	}
	else {
		if ( ![self.drmSessionManager leaveDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]] ) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"UNREGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to unregister device. Please try again later.",@"Alert message shown when device unregistration fails.")
										delegate:self 
							   cancelButtonTitle:nil
							   otherButtonTitles:@"OK", nil];
		}
	}
	[activityIndicator stopAnimating];
	[self.navigationController popViewControllerAnimated:YES];
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
	if ( drmSessionManager )
		[drmSessionManager release];
	[pbTableView release];
	[activityIndicator release];
    [super dealloc];
}


@end

