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
#import "BlioHelpSettingsController.h"
#import "BlioMyAccountViewController.h"
#import "BlioStoreManager.h"
#import "BlioEULATextController.h"
#import "BlioVersionController.h"
#import "BlioVoiceOverHelpSettingsController.h"
#import "BlioWebTextController.h"
#import "BlioAccountService.h"
#import "BlioLoginService.h"
#import "BlioIdentityProvidersViewController.h"

static const NSInteger kBlioGetProvidersCellActivityIndicatorViewTag = 99;
static const NSInteger kBlioGetProvidersCellActivityIndicatorViewWidth = 20;

@implementation BlioAppSettingsController

@synthesize didDeregister;

- (BlioAppSettingsController*)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"Settings",@"\"Settings\" view controller title");
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 440);
		}
    }
    return self;
}

-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		[self.tableView reloadData];
		//if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore])
        //    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	}
}

- (void)loadView {
	[super loadView];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
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
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);
	
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (didDeregister) {
        didDeregister = NO;
        // [self attemptLogin];  // necessary/desireable?
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return 1;
#ifdef TOSHIBA
	else if (section == 1)
		return 1;
	else if (section == 3)
		return 3;
#endif
	return 2;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
	switch ( [indexPath section] ) {
		case 1:
			switch ([indexPath row])
			{
#ifndef TOSHIBA
				case 0:
					[cell.textLabel setText:NSLocalizedString(@"Reading Voice",@"\"Reading Voice\" text label for App Settings cell")];
					break;
				case 1:
#else
                case 0:
#endif
					[cell.textLabel setText:NSLocalizedString(@"Reference Tools",@"\"Reference Tools\" text label for App Settings cell")];
				default:
					break;
			}
			break;
		case 0:
			if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@",
                                       NSLocalizedString(@"My Account: ",@"\"My Account: \" text label prefix for App Settings cell"),
                                       [[BlioAccountService sharedInstance] getAccountID]];
                                       //[[BlioStoreManager sharedInstance] usernameForSourceID:BlioBookSourceOnlineStore]];
			}
			else {
				cell.textLabel.text = NSLocalizedString(@"Log In",@"\"Log In\" text label for App Settings cell");// add activity indicator
                UIActivityIndicatorView * cellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                cellActivityIndicatorView.frame = CGRectMake(cell.contentView.frame.size.width - kBlioGetProvidersCellActivityIndicatorViewWidth - ((cell.contentView.frame.size.height-kBlioGetProvidersCellActivityIndicatorViewWidth)/2),(cell.contentView.frame.size.height-kBlioGetProvidersCellActivityIndicatorViewWidth)/2,kBlioGetProvidersCellActivityIndicatorViewWidth,kBlioGetProvidersCellActivityIndicatorViewWidth);
                cellActivityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                cellActivityIndicatorView.hidden = YES;
                [cellActivityIndicatorView startAnimating];
                cellActivityIndicatorView.hidesWhenStopped = YES;
                cellActivityIndicatorView.tag = kBlioGetProvidersCellActivityIndicatorViewTag;
                [cell.contentView addSubview:cellActivityIndicatorView];
                [cellActivityIndicatorView release];
			}
			break;
		case 2:
			switch ([indexPath row])
            {
                case 0:
                    [cell.textLabel setText:NSLocalizedString(@"VoiceOver",@"\"VoiceOver\" text label for App Settings cell")];
                    break;
                case 1:
                    [cell.textLabel setText:NSLocalizedString(@"Help",@"\"Help\" text label for App Settings cell")];
                default:
                    break;
        }
			break;
		case 3:
			switch ([indexPath row])
			{
				case 0:
					[cell.textLabel setText:NSLocalizedString(@"About",@"\"About\" text label for App Settings cell")];
					break;
				//				case 1:
				//					[cell.textLabel setText:NSLocalizedString(@"Navigation",@"\"Navigation\" text label for App Settings cell")];
				//					break;
				case 1:
					[cell.textLabel setText:NSLocalizedString(@"Terms of Use",@"\"Terms of Use\" text label for App Settings cell")];
                    break;
#ifdef TOSHIBA
				case 2:
					[cell.textLabel setText:NSLocalizedString(@"Privacy",@"\"Privacy\" text label for App Settings cell")];
                    break;
#endif
				default:
					break;
			}
		default:
			break;
	}
	
	[cell setAccessibilityTraits:UIAccessibilityTraitButton];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#ifndef TOSHIBA
	BlioReadingVoiceSettingsViewController *audioController;
#endif  
	BlioWebToolSettingsController *webToolController;
	BlioHelpSettingsController *helpController;
	BlioVersionController *versionController;
	BlioMyAccountViewController *myAccountController;
    BlioVoiceOverHelpSettingsController *voController;
#ifdef TOSHIBA
    BlioWebTextController* webTextController;
#else
	BlioEULATextController *eulaController;
#endif
    
	switch ( [indexPath section] ) {
		case 1:
			switch (indexPath.row)
			{
#ifndef TOSHIBA
				case 0:
					audioController = [[BlioReadingVoiceSettingsViewController alloc] init];
					[self.navigationController pushViewController:audioController animated:YES];
					[audioController release];
					break;
				case 1:
#else
                case 0:
#endif
					webToolController = [[BlioWebToolSettingsController alloc] init];
					[self.navigationController pushViewController:webToolController animated:YES];
					[webToolController release];
					break;
			}
			break;
		case 0:
			if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
				myAccountController = [[BlioMyAccountViewController alloc] init];
                myAccountController.delegate = self;
				[self.navigationController pushViewController:myAccountController animated:YES];
				[myAccountController release];
			}
			else {
                //[self attemptLogin];
                UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:kBlioGetProvidersCellActivityIndicatorViewTag];
                cellActivityIndicatorView.hidden = NO;
                [cellActivityIndicatorView.superview bringSubviewToFront:cellActivityIndicatorView];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
                NSMutableArray* providers = [[BlioLoginService sharedInstance] getIdentityProviders];
                [cellActivityIndicatorView stopAnimating];
                if (providers) {
                    BlioIdentityProvidersViewController* providersController = [[BlioIdentityProvidersViewController alloc] initWithProviders:providers];
                    [self.navigationController pushViewController:providersController animated:YES];
                    [providersController release];
                }
                else
                    // TODO alert
                    NSLog(@"Error getting identity providers.");
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 2:
            switch (indexPath.row)
            {
                case 0:
                    voController = [[BlioVoiceOverHelpSettingsController alloc] init];
                    [self.navigationController pushViewController:voController animated:YES];
                    [voController release];
                    break;
                case 1:
                    helpController = [[BlioHelpSettingsController alloc] init];
                    [self.navigationController pushViewController:helpController animated:YES];
                    [helpController release];
                    break;
            }
            break;
		case 3:
			switch (indexPath.row)
			{
				case 0:
					versionController = [[BlioVersionController alloc] init];
					[self.navigationController pushViewController:versionController animated:YES];
					[versionController release];
					break;
#ifdef TOSHIBA
				case 1:
					webTextController = [[BlioWebTextController alloc] initWithURL:@"https://www.toshibabookplace.com/terms-conditions"];
					[self.navigationController pushViewController:webTextController animated:YES];
					[webTextController release];
					break;
				case 2:
					webTextController = [[BlioWebTextController alloc] initWithURL:@"https://www.toshibabookplace.com/privacy-policy"];
					[self.navigationController pushViewController:webTextController animated:YES];
					[webTextController release];
					break;
#else
				case 1:
					eulaController = [[BlioEULATextController alloc] init];
					[self.navigationController pushViewController:eulaController animated:YES];
					[eulaController release];
					break;
#endif
			}
			break;
		default:
			break;
	}
}

/*
-(void)attemptLogin {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
    [[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore forceLoginDisplayUponFailure:YES];
}
 */

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end

