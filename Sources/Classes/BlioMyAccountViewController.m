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
#import "BlioAccountService.h"
#import "BlioVaultService.h"

static const NSInteger kBlioSupportTokenCellActivityIndicatorViewTag = 99;

@implementation BlioMyAccountViewController

@synthesize registrationOn, drmSessionManager,delegate;

#pragma mark -
#pragma mark Initialization

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"My Account",@"\"My Account\" view controller title.");
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
    if ( [[BlioStoreManager sharedInstance] deviceRegisteredForSourceID:BlioBookSourceOnlineStore] == BlioDeviceRegisteredStatusRegistered )
        return 4;
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (indexPath.section == 2) {
        cellActivityIndicatorView.hidden = NO;
        [cellActivityIndicatorView.superview bringSubviewToFront:cellActivityIndicatorView];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        [BlioVaultService getSupportToken:session];
    }
    else if (indexPath.section == 3) {
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Please Confirm",@"\"Please Confirm\" alert message title")
                                     message:NSLocalizedStringWithDefaultValue(@"CONFIRM_DEREGISTRATION_ALERT",nil,[NSBundle mainBundle],@"Are you sure you want to deregister your device for this account? Doing so will remove all books purchased under the account.",@"Prompt requesting confirmation for de-registration, explaining that doing so will remove all that account's purchased books.")
                                    delegate:self
                           cancelButtonTitle:nil
                           otherButtonTitles:NSLocalizedString(@"Not Now",@"\"Not Now\" button label within Confirm De/Registration alertview"), NSLocalizedString(@"Deregister",@"\"Deregister\" button label within Confirm Deregistration alertview"), nil];
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *ListCellIdentifier = @"UITableViewCellLogoutIdentifier";
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Log Out","\"Log Out\" cell label");
            
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [cell setAccessibilityTraits:UIAccessibilityTraitButton];
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
            if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDownloadNewBooksDefaultsKey] >= 0) {
                [switchView setOn:YES animated:NO];
            }
            else {
                [switchView setOn:NO animated:NO];
            }
            [switchView addTarget:self action:@selector(changeDownloadNewBooks:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:switchView];
            [switchView release];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if (indexPath.section == 2) {
        static NSString *ListCellIdentifier = @"UITableViewCellSupportTokenIdentifier";
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Get Support Token","\"Support Token\" cell label");
            
        }
        supportTokenCell = cell;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [cell setAccessibilityTraits:UIAccessibilityTraitButton];
        cellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        cellActivityIndicatorView.frame = CGRectMake(cell.contentView.frame.size.width - kBlioAppSettingCellActivityIndicatorViewWidth - ((cell.contentView.frame.size.height-kBlioAppSettingCellActivityIndicatorViewWidth)/2),(cell.contentView.frame.size.height-kBlioAppSettingCellActivityIndicatorViewWidth)/2,kBlioAppSettingCellActivityIndicatorViewWidth,kBlioAppSettingCellActivityIndicatorViewWidth);
        cellActivityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        cellActivityIndicatorView.hidden = YES;
        [cellActivityIndicatorView startAnimating];
        cellActivityIndicatorView.hidesWhenStopped = YES;
        cellActivityIndicatorView.tag = kBlioSupportTokenCellActivityIndicatorViewTag;
        [cell.contentView addSubview:cellActivityIndicatorView];
        [cellActivityIndicatorView release];
        return cell;
    }
    else if (indexPath.section == 3) {
        static NSString *ListCellIdentifier = @"UITableViewCellRegistrationIdentifier";
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
            cell.textLabel.text = NSLocalizedString(@"Deregister","\"Deregister\" cell label");
            
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        deregisterCell = cell;
        [cell setAccessibilityTraits:UIAccessibilityTraitButton];
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
        case 1:
        {
            title = NSLocalizedStringWithDefaultValue(@"AUTO_DOWNLOAD_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Your new book purchases can be downloaded automatically.  When Auto-Download is off, you can manually download titles in your Archive.",@"Explanatory message that appears at the bottom of the Auto-Download table footer.");
            break;
        }
		case 2:
		{
            title = NSLocalizedString(@"Before contacting customer support, you must obtain a token for identification.",@"\"Support token text\" table footer.");
			break;
		}
		case 3:
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
		changeSuccess = [[BlioStoreManager sharedInstance] setDeviceRegistered:BlioDeviceRegisteredStatusUnregistered forSourceID:BlioBookSourceOnlineStore];
		if (changeSuccess) {
            // Figure out whether/how it makes sense to remain logged in after deregistering
            //[[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
            [self.navigationController popViewControllerAnimated:YES];
            if ([delegate respondsToSelector:@selector(setDidDeregister:)])
                [delegate setDidDeregister:YES];
        }
	}
    deregisterCell.selected = NO;
    supportTokenCell.selected = NO;
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
	self.drmSessionManager = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [cellActivityIndicatorView stopAnimating];
    if (error) {
        NSLog(@"Support token data task failed with error: %@", [error description]);
        return;
    }
    NSString* token = [[NSString alloc] initWithData:supportTokenData encoding: NSUTF8StringEncoding];
    if (supportTokenData && token) {
            token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
            [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Support Token",@"\"Support Token\" alert message title")
                                     message:[NSString stringWithFormat:@"Your support token is %@",token]
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
    }
    else
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Support Token Error",@"\"Support Token Error\" alert message title")
                                        message:NSLocalizedStringWithDefaultValue(@"SUPPORT_TOKEN_ERROR",nil,[NSBundle mainBundle],@"A support token cannot be obtained at this time.  Please try again later.",@"Report that support token cannot be obtained.")
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    supportTokenData = nil;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (data) {
        if (!supportTokenData)
            supportTokenData = [[NSMutableData alloc] initWithCapacity:16];
        [supportTokenData appendData:data];
    }
}


@end

