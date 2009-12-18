//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioLayoutView.h"

@interface BlioPDFDrawingView : UIView {
  CGPDFPageRef page;
  id layoutView;
}

@property (nonatomic, assign) id layoutView;

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage;

@end

@interface BlioLayoutView(private)

- (void)loadPage:(int)pageIndex;

@end


@implementation BlioLayoutView

@synthesize scrollView, viewControllers, navigationController;

- (void)dealloc {
  CGPDFDocumentRelease(pdf);
  self.scrollView = nil;
  self.viewControllers = nil;
  self.navigationController = nil;
  [super dealloc];
}

- (id)initWithPath:(NSString *)path {
  NSURL *pdfURL = [NSURL fileURLWithPath:path];
  pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
  if (NULL == pdf) return nil;
  
    if ((self = [super initWithFrame:CGRectMake(0,0,320,480)])) {
      // Initialization code
      NSInteger pageCount = CGPDFDocumentGetNumberOfPages(pdf);
      
      UIScrollView *aScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
      aScrollView.contentSize = CGSizeMake(self.bounds.size.width * pageCount, self.bounds.size.height);
      aScrollView.backgroundColor = [UIColor grayColor];
      aScrollView.pagingEnabled = YES;
      aScrollView.showsHorizontalScrollIndicator = NO;
      aScrollView.showsVerticalScrollIndicator = NO;
      aScrollView.scrollsToTop = NO;
      aScrollView.delegate = self;
      [self addSubview:aScrollView];
      self.scrollView = aScrollView;
      [aScrollView release];
      
      // This pattern of an array of lazily loaded view controllers doesn't seem to have much benefit 
      // over a simple view array. However since this will need to be replaced with a more
      // memory efficient implementation anyway we will just leave it as is for now
      NSMutableArray *controllers = [[NSMutableArray alloc] init];
      for (unsigned i = 0; i < pageCount; i++) {
        [controllers addObject:[NSNull null]];
      }
      self.viewControllers = controllers;
      [controllers release];
      
      [self loadPage:0];
      [self loadPage:1];

    }
    return self;
}


- (void)loadPage:(int)pageIndex {
  if (pageIndex < 0) return;
  if (pageIndex >= CGPDFDocumentGetNumberOfPages (pdf)) return;
	
  // replace the placeholder if necessary
  UIViewController *controller = [self.viewControllers objectAtIndex:pageIndex];
  if ((NSNull *)controller == [NSNull null]) {
    
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, pageIndex + 1);
    BlioPDFDrawingView *pdfView = [[BlioPDFDrawingView alloc] initWithFrame:CGRectZero andPageRef:pdfPageRef];
    [pdfView setLayoutView:self];
    
    controller = [[UIViewController alloc] init];
    [controller setView:pdfView];
    [pdfView release];
    
    [viewControllers replaceObjectAtIndex:pageIndex withObject:controller];
    [controller release];
  }
  
  // add the controller's view to the scroll view
  if (nil == controller.view.superview) {
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    controller.view.frame = frame;
    [self.scrollView addSubview:controller.view];
  }
}

#pragma mark -
#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
  // Switch the indicator when more than 50% of the previous/next page is visible
  CGFloat pageWidth = self.scrollView.frame.size.width;
  int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	
  // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
  [self loadPage:currentPage - 1];
  [self loadPage:currentPage];
  [self loadPage:currentPage + 1];
}

@end

@implementation BlioPDFDrawingView

@synthesize layoutView;

- (void)dealloc {
  CGPDFPageRelease(page);
  self.layoutView = nil;
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage {
	self = [super initWithFrame:frame];
	if(self != nil) {
    page = newPage;
    CGPDFPageRetain(page);
    self.backgroundColor = [UIColor clearColor];    
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect inRect = UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(0, 16, 0, 16));
  
  CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 16, [UIColor blackColor].CGColor);
  CGContextBeginTransparencyLayer(context, NULL);

	CGContextTranslateCTM(context, 0.0, inRect.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextSaveGState(context);
	// CGPDFPageGetDrawingTransform provides an easy way to get the transform for a PDF page. It will scale down to fit, including any
	// base rotations necessary to display the PDF page correctly. 
  CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, inRect, 0, true);
	CGContextConcatCTM(context, fitTransform);
  
  CGRect cropRect = CGPDFPageGetBoxRect (page, kCGPDFCropBox);
  CGContextClipToRect(context, cropRect);
  
  CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
  CGContextFillRect(context, cropRect);
  
	CGContextDrawPDFPage(context, page);
	CGContextRestoreGState(context);
  
  CGContextEndTransparencyLayer(context);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.layoutView touchesBegan:touches withEvent:event];
}

@end
