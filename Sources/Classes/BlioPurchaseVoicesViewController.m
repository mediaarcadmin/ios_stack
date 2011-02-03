//
//  BlioPurchaseVoicesViewController.m
//  BlioApp
//
//  Created by Don Shin on 10/1/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioPurchaseVoicesViewController.h"
#import "BlioAcapelaAudioManager.h"
#import "BlioProcessing.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioInAppPurchaseManager.h"
#import "BlioAlertManager.h"
#import "SKProduct+LocalizedPrice.h"

@implementation BlioPurchaseVoicesViewController

@synthesize availableVoicesForPurchase,activityIndicatorView;

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		self.title = NSLocalizedString(@"Purchase Voices",@"\"Purchase Voices\" view controller title.");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
#endif
    }
    return self;
}

- (void)dealloc {
	self.availableVoicesForPurchase = nil;
	self.activityIndicatorView = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	CGFloat activityIndicatorDiameter = 50.0f;
	CGRect targetFrame = [[UIScreen mainScreen] bounds];
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((targetFrame.size.width-activityIndicatorDiameter)/2, (targetFrame.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
		
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseProductsFetchStarted:) name:BlioInAppPurchaseProductsFetchStarted object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseProductsFetchFailed:) name:BlioInAppPurchaseProductsFetchFailed object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseProductsFetchFinished:) name:BlioInAppPurchaseProductsFetchFinished object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseProductsUpdated:) name:BlioInAppPurchaseProductsUpdated object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inAppPurchaseTransactionDone:) name:BlioInAppPurchaseTransactionFailed object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inAppPurchaseTransactionDone:) name:BlioInAppPurchaseTransactionRestored object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inAppPurchaseTransactionDone:) name:BlioInAppPurchaseTransactionPurchased object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];		
	
	if (![BlioInAppPurchaseManager sharedInAppPurchaseManager].isFetchingProducts) {
		[[BlioInAppPurchaseManager sharedInAppPurchaseManager] fetchProductsFromProductServer];
		[self.tableView reloadData];
	}
	else [self.activityIndicatorView startAnimating];
}
-(void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;
	// Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;

}
-(void)didReceiveInAppPurchaseProductsFetchStarted:(NSNotification*)note {
	[self.activityIndicatorView startAnimating];
}
-(void)didReceiveInAppPurchaseProductsFetchFailed:(NSNotification*)note {
	[self.activityIndicatorView stopAnimating];
}
-(void)didReceiveInAppPurchaseProductsFetchFinished:(NSNotification*)note {
	[self.activityIndicatorView stopAnimating];
}
-(void)didReceiveInAppPurchaseProductsUpdated:(NSNotification*)note {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self.activityIndicatorView stopAnimating];
	self.availableVoicesForPurchase = [BlioInAppPurchaseManager sharedInAppPurchaseManager].inAppProducts;
//	NSArray * availableVoicesForUse = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForUse];
//	for (SKProduct * product in [BlioInAppPurchaseManager sharedInAppPurchaseManager].products) {
//		if (![availableVoicesForUse containsObject:product.localizedTitle]) [availableVoicesForPurchase addObject:product];
//	}
//
//	for (SKProduct * product in availableVoicesForPurchase) {
//		NSLog(@"voice product: %@",product.localizedTitle);
//	}
	[self.tableView reloadData];
}



 - (void)viewWillAppear:(BOOL)animated {
	 [super viewWillAppear:animated];
	 self.activityIndicatorView.hidden = NO;
	 
	 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		 CGRect localRect = CGRectMake(self.view.frame.size.width/2 - self.activityIndicatorView.frame.size.width/2, self.view.frame.size.height/2 - self.activityIndicatorView.frame.size.height/2, self.activityIndicatorView.frame.size.width, self.activityIndicatorView.frame.size.height);
		 [self.activityIndicatorView removeFromSuperview];
		 [self.view addSubview:self.activityIndicatorView];
		 self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		 //		 self.activityIndicatorView.frame = [self.view.window.layer convertRect:localRect fromLayer:self.view.layer];
		 self.activityIndicatorView.frame = localRect;
	 }	 
}
 

 - (void)viewDidAppear:(BOOL)animated {
	 [super viewDidAppear:animated];
	 
 }
 
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */

 - (void)viewDidDisappear:(BOOL)animated {
	 [super viewDidDisappear:animated];
	 self.activityIndicatorView.hidden = YES;
}
 

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	if ([BlioInAppPurchaseManager sharedInAppPurchaseManager].isFetchingProducts) return nil;
//	else if (!self.availableVoicesForPurchase || [self.availableVoicesForPurchase count] == 0) return nil;
	return NSLocalizedString(@"Available Voices",@"\"Available Voices\" table header in Download Voices View");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if ([BlioInAppPurchaseManager sharedInAppPurchaseManager].isFetchingProducts) return NSLocalizedStringWithDefaultValue(@"CHECKING_FOR_VOICES_AVAILABLE_FOR_PURCHASE",nil,[NSBundle mainBundle],@"Blio is checking the App Store for available voices. Please wait a moment...",@"Explanatory message that informs the end-user the Blio app is checking the App Store for available voices in the Purchase Voices View.");
	else if (!self.availableVoicesForPurchase || [self.availableVoicesForPurchase count] == 0) return NSLocalizedStringWithDefaultValue(@"NO_AVAILABLE_VOICES_FOR_PURCHASE",nil,[NSBundle mainBundle],@"There are no new voices available for you to purchase at this time.",@"Explanatory message that informs the end-user the Blio app is checking the App Store for available voices in the Purchase Voices View.");
	return NSLocalizedStringWithDefaultValue(@"PURCHASE_VOICES_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Voices take approximately 50MB of storage each, and may take time to download.",@"Explanatory message that appears at the bottom of the Available Voices table within Purchase Voices View.");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 80;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.availableVoicesForPurchase count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"BlioPurchaseVoiceTableViewCell";
    
    BlioPurchaseVoiceTableViewCell *cell = (BlioPurchaseVoiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[BlioPurchaseVoiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.delegate = self;
    }
    
    // Configure the cell...
	[cell configureWithInAppPurchaseProduct:[self.availableVoicesForPurchase objectAtIndex:indexPath.row]];
	
    return cell;
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
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
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
-(void)inAppPurchaseTransactionDone:(NSNotification*)note {
	[self.activityIndicatorView stopAnimating];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

#pragma mark -
#pragma mark BlioPurchaseVoiceViewDelegate

-(void)purchaseProductWithID:(NSString*)productID {
	[self.activityIndicatorView startAnimating];
	[[BlioInAppPurchaseManager sharedInAppPurchaseManager] purchaseProductWithID:productID];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end

@implementation BlioPurchaseVoiceTableViewCell

@synthesize downloadButton,product,progressView,progressLabel,delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.downloadButton = nil;
	self.product = nil;
	self.progressView = nil;
	self.progressLabel = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
		buttonState = -1;
		[self.imageView setImage:[UIImage imageNamed:@"voice-sample-play-button.png"]];
		UIButton * sampleButton = [UIButton buttonWithType:UIButtonTypeCustom];
		sampleButton.frame = CGRectMake(0,0,44,self.bounds.size.height);
		sampleButton.showsTouchWhenHighlighted = YES;
		[sampleButton addTarget:self action:@selector(onPlaySampleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[sampleButton setAccessibilityLabel:NSLocalizedString(@"Play sample", @"Accessibility label for Voice Download Play button")];
		
		[self.contentView addSubview:sampleButton];
		self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
		self.downloadButton.frame = CGRectMake(self.contentView.bounds.size.width - kBlioVoiceDownloadButtonWidth - kBlioVoiceDownloadButtonRightMargin, (self.bounds.size.height - kBlioVoiceDownloadButtonHeight)/2, kBlioVoiceDownloadButtonWidth, kBlioVoiceDownloadButtonHeight);
		//		self.downloadButton.frame = CGRectMake(0,0,320,44);
		self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.downloadButton addTarget:self action:@selector(onDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		self.downloadButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
		[self.downloadButton setBackgroundImage:[[UIImage imageNamed:@"downloadButton.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0] forState:UIControlStateNormal];
		[self.downloadButton setBackgroundImage:[[UIImage imageNamed:@"downloadButtonPressed.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0] forState:UIControlStateDisabled];
		[self.contentView addSubview:downloadButton];
		[self.contentView bringSubviewToFront:downloadButton];
		
		self.progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
		self.progressView.frame = CGRectMake(self.contentView.bounds.size.width - kBlioVoiceDownloadProgressViewWidth - kBlioVoiceDownloadProgressViewRightMargin, (self.bounds.size.height - kBlioVoiceDownloadProgressViewHeight)/2, kBlioVoiceDownloadProgressViewWidth, kBlioVoiceDownloadProgressViewHeight);
		self.progressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.contentView addSubview:progressView];
		[self.contentView bringSubviewToFront:progressView];
		
		self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x, self.progressView.frame.origin.y + self.progressView.frame.size.height, self.progressView.frame.size.width, 15.0f)];
		self.progressLabel.center = CGPointMake(self.progressView.center.x, self.progressView.center.y + self.progressView.bounds.size.height);
		self.progressLabel.font = [UIFont boldSystemFontOfSize:11];
		self.progressLabel.textAlignment = UITextAlignmentCenter;
		self.progressLabel.backgroundColor = [UIColor clearColor];
		self.progressLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.contentView addSubview:progressLabel];
		[self.contentView bringSubviewToFront:progressLabel];
		
		[self.contentView sendSubviewToBack:self.textLabel];
		self.textLabel.backgroundColor = [UIColor clearColor];
		[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchase];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseTransactionFailed:) name:BlioInAppPurchaseTransactionFailed object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseTransactionRestored:) name:BlioInAppPurchaseTransactionRestored object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveInAppPurchaseTransactionPurchased:) name:BlioInAppPurchaseTransactionPurchased object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];		
	}
    return self;
}
-(void)prepareForReuse {
	[super prepareForReuse];
	[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchase];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)setDownloadButtonState:(BlioVoiceDownloadButtonState)aButtonState {
	if (buttonState != aButtonState) {
		buttonState = aButtonState;
		switch (buttonState) {
			case BlioVoiceDownloadButtonStatePurchase:
				self.downloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
				[self.downloadButton setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateNormal];		
				self.downloadButton.hidden = NO;
				self.downloadButton.alpha = 1.0f;
				self.downloadButton.enabled = YES;
				
				self.progressView.hidden = YES;
				self.progressLabel.hidden = YES;
				break;
			case BlioVoiceDownloadButtonStatePurchasing:
				self.progressView.hidden = YES;
				self.progressLabel.hidden = YES;
				self.downloadButton.hidden = NO;
				self.downloadButton.alpha = 0.65f;
				[self.downloadButton setTitle:NSLocalizedString(@"Processing",@"\"Processing\" transition button label in purchase voices view.") forState:UIControlStateDisabled];
				self.downloadButton.enabled = NO;
				//			[self.downloadButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];		
				break;
				
			case BlioVoiceDownloadButtonStateInProgress:
				self.progressView.hidden = NO;
				self.progressLabel.hidden = NO;
				self.progressLabel.text = NSLocalizedString(@"Calculating...",@"\"Calculating...\" text label as temporary substitute for i of i MB progress label text.");
				self.downloadButton.hidden = YES;		
				break;
				
			case BlioVoiceDownloadButtonStateInstalled:
				self.progressView.hidden = YES;
				self.progressLabel.hidden = YES;
				self.downloadButton.hidden = NO;
				self.downloadButton.alpha = 0.65f;
				[self.downloadButton setTitle:NSLocalizedString(@"Installed",@"\"Installed\" button label in purchase voices view") forState:UIControlStateDisabled];
				self.downloadButton.enabled = NO;
				//			[self.downloadButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];		
				break;
		}
	}
}
-(NSString*)progressLabelFormattedText {
	return NSLocalizedStringWithDefaultValue(@"F_OF_F_MB_DOWNLOAD_PROGRESS",nil,[NSBundle mainBundle],@"%.1f of %.1f MB",@"\"%.1f of %.1f MB\" download voice progress label text");
}
-(void)configureWithInAppPurchaseProduct:(CCInAppPurchaseProduct*)aProduct {
	self.product = aProduct;
    self.textLabel.text = self.product.name;
	[self.downloadButton setTitle:[NSString stringWithFormat:@"%@",self.product.product.localizedPrice] forState:UIControlStateNormal];
	BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] downloadVoiceOperationByVoice:self.product.name];
	if (voiceOp) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
		self.progressView.progress = voiceOp.percentageComplete/100.0f;
		if (voiceOp.expectedContentLength != NSURLResponseUnknownLength) {
			CGFloat totalMB = voiceOp.expectedContentLength/1000000;
			CGFloat progressMB = (voiceOp.expectedContentLength * self.progressView.progress)/1000000;
			self.progressLabel.text = [NSString stringWithFormat:[self progressLabelFormattedText],progressMB,totalMB];
		}
	}
	else if ([[[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoiceNamesForUse] containsObject:self.product.name]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInstalled];
	}
	else if ([[BlioInAppPurchaseManager sharedInAppPurchaseManager] isPurchasingProductWithID:self.product.productId]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchasing];
	}
	else [self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchase];
}
-(void)onPlaySampleButtonPressed:(id)sender {
	//	NSLog(@"onPlaySampleButtonPressed");
	[[BlioAcapelaAudioManager sharedAcapelaAudioManager] playSampleForVoiceName:self.product.name];
}
-(void)onDownloadButtonPressed:(id)sender {
	//	NSLog(@"onDownloadButtonPressed");
	if ([[BlioInAppPurchaseManager sharedInAppPurchaseManager] canMakePurchases]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchasing];
		[self.delegate purchaseProductWithID:self.product.productId];
	}
	else {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:NSLocalizedStringWithDefaultValue(@"PURCHASES_NOT_ENABLED",nil,[NSBundle mainBundle],@"In-App Purchases are not currently enabled, possibly due to Parental Controls restrictions.",@"Alert message when SKPaymenQueue canMakePayments returns NO.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
	}
}
- (void)onProcessingOperationProgressNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [note object];
		if ([voiceOp.voice isEqualToString:self.product.productId]) {
			//			NSLog(@"BlioPurchaseVoiceTableViewCell onProcessingProgressNotification entered. percentage: %u",voiceOp.percentageComplete);
			[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
			if (voiceOp.percentageComplete != 100) {
				self.progressView.progress = voiceOp.percentageComplete/100.0f;
				CGFloat totalMB = voiceOp.expectedContentLength/1000000;
				CGFloat progressMB = (voiceOp.expectedContentLength * self.progressView.progress)/1000000;
				self.progressLabel.text = [NSString stringWithFormat:[self progressLabelFormattedText],progressMB,totalMB];		
			}
			else {
				self.progressLabel.text = self.progressLabel.text = NSLocalizedString(@"Installing...",@"\"Installing...\" text label as temporary substitute for i of i MB progress label text.");
				self.progressView.progress = 1.0;
			}
		}
	}
}
- (void)onProcessingOperationCompleteNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [note object];
		if ([voiceOp.voice isEqualToString:self.product.productId]) {
			//			NSLog(@"BlioPurchaseVoiceTableViewCell onProcessingOperationCompleteNotification entered.");
			[self setDownloadButtonState:BlioVoiceDownloadButtonStateInstalled];
		}
	}
}
- (void)onProcessingOperationFailedNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [note object];
		if ([voiceOp.voice isEqualToString:self.product.productId]) {
			//			NSLog(@"BlioPurchaseVoiceTableViewCell onProcessingOperationFailedNotification entered.");
			[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchase];
		}
	}
}
- (void)didReceiveInAppPurchaseTransactionFailed:(NSNotification*)note {
	SKPaymentTransaction* transaction = (SKPaymentTransaction*)[[note userInfo] objectForKey:BlioInAppPurchaseNotificationTransactionKey];
	if ([transaction.payment.productIdentifier isEqualToString:self.product.productId]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStatePurchase];
	}
}
- (void)didReceiveInAppPurchaseTransactionRestored:(NSNotification*)note {
	SKPaymentTransaction* transaction = (SKPaymentTransaction*)[[note userInfo] objectForKey:BlioInAppPurchaseNotificationTransactionKey];
	if ([transaction.payment.productIdentifier isEqualToString:self.product.productId]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
	}
}
- (void)didReceiveInAppPurchaseTransactionPurchased:(NSNotification*)note {
	SKPaymentTransaction* transaction = (SKPaymentTransaction*)[[note userInfo] objectForKey:BlioInAppPurchaseNotificationTransactionKey];
	if ([transaction.payment.productIdentifier isEqualToString:self.product.productId]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
	}
}
@end

