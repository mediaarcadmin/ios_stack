//
//  BlioStoreEntityController.m
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioStoreBookViewController.h"
#import "BlioProcessingStandardOperations.h"
#import <libEucalyptus/THUIImageAdditions.h>
#import "BlioBook.h"

#define AUTHORPADDINGABOVE 4
#define AUTHORPADDINGBELOW 9
NSString * const kBlioStoreDownloadButtonStateLabelInitial = @"Free";
NSString * const kBlioStoreDownloadButtonStateLabelConfirm = @"Download Now";
NSString * const kBlioStoreDownloadButtonStateLabelInProcess = @"Downloading";
NSString * const kBlioStoreDownloadButtonStateLabelDone = @"Installed";
NSString * const kBlioStoreDownloadButtonStateLabelNoDownload = @"Not Available";



@interface BlioStoreFetchThumbOperation : NSOperation {
    SEL action;
    id target;
    NSURL *thumbUrl;
}

- (id)initWithThumbUrl:(NSString *)url target:(id)target action:(SEL)action;

@end

@interface BlioStoreBookViewController (PRIVATE)
- (void)_getBook;
- (void)layoutViews;
-(void)displayBookView;
@end

@implementation BlioStoreBookViewController

@synthesize fetchThumbQueue, feed, scroller, container, bookThumb, bookTitle, bookShadow, bookPlaceholder, authors, download, summary, releaseDate, publicationDate,
pages, publisher, releaseDateLabel, publicationDateLabel, pagesLabel, publisherLabel, belowSummaryDetails,downloadStateLabels,downloadButtonContainer,downloadButtonBackgroundView,noBookSelectedView;
@synthesize processingDelegate;
@synthesize managedObjectContext;


- (void)dealloc {
    [self.fetchThumbQueue cancelAllOperations];
    self.fetchThumbQueue = nil;
	self.feed = nil;
    if (entity) [entity release];
    self.scroller = nil;
    self.container = nil;
	self.bookThumb = nil;
    self.bookTitle = nil;
    self.bookShadow = nil;
    self.bookPlaceholder = nil;
    self.authors = nil;
    self.download = nil;
    self.summary = nil;
    self.releaseDate = nil;
    self.publicationDate = nil;
    self.pages = nil;
    self.publisher = nil;
	self.releaseDateLabel = nil;
	self.publicationDateLabel = nil;
	self.pagesLabel = nil;
	self.publisherLabel = nil;
    self.belowSummaryDetails = nil;
	self.downloadStateLabels = nil;
	self.downloadButtonContainer = nil;
	self.downloadButtonBackgroundView = nil;
    self.processingDelegate = nil;
	self.managedObjectContext = nil;
	self.noBookSelectedView = nil;
    [super dealloc];
}


 - (id)initWithStyle {
 if ((self = [super init])) {
	 self.downloadStateLabels = [NSArray arrayWithObjects:kBlioStoreDownloadButtonStateLabelInitial,kBlioStoreDownloadButtonStateLabelConfirm,kBlioStoreDownloadButtonStateLabelInProcess,kBlioStoreDownloadButtonStateLabelDone,kBlioStoreDownloadButtonStateLabelNoDownload,nil];
	 self.entity = nil;
 }
 return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	self.noBookSelectedView.text = NSLocalizedString(@"No Book Selected", @"Label shown to user when Book Store View has no book entity set.");
}
- (void)viewWillAppear:(BOOL)animated {
	if (self.entity) {
		self.noBookSelectedView.hidden = YES;
		[self displayBookView];
	}
	else {
		self.noBookSelectedView.hidden = NO;
	}
}
-(void)setEntity:(BlioStoreParsedEntity *)aEntity {
	if (entity) {
		[entity release];
		entity = nil;
	}
	entity = [aEntity retain];
	self.noBookSelectedView.hidden = YES;
	[self displayBookView];
}
-(BlioStoreParsedEntity *)entity {
	return entity;
}
-(void)displayBookView {
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
    
    [self layoutViews];
	
    // DOWNLOAD BUTTON SETUP
	self.downloadButtonBackgroundView.image = [[UIImage imageNamed:@"downloadButton.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0];
 //   [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButton.png"] forState:UIControlStateNormal];
 //   [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButtonPressed.png"] forState:UIControlStateHighlighted];
 //   [self.download setBackgroundColor:[UIColor greenColor]];
    self.download.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [self.download setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateNormal];
	
	NSLog(@"[self.entity thumbUrl]: %@",[self.entity thumbUrl]);
        
    // Fetch bookThumb
    if (nil != [self.entity thumbUrl]) {
        BlioStoreFetchThumbOperation *anOperation = [[BlioStoreFetchThumbOperation alloc] initWithThumbUrl:[self.entity thumbUrl] target:self action:@selector(updateThumb:)];
        NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
        [aQueue addOperation:anOperation];
        [anOperation release];
        self.fetchThumbQueue = aQueue;
        [aQueue release];
    }
	
	// check data to see if downloadState must be changed:
	// access processing manager to see if the corresponding BlioBook is already in library
	
	BlioBook * resultBook = [self.processingDelegate bookWithSourceID:self.feed.sourceID sourceSpecificID:[self.entity id]];

	if (resultBook != nil) {
		// then update button options accordingly to prevent possible duplication of entries.
		NSLog(@"Found Book in context already"); 
		if ([[resultBook valueForKey:@"processingState"] isEqualToNumber: [NSNumber numberWithInt:kBlioBookProcessingStateComplete]]) {
			NSLog(@"and processingState is kBlioBookProcessingStateComplete."); 
			
			[self setDownloadState:kBlioStoreDownloadButtonStateDone animated:NO];
		}
		else
		{
			// Book is in context/state, but not complete.
			// Check operation queue to see if completeOperation for id is present
			BlioProcessingCompleteOperation * completeOperation = [self.processingDelegate processingCompleteOperationForSourceID:self.feed.sourceID sourceSpecificID:self.entity.id];
			if (completeOperation == nil) {
				// for now, treat as incomplete - redownload completely. TODO: processing manager should scan for pre-existing entity in context and append to it instead of creating new one.
				NSLog(@"but not processingState and could not find completeOperation."); 
				[self setDownloadState:kBlioStoreDownloadButtonStateConfirm animated:NO];
			}
			else {
				NSLog(@"but not processingState. However, completeOperation is present and will become listener."); 
				[self setDownloadState:kBlioStoreDownloadButtonStateInProcess animated:NO];
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBlioProcessingOperationCompleteNotification) name:BlioProcessingOperationCompleteNotification object:completeOperation];
			}
		}
	}
	else {
		NSLog(@"book is not already present in the library."); 
		if (![self.entity ePubUrl] && ![self.entity pdfUrl]) {
			[self setDownloadState:kBlioStoreDownloadButtonStateNoDownload animated:NO];
			
		} else [self setDownloadState:kBlioStoreDownloadButtonStateConfirm animated:NO]; // make initial state match the XIB file text
	}	
}

- (void)layoutViews {    
    // Layout views
    CGRect containerFrame = self.container.frame;
    CGRect bookTitleFrame = self.bookTitle.frame;
    bookTitleFrame.size.height = 47;
    bookTitleFrame.size.width = CGRectGetWidth(containerFrame) - 20 - CGRectGetMinX(bookTitleFrame);
    CGRect authorsFrame = self.authors.frame;
    authorsFrame.size.height = 68;
    authorsFrame.size.width = bookTitleFrame.size.width;
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
    
    CGRect summaryFrame = self.summary.frame;
    summaryFrame.size.height = 200;
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
    
}

- (void)didReceiveBlioProcessingOperationCompleteNotification {
	// NSLog(@"BlioStoreBookViewController didReceiveBlioProcessingCompleteOperationFinishedNotification entered");
	[self setDownloadState:kBlioStoreDownloadButtonStateDone animated:YES];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:self];
	[self _getBook];
}

- (void)updateThumb:(UIImage *)thumbImage {
    if (nil != self.bookThumb) {
        [self.bookThumb setImage:thumbImage];
        [self.bookThumb setAlpha:1.0f];
        [self.bookShadow setAlpha:1.0f];
    }
}

- (IBAction)downloadButtonPressed:(id)sender {
//	NSLog(@"BlioStoreBookViewController downloadButtonPressed");
//	NSLog(@"current downloadState: %i",downloadState);
	// assess and change button state
	if (downloadState == kBlioStoreDownloadButtonStateInitial) {
		[self setDownloadState:kBlioStoreDownloadButtonStateConfirm animated:YES];
	}
	else if (downloadState == kBlioStoreDownloadButtonStateConfirm) {
//		NSLog(@"button pressed while in Confirm state");
		// start processing download decision
				
		[self.processingDelegate enqueueBookWithTitle:self.entity.title 
											  authors:[NSArray arrayWithObject:self.entity.author]
											 coverURL:self.entity.coverUrl ? [NSURL URLWithString:self.entity.coverUrl] : nil
											  ePubURL:self.entity.ePubUrl ? [NSURL URLWithString:self.entity.ePubUrl] : nil 
											   pdfURL:self.entity.pdfUrl ? [NSURL URLWithString:self.entity.pdfUrl] : nil
                                               xpsURL:nil
                                          textFlowURL:nil
										 audiobookURL:nil
											 sourceID:self.feed.sourceID
									 sourceSpecificID:self.entity.id
		 ];
		
		// register as listener

		BlioProcessingCompleteOperation * completeOperation = [self.processingDelegate processingCompleteOperationForSourceID:self.feed.sourceID sourceSpecificID:self.entity.id];
		if (completeOperation == nil) {
			NSLog(@"WARNING: cannot find completeOperation for recently enqueued book sourceID:%i sourceSpecificID:%@",self.feed.id,self.entity.id);
		}
		else {
//			NSLog(@"completeOperation found, BlioStoreBookViewController becoming listener...");
			[self setDownloadState:kBlioStoreDownloadButtonStateInProcess animated:YES];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBlioProcessingOperationCompleteNotification) name:BlioProcessingOperationCompleteNotification object:completeOperation];
		}
	}
	else if (downloadState == kBlioStoreDownloadButtonStateInProcess) {
		// do nothing
		[self setDownloadState:kBlioStoreDownloadButtonStateDone animated:YES];

	}
	else if (downloadState == kBlioStoreDownloadButtonStateDone) {
		// do nothing
		[self setDownloadState:kBlioStoreDownloadButtonStateInitial animated:YES];
		
	}
	else NSLog(@"WARNING: downloadButtonState set to invalid value!");
}
			 
- (void) setDownloadState:(NSUInteger)state animated:(BOOL)animationStatus {
	// NSLog(@"BlioStoreBookViewController setDownloadState:%i entered",state);

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
			downloadButtonContainer.alpha = kBlioStoreDisabledButtonAlpha;
		}
		else {
			[self.download setEnabled:YES];
			downloadButtonContainer.alpha = 1;
		}
		if (!animationStatus)
		{
			downloadButtonContainer.bounds = newButtonBounds;
			downloadButtonContainer.center = newCenter;
			[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateNormal]; // now set the button to a string that reflects its state
			[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateHighlighted]; // now set the button to a string that reflects its state
			[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateSelected]; // now set the button to a string that reflects its state
			[self.download setTitle:[downloadStateLabels objectAtIndex:downloadState] forState:UIControlStateDisabled]; // now set the button to a string that reflects its state
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

- (void)_getBook
{
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//	UIGraphicsBeginImageContext(bookThumb.bounds.size);
//	[bookThumb.layer renderInContext:UIGraphicsGetCurrentContext()];
//	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIImage *viewImage = bookThumb.image;
//	UIGraphicsEndImageContext();
	
  //  CGSize viewImageSize = viewImage.size;
	
    _jumpingView = [[UIImageView alloc] initWithImage:viewImage];
    CGPoint anchorPoint = CGPointMake(0.5f,0.5f);
    _jumpingView.layer.anchorPoint = anchorPoint;
    _jumpingView.layer.position =bookThumb.layer.position;
    [self.view addSubview:_jumpingView];
    
    CGFloat animationDuration = 0.1f;
	
    CAKeyframeAnimation *transformAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];    
    transformAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)], 
								 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1f, 0.9f, 1.0f)],
								 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)],
								 nil];
    transformAnimation.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f], 
                                   [NSNumber numberWithFloat:0.65f],
                                   [NSNumber numberWithFloat:1.0f],
                                   nil];    
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transformAnimation.duration = animationDuration;
    transformAnimation.delegate = self;
    [transformAnimation setValue:@"GetBookPart1" forKey:@"THName"];
    [_jumpingView.layer addAnimation:transformAnimation forKey:@"GetBookPart1"];
}

- (void)_getBookPart1AnimationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    CGFloat animationDuration = 2.0f / 3.0f;
    
    UIView *window = self.view.window;
    CGPoint bookCenter = _jumpingView.layer.position;
    bookCenter.y -= _jumpingView.bounds.size.height / 2.0f;
    
    _jumpingView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    bookCenter = [self.view convertPoint:bookCenter toView:window];
    
	
    [_jumpingView removeFromSuperview];
    _jumpingView.layer.zPosition = 0;
    [window addSubview:_jumpingView];
    _jumpingView.layer.position = bookCenter;
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];    
    
    CGMutablePathRef thePath = CGPathCreateMutable();
    CGPathMoveToPoint(thePath,NULL,bookCenter.x,bookCenter.y);
    CGPoint endCenter = [self.downloadButtonContainer convertPoint:download.center toView:window];
    CGFloat curveTop = bookCenter.y - 104.0f;
    CGPathAddCurveToPoint(thePath,NULL,bookCenter.x,curveTop,
                          endCenter.x,curveTop,
                          endCenter.x,endCenter.y);
    positionAnimation.path=thePath;
	CGPathRelease(thePath);

    positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    positionAnimation.duration = animationDuration;
    positionAnimation.delegate = self;
    [positionAnimation setValue:@"GetBookPart2" forKey:@"THName"];
    [_jumpingView.layer addAnimation:positionAnimation forKey:@"GetBookPart2"];
    
    
    CAKeyframeAnimation *transformAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CGFloat scale = 30 / _jumpingView.bounds.size.width;
    transformAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)], 
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.00f, 1.00f, 1.0f)],
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05f, 1.05f, 1.0f)],
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale, scale, 1.0f)],
                                 nil];
    transformAnimation.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f], 
                                   [NSNumber numberWithFloat:0.25f],
                                   [NSNumber numberWithFloat:0.5f],
                                   [NSNumber numberWithFloat:1.0f],
                                   nil];
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transformAnimation.duration = animationDuration;
    [_jumpingView.layer addAnimation:transformAnimation forKey:@"GetBookPart2Transform"];
	
    _jumpingView.layer.transform = [transformAnimation.values.lastObject CATransform3DValue];
    _jumpingView.layer.position = endCenter;
}

- (void)_getBookPart2AnimationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    [_jumpingView removeFromSuperview];
    [_jumpingView release];
    _jumpingView = nil;
    
//    [[BookObtentionController sharedBookObtentionController] obtainBookWithEtextNumber:[((EucBookReference *)[_bookReferences objectAtIndex:_indexOfPickToGet]).etextNumber integerValue]];
//   _indexOfPickToGet = -1;
    
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//    if([_delegate respondsToSelector:@selector(picksViewDidEndModal:)]) {
//        [_delegate picksViewDidEndModal:self];
//    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished;
{
    NSString *name = [anim valueForKey:@"THName"];
    
    NSMutableString *selectorName = [NSMutableString stringWithCapacity:name.length + 28];
    [selectorName appendString:@"_"];
    [selectorName appendString:name];
    [selectorName appendString:@"AnimationDidStop:finished:"];
    unichar lowercaseFirstCharacter = tolower([name characterAtIndex:0]);
    [selectorName replaceCharactersInRange:NSMakeRange(1, 1) withString:[NSString stringWithCharacters:&lowercaseFirstCharacter length:1]];
	
    SEL selector = NSSelectorFromString(selectorName);
    if(![self respondsToSelector:selector]) {
        selector = NSSelectorFromString([selectorName substringFromIndex:1]);
        if(![self respondsToSelector:selector]) {
            selector = NULL;
        }
    }
    if(selector) {
        objc_msgSend(self, selector, anim, finished);
    } else {
        NSLog(@"Animation \"%@\" ended with no callback defined", name);
    }
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self layoutViews];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [thumbUrl release];
    [super dealloc];
}

@end

