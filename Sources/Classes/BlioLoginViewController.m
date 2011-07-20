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
#import <QuartzCore/CALayer.h>

@implementation BlioLoginHeaderView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];

        UIGraphicsBeginImageContext(CGSizeMake(100, 100));
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIImage *logoImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"]]];
        
        // Mask off the outside of the icon like the device does.
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddArcToPoint(context, 0, 0, 50, 0, 15);
        CGContextAddArcToPoint(context, 100, 0, 100, 50, 15);
        CGContextAddArcToPoint(context, 100, 100, 50, 100, 15);
        CGContextAddArcToPoint(context, 0, 100, 0, 50, 15);
        CGContextAddArcToPoint(context, 0, 0, 50, 0, 15);
        CGContextClosePath(context);
        CGContextClip(context);
        [logoImage drawInRect:CGRectMake(-7, -7, 114, 114)];
        
        logoView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
        
        [self addSubview:logoView];
        [logoView release];

		loginHeaderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		loginHeaderLabel.lineBreakMode = UILineBreakModeWordWrap;
		loginHeaderLabel.numberOfLines = 0;
        loginHeaderLabel.backgroundColor = [UIColor clearColor];
		loginHeaderLabel.text = NSLocalizedString(@"Log in to your Blio.com account to sync your reading list.\n\nIf you are a new customer, please visit our website to sign up.",@"Existing user message on welcome view controller.");
		[self addSubview:loginHeaderLabel];
		[loginHeaderLabel release];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        }
    }
    return self;
}
-(BOOL)isAccessibilityElement {
	return NO;	
}
- (NSInteger)accessibilityElementCount {
	return [self.subviews count];
}
- (id)accessibilityElementAtIndex:(NSInteger)index {    
    return [self.subviews objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [self.subviews indexOfObject:element];
}

-(void)layoutSubviews {
    
    contentMargin = 10;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation]; 

    CGFloat logoOffset = 0;
    if(UIInterfaceOrientationIsLandscape(orientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//        logoView.hidden = YES;
        logoView.alpha = 0;
    }
    else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            logoView.frame = CGRectMake(0, 0, 100, 100);
            contentMargin = 30;
        }
        logoView.frame = CGRectMake(0, 0, 80, 80);
        logoView.center = CGPointMake(self.bounds.size.width/2, logoView.bounds.size.height/2 + contentMargin);
//        logoView.hidden = NO;
        logoView.alpha = 1;
        logoOffset = CGRectGetMaxY(logoView.frame);
	}
    
    UIFont * loginHeaderLabelFont = [UIFont systemFontOfSize:16.0f];

    CGSize loginHeaderLabelSize = [loginHeaderLabel.text sizeWithFont:loginHeaderLabelFont constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),300) lineBreakMode:UILineBreakModeWordWrap];
    loginHeaderLabel.font = loginHeaderLabelFont;
    loginHeaderLabel.frame = CGRectMake(contentMargin, logoOffset + contentMargin, (self.frame.size.width - contentMargin*2), loginHeaderLabelSize.height);

    
    
}
@end


@implementation BlioLoginViewController

@synthesize sourceID, emailField, passwordField, activityIndicatorView, loginHeaderView, loginFooterView;

- (id)initWithSourceID:(BlioBookSourceID)bookSourceID
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self)
	{
		self.sourceID = bookSourceID;
		self.title = NSLocalizedString(@"Log in",@"\"Log in\" view controller title");
		self.tableView.backgroundColor = [UIColor whiteColor];
		UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
		aButton.showsTouchWhenHighlighted = NO;
		[aButton setTitle:NSLocalizedString(@"Forgot Password?",@"\"Forgot Password?\" button label") forState:UIControlStateNormal];
		[aButton setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateHighlighted];		
		[aButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
		[aButton.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
		[aButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
		[aButton setTitleColor:[UIColor colorWithRed:0.0f/255.0f green:50.0f/255.0f blue:100.0f/255.0f alpha:1] forState:UIControlStateNormal];
		[[aButton layer] setCornerRadius:4.0f];
		[[aButton layer] setMasksToBounds:YES];
		[[aButton layer] setBorderWidth:0.0f];		
		[[aButton layer] setBorderColor:[[UIColor colorWithRed:100.0f/255.0f green:100.0f/255.0f blue:100.0f/255.0f alpha:1] CGColor]];
//		[aButton setBackgroundImage:[[UIImage imageNamed:@"greyButton.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0] forState:UIControlStateNormal];
//		[aButton setBackgroundImage:[[UIImage imageNamed:@"greyButtonPressed.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0] forState:UIControlStateHighlighted];
		[aButton setBackgroundColor:[UIColor clearColor]];
//		[aButton setBackgroundImage:[UIImage imageNamed:@"button-background-graygradient.png"] forState:UIControlStateNormal];
		[aButton addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
//		aButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
		aButton.titleLabel.font = [UIFont systemFontOfSize:14];
		CGFloat leftMargin = kCellTopOffset;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			leftMargin = kCellLeftOffsetPad;
		}
		aButton.frame = CGRectMake(leftMargin, 20,150, 30);
		[aButton setAccessibilityLabel:NSLocalizedString(@"Forgot Password?", @"Accessibility label for Forgot Password button.")];
		[aButton setAccessibilityHint:	NSLocalizedString(@"Sends your password to your email address.", @"Accessibility hint for Forgot Password button.")];
		self.loginFooterView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		[self.loginFooterView addSubview:aButton];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.loginHeaderView = [[[BlioLoginHeaderView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, 160)] autorelease];
        self.loginHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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
//	[(UILabel*)self.navigationItem.titleView setText:NSLocalizedString(@"Log in to Blio",@"\"Log in to Blio\" view controller header")];
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
//	self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	[self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
//	self.loginButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
//	self.loginButton.backgroundColor = [UIColor clearColor];
//	self.loginButton.frame = CGRectMake(0, 0, 150, kStdButtonHeight);
//	[self.loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	 	
	CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
	CGFloat activityIndicatorDiameter = 50.0f;
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((mainScreenBounds.size.width-activityIndicatorDiameter)/2, (mainScreenBounds.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
}
-(void)viewDidUnload {
	[activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;
}
-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
//	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"AlertWelcome"]) {
//		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"AlertWelcome"];
//		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Welcome To Blio",@"\"Welcome To Blio\" alert message title") 
//									 message:NSLocalizedStringWithDefaultValue(@"INTRO_WELCOME_ALERT",nil,[NSBundle mainBundle],@"If you have an account, you can log in to download books that you've purchased. Otherwise you can create an account.",@"Alert Text encouraging the end-user to either login or create a new account.")
//									delegate:nil
//						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
//						   otherButtonTitles:nil];		
//	}

}
- (void)viewDidDisappear:(BOOL)animated {
	[activityIndicatorView removeFromSuperview];
}
-(void)loginButtonPressed:(id)sender {
	if (!emailField.text || [emailField.text isEqualToString:@""]) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Login Error",@"\"Login Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"EMAIL_FIELD_MUST_BE_POPULATED",nil,[NSBundle mainBundle],@"Please enter your email address.",@"Alert Text informing the end-user that the email address must be entered to login.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
		[emailField becomeFirstResponder];
		return;
	}
	if (!passwordField.text || [passwordField.text isEqualToString:@""]) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Login Error",@"\"Login Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"PASSWORD_FIELD_MUST_BE_POPULATED",nil,[NSBundle mainBundle],@"Please enter your password.",@"Alert Text informing the end-user that the password must be entered to login.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];			
		[passwordField becomeFirstResponder];
		return;
	}	
	
	[activityIndicatorView startAnimating];
	[[BlioStoreManager sharedInstance] loginWithUsername:emailField.text password:passwordField.text sourceID:self.sourceID];	
}
- (void)receivedLoginResult:(BlioLoginResult)loginResult {
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
		loginErrorText = NSLocalizedStringWithDefaultValue(@"LOGIN_ERROR_CONNECTION_ERROR",nil,[NSBundle mainBundle],@"There was a problem logging in due to a network connection error. Please check the availability of your Internet connection and try again later.",@"Alert message when the login web service has failed.");
	}
	[activityIndicatorView stopAnimating];
	if (loginErrorText != nil) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Login Error",@"\"Login Error\" alert message title") 
									 message:loginErrorText
									delegate:self 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
	}
}

- (void) dismissLoginView: (id) sender {
	[[BlioStoreManager sharedInstance] loginFinishedForSourceID:sourceID];
//	[self dismissModalViewControllerAnimated:YES];
	[[BlioStoreManager sharedInstance] dismissLoginView];
}

- (UITextField *)createEmailTextField {
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
	if (!self.emailField) self.emailField = [[[UITextField alloc] initWithFrame:frame] autorelease];
	emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
	emailField.keyboardType = UIKeyboardTypeEmailAddress;
	emailField.keyboardAppearance = UIKeyboardAppearanceDefault;
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	emailField.placeholder = NSLocalizedString(@"E-mail Address",@"\"E-mail Address\" placeholder");
	emailField.delegate = self;
	
	NSString * loginUsername = [[BlioStoreManager sharedInstance] savedLoginUsername];
	if (loginUsername) {
		emailField.text = loginUsername;
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
	passwordField.returnKeyType = UIReturnKeyGo;
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
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
	return YES;
}

- (void)dealloc {
	self.emailField = nil;
	self.passwordField = nil;
	self.loginFooterView = nil;
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
		[textField resignFirstResponder];
		[self loginButtonPressed:textField];
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
//	return 2; // temporarily disabling "Create Account" to meet Apple's requirements.
    return 1;
}
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) return 2;
	else return 1;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
		return self.loginHeaderView;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//	return self.loginHeaderView.bounds.size.height;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return 225;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation]; 
    if(UIInterfaceOrientationIsLandscape(orientation)) return 90;
    return 210;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == 0) {
		return self.loginFooterView;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 60;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) return NSLocalizedStringWithDefaultValue(@"LOGIN_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"If you have a blioreader.com username, login now to retrieve your latest blioreader.com purchases.",@"Explanatory message that appears at the bottom of the Login table.");
	return nil;
}
*/
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
//		if (section == 1) {
//			cell.textLabel.textAlignment = UITextAlignmentCenter;
//			cell.textLabel.text = @"Forgot Password";
//			
//		}
		if (section == 1) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = NSLocalizedString(@"Create Account",@"\"Create Account\" text label for cell in Login View Controller");
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = [indexPath section];
//	if (section == 1) {
//		[tableView deselectRowAtIndexPath:indexPath animated:YES];
//		[self forgotPassword];
//		return;
//	}
	if (section == 1) {
		BlioCreateAccountViewController * createAccountViewController = [[[BlioCreateAccountViewController alloc] initWithSourceID:sourceID] autorelease];
		[self.navigationController pushViewController:createAccountViewController animated:YES];
	}
}

-(void)forgotPassword:(id)sender {
	if (!self.emailField.text || [self.emailField.text isEqualToString:@""]) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"ENTER_PASSWORD_IF_FORGOTTEN",nil,[NSBundle mainBundle],@"Please enter your email address so your password can be sent.",@"Alert Text informing the end-user that his/her email address must be entered before Blio can send his/her password.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];	
		return;
	}
	DigitalLockerRequest * request = [[DigitalLockerRequest alloc] init];
	request.Service = DigitalLockerServiceRegistration;
	request.Method = DigitalLockerMethodForgot;
	NSMutableDictionary * inputData = [NSMutableDictionary dictionaryWithCapacity:1];
	[inputData setObject:[NSString stringWithString:self.emailField.text] forKey:DigitalLockerInputDataEmailKey];
	request.InputData = inputData;
	DigitalLockerConnection * connection = [[DigitalLockerConnection alloc] initWithDigitalLockerRequest:request siteNum:[[BlioStoreManager sharedInstance] storeSiteIDForSourceID:sourceID] siteKey:[[BlioStoreManager sharedInstance] storeSiteKeyForSourceID:sourceID] delegate:self];
	[connection start];
	[request release];	
}

#pragma mark -
#pragma mark DigitalLockerConnectionDelegate methods

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection {
	NSLog(@"BlioLoginViewController connectionDidFinishLoading...");
	[activityIndicatorView stopAnimating];
	if (aConnection.digitalLockerResponse.ReturnCode == 0) {
		[[BlioStoreManager sharedInstance] saveUsername:emailField.text password:nil sourceID:sourceID];
		NSString * alertMessage = NSLocalizedStringWithDefaultValue(@"PASSWORD_SENT",nil,[NSBundle mainBundle],@"Your password has been sent to your email address.",@"Alert Text informing the end-user that his/her password has been sent to the email address specified.");
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
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
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Server Error",@"\"Server Error\" alert message title") 
									 message:errorMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
	}
	[aConnection release];
}

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error {
	[aConnection release];
}

@end
