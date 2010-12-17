//
//  BlioCreateAccountViewController.m
//  BlioApp
//
//  Created by Don Shin on 9/12/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioCreateAccountViewController.h"
#import "CellTextField.h"
#import "BlioAppSettingsConstants.h"
#import "BlioAlertManager.h"

@interface BlioCreateAccountViewController (PRIVATE)
- (UITextField *)createConfirmPasswordTextField;
-(void)dismissLoginView:(id)sender;
@end

@implementation BlioCreateAccountViewController

@synthesize confirmPasswordField,firstNameField,lastNameField;

#pragma mark -
#pragma mark Initialization

- (id)initWithSourceID:(BlioBookSourceID)bookSourceID
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self)
	{
		self.sourceID = bookSourceID;
		self.title = NSLocalizedString(@"Create New Account",@"\"Create New Account\" view controller title");
	}
	
	return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
	[super loadView];
	self.tableView.frame = [[UIScreen mainScreen] applicationFrame];
	self.tableView.scrollEnabled = YES;
	self.tableView.autoresizesSubviews = YES;
	 	
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

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification object:self.view.window]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillHideNotification object:self.view.window]; 	
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil]; 
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
- (UITextField *)createEmailTextField {
	UITextField * textField = [super createEmailTextField];
	textField.text = @"";
	return textField;
}

- (UITextField *)createPasswordTextField {
	UITextField * textField = [super createPasswordTextField];
	textField.text = @"";
	textField.returnKeyType = UIReturnKeyNext;
	return textField;
}


- (UITextField *)createConfirmPasswordTextField
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	if (!self.confirmPasswordField) self.confirmPasswordField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	confirmPasswordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	confirmPasswordField.keyboardType = UIKeyboardTypeAlphabet;
	confirmPasswordField.keyboardAppearance = UIKeyboardAppearanceDefault;
	confirmPasswordField.returnKeyType = UIReturnKeyGo;
	confirmPasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	confirmPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
	confirmPasswordField.placeholder = NSLocalizedString(@"Confirm Password",@"\"Confirm Password\" placeholder");
	confirmPasswordField.delegate = self;
	confirmPasswordField.secureTextEntry = YES;
	
	//	passwordField.text = @"Soniac1Soniac1";
	
	return confirmPasswordField;
}
- (UITextField *)createFirstNameTextField
{
	NSLog(@"createFirstNameTextField");
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	if (!self.firstNameField) self.firstNameField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	firstNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	firstNameField.keyboardType = UIKeyboardTypeAlphabet;
	firstNameField.keyboardAppearance = UIKeyboardAppearanceDefault;
	firstNameField.returnKeyType = UIReturnKeyNext;
	firstNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	firstNameField.autocorrectionType = UITextAutocorrectionTypeNo;
	firstNameField.placeholder = NSLocalizedString(@"First Name",@"\"First Name\" placeholder");
	firstNameField.delegate = self;
		
	return firstNameField;
}
- (UITextField *)createLastNameTextField
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	if (!self.lastNameField) self.lastNameField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	lastNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	lastNameField.keyboardType = UIKeyboardTypeAlphabet;
	lastNameField.keyboardAppearance = UIKeyboardAppearanceDefault;
	lastNameField.returnKeyType = UIReturnKeyNext;
	lastNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	lastNameField.autocorrectionType = UITextAutocorrectionTypeNo;
	lastNameField.placeholder = NSLocalizedString(@"Last Name",@"\"Last Name\" placeholder");
	lastNameField.delegate = self;
	
	return lastNameField;
}

- (void)receivedLoginResult:(BlioLoginResult)loginResult {
	[activityIndicatorView stopAnimating];
	NSString * loginErrorText = nil;
	if ( loginResult == BlioLoginResultSuccess ) {
		[self dismissModalViewControllerAnimated:YES];
	}
	else if ( loginResult == BlioLoginResultInvalidPassword ) {
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_INVALID_CREDENTIALS",nil,[NSBundle mainBundle],@"An invalid username or password was entered. Please try again.",@"Alert message when user attempts to login with invalid login credentials.");
		passwordField.text = @"";
	}
	else if ( loginResult == BlioLoginResultError ) { 
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_SERVER_ERROR",nil,[NSBundle mainBundle],@"There was a problem logging in due to a server error. Please try again later.",@"Alert message when the login web service has failed.");
	}
	else if ( loginResult == BlioLoginResultConnectionError ) {
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_CONNECTION_ERROR",nil,[NSBundle mainBundle],@"There was a problem logging in due to an network connection error. Please check the availability of your Internet connection and try again later.",@"Alert message when the login web service has failed.");
	}
	if (loginErrorText != nil) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
									 message:loginErrorText
									delegate:self 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
	}
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 5;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
//	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
		cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@_%i",kCellTextField_ID,row]];
		if (cell == nil) {
			cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:[NSString stringWithFormat:@"%@_%i",kCellTextField_ID,row]] autorelease];
			if (row == 0) 
				((CellTextField *)cell).view = [self createFirstNameTextField];
			else if (row == 1) 
				((CellTextField *)cell).view = [self createLastNameTextField];
			else if (row == 2) 
				((CellTextField *)cell).view = [self createEmailTextField];
			else if (row == 3) 
				((CellTextField *)cell).view = [self createPasswordTextField];
			else
				((CellTextField *)cell).view = [self createConfirmPasswordTextField];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"CREATE_ACCOUNT_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Passwords must have a minimum of 8 characters, including at least one upper case and one digit. Characters %@ are not allowed.",@"Explanatory message that appears at the bottom of the Create Account fields."),BlioPasswordInvalidCharacters];
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 100;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return;
}

#pragma mark UITextFieldDelegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField {           // became first responder
	if (textField.superview) {
		NSInteger offsetY = [textField convertPoint:textField.center toView:self.view].y - kCellHeight * 2;
		if (offsetY < 0) offsetY = 0;
		[self.tableView setContentOffset:CGPointMake(0, offsetY) animated:YES];
	}
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	if (textField == firstNameField) 
		[lastNameField becomeFirstResponder];
	else if (textField == lastNameField) 
		[emailField becomeFirstResponder];
	else if (textField == emailField) 
		[passwordField becomeFirstResponder];
	else if (textField == passwordField) {
		[confirmPasswordField becomeFirstResponder];
	}
	else {
		if (!firstNameField.text || [firstNameField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Information Missing",@"\"Information Missing\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"FIRSTNAME_FIELD_MUST_BE_POPULATED_ACCOUNT_CREATION",nil,[NSBundle mainBundle],@"Please enter your first name.",@"Alert Text informing the end-user that the first name must be entered to create an account.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			[firstNameField becomeFirstResponder];
			return NO;
		}
		if (!lastNameField.text || [lastNameField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Information Missing",@"\"Information Missing\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"LASTNAME_FIELD_MUST_BE_POPULATED_ACCOUNT_CREATION",nil,[NSBundle mainBundle],@"Please enter your last name.",@"Alert Text informing the end-user that the last name must be entered to create an account.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")	
							   otherButtonTitles:nil];
			[lastNameField becomeFirstResponder];
			return NO;
		}
		
		// TODO: validate email address using regex

		if (!emailField.text || [emailField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Information Missing",@"\"Information Missing\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"EMAIL_FIELD_MUST_BE_POPULATED_ACCOUNT_CREATION",nil,[NSBundle mainBundle],@"Please enter your email address.",@"Alert Text informing the end-user that the email address must be entered to create an account.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			[emailField becomeFirstResponder];
			return NO;
		}
		if (!passwordField.text || [passwordField.text isEqualToString:@""]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Information Missing",@"\"Information Missing\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_FIELD_MUST_BE_POPULATED_ACCOUNT_CREATION",nil,[NSBundle mainBundle],@"Please enter your password.",@"Alert Text informing the end-user that the password must be entered to create an account.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];			
			[passwordField becomeFirstResponder];
			return NO;
		}
		
		
		
		
		// check to confirm password fields match
		if (!confirmPasswordField.text || ![passwordField.text isEqualToString:confirmPasswordField.text]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Password Not Confirmed",@"\"Password Not Confirmed\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORDS_MUST_MATCH_ALERT_TEXT",nil,[NSBundle mainBundle],@"Please make sure your password entries match.",@"Alert Text informing the end-user that the password and confirm password fields must match.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}
		// check to make sure password field doesn't contain invalid characters
		NSRange passwordInvalidCharacterRange = [passwordField.text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:BlioPasswordInvalidCharacters]];
		if (passwordInvalidCharacterRange.location != NSNotFound) {
			// password field contains an invalid character!
			NSString * offendingCharacter = [passwordField.text substringWithRange:passwordInvalidCharacterRange];
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Invalid Password",@"\"Invalid Password\" alert message title") 
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_NOT_CONTAIN_INVALID_CHARACTER_ALERT_TEXT",nil,[NSBundle mainBundle],@"Please make sure your password does not contain the character: %@.",@"Alert Text informing the end-user that the password and confirm password fields must match."),offendingCharacter]
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}	
		// check to make sure password field is at least 6 characters in length
		if ([passwordField.text length] < BlioPasswordCharacterLengthMinimum) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Invalid Password",@"\"Invalid Password\" alert message title") 
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_MINIMUM_NUMBER_OF_CHARACTERS",nil,[NSBundle mainBundle],@"Please make sure your password contains at least %u characters.",@"Alert Text informing the end-user that the password must contain the minimum number of characters."),BlioPasswordCharacterLengthMinimum]
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		// check to make sure password field contains at least one uppercase character
		if ([passwordField.text rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == NSNotFound) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Invalid Password",@"\"Invalid Password\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_UPPERCASE_CHARACTER",nil,[NSBundle mainBundle],@"Please make sure your password contains at least one uppercase letter.",@"Alert Text informing the end-user that the password must contain at least one uppercase character.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		// check to make sure password field contains at least one digit
		if ([passwordField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Invalid Password",@"\"Invalid Password\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_DIGIT",nil,[NSBundle mainBundle],@"Please make sure your password contains at least one digit.",@"Alert Text informing the end-user that the password must contain at least one digit.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		[activityIndicatorView startAnimating];
		[textField resignFirstResponder];

		// attempt account creation

		DigitalLockerRequest * request = [[DigitalLockerRequest alloc] init];
		request.Service = DigitalLockerServiceRegistration;
		request.Method = DigitalLockerMethodCreate;
		NSMutableDictionary * inputData = [NSMutableDictionary dictionaryWithCapacity:6];
		[inputData setObject:[NSString stringWithString:self.firstNameField.text] forKey:DigitalLockerInputDataFirstNameKey];
		[inputData setObject:[NSString stringWithString:self.lastNameField.text] forKey:DigitalLockerInputDataLastNameKey];
		[inputData setObject:[NSString stringWithString:self.emailField.text] forKey:DigitalLockerInputDataEmailKey];
		[inputData setObject:[NSString stringWithString:self.passwordField.text] forKey:DigitalLockerInputDataPasswordKey];
		[inputData setObject:@"N" forKey:DigitalLockerInputDataEmailOptionKey];
		request.InputData = inputData;
		DigitalLockerConnection * connection = [[DigitalLockerConnection alloc] initWithDigitalLockerRequest:request siteNum:[[BlioStoreManager sharedInstance] storeSiteIDForSourceID:sourceID] siteKey:[[BlioStoreManager sharedInstance] storeSiteKeyForSourceID:sourceID] delegate:self];
		[connection start];
		[request release];
	}
	return NO;
}

#pragma mark -
#pragma mark DigitalLockerConnectionDelegate methods

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection {
	NSLog(@"BlioCreateAccountViewController connectionDidFinishLoading...");
	[activityIndicatorView stopAnimating];
	if (aConnection.digitalLockerResponse.ReturnCode == 0) {
		[[BlioStoreManager sharedInstance] saveUsername:emailField.text password:passwordField.text sourceID:sourceID];
		NSString * alertMessage = NSLocalizedStringWithDefaultValue(@"ACCOUNT_CREATED",nil,[NSBundle mainBundle],@"Your account has been created! Blio will now login under your new account.",@"Alert Text informing the end-user that an account has been created, and the app will now login under that new account.");
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Congratulations",@"\"Congratulations\" alert message title") 
									 message:alertMessage
									delegate:self 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
	}
	else {
		NSString * errorMessage = aConnection.digitalLockerResponse.ReturnMessage;
		if (aConnection.digitalLockerResponse.ReturnCode == 300) {
			if (aConnection.digitalLockerResponse.Errors && [aConnection.digitalLockerResponse.Errors count] > 0) errorMessage = ((DigitalLockerResponseError*)[aConnection.digitalLockerResponse.Errors objectAtIndex:0]).ErrorText;
		}
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Error Creating Account",@"\"Error Creating Account\" alert message title") 
									 message:errorMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
	}
	[aConnection release];
}

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error {
	[activityIndicatorView stopAnimating];
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
								 message:[NSString stringWithFormat:@"%@ %@",[error localizedDescription],NSLocalizedString(@"Please try again later.",@"\"Please try again later.\" alert view message supplement.")]
								delegate:self 
					   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
					   otherButtonTitles:nil];
	[aConnection release];
//	[self dismissLoginView:nil];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[[BlioStoreManager sharedInstance] saveUsername:emailField.text password:passwordField.text sourceID:self.sourceID];
	[[BlioStoreManager sharedInstance] loginWithUsername:emailField.text password:passwordField.text sourceID:self.sourceID];
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
	self.confirmPasswordField = nil;
	self.firstNameField = nil;
	self.lastNameField = nil;
    [super dealloc];
}

- (void)keyboardWillShow:(NSNotification *)notification {
//	NSValue* sizeValue = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];			
//	CGSize keyboardSize = [sizeValue CGRectValue].size;
//	
//	CGRect viewFrame = self.tableView.frame;
//	viewFrame.size.height -= keyboardSize.height;
//	self.tableView.frame = viewFrame;
	    
}
- (void)keyboardWillHide:(NSNotification *)notification {
//	NSValue* sizeValue = [notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];			
//	CGSize keyboardSize = [sizeValue CGRectValue].size;
//	
//	CGRect viewFrame = self.tableView.frame;
//	viewFrame.size.height += keyboardSize.height;
//	self.tableView.frame = viewFrame;	
}

@end

