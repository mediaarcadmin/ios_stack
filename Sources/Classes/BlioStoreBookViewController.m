//
//  BlioStoreEntityController.m
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioStoreBookViewController.h"
#import <libEucalyptus/THUIImageAdditions.h>
#import "BlioProcessingManager.h"

#define AUTHORPADDINGABOVE 4
#define AUTHORPADDINGBELOW 9

@interface BlioStoreFetchThumbOperation : NSOperation {
    SEL action;
    id target;
    NSURL *thumbUrl;
}

- (id)initWithThumbUrl:(NSString *)url target:(id)target action:(SEL)action;

@end

@implementation BlioStoreBookViewController

@synthesize fetchThumbQueue, entity, scroller, container, bookThumb, bookTitle, bookShadow, bookPlaceholder, authors, download, summary, releaseDate, publicationDate, pages, publisher, belowSummaryDetails;
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
    }
    if (nil != [self.entity publishedDate]) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateStyle:NSDateFormatterLongStyle];
        NSString *dateString = [dateFormat stringFromDate:[self.entity publishedDate]];
        [dateFormat release];
        self.publicationDate.text = dateString;
    }
    if (nil != [self.entity pageCount]) {
        self.pages.text = [self.entity pageCount];
    }
    if (nil != [self.entity publisher]) {
        self.publisher.text = [self.entity publisher];
    }
    
    // Set buttonImages
    [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButton.png"] forState:UIControlStateNormal];
    [self.download setBackgroundImage:[UIImage midpointStretchableImageNamed:@"downloadButtonPressed.png"] forState:UIControlStateHighlighted];
    [self.download setBackgroundColor:[UIColor clearColor]];
    self.download.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [self.download setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.50] forState:UIControlStateNormal];
    if (![self.entity ePubUrl] && ![self.entity pdfUrl]) {
        [self.download setEnabled:NO];
        [self.download setTitle:@"No Download" forState:UIControlStateDisabled];
    }
    
    // Layout views
    CGRect bookTitleFrame = self.bookTitle.frame;
    CGRect authorsFrame = self.authors.frame;
    CGRect downloadFrame = self.download.frame;
    CGSize titleSize = [self.bookTitle.text sizeWithFont:self.bookTitle.font constrainedToSize:bookTitleFrame.size lineBreakMode:self.bookTitle.lineBreakMode];
    CGSize authorsSize = [self.authors.text sizeWithFont:self.authors.font constrainedToSize:authorsFrame.size lineBreakMode:self.authors.lineBreakMode];    
    bookTitleFrame.size = titleSize;
    authorsFrame.size = authorsSize;
    authorsFrame.origin.y = CGRectGetMaxY(bookTitleFrame) + AUTHORPADDINGABOVE;
    downloadFrame.origin.y = CGRectGetMaxY(authorsFrame) + AUTHORPADDINGBELOW;
    [self.bookTitle setFrame:bookTitleFrame];
    [self.authors setFrame:authorsFrame];
    [self.download setFrame:downloadFrame];
    
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
    [self.processingDelegate enqueueBookWithTitle:self.entity.title 
                                          authors:[NSArray arrayWithObject:self.entity.author]
                                         coverURL:self.entity.coverUrl ? [NSURL URLWithString:self.entity.coverUrl] : nil
                                          ePubURL:self.entity.ePubUrl ? [NSURL URLWithString:self.entity.ePubUrl] : nil 
                                           pdfURL:self.entity.pdfUrl ? [NSURL URLWithString:self.entity.pdfUrl] : nil];
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

