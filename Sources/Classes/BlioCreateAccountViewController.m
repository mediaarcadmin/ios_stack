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
@end

@implementation BlioCreateAccountViewController

@synthesize confirmPasswordField, createAccountResponseData;

#pragma mark -
#pragma mark Initialization

- (id)initWithSourceID:(BlioBookSourceID)bookSourceID
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self)
	{
		self.sourceID = bookSourceID;
		self.title = NSLocalizedString(@"Create New Account",@"\"Create New Account\" view controller header");
	}
	
	return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
	[super loadView];
	self.tableView.frame = [[UIScreen mainScreen] applicationFrame];
	self.tableView.scrollEnabled = NO;
	self.tableView.autoresizesSubviews = YES;
	 	
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
	
}

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
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
	self.confirmPasswordField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	confirmPasswordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	confirmPasswordField.keyboardType = UIKeyboardTypeAlphabet;
	confirmPasswordField.keyboardAppearance = UIKeyboardAppearanceAlert;
	confirmPasswordField.returnKeyType = UIReturnKeyDone;
	confirmPasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	confirmPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
	confirmPasswordField.placeholder = NSLocalizedString(@"Confirm Password",@"\"Confirm Password\" placeholder");
	confirmPasswordField.delegate = self;
	confirmPasswordField.secureTextEntry = YES;
	
	//	passwordField.text = @"Soniac1Soniac1";
	
	return confirmPasswordField;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
//	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
		cell = [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
		if (cell == nil) {
			cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
			//((CellTextField *)cell).delegate = self;
			//cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellTextField_ID] autorelease];
		}
		
	if (row == 0) 
		((CellTextField *)cell).view = [self createEmailTextField];
	else if (row == 1) 
		((CellTextField *)cell).view = [self createPasswordTextField];
	else
		((CellTextField *)cell).view = [self createConfirmPasswordTextField];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"CREATE_ACCOUNT_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Passwords must have a minimum of 6 characters, including at least one upper case and one digit. Characters %@ are not allowed.",@"Explanatory message that appears at the bottom of the Create Account fields."),BlioPasswordInvalidCharacters];
	return nil;
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

#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	if (textField == emailField) 
		[passwordField becomeFirstResponder];
	else if (textField == passwordField) {
		[confirmPasswordField becomeFirstResponder];
	}
	else {
		// TODO: validate email address
		
		
		
		// check to confirm password fields match
		if (![passwordField.text isEqualToString:confirmPasswordField.text]) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORDS_MUST_MATCH_ALERT_TEXT",nil,[NSBundle mainBundle],@"Please make sure your passwords match.",@"Alert Text informing the end-user that the password and confirm password fields must match.")
										delegate:self 
							   cancelButtonTitle:@"OK"
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
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_NOT_CONTAIN_INVALID_CHARACTER_ALERT_TEXT",nil,[NSBundle mainBundle],@"Please make sure your password does not contain the character: %@.",@"Alert Text informing the end-user that the password and confirm password fields must match."),offendingCharacter]
										delegate:self 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}	
		// check to make sure password field is at least 6 characters in length
		if ([passwordField.text length] < BlioPasswordCharacterLengthMinimum) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_MINIMUM_NUMBER_OF_CHARACTERS",nil,[NSBundle mainBundle],@"Please make sure your password contains at least %u characters.",@"Alert Text informing the end-user that the password must contain the minimum number of characters."),BlioPasswordCharacterLengthMinimum]
										delegate:self 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		// check to make sure password field contains at least one uppercase character
		if ([passwordField.text rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == NSNotFound) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_UPPERCASE_CHARACTER",nil,[NSBundle mainBundle],@"Please make sure your password contains at least one uppercase character.",@"Alert Text informing the end-user that the password must contain at least one uppercase character.")
										delegate:self 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		// check to make sure password field contains at least one digit
		if ([passwordField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_MUST_CONTAIN_DIGIT",nil,[NSBundle mainBundle],@"Please make sure your password contains at least one digit.",@"Alert Text informing the end-user that the password must contain at least one digit.")
										delegate:self 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
			passwordField.text = @"";
			confirmPasswordField.text = @"";
			[passwordField becomeFirstResponder];
			return NO;
		}		
		[activityIndicator startAnimating];

		// attempt account creation
		NSString *post = [NSString stringWithFormat:@"request=<Gateway version=\"4.1\" debug=\"1\"><State><ClientIPAddress>70.124.88.130</ClientIPAddress><ClientDomain>gw.bliodigitallocker.net</ClientDomain><ClientLanguage>en</ClientLanguage><ClientLocation>US</ClientLocation><ClientUserAgent>Blio iPhone/1.0; APPID-OEM-HP-001-</ClientUserAgent><SiteKey>B7DFE07B232B97FC282A1774AC662E79A3BBD61A</SiteKey><SessionId>NEW</SessionId></State><Request><Service>Registration</Service><Method>Create</Method><InputData><FirstName>Joe</FirstName><LastName>Consumer</LastName><UserName></UserName><UserEmail>%@</UserEmail><UserPassword>%@</UserPassword><EmailOption>Y</EmailOption></InputData></Request></Gateway>",self.emailField.text,self.passwordField.text];

//		CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
//																		NULL,
//																		(CFStringRef)post,
//																		NULL,
//																		(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
//																		kCFStringEncodingNonLossyASCII );
//		post = [(NSString *)urlString autorelease];
		
		NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
		NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://gw.bliodigitallocker.net/nww/gateway/request"]]];
		[request setHTTPMethod:@"POST"];
//		[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//		[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];  
//		[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];  
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
		
		self.createAccountResponseData = [NSMutableData data];

		NSURLConnection * urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		[urlConnection start];
		[request release];
		// attempt login
//		NSMutableDictionary * loginCredentials = [NSMutableDictionary dictionaryWithCapacity:2];
//		[loginCredentials setObject:[NSString stringWithString:usernameField.text] forKey:@"username"];
//		[loginCredentials setObject:[NSString stringWithString:passwordField.text] forKey:@"password"];
//		[[NSUserDefaults standardUserDefaults] setObject:loginCredentials forKey:[[BlioStoreManager sharedInstance] storeTitleForSourceID:sourceID]];
//		
//		[[BlioStoreManager sharedInstance] loginWithUsername:usernameField.text password:passwordField.text sourceID:self.sourceID];
		[textField resignFirstResponder];
	}
	return NO;
}
#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"BlioCreateAccountViewController didReceiveResponse: %@",[[response URL] absoluteString]);
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
	NSLog(@"MIMEType: %@",response.MIMEType);
	NSLog(@"textEncodingName: %@",response.textEncodingName);
	NSLog(@"suggestedFilename: %@",response.suggestedFilename);
	if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {		
		NSLog(@"statusCode: %i",httpResponse.statusCode);
		NSLog(@"allHeaderFields: %@",httpResponse.allHeaderFields);
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	NSLog(@"BlioCreateAccountViewController connection:%@ didReceiveData: %@",aConnection,data);
	[self.createAccountResponseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	NSString * stringData = [[[NSString alloc] initWithData:self.createAccountResponseData encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"stringData: %@",stringData);
	[aConnection release];
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	NSLog(@"BlioCreateAccountViewController connection:%@ didFailWithError: %@, %@",aConnection,error,[error localizedDescription]);
	[aConnection release];
}

// TODO: consider taking the two delegate methods below out for final release, as this is a work-around for B&T's godaddy certificate (reads as invalid)!
- (BOOL)connection: ( NSURLConnection * )connection canAuthenticateAgainstProtectionSpace: ( NSURLProtectionSpace * ) protectionSpace {
	NSLog(@"BlioCreateAccountViewController connection:%@ canAuthenticateAgainstProtectionSpace: %@",connection, protectionSpace);
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {  
	NSLog(@"BlioCreateAccountViewController connection:%@ didReceiveAuthenticationChallenge: %@",connection, challenge);
    //if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])  
	//if ([trustedHosts containsObject:challenge.protectionSpace.host])  
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];  
	
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];  
}  

#pragma mark -
#pragma mark NSXMLParserDelegate methods



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
    [super dealloc];
}


@end

