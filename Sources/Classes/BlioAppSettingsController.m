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
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
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
        [self attemptLogin];
    }
}
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
	return YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 1) 
		return 1;
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
					[cell.textLabel setText:NSLocalizedString(@"Voice",@"\"Voice\" text label for App Settings cell")];
					break;
//				case 1:
//					[cell.textLabel setText:NSLocalizedString(@"Navigation",@"\"Navigation\" text label for App Settings cell")];
//					break;
				case 1:
					[cell.textLabel setText:NSLocalizedString(@"Reference Tools",@"\"Reference Tools\" text label for App Settings cell")];
				default:
					break;
			}
			break;
		case 1:
			if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"My Account: ",@"\"My Account: \" text label prefix for App Settings cell"),[[BlioStoreManager sharedInstance] usernameForSourceID:BlioBookSourceOnlineStore]];
				//			 cell.textLabel.text = [NSString stringWithFormat:@"Logged in as %@",[[BlioStoreManager sharedInstance] usernameForSourceID:BlioBookSourceOnlineStore]];
			}
			else {
//				cell.textLabel.textAlignment = UITextAlignmentCenter;
//				cell.accessoryType = UITableViewCellAccessoryNone;
//				cell.textLabel.text = @"Login";
				cell.textLabel.text = NSLocalizedString(@"My Account",@"\"My Account\" text label for App Settings cell");
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
	BlioReadingVoiceSettingsViewController *audioController;
	BlioWebToolSettingsController *webToolController;
	BlioHelpSettingsController *helpController;
	BlioVersionController *versionController;
	BlioMyAccountViewController *myAccountController;
	BlioEULATextController *eulaController;
    BlioVoiceOverHelpSettingsController *voController;
    
	switch ( [indexPath section] ) {
		case 0:
			switch (indexPath.row)
			{
				case 0:
					audioController = [[BlioReadingVoiceSettingsViewController alloc] init];
					[self.navigationController pushViewController:audioController animated:YES];
					[audioController release];
					break;
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
                myAccountController.delegate = self;
				[self.navigationController pushViewController:myAccountController animated:YES];
				[myAccountController release];
			}
			else {
                [self attemptLogin];
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
				case 1:
					eulaController = [[BlioEULATextController alloc] init];
					[self.navigationController pushViewController:eulaController animated:YES];
					[eulaController release];
					break;
			}
			break;
		default:
			break;
	}
}
-(void)attemptLogin {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
    [[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore forceLoginDisplayUponFailure:YES];
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end

