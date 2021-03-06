//
//  BlioIdentityProvidersViewController.m
//  StackApp
//
//  Created by Arnold Chien on 1/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioIdentityProvidersViewController.h"
#import "BlioWebAuthenticationViewController.h"
#import "BlioStoreManager.h"
#import "BlioAccountService.h"

@interface BlioIdentityProvidersViewController ()

@end

@implementation BlioIdentityProvidersViewController

- (id)initWithProviders:(NSDictionary*)providers {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Choose an Account";
        images = [[NSMutableArray alloc] initWithCapacity:[providers count]];
        names = [[NSMutableArray alloc] initWithCapacity:[providers count]];
        loginURLs = [[NSMutableArray alloc] initWithCapacity:[providers count]];
        logoutURLs = [[NSMutableArray alloc] initWithCapacity:[providers count]];
        [providers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [names addObject:key];
            [images addObject:[(NSDictionary*)obj valueForKey:@"Image"]];
            [loginURLs addObject:[(NSDictionary*)obj valueForKey:@"LoginURL"]];
            [logoutURLs addObject:[(NSDictionary*)obj valueForKey:@"LogoutURL"]];
         }];
    }
    return self;
}

- (void)dealloc {
    images = nil;
    names = nil;
    loginURLs = nil;
    logoutURLs = nil;
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	//CGFloat viewHeight = self.tableView.contentSize.height;
	//if (viewHeight > 600)
    //viewHeight = 600;
	//self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);
	
}

- (void)loadView {
	[super loadView];
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                  initWithTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" bar button")
                                                  style:UIBarButtonItemStyleDone
                                                  target:self
                                                  action:@selector(dismissSettingsView:)]
                                                 autorelease];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dismissSettingsView: (id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [names count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSInteger ix = [indexPath section];
    if ([names count] && [images count]) {
        cell.textLabel.text = names[ix];
        cell.imageView.image = images[ix];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlioWebAuthenticationViewController *authenticationController;
    NSInteger section = [indexPath section];
    authenticationController = [[BlioWebAuthenticationViewController alloc] initWithURL:[loginURLs objectAtIndex:section]];
    [self.navigationController pushViewController:authenticationController animated:YES];
    [authenticationController release];
    if ([BlioAccountService sharedInstance].logoutUrl)
        [BlioAccountService sharedInstance].logoutUrl = nil;
    [BlioAccountService sharedInstance].logoutUrl = [logoutURLs objectAtIndex:section];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
