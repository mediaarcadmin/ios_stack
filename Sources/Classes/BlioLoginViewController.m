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

@implementation BlioLoginViewController

@synthesize loginTableView, vaultManager, usernameField, passwordField, activityIndicator, statusField;

- (id)init
{
	self = [super init];
	if (self)
	{
		//self.title = NSLocalizedString(@"Sign in to Blio", @"");
		
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
	
	self.navigationItem.titleView = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,4.0f,320.0f,36.0f)];
	[(UILabel*)self.navigationItem.titleView setText:NSLocalizedString(@"Sign in to Blio",@"\"Sign in to Blio\" view controller header")];
	[(UILabel*)self.navigationItem.titleView setBackgroundColor:[UIColor clearColor]];
	[(UILabel*)self.navigationItem.titleView setTextColor:[UIColor whiteColor]];
	[(UILabel*)self.navigationItem.titleView setTextAlignment:UITextAlignmentCenter];
	[(UILabel*)self.navigationItem.titleView setFont:[UIFont boldSystemFontOfSize:18.0f]];
 	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
											  initWithTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" bar button") 
											   style:UIBarButtonItemStyleDone 
											   target:self
											   action:@selector(dismissLoginView:)]
											 autorelease];
	
	loginTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	loginTableView.delegate = self;
	loginTableView.dataSource = self;
	loginTableView.scrollEnabled = NO;
	loginTableView.autoresizesSubviews = YES;
	self.view = loginTableView;
	
	CGFloat yPlacement = kTopMargin + 2*kCellHeight;
	 
	activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(kLeftMargin, yPlacement, 16.0f, 16.0f)];
	[activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:activityIndicator];

	CGRect frame = CGRectMake(kLeftMargin+activityIndicator.bounds.size.width+4, yPlacement+kLabelHeight, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	statusField = [BlioLoginViewController labelWithFrame:frame title:@""];
	[self.view addSubview:statusField];
}

- (void) dismissLoginView: (id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (UITextField *)createUsernameTextField {
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	usernameField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	usernameField.keyboardType = UIKeyboardTypeAlphabet;
	usernameField.keyboardAppearance = UIKeyboardAppearanceAlert;
	usernameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	usernameField.placeholder = NSLocalizedString(@"Username",@"\"Username\" placeholder");
	usernameField.delegate = self;
	//temporarily populate to save time
	usernameField.text = @"achien@knfbreader.com";
	
	return usernameField;
}
	
- (UITextField *)createPasswordTextField
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	passwordField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	passwordField.keyboardType = UIKeyboardTypeAlphabet;
	passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
	passwordField.returnKeyType = UIReturnKeyDone;
	passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	passwordField.placeholder = NSLocalizedString(@"Password",@"\"Password\" placeholder");
	passwordField.delegate = self;
	passwordField.secureTextEntry = YES;
		
	passwordField.text = @"Soniac1Soniac1";

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
	self.vaultManager = nil;
	self.loginTableView = nil;
	self.usernameField = nil;
	self.passwordField = nil;
	self.statusField = nil;
	self.activityIndicator = nil;
	[super dealloc];
}
	
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	NSString * loginErrorText = nil;
	if (textField == usernameField) 
		[passwordField becomeFirstResponder];
	else { 
		statusField.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
		statusField.text = NSLocalizedString(@"Signing in...",@"\"Signing in...\" indicator"); 
		[activityIndicator startAnimating];
		BlioLoginResult loginStatus = [[self.vaultManager loginManager] login:usernameField.text password:passwordField.text];
		if ( loginStatus == BlioLoginResultSuccess ) {
			[self dismissModalViewControllerAnimated:YES];
			[self.vaultManager archiveBooks];
		}
		else if ( loginStatus == BlioLoginResultInvalidPassword ) 
			loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_INVALID_CREDENTIALS",nil,[NSBundle mainBundle],@"An invalid username or password was entered. Please try again.",@"Alert message when user attempts to login with invalid login credentials.");
		else
			loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_SERVER_ERROR",nil,[NSBundle mainBundle],@"There was a problem logging in due to a server error. Please try again later.",@"Alert message when the login web service has failed.");
		[activityIndicator stopAnimating];
		statusField.text = @"";
		passwordField.text = @"";
		[textField resignFirstResponder];
		if (loginErrorText != nil) {
//			UIAlertView *errorAlert = [[UIAlertView alloc] 
//									   initWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") message:loginErrorText
//									   delegate:self cancelButtonTitle:@"OK"
//									   otherButtonTitles:nil];
//			[errorAlert show];
//			[errorAlert release];
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
										 message:loginErrorText
										delegate:self 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			
		}
	}	
	return NO;
}
	
#pragma mark - UITableView delegates
	
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}
	
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return kCellHeight;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
    if (cell == nil) {
		cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
		//((CellTextField *)cell).delegate = self;
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellTextField_ID] autorelease];
    }
	
	if (row == 0) 
		((CellTextField *)cell).view = [self createUsernameTextField];
	else
		((CellTextField *)cell).view = [self createPasswordTextField];
		
	return cell;
}
	
	

@end
