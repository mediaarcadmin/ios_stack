//
//  BlioDownloadVoicesViewController.m
//  BlioApp
//
//  Created by Don Shin on 5/28/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioDownloadVoicesViewController.h"
#import "BlioAcapelaAudioManager.h"
#import "BlioProcessing.h"
#import "BlioProcessingStandardOperations.h"


@implementation BlioDownloadVoicesViewController

@synthesize availableVoicesForDownload;

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		self.title = NSLocalizedString(@"Download Voices",@"\"Download Voices\" view controller title.");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
#endif

    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.availableVoicesForDownload = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
//    self.clearsSelectionOnViewWillAppear = NO;
 
	self.availableVoicesForDownload = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForDownload];
	
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	CGFloat viewHeight = self.tableView.contentSize.height;
	NSLog(@"viewHeight: %f",viewHeight);
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);	
	
}

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
	return NSLocalizedString(@"Available Voices",@"\"Available Voices\" table header in Download Voices View");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return NSLocalizedStringWithDefaultValue(@"DOWNLOAD_VOICES_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Voices take approximately 50MB of storage each, and may take time to download. Do not quit Blio while download is in progress.",@"Explanatory message that appears at the bottom of the Available Voices table within Download Voices View.");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.availableVoicesForDownload count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"BlioDownloadVoiceTableViewCell";
    
    BlioDownloadVoiceTableViewCell *cell = (BlioDownloadVoiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[BlioDownloadVoiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	[cell configureWithVoice:[self.availableVoicesForDownload objectAtIndex:indexPath.row]];

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
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {

}
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {

}
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	// grab data values in response
	
	[aConnection release];
	
//	SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:aSet];	
//	productsRequest.delegate = self;
//	[productsRequest start];
	
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	// notify end-user
	
	[aConnection release];
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


@end

@implementation BlioDownloadVoiceTableViewCell

@synthesize downloadButton,voice,progressView,progressLabel;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.downloadButton = nil;
	self.voice = nil;
	self.progressView = nil;
	self.progressLabel = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
		
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
		
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateDownload];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingOperationFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
	}
    return self;
}
-(void)prepareForReuse {
	[super prepareForReuse];
	[self setDownloadButtonState:BlioVoiceDownloadButtonStateDownload];
}
-(void)setDownloadButtonState:(BlioVoiceDownloadButtonState)buttonState {
	switch (buttonState) {
		case BlioVoiceDownloadButtonStateDownload:
			[self.downloadButton setTitle:NSLocalizedString(@"Download",@"\"Download\" button label in download voices view") forState:UIControlStateNormal];
			self.downloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
			[self.downloadButton setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateNormal];		
			self.downloadButton.hidden = NO;
			self.downloadButton.alpha = 1.0f;
			self.downloadButton.enabled = YES;
			
			self.progressView.hidden = YES;
			self.progressLabel.hidden = YES;
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
			[self.downloadButton setTitle:NSLocalizedString(@"Installed",@"\"Installed\" button label in download voices view") forState:UIControlStateNormal];
			self.downloadButton.enabled = NO;
//			[self.downloadButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];		
			break;
	}
}
-(NSString*)progressLabelFormattedText {
	return NSLocalizedStringWithDefaultValue(@"F_OF_F_MB_DOWNLOAD_PROGRESS",nil,[NSBundle mainBundle],@"%.1f of %.1f MB",@"\"%.1f of %.1f MB\" download voice progress label text");
}
-(void)configureWithVoice:(NSString*)aVoice {
	self.voice = aVoice;
    self.textLabel.text = [BlioAcapelaAudioManager voiceNameForVoice:aVoice];
	self.textLabel.backgroundColor = [UIColor clearColor];
	BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] downloadVoiceOperationByVoice:aVoice];
	if (voiceOp) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
		self.progressView.progress = voiceOp.percentageComplete/100.0f;
		if (voiceOp.expectedContentLength != NSURLResponseUnknownLength) {
			CGFloat totalMB = voiceOp.expectedContentLength/1000000;
			CGFloat progressMB = (voiceOp.expectedContentLength * self.progressView.progress)/1000000;
			self.progressLabel.text = [NSString stringWithFormat:[self progressLabelFormattedText],progressMB,totalMB];
		}
	}
	else if ([[[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForUse] containsObject:aVoice]) {
		[self setDownloadButtonState:BlioVoiceDownloadButtonStateInstalled];
	}
	else [self setDownloadButtonState:BlioVoiceDownloadButtonStateDownload];
}
-(void)onPlaySampleButtonPressed:(id)sender {
//	NSLog(@"onPlaySampleButtonPressed");
	[[BlioAcapelaAudioManager sharedAcapelaAudioManager] playSampleForVoice:self.voice];
}
-(void)onDownloadButtonPressed:(id)sender {
//	NSLog(@"onDownloadButtonPressed");
	[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
	[[BlioAcapelaAudioManager sharedAcapelaAudioManager] downloadVoice:self.voice];
}
- (void)onProcessingOperationProgressNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [note object];
		if ([voiceOp.voice isEqualToString:self.voice]) {
//			NSLog(@"BlioDownloadVoiceTableViewCell onProcessingProgressNotification entered. percentage: %u",voiceOp.percentageComplete);
			[self setDownloadButtonState:BlioVoiceDownloadButtonStateInProgress];
			if (voiceOp.percentageComplete != 100) {
				self.progressView.progress = voiceOp.percentageComplete/100.0f;
				CGFloat totalMB = voiceOp.expectedContentLength/1000000.0f;
				CGFloat progressMB = (voiceOp.expectedContentLength * self.progressView.progress)/1000000.0f;
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
		if ([voiceOp.voice isEqualToString:self.voice]) {
			//			NSLog(@"BlioDownloadVoiceTableViewCell onProcessingOperationCompleteNotification entered.");
			[self setDownloadButtonState:BlioVoiceDownloadButtonStateInstalled];
		}
	}
}
- (void)onProcessingOperationFailedNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOp = [note object];
		if ([voiceOp.voice isEqualToString:self.voice]) {
			//			NSLog(@"BlioDownloadVoiceTableViewCell onProcessingOperationFailedNotification entered.");
			[self setDownloadButtonState:BlioVoiceDownloadButtonStateDownload];
		}
	}
}

@end

