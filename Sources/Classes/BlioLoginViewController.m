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

@implementation BlioLoginViewController

@synthesize loginTableView, loginManager, usernameField, passwordField, activityIndicator, statusField;

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Sign in to Blio", @"");
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
	
    return label;
}

- (void)loadView {
	
	self.navigationItem.titleView = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,4.0f,320.0f,36.0f)];
	[(UILabel*)self.navigationItem.titleView setText:@"Sign in to Blio"];
	[(UILabel*)self.navigationItem.titleView setBackgroundColor:[UIColor clearColor]];
	[(UILabel*)self.navigationItem.titleView setTextColor:[UIColor whiteColor]];
	[(UILabel*)self.navigationItem.titleView setTextAlignment:UITextAlignmentCenter];
	[(UILabel*)self.navigationItem.titleView setFont:[UIFont boldSystemFontOfSize:18.0f]];
 	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
											   initWithTitle:@"Cancel" 
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
	
	CGFloat yPlacement = kTopMargin + 3*kTextFieldHeight;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	statusField = [BlioLoginViewController labelWithFrame:frame title:@""];
	[self.view addSubview:statusField];
	 
	 activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((6.5)*kLeftMargin, yPlacement, 16.0f, 16.0f)];
	 //[activityIndicator setCenter:CGPointMake(160.0f, 208.0f)];
	 [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	 [self.view addSubview:activityIndicator];
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
	usernameField.placeholder = @"Username";
	usernameField.delegate = self;
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
	passwordField.placeholder = @"Password";
	passwordField.delegate = self;
	passwordField.secureTextEntry = YES;
		
	return passwordField;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}


- (void)dealloc {
	[activityIndicator release];
	[loginTableView release];
    [super dealloc];
}
	
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{   
	if (textField == usernameField) 
		[passwordField becomeFirstResponder];
	else { 
		statusField.text = @"Signing in..."; 
		[activityIndicator startAnimating];
		BlioLoginResult loginStatus = [self.loginManager login:usernameField.text password:passwordField.text];
		[activityIndicator stopAnimating];
		if ( loginStatus == success ) 
			[self dismissModalViewControllerAnimated:YES];
		else if ( loginStatus == invalidPassword ) 
			statusField.text = @"Invalid username or password.";
		else
			statusField.text = @"Error signing in.";
		statusField.textColor = [UIColor redColor];
		[textField resignFirstResponder];
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
