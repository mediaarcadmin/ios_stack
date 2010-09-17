    //
//  BlioLoginViewController.m
//  BlioApp
//
//  Created by Arnold Chien on 4/6/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioLoginViewController.h"
#import "BlioAppSettingsConstants.h"
#import "CellTextField.h"
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"
#import "BlioCreateAccountViewController.h"

@implementation BlioLoginViewController

@synthesize sourceID, emailField, passwordField, activityIndicator, statusField;

- (id)initWithSourceID:(BlioBookSourceID)bookSourceID
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self)
	{
		self.sourceID = bookSourceID;
		self.title = NSLocalizedString(@"Sign in to Blio",@"\"Sign in to Blio\" view controller header");
	}
	
	return self;
}

+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title
{
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    
	label.textAlignment = UITextAlignmentLeft;
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
    return label;
}

- (void)loadView {
	[super loadView];
	self.tableView.frame = [[UIScreen mainScreen] applicationFrame];
	self.tableView.scrollEnabled = YES;
	self.tableView.autoresizesSubviews = YES;
	
//	self.navigationItem.titleView = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f,4.0f,320.0f,36.0f)] autorelease];
//	[(UILabel*)self.navigationItem.titleView setText:NSLocalizedString(@"Sign in to Blio",@"\"Sign in to Blio\" view controller header")];
//	[(UILabel*)self.navigationItem.titleView setBackgroundColor:[UIColor clearColor]];
//	[(UILabel*)self.navigationItem.titleView setTextColor:[UIColor whiteColor]];
//	[(UILabel*)self.navigationItem.titleView setTextAlignment:UITextAlignmentCenter];
//	[(UILabel*)self.navigationItem.titleView setFont:[UIFont boldSystemFontOfSize:18.0f]];
 	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											  initWithTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" bar button") 
											   style:UIBarButtonItemStyleDone 
											   target:self
											   action:@selector(dismissLoginView:)]
											 autorelease];
	
	
	CGFloat yPlacement = kTopMargin + 2*kCellHeight;
	 
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(kLeftMargin, yPlacement, 16.0f, 16.0f)] autorelease];
	[activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:activityIndicator];

	CGRect frame = CGRectMake(kLeftMargin+activityIndicator.bounds.size.width+4, yPlacement+kLabelHeight, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	self.statusField = [BlioLoginViewController labelWithFrame:frame title:@""];
	[self.view addSubview:statusField];
	
}

- (void) dismissLoginView: (id) sender {
	[[BlioStoreManager sharedInstance] loginFinishedForSourceID:sourceID];
	[self dismissModalViewControllerAnimated:YES];
}

- (UITextField *)createEmailTextField {
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	self.emailField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
	emailField.keyboardType = UIKeyboardTypeAlphabet;
	emailField.keyboardAppearance = UIKeyboardAppearanceAlert;
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	emailField.placeholder = NSLocalizedString(@"E-mail Address",@"\"E-mail Address\" placeholder");
	emailField.delegate = self;
	
	NSMutableDictionary * loginCredentials = [[NSUserDefaults standardUserDefaults] objectForKey:[[BlioStoreManager sharedInstance] storeTitleForSourceID:sourceID]];
	if (loginCredentials && [loginCredentials objectForKey:@"username"]) {
		emailField.text = [loginCredentials objectForKey:@"username"];
	}
	
	//temporarily populate to save time
//	emailField.text = @"achien@knfbreader.com";
	
	return emailField;
}
	
- (UITextField *)createPasswordTextField
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	self.passwordField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	passwordField.keyboardType = UIKeyboardTypeAlphabet;
	passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
	passwordField.returnKeyType = UIReturnKeyDone;
	passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	passwordField.placeholder = NSLocalizedString(@"Password",@"\"Password\" placeholder");
	passwordField.delegate = self;
	passwordField.secureTextEntry = YES;
		
//	passwordField.text = @"Soniac1Soniac1";

	return passwordField;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
        return YES;
}

- (void)dealloc {
	self.emailField = nil;
	self.passwordField = nil;
	self.statusField = nil;
	self.activityIndicator = nil;
	[super dealloc];
}
	
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	if (textField == emailField) 
		[passwordField becomeFirstResponder];
	else { 
		statusField.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
		statusField.text = NSLocalizedString(@"Signing in...",@"\"Signing in...\" indicator"); 
		[activityIndicator startAnimating];
		
		NSMutableDictionary * loginCredentials = [NSMutableDictionary dictionaryWithCapacity:2];
		[loginCredentials setObject:[NSString stringWithString:emailField.text] forKey:@"username"];
		[loginCredentials setObject:[NSString stringWithString:passwordField.text] forKey:@"password"];
		[[NSUserDefaults standardUserDefaults] setObject:loginCredentials forKey:[[BlioStoreManager sharedInstance] storeTitleForSourceID:sourceID]];

		[[BlioStoreManager sharedInstance] loginWithUsername:emailField.text password:passwordField.text sourceID:self.sourceID];
	}
	[textField resignFirstResponder];
	return NO;
}

- (void)receivedLoginResult:(BlioLoginResult)loginResult {
	NSString * loginErrorText = nil;
	if ( loginResult == BlioLoginResultSuccess ) {
		[self dismissModalViewControllerAnimated:YES];
	}
	else if ( loginResult == BlioLoginResultInvalidPassword ) 
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_INVALID_CREDENTIALS",nil,[NSBundle mainBundle],@"An invalid username or password was entered. Please try again.",@"Alert message when user attempts to login with invalid login credentials.");
	else
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_SERVER_ERROR",nil,[NSBundle mainBundle],@"There was a problem logging in due to a server error. Please try again later.",@"Alert message when the login web service has failed.");
	[activityIndicator stopAnimating];
	statusField.text = @"";
	passwordField.text = @"";
	if (loginErrorText != nil) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
									 message:loginErrorText
									delegate:self 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];
	}
}
#pragma mark - UITableView delegates
	
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}
	
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) return 2;
	else return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) return NSLocalizedStringWithDefaultValue(@"LOGIN_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"If you have a blioreader.com username, login now to retrieve your latest blioreader.com purchases.",@"Explanatory message that appears at the bottom of the Login table.");
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	if (section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
		if (cell == nil) {
			cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
			//((CellTextField *)cell).delegate = self;
			//cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellTextField_ID] autorelease];
		}
		
		if (row == 0) 
			((CellTextField *)cell).view = [self createEmailTextField];
		else
			((CellTextField *)cell).view = [self createPasswordTextField];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else {
		NSString * genericTableViewCellID = @"genericTableCell";
		cell = [tableView dequeueReusableCellWithIdentifier:genericTableViewCellID];
		if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:genericTableViewCellID] autorelease];		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if (section == 1) cell.textLabel.text = @"Forgot Password";
		else if (section == 2) cell.textLabel.text = @"Create New Account";
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = [indexPath section];
	if (section == 1) {
		return;
	}
	else if (section == 2) {
		BlioCreateAccountViewController * createAccountViewController = [[[BlioCreateAccountViewController alloc] initWithSourceID:sourceID] autorelease];
		[self.navigationController pushViewController:createAccountViewController animated:YES];
	}
}

@end
