//
//  BlioMyAccountViewController.m
//  BlioApp
//
//  Created by Don Shin on 10/15/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioMyAccountViewController.h"
#import "BlioStoreManager.h"
#import "BlioAppSettingsConstants.h"
#import "BlioDrmManager.h"
#import "BlioAlertManager.h"

@implementation BlioMyAccountViewController

@synthesize activityIndicator, registrationOn, drmSessionManager,delegate;

#pragma mark -
#pragma mark Initialization

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"My Account",@"\"My Account\" view controller title.");
        // TICKET 507: remove Logout button
//		UIBarButtonItem * aButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout",@"\"Logout\" bar button text label within My Account.") style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonPressed:)];
//		self.navigationItem.rightBarButtonItem = aButton;
//		[aButton release];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
    }
    return self;
}


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	CGFloat viewHeight = self.tableView.contentSize.height;
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);	
	
}
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

#pragma mark Event handlers

-(void)logoutButtonPressed:(id)sender {
	[[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
	[self.navigationController popViewControllerAnimated:YES];	
}
-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		[self.tableView reloadData];
	}
}

- (void)changeRegistration:(UIControl*)sender {
	//self.registrationOn = !self.registrationOn;
	
	sender.enabled = NO;
	
	BOOL changeSuccess = NO;
	if ( [(UISwitch*)sender isOn] ) {
		[activityIndicator startAnimating];  // thread issue...
		changeSuccess = [[BlioStoreManager sharedInstance] setDeviceRegistered:BlioDeviceRegisteredStatusRegistered forSourceID:BlioBookSourceOnlineStore];
		[activityIndicator stopAnimating];
		if (!changeSuccess) {
			if ([[BlioStoreManager sharedInstance] deviceRegisteredForSourceID:BlioBookSourceOnlineStore]) [(UISwitch*)sender setOn:YES];
			else {
                [(UISwitch*)sender setOn:NO];
                // TICKET 507: automatically logout when de-registering device (or registration fails for legacy logged in users).
                [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
                [self.navigationController popViewControllerAnimated:YES];	
                if ([delegate respondsToSelector:@selector(setDidDeregister:)]) [delegate setDidDeregister:YES];
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
                                             message:NSLocalizedStringWithDefaultValue(@"LOGGED_IN_BUT_REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"You have been logged out due to a registration error. Please try again later.",@"Alert  informing a logged in end-user that registration failed, resulting in logout.")
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                   otherButtonTitles:nil];
            }
		}
		sender.enabled = YES;
	}
	else {
		registrationSwitch = (UISwitch*)sender;
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Please Confirm",@"\"Please Confirm\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"CONFIRM_DEREGISTRATION_ALERT",nil,[NSBundle mainBundle],@"Are you sure you want to deregister your device for this account? Doing so will remove all books purchased under the account.",@"Prompt requesting confirmation for de-registration, explaining that doing so will remove all that account's purchased books.")
									delegate:self
						   cancelButtonTitle:nil
						   otherButtonTitles:NSLocalizedString(@"Not Now",@"\"Not Now\" button label within Confirm De/Registration alertview"), NSLocalizedString(@"Deregister",@"\"Deregister\" button label within Confirm Deregistration alertview"), nil];
		
	}
    //	[self.navigationController popViewControllerAnimated:YES];
}

- (void)changeDownloadNewBooks:(UIControl*)sender {
	if ( [(UISwitch*)sender isOn] ) {
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kBlioDownloadNewBooksDefaultsKey];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setInteger:-1 forKey:kBlioDownloadNewBooksDefaultsKey];		 
	}
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *ListCellIdentifier = @"UITableViewCellRegistrationIdentifier";
        UITableViewCell *cell;
        
        cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Registration","\"Registration\" cell label");
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 80.0f - 35.0f, 9.0f, 80.0f, 28.0f)];
            switchView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [switchView setTag:997];
            [cell addSubview:switchView];
            if ( [[BlioStoreManager sharedInstance] deviceRegisteredForSourceID:BlioBookSourceOnlineStore] == BlioDeviceRegisteredStatusRegistered ) {
                [switchView setOn:YES animated:NO];
                self.registrationOn = YES;
            }
            else {
                [switchView setOn:NO animated:NO];
                self.registrationOn = NO;
            }
            [switchView addTarget:self action:@selector(changeRegistration:) forControlEvents:UIControlEventValueChanged];
            [switchView release];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if (indexPath.section == 1) {
        static NSString *AutoDownloadCellIdentifier = @"UITableViewCellAutoDownloadIdentifier";
        UITableViewCell *cell;
        
        cell = [tableView dequeueReusableCellWithIdentifier:AutoDownloadCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutoDownloadCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Auto-Download","\"Auto-Download\" cell label");
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 80.0f - 35.0f, 9.0f, 80.0f, 28.0f)];
            switchView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [switchView setTag:997];
            [cell addSubview:switchView];
            if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDownloadNewBooksDefaultsKey] >= 0) {
                [switchView setOn:YES animated:NO];
            }
            else {
                [switchView setOn:NO animated:NO];
            }
            [switchView addTarget:self action:@selector(changeDownloadNewBooks:) forControlEvents:UIControlEventValueChanged];
            [switchView release];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
	return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
    return title;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *title = nil;
	switch (section)
	{
		case 0:
		{
			title = NSLocalizedString(@"You may register up to five devices for reading books purchased from the Blio bookstore.",@"\"Registration text\" table header in Paid Books Settings View");
			break;
		}
        case 1:
        {
            title = NSLocalizedStringWithDefaultValue(@"AUTO_DOWNLOAD_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Blio can automatically download new book purchases.  When Auto-Download is off, you can manually download titles from the Archive tab in the Get Books section.",@"Explanatory message that appears at the bottom of the Auto-Download table section within Archive Settings View.");
            break;
        }
	}
    return title;
}

#pragma mark -
#pragma mark Table view delegate

#pragma mark -
#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[registrationSwitch setOn:YES];
	}
	else if (buttonIndex == 1) {
		BOOL changeSuccess = NO;
		[activityIndicator startAnimating];  // thread issue...
		changeSuccess = [[BlioStoreManager sharedInstance] setDeviceRegistered:BlioDeviceRegisteredStatusUnregistered forSourceID:BlioBookSourceOnlineStore];
		[activityIndicator stopAnimating];
		if (!changeSuccess) {
			if ([[BlioStoreManager sharedInstance] deviceRegisteredForSourceID:BlioBookSourceOnlineStore]) [registrationSwitch setOn:YES];
			else [registrationSwitch setOn:NO];
		}
		else {
            [registrationSwitch setOn:NO];
            
            // TICKET 507: automatically logout when de-registering device.
            [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
            [self.navigationController popViewControllerAnimated:YES];	
            if ([delegate respondsToSelector:@selector(setDidDeregister:)]) [delegate setDidDeregister:YES];
        }
	}
	registrationSwitch.enabled = YES;	
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
	self.activityIndicator = nil;
	self.drmSessionManager = nil;
    [super dealloc];
}


@end

