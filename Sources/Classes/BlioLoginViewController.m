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

@synthesize sourceID, emailField, passwordField, activityIndicatorView;

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
	
	
	 
	CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
	CGFloat activityIndicatorDiameter = 50.0f;
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((mainScreenBounds.size.width-activityIndicatorDiameter)/2, (mainScreenBounds.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"AlertWelcome"]) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"AlertWelcome"];
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Welcome To Blio",@"\"Welcome To Blio\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"INTRO_WELCOME_ALERT",nil,[NSBundle mainBundle],@"Lets get started! If you have an account with Blio, please enter your registered email address and password above. Otherwise, please create an account by selecting the option below.",@"Alert Text encouraging the end-user to either login or create a new account.")
									delegate:nil
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];		
	}

}
- (void) dismissLoginView: (id) sender {
	[[BlioStoreManager sharedInstance] loginFinishedForSourceID:sourceID];
	[self dismissModalViewControllerAnimated:YES];
}

- (UITextField *)createEmailTextField {
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	if (!self.emailField) self.emailField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
	emailField.keyboardType = UIKeyboardTypeAlphabet;
	emailField.keyboardAppearance = UIKeyboardAppearanceDefault;
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
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
	if (!self.passwordField) self.passwordField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	passwordField.keyboardType = UIKeyboardTypeAlphabet;
	passwordField.keyboardAppearance = UIKeyboardAppearanceDefault;
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
	if (self.activityIndicatorView) [self.activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;
	[super dealloc];
}
	
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	
	if (textField == emailField) 
		[passwordField becomeFirstResponder];
	else { 
		if (!emailField.text || [emailField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"EMAIL_FIELD_MUST_BE_POPULATED",nil,[NSBundle mainBundle],@"Please enter your email address before logging in.",@"Alert Text informing the end-user that the email address must be entered to login.")
										delegate:nil 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			[emailField becomeFirstResponder];
			return NO;
		}
		if (!passwordField.text || [passwordField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_FIELD_MUST_BE_POPULATED",nil,[NSBundle mainBundle],@"Please enter your password before logging in.",@"Alert Text informing the end-user that the password must be entered to login.")
										delegate:nil 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];			
			[passwordField becomeFirstResponder];
			return NO;
		}
		[activityIndicatorView startAnimating];
		
		NSMutableDictionary * loginCredentials = [NSMutableDictionary dictionaryWithCapacity:2];
		[loginCredentials setObject:[NSString stringWithString:emailField.text] forKey:@"username"];
		[loginCredentials setObject:[NSString stringWithString:passwordField.text] forKey:@"password"];
		[[NSUserDefaults standardUserDefaults] setObject:loginCredentials forKey:[[BlioStoreManager sharedInstance] storeTitleForSourceID:sourceID]];
		[textField resignFirstResponder];
		[[BlioStoreManager sharedInstance] loginWithUsername:emailField.text password:passwordField.text sourceID:self.sourceID];
	}
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
	[activityIndicatorView stopAnimating];
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
		cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@_%i",kCellTextField_ID,row]];
		if (cell == nil) {
			cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:[NSString stringWithFormat:@"%@_%i",kCellTextField_ID,row]] autorelease];
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
		if (section == 1) {
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.textLabel.text = @"Forgot Password";
			
		}
		else if (section == 2) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Create New Account";
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = [indexPath section];
	if (section == 1) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self forgotPassword];
		return;
	}
	else if (section == 2) {
		BlioCreateAccountViewController * createAccountViewController = [[[BlioCreateAccountViewController alloc] initWithSourceID:sourceID] autorelease];
		[self.navigationController pushViewController:createAccountViewController animated:YES];
	}
}

-(void)forgotPassword {
	if (!self.emailField.text || [self.emailField.text isEqualToString:@""]) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"ENTER_PASSWORD_IF_FORGOTTEN",nil,[NSBundle mainBundle],@"In order for Blio to send you your password, please first enter your email address.",@"Alert Text informing the end-user that his/her email address must be entered before Blio can send his/her password.")
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];	
		return;
	}
	DigitalLockerRequest * request = [[DigitalLockerRequest alloc] init];
	request.Service = DigitalLockerServiceRegistration;
	request.Method = DigitalLockerMethodForgot;
	NSMutableDictionary * inputData = [NSMutableDictionary dictionaryWithCapacity:1];
	[inputData setObject:[NSString stringWithString:self.emailField.text] forKey:DigitalLockerInputDataEmailKey];
	request.InputData = inputData;
	DigitalLockerConnection * connection = [[DigitalLockerConnection alloc] initWithDigitalLockerRequest:request delegate:self];
	[connection start];
	[request release];	
}

#pragma mark -
#pragma mark DigitalLockerConnectionDelegate methods

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection {
	NSLog(@"BlioLoginViewController connectionDidFinishLoading...");
	[activityIndicatorView stopAnimating];
	if (aConnection.digitalLockerResponse.ReturnCode == 0) {
		NSMutableDictionary * loginCredentials = [NSMutableDictionary dictionaryWithCapacity:2];
		[loginCredentials setObject:[NSString stringWithString:emailField.text] forKey:@"username"];
		[[NSUserDefaults standardUserDefaults] setObject:loginCredentials forKey:[[BlioStoreManager sharedInstance] storeTitleForSourceID:sourceID]];
		NSString * alertMessage = NSLocalizedStringWithDefaultValue(@"PASSWORD_SENT",nil,[NSBundle mainBundle],@"Your password has been sent to your email address.",@"Alert Text informing the end-user that his/her password has been sent to the email address specified.");
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:alertMessage
									delegate:self 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];
	}
	else {
		NSString * errorMessage = aConnection.digitalLockerResponse.ReturnMessage;
		if (aConnection.digitalLockerResponse.ReturnCode == 300) {
			if (aConnection.digitalLockerResponse.Errors && [aConnection.digitalLockerResponse.Errors count] > 0) errorMessage = ((DigitalLockerResponseError*)[aConnection.digitalLockerResponse.Errors objectAtIndex:0]).ErrorText;
		}
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:errorMessage
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];
	}
	[aConnection release];
}

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error {
	[aConnection release];
}

@end
