//
//  BlioVoiceOverHelpSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioVoiceOverHelpSettingsController.h"
#import "BlioVOTipsSettingsController.h"
#import "BlioVoiceOverTextController.h"

@implementation BlioVoiceOverHelpSettingsController


- (BlioVoiceOverHelpSettingsController*)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"VoiceOver",@"\"VoiceOver\" view controller title");
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
    }
    return self;
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
    
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	switch ( [indexPath section] ) {
		case 0:
            cell.textLabel.text = NSLocalizedString(@"Quick Start",@"\"Quick Start\" text label for VoiceOver cell");
			break;
		case 1:
            cell.textLabel.text = NSLocalizedString(@"Help",@"\"Quick Start\" text label for VoiceOver cell");
			break;
		default:
			break;
	}
	
	[cell setAccessibilityTraits:UIAccessibilityTraitButton];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioVoiceOverTextController *voquickstartController;
    BlioVOTipsSettingsController *votipsController;
    
	switch ( [indexPath section] ) {
		case 0:
            voquickstartController = [[BlioVoiceOverTextController alloc] init];
            [self.navigationController pushViewController:voquickstartController animated:YES];
            [voquickstartController release];
			break;
		case 1:
            votipsController = [[BlioVOTipsSettingsController alloc] init];
            [self.navigationController pushViewController:votipsController animated:YES];
            [votipsController release];
			break;
		default:
			break;
	}
}
- (void)dealloc {
	[super dealloc];
}


@end

