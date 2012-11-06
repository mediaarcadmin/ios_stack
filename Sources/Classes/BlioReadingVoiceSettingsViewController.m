//
//  BlioReadingVoiceSettingsViewController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioReadingVoiceSettingsViewController.h"
#import "BlioAppSettingsConstants.h"
#import "BlioBookViewController.h"
//#import "BlioDownloadVoicesViewController.h"
#import "BlioPurchaseVoicesViewController.h"
#import "BlioAcapelaAudioManager.h"
#import "AcapelaSpeech.h"
#import "BlioBookManager.h"
#import "BlioInAppPurchaseManager.h"

@interface BlioReadingVoiceSettingsViewController(PRIVATE)
- (void)layoutControlsForOrientation:(UIInterfaceOrientation)orientation;
- (NSString *)ttsBooksInLibraryDisclosure;
@end

@implementation BlioReadingVoiceSettingsViewController

@synthesize activityIndicatorView, voiceControl, speedControl, volumeControl, playButton, voiceLabel, speedLabel, volumeLabel, availableVoices, contentView, footerHeight,ttsFetchedResultsController,totalFetchedResultsController;

- (id)init
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self)
	{
		self.title = NSLocalizedString(@"Reading Voice",@"\"Reading Voice\" view controller title.");
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
	}
	return self;
}
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.voiceControl = nil;
	self.speedControl = nil;
	self.volumeControl = nil;
	self.playButton = nil;
    self.voiceLabel = nil;
    self.speedLabel = nil;
    self.volumeLabel = nil;
	self.availableVoices = nil;
	self.contentView = nil;
	self.ttsFetchedResultsController = nil;
	self.totalFetchedResultsController = nil;
	[super dealloc];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat activityIndicatorDiameter = 50.0f;
	CGRect targetFrame = [[UIScreen mainScreen] bounds];
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((targetFrame.size.width-activityIndicatorDiameter)/2, (targetFrame.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInAppPurchaseRestoreTransactionsStarted:) name:BlioInAppPurchaseRestoreTransactionsStartedNotification object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInAppPurchaseRestoreTransactionsFinished:) name:BlioInAppPurchaseRestoreTransactionsFinishedNotification object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInAppPurchaseRestoreTransactionsFailed:) name:BlioInAppPurchaseRestoreTransactionsFailedNotification object:[BlioInAppPurchaseManager sharedInAppPurchaseManager]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVoiceListRefreshedNotification:) name:BlioVoiceListRefreshedNotification object:nil];

    // Uncomment the following line to preserve selection between presentations.
//    self.clearsSelectionOnViewWillAppear = YES;
	
	NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread]; 
	if (!moc) NSLog(@"WARNING: ManagedObjectContext is nil inside BlioLibraryViewController!");
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO] autorelease];
    NSArray *sorters = [NSArray arrayWithObject:sortDescriptor]; 
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
	
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
 	[request setPredicate:[NSPredicate predicateWithFormat:@"ttsCapable == %@ && processingState == %@ && transactionType != %@",[NSNumber numberWithBool:YES], [NSNumber numberWithInt:kBlioBookProcessingStateComplete],[NSNumber numberWithInt:BlioTransactionTypePreorder]]];
	[request setSortDescriptors:sorters];
 
	 self.ttsFetchedResultsController = [[[NSFetchedResultsController alloc]
									   initWithFetchRequest:request
									   managedObjectContext:moc
									   sectionNameKeyPath:nil
									   cacheName:nil] autorelease];
	 [request release];
	 
	 [ttsFetchedResultsController setDelegate:self];
	 NSError *error = nil; 
	 [ttsFetchedResultsController performFetch:&error];
	 
	 if (error) 
	 NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	 else {
		 ttsBooks = [[ttsFetchedResultsController fetchedObjects] count];
	 }	
	 
	 request = [[NSFetchRequest alloc] init]; 
	 
	 [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
	 [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@ && transactionType != %@", [NSNumber numberWithInt:kBlioBookProcessingStateComplete],[NSNumber numberWithInt:BlioTransactionTypePreorder]]];
	[request setSortDescriptors:sorters];

	  self.totalFetchedResultsController = [[[NSFetchedResultsController alloc]
										initWithFetchRequest:request
										managedObjectContext:moc
										sectionNameKeyPath:nil
										cacheName:nil] autorelease];
	  [request release];
	  
	  [totalFetchedResultsController setDelegate:self];
	  error = nil; 
	  [totalFetchedResultsController performFetch:&error];
	  
	  if (error) 
	  NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	  else {
		  totalBooks = [[totalFetchedResultsController fetchedObjects] count];
		  [self.tableView reloadData];
	  }	
	  
}
-(void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioVoiceListRefreshedNotification object:nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioInAppPurchaseRestoreTransactionsStartedNotification object:nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioInAppPurchaseRestoreTransactionsFinishedNotification object:nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioInAppPurchaseRestoreTransactionsFailedNotification object:nil];
}
-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	CGFloat viewHeight = self.tableView.contentSize.height;
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);	
}
- (void)viewWillDisappear:(BOOL)animated {
	BlioAcapelaAudioManager * tts = [BlioAcapelaAudioManager sharedAcapelaAudioManager];
	if (tts != nil && [tts isSpeaking] )
		[tts stopSpeaking]; 
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

- (void)createControls
{
	
//	// Voice control
//    self.voiceLabel = [BlioAudioSettingsController labelWithFrame:CGRectZero title:@"Voice"];
//	[self.contentView addSubview:voiceLabel];

//	NSArray *segmentTextContent = [NSArray arrayWithObjects: @"Laura", @"Ryan", nil];
//    self.voiceControl = [[[UISegmentedControl alloc] initWithItems:segmentTextContent] autorelease];
//    voiceControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
//    
//	[voiceControl addTarget:self action:@selector(changeVoice:) forControlEvents:UIControlEventValueChanged];
//	voiceControl.segmentedControlStyle = UISegmentedControlStyleBar;
//	// If no voice has previously been set, set to the first voice (female).
//	[voiceControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]];
//	[self.contentView addSubview:voiceControl];
	
	// Speed control
	
    self.speedLabel = [BlioReadingVoiceSettingsViewController labelWithFrame:CGRectZero title:NSLocalizedString(@"Speed",@"\"Speed\" audio setting label.")];
	[self.contentView addSubview:speedLabel];
	
	
	self.speedControl = [[[UISlider alloc] initWithFrame:CGRectZero] autorelease];
    speedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[speedControl addTarget:self action:@selector(changeSpeed:) forControlEvents:UIControlEventValueChanged];
	// in case the parent view draws with a custom color or gradient, use a transparent color
	speedControl.backgroundColor = [UIColor clearColor];
	speedControl.minimumValue = 80.0;
	speedControl.maximumValue = 360.0;
	speedControl.continuous = NO;
    [speedControl setAccessibilityLabel:NSLocalizedString(@"Speed", @"Accessibility label for Audio settings speed slider")];

	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:180.0 forKey:kBlioLastSpeedDefaultsKey];
	speedControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey];
	[self.contentView addSubview:speedControl];
	
	// Volume control
    self.volumeLabel = [BlioReadingVoiceSettingsViewController labelWithFrame:CGRectZero title:NSLocalizedString(@"Volume",@"\"Volume\" audio setting label.")];
	[self.contentView addSubview:volumeLabel];

	self.volumeControl = [[[UISlider alloc] initWithFrame:CGRectZero] autorelease];
    volumeControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[volumeControl addTarget:self action:@selector(changeVolume:) forControlEvents:UIControlEventValueChanged];
	volumeControl.backgroundColor = [UIColor clearColor];
	volumeControl.minimumValue = 0.1; 
	volumeControl.maximumValue = 100.0;
	volumeControl.continuous = NO;
    [volumeControl setAccessibilityLabel:NSLocalizedString(@"Volume", @"Accessibility label for Audio settings volume slider")];

	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:50.0 forKey:kBlioLastVolumeDefaultsKey];
	volumeControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey];
	[self.contentView addSubview:volumeControl];
	
	// Play sample button.
	self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[playButton setTitle:NSLocalizedString(@"Play sample",@"\"Play sample\" button title in audio settings.") forState:UIControlStateNormal];
	playButton.backgroundColor = [UIColor clearColor];
	[playButton addTarget:self action:@selector(playSample:) forControlEvents:UIControlEventTouchUpInside];
	[self.contentView addSubview:playButton];
    
    [self layoutControlsForOrientation:self.interfaceOrientation];
}

- (void)layoutControlsForOrientation:(UIInterfaceOrientation)orientation {
    CGFloat topMargin = floorf(kTopMargin/2.0f);
    CGFloat tweenMargin = floorf(kTweenMargin/2.0f);;
    
	CGRect frame = CGRectZero;
    CGFloat yPlacement = topMargin;

	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width,
					   kLabelHeight);
    speedLabel.frame = frame;
    
    yPlacement += tweenMargin + kLabelHeight;
    frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSliderHeight);
    speedControl.frame = frame;
    
    yPlacement += (tweenMargin * 2.0) + kSliderHeight + kLabelHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width,
					   kLabelHeight);
    volumeLabel.frame = frame;
    
    yPlacement += tweenMargin + kLabelHeight;
    frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSliderHeight);
    volumeControl.frame = frame;
    
    yPlacement += (tweenMargin * 2.0) + kSliderHeight + kLabelHeight;
    frame = CGRectMake((self.view.bounds.size.width - kStdButtonWidth)/2, yPlacement, kStdButtonWidth, kStdButtonHeight);
    
    playButton.frame = frame;
	self.footerHeight = yPlacement + kStdButtonHeight;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView beginAnimations:@"rotation" context:nil];
    [UIView setAnimationDuration:duration];
    [self layoutControlsForOrientation:toInterfaceOrientation];
    [UIView commitAnimations];
}

- (void)loadView
{	
	[super loadView];
	// create a gradient-based content view	
	self.contentView = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[AcapelaSpeech refreshVoiceList];
	self.availableVoices = [AcapelaSpeech availableVoices];
	[self createControls];	
}

-(void)onVoiceListRefreshedNotification:(NSNotification*)note {
	NSLog(@"BlioAudioSettingsController onVoiceListRefreshedNotification entered");
	self.availableVoices = [AcapelaSpeech availableVoices];
	[self.tableView reloadData];
}


//- (void)changeVoice:(id)sender
//{
//	UISegmentedControl* ctl = (UISegmentedControl*)sender;
//	if ( ctl == voiceControl )
//		[[NSUserDefaults standardUserDefaults] setInteger:(AcapelaVoice)([sender selectedSegmentIndex]) forKey:kBlioLastVoiceDefaultsKey];
//}

- (void)changeSpeed:(id)sender
{
	UISlider* ctl = (UISlider*)sender;
	if ( ctl == speedControl )
		[[NSUserDefaults standardUserDefaults] setFloat:ctl.value forKey:kBlioLastSpeedDefaultsKey];
}

- (void)changeVolume:(id)sender
{
	UISlider* ctl = (UISlider*)sender;
	if ( ctl == volumeControl )
		[[NSUserDefaults standardUserDefaults] setFloat:ctl.value forKey:kBlioLastVolumeDefaultsKey];
}

- (void)playSample:(id)sender {	
	BlioAcapelaAudioManager * tts = [BlioAcapelaAudioManager sharedAcapelaAudioManager];
	if (tts != nil && [tts isSpeaking] )
		[tts stopSpeaking];
	tts.currentWordOffset = 0;
	UIButton* ctl = (UIButton*)sender;
	if ( ctl == playButton ) {
		[tts setEngineWithPreferences];
		NSString *samplePhrase = NSLocalizedStringWithDefaultValue(@"TTS_SAMPLE_PHRASE",nil,[NSBundle mainBundle],@"It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness.",@"Sample phrase spoken by TTS engine.");

		[tts startSpeaking:samplePhrase]; 
		
	}
}
- (NSString *)ttsBooksInLibraryDisclosure {
	return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"TTS_BOOKS_IN_LIBRARY_DISCLOSURE",nil,[NSBundle mainBundle],@"%i of %i books in your library may be read aloud by Text-To-Speech voices.",@"Message that discloses how many of the user's books can be read by TTS."),ttsBooks,totalBooks];
}

-(void)onInAppPurchaseRestoreTransactionsStarted:(NSNotification*)notification {
    [self.activityIndicatorView startAnimating];
}
-(void)onInAppPurchaseRestoreTransactionsFailed:(NSNotification*)notification {
    [self.activityIndicatorView stopAnimating];
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:self.availableVoices.count inSection:0] animated:NO];
}
-(void)onInAppPurchaseRestoreTransactionsFinished:(NSNotification*)notification {
    [self.activityIndicatorView stopAnimating];
    //		[self.navigationController pushViewController:[[[BlioDownloadVoicesViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease] animated:YES];
    [self.navigationController pushViewController:[[[BlioPurchaseVoicesViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease] animated:YES];
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.availableVoices && [self.availableVoices count] > 0) return 2;
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) return NSLocalizedString(@"Voices",@"\"Voices\" table header in Audio Settings View");
	return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		NSInteger voicesAvailableForDownloadStatus = 0;
		if ([[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForDownload]) voicesAvailableForDownloadStatus = 1;
		return [self.availableVoices count] + voicesAvailableForDownloadStatus;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *ListCellIdentifier = @"UITableViewCelldentifier";
	UITableViewCell *cell;
	
	cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
	}
	if (indexPath.row == self.availableVoices.count) {
		// special "More Voices" cell
		cell.textLabel.text = NSLocalizedString(@"Download Voices","\"Download Voices\" cell label");
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setAccessibilityTraits:UIAccessibilityTraitButton];
	}
	else {
		cell.textLabel.text = [self.availableVoices objectAtIndex:indexPath.row];
        NSLog(@"cell.textLabel.text: %@",cell.textLabel.text);
		NSString * voiceName = [BlioAcapelaAudioManager voiceNameForVoice:cell.textLabel.text];
		if (voiceName) cell.textLabel.text = voiceName;
		if ([[self.availableVoices objectAtIndex:indexPath.row] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:kBlioLastVoiceDefaultsKey]]) 
		{
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		}
		else [cell setAccessoryType:UITableViewCellAccessoryNone];
	}	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return [self ttsBooksInLibraryDisclosure];
}

#pragma mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.availableVoices.count) {
//        [[BlioInAppPurchaseManager sharedInAppPurchaseManager] restoreCompletedTransactions];
        [self.navigationController pushViewController:[[[BlioPurchaseVoicesViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease] animated:YES];
	}
	else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		for (UITableViewCell * cell in [tableView visibleCells]) {
			if (cell != [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow: self.availableVoices.count inSection:0]]) [cell setAccessoryType:UITableViewCellAccessoryNone];
		}
		BlioAcapelaAudioManager * tts = [BlioAcapelaAudioManager sharedAcapelaAudioManager];
		if (tts != nil && [tts isSpeaking] )
			[tts stopSpeaking];
		[[NSUserDefaults standardUserDefaults] setObject:[self.availableVoices objectAtIndex:indexPath.row] forKey:kBlioLastVoiceDefaultsKey];
		[[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == 1 && self.availableVoices && [self.availableVoices count] > 0) return self.contentView;
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 0) return ([[self ttsBooksInLibraryDisclosure] sizeWithFont:[UIFont boldSystemFontOfSize:13] constrainedToSize:CGSizeMake(self.view.bounds.size.width - kLeftMargin - kRightMargin, self.view.bounds.size.height) lineBreakMode:UILineBreakModeWordWrap]).height + 15;
	if (section == 1) return self.footerHeight + 10;
	return 0;
}

#pragma mark -
#pragma mark Fetched Results Controller Delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	NSLog(@"BlioAudioSettingsController controllerDidChangeContent entered");
	ttsBooks = [[ttsFetchedResultsController fetchedObjects] count];
	totalBooks = [[totalFetchedResultsController fetchedObjects] count];

	[self.tableView reloadData];	
}


@end