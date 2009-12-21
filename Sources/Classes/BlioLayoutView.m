//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"

static const CGFloat kBlioMaxZoom = 54.0f; // That's just showing off!

@interface BlioPDFTiledLayerDelegate : NSObject {
  CGPDFPageRef page;
}

@property(nonatomic) CGPDFPageRef page;

@end

@interface BlioPDFBackgroundLayerDelegate : NSObject {
  CGPDFPageRef page;
}

@property(nonatomic) CGPDFPageRef page;

@end

@interface BlioPDFDrawingView : UIView {
  CGPDFPageRef page;
  id layoutView;
  CATiledLayer *tiledLayer;
  CALayer *backgroundLayer;
  BlioPDFTiledLayerDelegate *tiledLayerDelegate;
  BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
  CGFloat currentZoom;
  CGPoint currentOffset;
  CGFloat zoomToFit;
  BOOL moving;
  BOOL pinchZoom;
  CGPoint previousPoint;
  CGFloat previousDistance;
}

@property (nonatomic, assign) id layoutView;
@property (nonatomic, retain) BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
@property (nonatomic, retain) BlioPDFTiledLayerDelegate *tiledLayerDelegate;

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage;

@end

@interface BlioLayoutView(private)
  NSInteger visiblePage;

- (void)loadPage:(int)pageIndex;

@end


@implementation BlioLayoutView

@synthesize scrollView, pageViews, navigationController;

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  CGPDFDocumentRelease(pdf);
  self.scrollView = nil;
  self.pageViews = nil;
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
      aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width * pageCount, aScrollView.frame.size.height);
      aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
      aScrollView.pagingEnabled = YES;
      aScrollView.showsHorizontalScrollIndicator = NO;
      aScrollView.showsVerticalScrollIndicator = NO;
      aScrollView.scrollsToTop = NO;
      aScrollView.delegate = self;
      [self addSubview:aScrollView];
      self.scrollView = aScrollView;
      [aScrollView release];
      
      // This pattern of an array of lazily loaded views will need to be replaced with a more
      // memory efficient implementation - if ou scrolled to the end of the book you would run out of memory
      
      NSMutableArray *pageViewArray = [[NSMutableArray alloc] init];
      for (unsigned i = 0; i < pageCount; i++) {
        [pageViewArray addObject:[NSNull null]];
      }
      self.pageViews = pageViewArray;
      [pageViewArray release];
      
      visiblePage = 0;
      [self loadPage:0];
      [self loadPage:1];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomInProgress:) name:@"BlioLayoutZoomInProgress" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomEnded:) name:@"BlioLayoutZoomEnded" object:nil];

    }
    return self;
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)layoutZoomInProgress:(NSNotification *)notification {
  [self.scrollView setScrollEnabled:NO];
}

- (void)layoutZoomEnded:(NSNotification *)notification {
  [self.scrollView setScrollEnabled:YES];
}


- (void)loadPage:(int)pageIndex {
  if (pageIndex < 0) return;
  if (pageIndex >= CGPDFDocumentGetNumberOfPages (pdf)) return;
	
  // replace the placeholder if necessary
  BlioPDFDrawingView *pageView = [self.pageViews objectAtIndex:pageIndex];
  
  if ((NSNull *)pageView == [NSNull null]) {
    
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, pageIndex + 1);
    pageView = [[BlioPDFDrawingView alloc] initWithFrame:self.scrollView.frame andPageRef:pdfPageRef];
    [self.pageViews replaceObjectAtIndex:pageIndex withObject:pageView];
    [pageView release];
  }
  
  // add the controller's view to the scroll view
  if (nil == pageView.superview) {
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    pageView.frame = frame;
    [self.scrollView addSubview:pageView];
  }
}

#pragma mark -
#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
  // Switch the indicator when more than 50% of the previous/next page is visible
  CGFloat pageWidth = self.scrollView.frame.size.width;
  int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	
  if (currentPage != visiblePage) {
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadPage:currentPage - 1];
    [self loadPage:currentPage];
    [self loadPage:currentPage + 1];
    visiblePage = currentPage;
  }
}

@end

@implementation BlioPDFDrawingView

@synthesize layoutView, tiledLayerDelegate, backgroundLayerDelegate;

- (void)dealloc {
  CGPDFPageRelease(page);
  self.layoutView = nil;
  [tiledLayer setDelegate:nil];
  [backgroundLayer setDelegate:nil];
  self.tiledLayerDelegate = nil;
  self.backgroundLayerDelegate = nil;
	[super dealloc];
}

- (void)configureTiledLayer {
  currentZoom = 1.0f;
  tiledLayer = [CATiledLayer layer];
  BlioPDFTiledLayerDelegate *aDelegate = [[BlioPDFTiledLayerDelegate alloc] init];
  [aDelegate setPage:page];
  tiledLayer.delegate = aDelegate;
  self.tiledLayerDelegate = aDelegate;
  [aDelegate release];
  
  CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
  CGFloat inset = -16;
  int w = pageRect.size.width;
  int h = pageRect.size.height;
  
  int levels = 1;
  while (w > 1 && h > 1) {
    levels++;
    w = w >> 1;
    h = h >> 1;
  }
  
  tiledLayer.levelsOfDetail = levels + 2;
  tiledLayer.levelsOfDetailBias = levels;
  tiledLayer.bounds = pageRect;
  
  CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
  CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
  currentZoom = fitTransform.a;
  zoomToFit = currentZoom;
  tiledLayer.position = CGPointMake(self.layer.bounds.size.width/2.0f, self.layer.bounds.size.height/2.0f);
  tiledLayer.transform = CATransform3DMakeScale(currentZoom, currentZoom, 1.0f);
  
  
  // transform the super layer so things draw 'right side up'
  CATransform3D superTransform = CATransform3DMakeTranslation(0.0f, self.bounds.size.height, 0.0f);
  self.layer.transform = CATransform3DScale(superTransform, 1.0, -1.0f, 1.0f);
  [self.layer addSublayer:tiledLayer];
  
  [tiledLayer setNeedsDisplay];
}

- (void)configureBackgroundLayer {
  backgroundLayer = [CALayer layer];
  BlioPDFBackgroundLayerDelegate *aDelegate = [[BlioPDFBackgroundLayerDelegate alloc] init];
  [aDelegate setPage:page];
  backgroundLayer.delegate = aDelegate;
  self.backgroundLayerDelegate = aDelegate;
  [aDelegate release];
  
  CGFloat inset = -32; // Make this a constant
  CGRect inRect = UIEdgeInsetsInsetRect(tiledLayer.bounds, UIEdgeInsetsMake(inset, inset, inset, inset));
  backgroundLayer.bounds = inRect;
  backgroundLayer.position = tiledLayer.position;
  backgroundLayer.transform = tiledLayer.transform;
  [self.layer insertSublayer:backgroundLayer below:tiledLayer];
  [backgroundLayer setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage {
	self = [super initWithFrame:frame];
	if(self != nil) {
    page = newPage;
    CGPDFPageRetain(page);
    
    self.multipleTouchEnabled = YES;
    
    moving = NO;
    pinchZoom = NO;
    
    [self configureTiledLayer];
    [self configureBackgroundLayer];
	}
	return self;
}

- (void)setZoom:(CGFloat)newZoom andOffset:(CGPoint)newOffset {
  // Boundary checks
  if (newZoom < zoomToFit) {
    newZoom = zoomToFit;
    newOffset = CGPointZero;
  } else if (newZoom > kBlioMaxZoom) {
    newZoom = kBlioMaxZoom;
  }
    
  // This isn't working properly
  if (newOffset.x < -(self.bounds.size.width - self.bounds.size.width*zoomToFit)*newZoom) {
    newOffset.x = -(self.bounds.size.width - self.bounds.size.width*zoomToFit)*newZoom;
  } else if (newOffset.x > (self.bounds.size.width - self.bounds.size.width*zoomToFit)*newZoom) {
    newOffset.x = (self.bounds.size.width - self.bounds.size.width*zoomToFit)*newZoom;
  }
  
  if (newOffset.y < -(self.bounds.size.height - self.bounds.size.height*zoomToFit)*newZoom) {
    newOffset.y = -(self.bounds.size.height - self.bounds.size.height*zoomToFit)*newZoom;
  } else if (newOffset.y > (self.bounds.size.height - self.bounds.size.height*zoomToFit)*newZoom) {
    newOffset.y = (self.bounds.size.height - self.bounds.size.height*zoomToFit)*newZoom;
  }
  
  // Just a catchall to ensure we don't move the fitted view - shouldn't be required
  if (newZoom == zoomToFit) newOffset = CGPointZero;
  
  currentZoom = newZoom;
  currentOffset = newOffset;
  
  CATransform3D newTransform = CATransform3DTranslate(CATransform3DMakeScale(currentZoom, currentZoom, 1.0f), currentOffset.x, currentOffset.y, 0);
  tiledLayer.transform = newTransform;
  backgroundLayer.transform = tiledLayer.transform;
  
  if (currentZoom == zoomToFit) 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomEnded" object:nil userInfo:nil];
  else
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomInProgress" object:nil userInfo:nil];
}

- (void)doubleTapZoomAtPoint:(CGPoint)point {
  CGFloat xOffset = 0.0f;
  CGFloat yOffset = 0.0f;
  CGFloat newZoom = 1.0f;
  
  if (currentZoom == zoomToFit) {
    newZoom = 2;
    CGPoint centerPoint = CGPointMake(self.layer.bounds.size.width/2.0f, self.layer.bounds.size.height/2.0f);
    xOffset = centerPoint.x - point.x;
    yOffset = centerPoint.y - point.y;
  } else {
    newZoom = zoomToFit;
  }
  [self setZoom:newZoom andOffset:CGPointMake(xOffset, yOffset)];
  
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//  [self.layoutView touchesBegan:touches withEvent:event];
//}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  NSSet *allTouches = [event allTouches];
  
  if([allTouches count] == 1) {
    previousPoint = [[touches anyObject] locationInView:self];
    previousDistance = -1;
  } else if([allTouches count] == 2) {
    pinchZoom = YES;
    NSArray *touches = [event.allTouches allObjects];
    CGPoint pointOne = [[touches objectAtIndex:0] locationInView:self];
    CGPoint pointTwo = [[touches objectAtIndex:1] locationInView:self];
    previousDistance = sqrt(pow(pointOne.x - pointTwo.x, 2.0f) + 
                            pow(pointOne.y - pointTwo.y, 2.0f));
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  NSSet *allTouches = [event allTouches]; // this gives us all the touches currently on the screen
  
  if ([allTouches count] == 1) {
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    
    if (!pinchZoom) {
      CGPoint movementDelta = CGPointMake(currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y);
      CGPoint newOffset = CGPointMake(currentOffset.x + movementDelta.x/currentZoom, currentOffset.y + movementDelta.y/currentZoom);
      [self setZoom:currentZoom andOffset:newOffset];
      moving = YES;
    }
    
    previousPoint = currentPoint;

  } else if ([allTouches count] == 2) {
    NSArray *touches = [event.allTouches allObjects];
    CGPoint pointOne = [[touches objectAtIndex:0] locationInView:self];
    CGPoint pointTwo = [[touches objectAtIndex:1] locationInView:self];
    CGFloat currentDistance = sqrt(pow(pointOne.x - pointTwo.x, 2.0f) + 
                                   pow(pointOne.y - pointTwo.y, 2.0f));
    CGFloat newDistance = currentDistance - previousDistance;
    if (newDistance !=0) {
      CGFloat newZoom = fabs(currentZoom * currentDistance/previousDistance);
      [self setZoom:newZoom andOffset:currentOffset];
      previousDistance = currentDistance;
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  previousDistance = -1;
  
  NSSet *allTouches = [event allTouches];
  
  if ([allTouches count] == 1) {
    pinchZoom = NO;
  }
  
  if(!moving) {
    if (touches.count == 1) {
      UITouch * t = [touches anyObject];
      
      if ([t tapCount] == 2) {
        CGPoint point = [t locationInView:self];
        [self doubleTapZoomAtPoint:point];
      }
    }
  } else {
    moving = NO;
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  previousDistance = -1;
  moving = NO;
  pinchZoom = NO;
}

@end


@implementation BlioPDFTiledLayerDelegate

@synthesize page;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
  CGRect cropRect = CGPDFPageGetBoxRect (self.page, kCGPDFCropBox);
  CGContextClipToRect(ctx, cropRect);
  CGContextDrawPDFPage(ctx, self.page);
}

- (void)dealloc {
  NSLog(@"BlioPDFTiledLayerDelegate dealloc");
	[super dealloc];
}

@end

@implementation BlioPDFBackgroundLayerDelegate

@synthesize page;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
  CGFloat shadow = 16 * CGContextGetCTM(ctx).a; // Shadow should be constant
  CGContextSetShadowWithColor(ctx, CGSizeMake(0, (shadow/2.0f)), shadow, [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor);
  CGContextBeginTransparencyLayer(ctx, NULL);
  CGRect cropRect = CGPDFPageGetBoxRect (self.page, kCGPDFCropBox);
  CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
  CGContextFillRect(ctx, cropRect);
  CGContextEndTransparencyLayer(ctx);
}

- (void)dealloc {
  NSLog(@"BlioPDFBackgroundLayerDelegate dealloc");
	[super dealloc];
}

@end