//
//  BlioAppSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAppSettingsController.h"
#import "BlioAudioSettingsController.h"
#import "BlioWebToolSettingsController.h"
#import "BlioPaidBooksSettingsController.h"
#import "BlioAboutSettingsController.h"
#import "BlioHelpSettingsController.h"

@implementation BlioAppSettingsController


- (BlioAppSettingsController*)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = @"Settings";
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
#endif
    }
    return self;
}

- (void)loadView {
	[super loadView];
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
												   initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button")
												   style:UIBarButtonItemStyleDone 
												   target:self
												   action:@selector(dismissSettingsView:)]
												  autorelease];		
	}
#else
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											   initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button")
											   style:UIBarButtonItemStyleDone 
											   target:self
											   action:@selector(dismissSettingsView:)]
											  autorelease];
#endif
	
}

- (void) dismissSettingsView: (id) sender {
    [self dismissModalViewControllerAnimated:YES];
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	switch ( [indexPath section] ) {
		case 0:
			[cell.textLabel setText:@"Text to Speech"];
			break;
		case 1:
			[cell.textLabel setText:@"Web Tools"];
			break;
		case 2:
			[cell.textLabel setText:@"Paid Books"];
			break;
		case 3:
			[cell.textLabel setText:@"Help"];
			break;
		case 4:
			[cell.textLabel setText:@"About"];
			break;
		default:
			break;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioAudioSettingsController *audioController;
	BlioWebToolSettingsController *webToolController;
	BlioPaidBooksSettingsController *paidBooksController;
	BlioHelpSettingsController *helpController;
	BlioAboutSettingsController *aboutController;
	switch ( [indexPath section] ) {
		case 0:
			audioController = [[BlioAudioSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
			[self.navigationController pushViewController:audioController animated:YES];
			[audioController release];
			break;
		case 1:
			webToolController = [[BlioWebToolSettingsController alloc] init];
			[self.navigationController pushViewController:webToolController animated:YES];
			[webToolController release];
			break;
		case 2:
			paidBooksController = [[BlioPaidBooksSettingsController alloc] init];
			[self.navigationController pushViewController:paidBooksController animated:YES];
			[paidBooksController release];
			break;
		case 3:
			helpController = [[BlioHelpSettingsController alloc] init];
			[self.navigationController pushViewController:helpController animated:YES];
			[helpController release];
			break;
		case 4:
			aboutController = [[BlioAboutSettingsController alloc] init];
			[self.navigationController pushViewController:aboutController animated:YES];
			[aboutController release];
			break;
		default:
			break;
	}
}

- (void)dealloc {
    [super dealloc];
}


@end

