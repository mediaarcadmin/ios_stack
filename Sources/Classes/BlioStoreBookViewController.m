//
//  BlioStoreEntityController.m
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioStoreBookViewController.h"
#import "BlioProcessing.h"
#import <libEucalyptus/THUIImageAdditions.h>

#define AUTHORPADDINGABOVE 4
#define AUTHORPADDINGBELOW 9
NSString * const kBlioStoreDownloadButtonStateLabelInitial = @"Free";
NSString * const kBlioStoreDownloadButtonStateLabelConfirm = @"Download Now";
NSString * const kBlioStoreDownloadButtonStateLabelInProcess = @"Downloading";
NSString * const kBlioStoreDownloadButtonStateLabelDone = @"Installed";
NSString * const kBlioStoreDownloadButtonStateLabelNoDownload = @"No!";



@interface BlioStoreFetchThumbOperation : NSOperation {
    SEL action;
    id target;
    NSURL *thumbUrl;
}

- (id)initWithThumbUrl:(NSString *)url target:(id)target action:(SEL)action;

@end

@implementation BlioStoreBookViewController

@synthesize fetchThumbQueue, entity, scroller, container, bookThumb, bookTitle, bookShadow, bookPlaceholder, authors, download, summary, releaseDate, publicationDate, pages, publisher, releaseDateLabel, publicationDateLabel, pagesLabel, publisherLabel, belowSummaryDetails,downloadStateLabels,downloadButtonContainer,downloadButtonBackgroundView;
@synthesize processingDelegate;

- (void)dealloc {
    [self.fetchThumbQueue cancelAllOperations];
    self.fetchThumbQueue = nil;
    self.entity = nil;
    self.scroller = nil;
    self.container = nil;
    self.bookTitle = nil;
    self.bookShadow = nil;
    self.bookPlaceholder = nil;
    self.authors = nil;
    self.download = nil;
    self.summary = nil;
    self.belowSummaryDetails = nil;
    self.releaseDate = nil;
    self.publicationDate = nil;
    self.pages = nil;
    self.publisher = nil;
    self.processingDelegate = nil;
    [super dealloc];
}

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */


- (void)viewDidLoad {
    [super viewDidLoad];
    // check data to see if downloadState must be changed (TODO)
	downloadState = kBlioStoreDownloadButtonStateConfirm;

	self.downloadStateLabels = [NSArray arrayWithObjects:kBlioStoreDownloadButtonStateLabelInitial,kBlioStoreDownloadButtonStateLabelConfirm,kBlioStoreDownloadButtonStateLabelInProcess,kBlioStoreDownloadButtonStateLabelDone,kBlioStoreDownloadButtonStateLabelNoDownload,nil];


	NSMutableArray * validFieldViews = [NSMutableArray array];
    self.bookTitle.text = [self.entity title];
    if ([self.entity author]) {
        self.authors.text = [[NSString stringWithFormat:@"By %@", [self.entity author]] uppercaseString];
    } else if ([self.entity publisher]) {
        self.authors.text = [[NSString stringWithFormat:@"By %@", [self.entity publisher]] uppercaseString];      
    } else {
        self.authors.text = nil;
    }
    self.summary.text = [self.entity summary];
    [[self.bookPlaceholder layer] setBorderWidth:1.0f];
    [[self.bookPlaceholder layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    if (nil != [self.entity releasedDate]) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy"];
        NSString *dateString = [dateFormat stringFromDate:[self.entity releasedDate]];
        [dateFormat release];
        self.releaseDate.text = dateString;
		[validFieldViews addObject: self.releaseDate];
    }

    if (nil != [self.entity publishedDate]) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateStyle:NSDateFormatterLongStyle];
        NSString *dateString = [dateFormat stringFromDate:[self.entity publishedDate]];
        [dateFormat release];
        self.publicationDate.text = dateString;
		[validFieldViews addObject: self.publicationDate];
    }
    if (nil != [self.entity pageCount]) {
        self.pages.text = [self.entity pageCount];
		[validFieldViews addObject: self.pages];
    }
    if (nil != [self.entity publisher]) {
        self.publisher.text = [self.entity publisher];
		[validFieldViews addObject: self.publisher];
    }

	// LABEL/FIELD REPOSITIONING CODE
	// memorize position of first Label[container viewWithTag:1]
	CGFloat startingY = [container viewWithTag:1].frame.origin.y;
	NSArray * fieldViewLabels = [NSArray arrayWithObjects:[container viewWithTag:1],
								 [container viewWithTag:2],
								 [container viewWithTag:3],
								 [container viewWithTag:4],
								 nil];
	
    // hide non-valid/empty fields
	NSUInteger index = 0;
	for (UIView * fieldViewLabel in fieldViewLabels)
	{
		// is corresponding data view valid?
		UIView * fieldView = [container viewWithTag:-fieldViewLabel.tag]; // find corresponding view that has tag * (-1)
		if ([validFieldViews containsObject:fieldView]) {
			// we have a valid view
			fieldViewLabel.hidden = NO;
			fieldView.hidden = NO;
			// reposition both to appropriate Y
			CGFloat newY = startingY + (kBlioBookDetailFieldYMargin * index);
			fieldViewLabel.frame = CGRectMake(fieldViewLabel.frame.origin.x, newY, fieldViewLabel.frame.size.width, fieldViewLabel.frame.size.height);
			fieldView.frame = CGRectMake(fieldView.frame.origin.x, newY, fieldView.frame.size.width, fieldView.frame.size.height);
			index++;
		}
		else {
			// hide both label and field views
			fieldViewLabel.hidden = YES;
			fieldView.hidden = YES;
		}

	}
	// END LABEL/FIELD REPOSITIONING CODE

	
    // DOWNLOAD BUTTON SETUP
	self.downloadButtonBackgroundView.image = [[UIImage imageNamed:@"downloadButton.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0];
 //   [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButton.png"] forState:UIControlStateNormal];
 //   [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButtonPressed.png"] forState:UIControlStateHighlighted];
 //   [self.download setBackgroundColor:[UIColor greenColor]];
    self.download.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [self.download setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateNormal];
	self.download.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.downloadButtonBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.downloadButtonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
    if (![self.entity ePubUrl] && ![self.entity pdfUrl]) {
        [self setDownloadState:kBlioStoreDownloadButtonStateNoDownload animated:NO];

    }
    
    // Layout views
    CGRect bookTitleFrame = self.bookTitle.frame;
    CGRect authorsFrame = self.authors.frame;
    CGRect downloadFrame = self.downloadButtonContainer.frame;
    CGSize titleSize = [self.bookTitle.text sizeWithFont:self.bookTitle.font constrainedToSize:bookTitleFrame.size lineBreakMode:self.bookTitle.lineBreakMode];
    CGSize authorsSize = [self.authors.text sizeWithFont:self.authors.font constrainedToSize:authorsFrame.size lineBreakMode:self.authors.lineBreakMode];    
    bookTitleFrame.size = titleSize;
    authorsFrame.size = authorsSize;
    authorsFrame.origin.y = CGRectGetMaxY(bookTitleFrame) + AUTHORPADDINGABOVE;
    downloadFrame.origin.y = CGRectGetMaxY(authorsFrame) + AUTHORPADDINGBELOW;
    [self.bookTitle setFrame:bookTitleFrame];
    [self.authors setFrame:authorsFrame];
    [self.downloadButtonContainer setFrame:downloadFrame];
    
    CGRect containerFrame = self.container.frame;
    CGRect summaryFrame = self.summary.frame;
    summaryFrame.size.height = containerFrame.size.height;
    CGRect belowSummaryFrame = self.belowSummaryDetails.frame;
    CGSize summarySize = [self.summary.text sizeWithFont:self.summary.font constrainedToSize:summaryFrame.size lineBreakMode:UILineBreakModeWordWrap];
    summaryFrame.size = summarySize;
    belowSummaryFrame.origin.y = CGRectGetMaxY(summaryFrame);
    [self.summary setFrame:summaryFrame];
    [self.belowSummaryDetails setFrame:belowSummaryFrame];
    
    CGFloat newHeight = CGRectGetMaxY(belowSummaryFrame) > self.view.frame.size.height ? CGRectGetMaxY(belowSummaryFrame) : self.view.frame.size.height;
    containerFrame.size.height = newHeight;
    [self.container setFrame:containerFrame];
    [self.scroller setContentSize:containerFrame.size];
    
    // Fetch bookThumb
    if (nil != [self.entity thumbUrl]) {
        BlioStoreFetchThumbOperation *anOperation = [[BlioStoreFetchThumbOperation alloc] initWithThumbUrl:[self.entity thumbUrl] target:self action:@selector(updateThumb:)];
        NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
        [aQueue addOperation:anOperation];
        [anOperation release];
        self.fetchThumbQueue = aQueue;
        [aQueue release];
    }
	
}

- (void)updateThumb:(UIImage *)thumbImage {
    if (nil != self.bookThumb) {
        [self.bookThumb setImage:thumbImage];
        [self.bookThumb setAlpha:1.0f];
        [self.bookShadow setAlpha:1.0f];
    }
}

- (IBAction)downloadButtonPressed:(id)sender {
	NSLog(@"BlioStoreBookViewController downloadButtonPressed");
	NSLog(@"current downloadState: %i",downloadState);
	// assess and change button state
	if (downloadState == kBlioStoreDownloadButtonStateInitial) {
		[self setDownloadState:kBlioStoreDownloadButtonStateConfirm animated:YES];
	}
	else if (downloadState == kBlioStoreDownloadButtonStateConfirm) {
//		NSLog(@"button pressed while in Confirm state");
		// start processing download decision
		/*
		[self.processingDelegate enqueueBookWithTitle:self.entity.title 
											  authors:[NSArray arrayWithObject:self.entity.author]
											 coverURL:self.entity.coverUrl ? [NSURL URLWithString:self.entity.coverUrl] : nil
											  ePubURL:self.entity.ePubUrl ? [NSURL URLWithString:self.entity.ePubUrl] : nil 
											   pdfURL:self.entity.pdfUrl ? [NSURL URLWithString:self.entity.pdfUrl] : nil
										  textFlowURL:nil
										 audiobookURL:nil];
		*/
		// register as listener, possibly set graphic state to kBlioStoreDownloadButtonStateInProcess
		[self setDownloadState:kBlioStoreDownloadButtonStateInProcess animated:YES];
	}
	else if (downloadState == kBlioStoreDownloadButtonStateInProcess) {
		// do nothing
		[self setDownloadState:kBlioStoreDownloadButtonStateDone animated:YES];

	}
	else if (downloadState == kBlioStoreDownloadButtonStateDone) {
		// do nothing
		[self setDownloadState:kBlioStoreDownloadButtonStateInitial animated:YES];
		
	}
	else NSLog(@"WARNING: downloadButtonState set to unknown value!");
}
			 
- (void) setDownloadState:(NSUInteger)state animated:(BOOL)animationStatus {
//	NSLog(@"BlioStoreBookViewController setDownloadState:%i entered",state);

	if (downloadState != state) {
		downloadState = state;
		NSString * newLabelText = [downloadStateLabels objectAtIndex:downloadState];
		UIButton * button = self.download;
		button.contentMode = UIViewContentModeRedraw;
		// calculate width delta from old label to new
		CGSize oldLabelSize = [button.titleLabel.text sizeWithFont:button.titleLabel.font];		
		CGSize newLabelSize = [newLabelText sizeWithFont:button.titleLabel.font];
		CGFloat widthDelta = newLabelSize.width - oldLabelSize.width;

		// translate that delta to change in bounds
		CGRect oldButtonBounds = downloadButtonContainer.bounds;
		CGRect newButtonBounds = CGRectMake(oldButtonBounds.origin.x, oldButtonBounds.origin.y,oldButtonBounds.size.width + widthDelta, 24);
		CGPoint newCenter = CGPointMake(downloadButtonContainer.center.x + (widthDelta/2), downloadButtonContainer.center.y);
//		CGPoint newCenterSubviews = CGPointMake(button.center.x + (widthDelta/2), button.center.y);
/*
				NSLog(@"current label text: %@", button.titleLabel.text);
				NSLog(@"oldLabelSize width:%f height:%f",oldLabelSize.width,oldLabelSize.height);
				NSLog(@"new label text: %@", newLabelText);
				NSLog(@"newLabelSize width:%f height:%f",newLabelSize.width,newLabelSize.height);
				NSLog(@"widthDelta: %f",widthDelta);
			NSLog(@"oldButtonBounds x:%f y:%f width:%f height:%f",oldButtonBounds.origin.x,oldButtonBounds.origin.y,oldButtonBounds.size.width,oldButtonBounds.size.height);
			NSLog(@"newButtonBounds x:%f y:%f width:%f height:%f",newButtonBounds.origin.x,newButtonBounds.origin.y,newButtonBounds.size.width,newButtonBounds.size.height);
*/
		if (state == kBlioStoreDownloadButtonStateInProcess || state == kBlioStoreDownloadButtonStateDone || state == kBlioStoreDownloadButtonStateNoDownload) { // special cases - disable button
			[self.download setEnabled:NO];
			downloadButtonContainer.alpha = .5;
			[self.download setTitle:newLabelText forState:UIControlStateDisabled];
		}
		if (!animationStatus)
		{
			downloadButtonContainer.bounds = newButtonBounds;
			downloadButtonContainer.center = newCenter;
		}
		else {
			// clear label string temporarily during morph
			[self.download setTitle:@"" forState:UIControlStateNormal];
			[self.download setTitle:@"" forState:UIControlStateHighlighted];
			[self.download setTitle:@"" forState:UIControlStateSelected];
			[self.download setTitle:@"" forState:UIControlStateDisabled];
			
			// animation block
			[UIView beginAnimations:@"buttonMorph" context:nil];
			[UIView setAnimationDelegate:self];
			downloadButtonContainer.bounds = newButtonBounds;
			downloadButtonContainer.center = newCenter;
			[UIView setAnimationDidStopSelector:@selector(downloadButtonAnimationFinished:finished:context:)];
			[UIView commitAnimations];
		}
	}
	
}
- (void)downloadButtonAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
//	NSLog(@"BlioStoreBookViewController downloadButtonAnimationFinished:%@ finished:%i context:%@",animationID,finished,context);
	// REVEAL label string
	[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateNormal]; // now set the button to a string that reflects its state
	[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateHighlighted]; // now set the button to a string that reflects its state
	[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateSelected]; // now set the button to a string that reflects its state
	[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateDisabled]; // now set the button to a string that reflects its state
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end

@implementation BlioStoreFetchThumbOperation

- (id)initWithThumbUrl:(NSString *)url target:(id)aTarget action:(SEL)aAction {
    if(url == nil) return nil;
    
    if((self = [super init])) {
        action = aAction;
        target = aTarget;
        thumbUrl = [[NSURL alloc] initWithString:url];
    }
    
    return self;
}

- (void)main {
    if ([self isCancelled]) return;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    NSData *imgData = [[NSData alloc] initWithContentsOfURL:thumbUrl];
    
    if ([self isCancelled]) { 
        [imgData release]; 
        [pool drain];
        return;
    }
    
    UIImage *image = [[UIImage alloc] initWithData:imgData];
    
    if ([self isCancelled]) { 
        [imgData release]; 
        [image release];
        [pool drain];
        return;
    }
    
    if([target respondsToSelector:action])
        [target performSelectorOnMainThread:action withObject:image waitUntilDone:NO];
    
    [imgData release];
    [image release];
    [pool drain];
}

- (void)dealloc {
    [thumbUrl release];
    [super dealloc];
}

@end

