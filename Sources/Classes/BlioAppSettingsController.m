//
//  BlioAppSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAppSettingsController.h"
#import "BlioAudioSettingsController.h"

@implementation BlioAppSettingsController


- (BlioAppSettingsController*)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = @"Settings";
    }
    return self;
}

- (void)loadView {
	[super loadView];
	
	self.navigationItem.titleView = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,4.0f,320.0f,36.0f)];
	[(UILabel*)self.navigationItem.titleView setText:@"Settings"];
	[(UILabel*)self.navigationItem.titleView setBackgroundColor:[UIColor clearColor]];
	[(UILabel*)self.navigationItem.titleView setTextColor:[UIColor whiteColor]];
	[(UILabel*)self.navigationItem.titleView setTextAlignment:UITextAlignmentCenter];
	[(UILabel*)self.navigationItem.titleView setFont:[UIFont boldSystemFontOfSize:18.0f]];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											  initWithTitle:@"Done" 
											  style:UIBarButtonItemStyleDone 
											  target:self
											   action:@selector(dismissSettingsView:)]
											  autorelease];
 
}

- (void) dismissSettingsView: (id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
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
    
	[cell.textLabel setText:@"Text to Speech"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioAudioSettingsController *audioController = [[BlioAudioSettingsController alloc] init];
	[self.navigationController pushViewController:audioController animated:YES];
	[audioController release];
}

- (void)dealloc {
    [super dealloc];
}


@end

