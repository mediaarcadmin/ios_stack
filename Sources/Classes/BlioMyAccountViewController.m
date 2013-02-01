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

- (void)deregister:(UIControl*)sender {
    sender.enabled = NO;
    deregisterButton = (UIButton*)sender;
    [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Please Confirm",@"\"Please Confirm\" alert message title")
                                 message:NSLocalizedStringWithDefaultValue(@"CONFIRM_DEREGISTRATION_ALERT",nil,[NSBundle mainBundle],@"Are you sure you want to deregister your device for this account? Doing so will remove all books purchased under the account.",@"Prompt requesting confirmation for de-registration, explaining that doing so will remove all that account's purchased books.")
                                delegate:self
                       cancelButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Not Now",@"\"Not Now\" button label within Confirm De/Registration alertview"), NSLocalizedString(@"Deregister",@"\"Deregister\" button label within Confirm Deregistration alertview"), nil];
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
    if ( [[BlioStoreManager sharedInstance] deviceRegisteredForSourceID:BlioBookSourceOnlineStore] == BlioDeviceRegisteredStatusRegistered )
        return 2;
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
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
    else if (indexPath.section == 1) {
        static NSString *ListCellIdentifier = @"UITableViewCellRegistrationIdentifier";
        UITableViewCell *cell;
        
        cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Deregister Device","\"Deregister Device\" cell label");
            UIButton *buttonView = [[UIButton alloc] initWithFrame:CGRectMake(cell.contentView.bounds.origin.x,cell.contentView.bounds.origin.y,cell.contentView.bounds.size.width, cell.contentView.bounds.size.height)];
            buttonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            //[buttonView setTag:999];
            [cell addSubview:buttonView];
            [buttonView addTarget:self action:@selector(deregister:) forControlEvents:UIControlEventTouchUpInside];
            [buttonView release];
            
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
            title = NSLocalizedStringWithDefaultValue(@"AUTO_DOWNLOAD_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Your new book purchases can be downloaded automatically.  When Auto-Download is off, you can manually download titles from the Archive tab in the Get Books section.",@"Explanatory message that appears at the bottom of the Auto-Download table section within Archive Settings View.");
            break;
        }
		case 1:
		{
			title = NSLocalizedString(@"You may register up to five devices for reading your purchased books.",@"\"Registration text\" table header in Paid Books Settings View");
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
    if (buttonIndex == 1) {
		BOOL changeSuccess = NO;
		[activityIndicator startAnimating];  // thread issue...
		changeSuccess = [[BlioStoreManager sharedInstance] setDeviceRegistered:BlioDeviceRegisteredStatusUnregistered forSourceID:BlioBookSourceOnlineStore];
		[activityIndicator stopAnimating];
		if (changeSuccess) {
            // TICKET 507: automatically logout when de-registering device.
            [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
            [self.navigationController popViewControllerAnimated:YES];
            if ([delegate respondsToSelector:@selector(setDidDeregister:)])
                [delegate setDidDeregister:YES];
        }
	}
    deregisterButton.enabled = YES;
    
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

