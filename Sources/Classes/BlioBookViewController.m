//
//  BookViewController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioBookViewController.h"
#import <libEucalyptus/THNavigationButton.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THEventCapturingWindow.h>
#import <libEucalyptus/EucBookTitleView.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucEPubBook.h>
#import "BlioViewSettingsSheet.h"
#import "BlioEPubView.h"
#import "BlioLayoutView.h"
#import "BlioSpeedReadView.h"
#import "BlioContentsTabViewController.h"
#import "BlioLightSettingsViewController.h"
#import "BlioBookmarkPoint.h"

static NSString * const kBlioLastLayoutDefaultsKey = @"lastLayout";
static NSString * const kBlioLastFontSizeDefaultsKey = @"lastFontSize";
static NSString * const kBlioLastPageColorDefaultsKey = @"lastPageColor";
static NSString * const kBlioLastLockRotationDefaultsKey = @"lastLockRotation";
static NSString * const kBlioLastTapAdvanceDefaultsKey = @"lastTapAdvance";
static NSString * const kBlioLastTltScrollDefaultsKey = @"lastTiltScroll";

typedef enum {
    kBlioLibraryAddBookmarkAction = 0,
    kBlioLibraryAddNoteAction = 1,
} BlioLibraryAddActions;

typedef enum {
    kBlioPageLayoutPlainText = 0,
    kBlioPageLayoutPageLayout = 1,
    kBlioPageLayoutSpeedRead = 2,
} BlioPageLayout;

typedef enum {
    kBlioFontSizeVerySmall = 0,
    kBlioFontSizeSmall = 1,
    kBlioFontSizeMedium = 2,
    kBlioFontSizeLarge = 3,
    kBlioFontSizeVeryLarge = 4,
} BlioFontSize;
static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

static NSString *kBlioFontPageTextureNamesArray[] = { @"paper-white.png", @"paper-black.png", @"paper-neutral.png" };
static const BOOL kBlioFontPageTexturesAreDarkArray[] = { NO, YES, NO };

typedef enum {
    kBlioRotationLockOff = 0,
    kBlioRotationLockOn = 1,
} BlioRotationLock;

typedef enum {
    kBlioTapTurnOff = 0,
    kBlioTapTurnOn = 1,
} BlioTapTurn;

@interface BlioBookViewControllerProgressPieButton : UIControl {
    CGFloat progress;
    UIColor *tintColor;
    BOOL toggled;
}

@property (nonatomic) CGFloat progress;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic) BOOL toggled;

@end

@implementation BlioBookViewControllerProgressPieButton

@synthesize progress, tintColor, toggled;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.progress = 0.0f;
        self.toggled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.tintColor = [UIColor blackColor];
        
        [self addTarget:self action:@selector(highlightOn) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchCancel];
    }
    return self;
}

- (void)dealloc {
    self.tintColor = nil;
    [super dealloc];
}

- (void)highlightOn {
    [self setHighlighted:YES];
    [self setNeedsDisplay];
}

- (void)highlightOff {
    [self setHighlighted:NO];
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)newFloat {
    progress = newFloat;
    [self setNeedsDisplay];
}

- (void)setToggled:(BOOL)newToggle {
    toggled = newToggle;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)newTint {
    [newTint retain];
    [tintColor release];
    tintColor = newTint;
    [self setNeedsDisplay];
}

void addRoundedRectToPath(CGContextRef c, CGFloat radius, CGRect rect) {
    CGContextSaveGState(c);
    
    if (radius > rect.size.width/2.0)
        radius = rect.size.width/2.0;
    if (radius > rect.size.height/2.0)
        radius = rect.size.height/2.0;    
    
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    CGContextMoveToPoint(c, minx, midy);
    CGContextAddArcToPoint(c, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(c, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(c, minx, maxy, minx, midy, radius);
    
    CGContextClosePath(c); 
    CGContextRestoreGState(c); 
}

void drawGlossGradient(CGContextRef c, CGRect rect) {
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 0.380,  // Start color
        1.0, 1.0, 1.0, 0.188 }; // End color
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGPoint midCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGContextDrawLinearGradient(c, glossGradient, topCenter, midCenter, 0);    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
}

void addOvalToPath(CGContextRef c, CGPoint center, float a, float b, 
                   float start_angle, float arc_angle, int pie) { 
    float CGstart_angle = 90.0 - start_angle; 
    CGContextSaveGState(c); 
    CGContextTranslateCTM(c, center.x, center.y); 
    CGContextScaleCTM(c, a, b); 
    if (pie) { 
        CGContextMoveToPoint(c, 0, 0); 
    } else { 
        CGContextMoveToPoint(c, cos(CGstart_angle * M_PI / 180), 
                             sin(CGstart_angle * M_PI / 180)); 
    } 
    CGContextAddArc(c, 0, 0, 1, 
                    CGstart_angle * M_PI / 180, 
                    (CGstart_angle - arc_angle) * M_PI / 180, 
                    arc_angle>0 ? 1 : 0); 
    if (pie) { 
        CGContextClosePath(c); 
    } 
    CGContextRestoreGState(c); 
} 

void fillOval(CGContextRef c, CGRect rect, float start_angle, float arc_angle) { 
    float a, b; 
    CGPoint center; 
    CGContextBeginPath(c); 
    center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)); 
    a = CGRectGetWidth(rect) / 2; 
    b = CGRectGetHeight(rect) / 2; 
    addOvalToPath(c, center, a, b, start_angle, arc_angle, 1); 
    CGContextClosePath(c); 
    CGContextFillPath(c); 
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0.0, CGRectGetMaxY(rect));
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGFloat yButtonPadding = 7.0f;
    CGFloat xButtonPadding = 7.0f;
    CGFloat wedgePadding = 2.0f;
    CGRect inRect = CGRectInset(rect, xButtonPadding, yButtonPadding);
    CGFloat insetX, insetY;
    CGFloat width = inRect.size.width;
    CGFloat height = inRect.size.height;
    
    if (width > height) {
        insetX = (width - height); // Right aligned
        insetY = 0;
        width = width - insetX;
    } else {
        insetX = 0;
        insetY = (height - width)/2.0f;
        height = height - 2 * insetY;
    }
    
    CGRect outerSquare = CGRectIntegral(CGRectMake(inRect.origin.x + insetX, inRect.origin.y + insetY, width, height));
    CGRect innerSquare = CGRectInset(outerSquare, wedgePadding, wedgePadding);
    CGRect buttonSquare = CGRectInset(outerSquare, -xButtonPadding, -yButtonPadding);
    CGRect backgroundSquare = UIEdgeInsetsInsetRect(buttonSquare, UIEdgeInsetsMake(1, 0, 0, 0));
    
    CGContextClipToRect(ctx, buttonSquare);
    
    if ([self isHighlighted] || toggled) {
        CGContextSetShadowWithColor(ctx, CGSizeMake(0,-1), 0, [UIColor colorWithWhite:0.5f alpha:0.25f].CGColor);
    } else {
        CGContextSetShadowWithColor(ctx, CGSizeMake(0,-1), 0, [UIColor colorWithWhite:1.0f alpha:0.25f].CGColor);
    }
    
    CGContextBeginTransparencyLayer(ctx, NULL);
    addRoundedRectToPath(ctx, 6.0f, backgroundSquare);
    CGContextClip(ctx);
    
    CGContextSetFillColorWithColor(ctx, tintColor.CGColor);
    CGContextFillRect(ctx, backgroundSquare);
    drawGlossGradient(ctx, backgroundSquare);
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(0,-0.5f), 0.5f, [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    addRoundedRectToPath(ctx, 6.0f, backgroundSquare);
    CGContextStrokePath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor);
    CGContextSetLineWidth(ctx, 2.0f);
    
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1.0f), 0.0f, [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor);
    CGContextStrokeEllipseInRect(ctx, outerSquare);
    CGContextRestoreGState(ctx);
    
    if (progress) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor);
        fillOval(ctx, innerSquare, 0, progress*360);
    }
    
    if ([self isHighlighted] || toggled) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.25f].CGColor);
        CGContextFillRect(ctx, backgroundSquare);
    }
    
    CGContextEndTransparencyLayer(ctx);
}

@end


@interface _BlioBookViewControllerTransparentView : UIView {
    BlioBookViewController *controller;
}

@property (nonatomic, assign) BlioBookViewController *controller;
@end

@implementation _BlioBookViewControllerTransparentView

@synthesize controller;

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *ret = [super hitTest:point withEvent:event];
    if(ret == self) {
        UIView *view = controller.bookView;
        CGPoint insidePoint = [self convertPoint:point toView:view];
        ret = [view hitTest:insidePoint withEvent:event];
    }
    return ret;
}

@end


@interface BlioBookViewController (PRIVATE)
- (NSArray *)_toolbarItemsForReadingView;
- (void) _updatePageJumpLabelForPage:(NSInteger)page;

- (void) updatePageJumpPanelForPage:(NSInteger)pageNumber animated:(BOOL)animated;

@end

@implementation BlioBookViewController

@synthesize book = _book;
@synthesize bookView = _bookView;
@synthesize pageJumpView = _pageJumpView;
@synthesize pieButton = _pieButton;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

@synthesize currentPageColor = _currentPageColor;

@synthesize audioPlaying = _audioPlaying;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize tiltScroller, tapDetector, motionControlsEnabled;

- (BOOL)toolbarsVisibleAfterAppearance 
{
    return !self.hidesBottomBarWhenPushed;
}

- (void)setToolbarsVisibleAfterAppearance:(BOOL)visible 
{
    self.hidesBottomBarWhenPushed = !visible;
}

- (void)setReturnToNavigationBarStyle:(UIBarStyle)barStyle
{
    _returnToNavigationBarStyle = barStyle;
    _overrideReturnToNavigationBarStyle = YES;
}

- (void)setReturnToStatusBarStyle:(UIStatusBarStyle)barStyle
{
    _returnToStatusBarStyle = barStyle;
    _overrideReturnToStatusBarStyle = YES;
}

- (void)setReturnToNavigationBarHidden:(BOOL)barHidden
{
    _returnToNavigationBarHidden = barHidden;
    _overrideReturnToNavigationBarHidden = YES;
}

- (void)setReturnToStatusBarHidden:(BOOL)barHidden
{
    _returnToStatusBarHidden = barHidden;
    _overrideReturnToStatusBarHidden = YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (id)initWithBook:(BlioMockBook *)newBook {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.audioPlaying = NO;
        self.wantsFullScreenLayout = YES;
        
        UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent];
        [backArrow addTarget:self
                      action:@selector(_backButtonTapped) 
            forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backArrow];
        self.navigationItem.leftBarButtonItem = backItem;
        [backItem release];
        
        EucBookTitleView *titleView = [[EucBookTitleView alloc] init];
        CGRect frame = titleView.frame;
        frame.size.width = [[UIScreen mainScreen] bounds].size.width;
        [titleView setFrame:frame];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = titleView;
        [titleView release];
        
        _firstAppearance = YES;
        
        self.toolbarItems = [self _toolbarItemsForReadingView];
        
        _pageJumpView = nil;
        
        tiltScroller = [[MSTiltScroller alloc] init];
        tapDetector = [[MSTapDetector alloc] init];
        motionControlsEnabled = kBlioTapTurnOff;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapToNextPage) name:@"TapToNextPage" object:nil];
        
        BlioPageLayout lastLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastLayoutDefaultsKey];
        
        switch (lastLayout) {
            case kBlioPageLayoutPageLayout: {
                if ([newBook pdfPath]) {
                    BlioLayoutView *aBookView = [[BlioLayoutView alloc] initWithBook:newBook animated:YES];
                    self.book = newBook;
                    self.bookView = aBookView;
                    [aBookView release];
                } else {
                    return nil;
                }
            }
                break;
            default: {
                if ([newBook bookPath]) {
                    BlioEPubView *aBookView = [[BlioEPubView alloc] initWithBook:newBook animated:YES];
                    self.book = newBook;
                    self.bookView = aBookView;
                    self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
                    [aBookView release];
                } else {
                    return nil;
                }
            } 
                break;
        }        
    }
    return self;
}

- (NSArray *)_toolbarItemsForReadingView {
    
    NSMutableArray *readingItems = [NSMutableArray array];
    UIBarButtonItem *item;
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-contents.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showContents:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showAddMenu:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(dummyShowParsedText:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    UIImage *audioImage = nil;
    if (self.audioPlaying)
        audioImage = [UIImage imageNamed:@"icon-pause.png"];
    else 
        audioImage = [UIImage imageNamed:@"icon-play.png"];
    
    item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(toggleAudio:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-eye.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showViewSettings:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    return [NSArray arrayWithArray:readingItems];
}

- (void)setBookView:(UIView<BlioBookView> *)bookView
{
    if(_bookView != bookView) {
        if(_bookView) {
            [_bookView removeObserver:self forKeyPath:@"pageNumber"];
            [_bookView removeObserver:self forKeyPath:@"pageCount"];        
            if(_bookView.superview) {
                //THEventCapturingWindow *window = (THEventCapturingWindow *)_bookView.window;
                //[window removeTouchObserver:self forView:_bookView];
                [_bookView removeFromSuperview];
            }
        }
        
        [_bookView release];
        _bookView = [bookView retain];
        
        if(_bookView) {
            if(self.isViewLoaded) {
                EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
                [titleView setTitle:[self.book title]];
                [titleView setAuthor:[self.book author]];              
                
                [self.view addSubview:_bookView];
                [self.view sendSubviewToBack:_bookView];
                
                //[(THEventCapturingWindow *)_bookView.window addTouchObserver:self forView:_bookView];
            }
            
            [_bookView addObserver:self 
                        forKeyPath:@"pageNumber" 
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                           context:nil];
            
            [_bookView addObserver:self 
                        forKeyPath:@"pageCount" 
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                           context:nil];   
        }
    }
}

- (void)_backButtonTapped
{
	if (self.audioPlaying) {
		[self stopAudio];
		self.audioPlaying = NO;  
	}
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updatePieButtonForPage:(NSInteger)pageNumber animated:(BOOL)animated {
    [self.pieButton setProgress:pageNumber/(CGFloat)self.bookView.pageCount];
}


- (void)updatePieButtonAnimated:(BOOL)animated {
    [self updatePieButtonForPage:self.bookView.pageNumber animated:animated];
}

- (void)updatePageJumpPanelForPage:(NSInteger)pageNumber animated:(BOOL)animated
{
    if (_pageJumpSlider) {
        _pageJumpSlider.maximumValue = self.bookView.pageCount;
        _pageJumpSlider.minimumValue = 1;
        [_pageJumpSlider setValue:pageNumber animated:animated];
        [self _updatePageJumpLabelForPage:pageNumber];
    }    
}

- (void)updatePageJumpPanelAnimated:(BOOL)animated
{
    [self updatePageJumpPanelForPage:self.bookView.pageNumber animated:YES];
}

- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid {
    [self performSelector:@selector(dismissContentsTabView:)];
}


- (void)loadView 
{
    UIView *root = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    root.backgroundColor = [UIColor blackColor];
    root.opaque = YES;
    if(_bookView) {
        [root addSubview:_bookView];
        [root sendSubviewToBack:_bookView];
    }
    self.view = root;
    [root release];
    
    if(!self.toolbarsVisibleAfterAppearance) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }    
}

- (void)viewWillAppear:(BOOL)animated
{
    if(!self.modalViewController) {        
        UIApplication *application = [UIApplication sharedApplication];
        
        // Store the hidden/visible state and style of the status and navigation
        // bars so that we can restore them when popped.
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        UIBarStyle navigationBarStyle = navigationBar.barStyle;
        UIColor *navigationBarTint = [navigationBar.tintColor retain];
        BOOL navigationBarHidden = self.navigationController.isNavigationBarHidden;
        
        UIToolbar *toolbar = self.navigationController.toolbar;
        UIBarStyle toolbarStyle = toolbar.barStyle;
        UIColor *toolbarTint = [toolbar.tintColor retain];
        
        UIStatusBarStyle statusBarStyle = application.statusBarStyle;
        BOOL statusBarHidden = application.isStatusBarHidden;
        
        if(!_overrideReturnToNavigationBarStyle) {
            _returnToNavigationBarStyle = navigationBarStyle;
        }
        if(!_overrideReturnToStatusBarStyle) {
            _returnToStatusBarStyle = statusBarStyle;
        }
        if(!_overrideReturnToNavigationBarHidden) {
            _returnToNavigationBarHidden = navigationBarHidden;
        }
        if(!_overrideReturnToStatusBarHidden) {
            _returnToStatusBarHidden = statusBarHidden;
        }
        _returnToToolbarTint = [toolbarTint retain];
        _returnToNavigationBarTint = [navigationBarTint retain];
        _returnToToolbarStyle = toolbarStyle;
        _returnToNavigationBarTranslucent = navigationBar.translucent;
        _returnToToolbarTranslucent = toolbar.translucent;
        
        // Set the status bar and navigation bar styles.
        if([_book.author isEqualToString:@"Ward Just"]) {
            navigationBar.barStyle = UIBarStyleBlackTranslucent;
            navigationBar.tintColor = [UIColor blackColor];
            navigationBar.translucent = YES;
            toolbar.barStyle = UIBarStyleBlackTranslucent;
            toolbar.tintColor = [UIColor blackColor];
            toolbar.translucent = YES;
        } else {
            navigationBar.translucent = NO;
            navigationBar.tintColor = nil;
            navigationBar.barStyle = UIBarStyleBlackTranslucent;
            toolbar.translucent = NO;
            toolbar.tintColor = nil;
            toolbar.barStyle = UIBarStyleBlackTranslucent;
        }
        
        if(statusBarStyle != UIStatusBarStyleBlackTranslucent) {
            [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
        }
        // Hide the navigation bar if appropriate.
        // We'll take care of the status bar in -viewDidAppear: (if we do it
        // here, we can see white below on the left as the navigation transition
        // takes place).
        if(self.toolbarsVisibleAfterAppearance) {
            if(navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:NO animated:YES];
            }
        } else {
            if(!navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:YES animated:YES];
            }
            if(!self.navigationController.toolbarHidden) {
                [self.navigationController setToolbarHidden:YES];
            }
        }
        
        //if(_bookView) {
            // Couldn't be done at view creation time, because there was
            // no handle to the window.
            //UIWindow *window = self.navigationController.view.window;
            //[(THEventCapturingWindow *)window addTouchObserver:self forView:_bookView];
        //}
        
        EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
        [titleView setTitle:[self.book title]];
        [titleView setAuthor:[self.book author]];
        
        BlioBookViewControllerProgressPieButton *aPieButton = [[BlioBookViewControllerProgressPieButton alloc] initWithFrame:CGRectMake(0,0, 50, 30)];
        [aPieButton addTarget:self action:@selector(togglePageJumpPanel) forControlEvents:UIControlEventTouchUpInside];
        _pageJumpButton = [[UIBarButtonItem alloc] initWithCustomView:aPieButton];
        self.pieButton = aPieButton;
        [aPieButton release];
        
        [self.navigationItem setRightBarButtonItem:_pageJumpButton];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if(_firstAppearance) {
        UIApplication *application = [UIApplication sharedApplication];
        if(self.toolbarsVisibleAfterAppearance) {
            if([application isStatusBarHidden]) {
                [application setStatusBarHidden:NO animated:YES];
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController setNavigationBarHidden:NO animated:NO];
            }
            if(!animated) {
                CGRect frame = self.navigationController.toolbar.frame;
                frame.origin.y += frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView beginAnimations:@"PullInToolbarAnimations" context:NULL];
                frame.origin.y -= frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView commitAnimations];                
            }                    
        } else {
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleBlackTranslucent;  
            if(![application isStatusBarHidden]) {
                [application setStatusBarHidden:YES animated:YES];
            }            
        }
    }
    _firstAppearance = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
    if(!self.modalViewController) {
        _viewIsDisappearing = YES;
        //        if(_contentsSheet) {
        //            [self performSelector:@selector(dismissContents)];
        //        }
        if(_bookView) {
            // Need to do this now before the view is removed and doesn't have a window.
            //[(THEventCapturingWindow *)_bookView.window removeTouchObserver:self forView:_bookView];
            
            if([_bookView respondsToSelector:@selector(stopAnimation)]) {
                [_bookView performSelector:@selector(stopAnimation)];
            }
            
            [self.navigationController setToolbarHidden:YES animated:NO];
            [self.navigationController setToolbarHidden:NO animated:NO];
            UIToolbar *toolbar = self.navigationController.toolbar;
            toolbar.translucent = _returnToToolbarTranslucent;
            toolbar.barStyle = _returnToToolbarStyle; 
            toolbar.tintColor = _returnToToolbarTint;
            [_returnToToolbarTint release];
            _returnToToolbarTint = nil;
            
            if(animated) {
                CATransition *animation = [CATransition animation];
                animation.type = kCATransitionPush;
                animation.subtype = kCATransitionFromLeft;
                animation.duration = 1.0/3.0;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                
                [animation setValue:_bookView forKey:@"THView"];                
                [[toolbar layer] addAnimation:animation forKey:@"PageViewTransitionOut"];
            } 
            
            // Restore the hiden/visible state of the status bar and 
            // navigation bar.
            // The combination of animation and order below has been found
            // by trial-and-error to give the 'smoothest' looking transition
            // back.
            UIApplication *application = [UIApplication sharedApplication];
            [UIView beginAnimations:@"TransitionBackBarAnimations" context:NULL];
            if(_returnToStatusBarStyle != application.statusBarStyle) {
                [application setStatusBarStyle:_returnToStatusBarStyle
                                      animated:YES];
            }                        
            if(_returnToStatusBarHidden != application.isStatusBarHidden){
                [application setStatusBarHidden:_returnToStatusBarHidden 
                                       animated:YES];
            }           
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleDefault;
            navBar.translucent = _returnToNavigationBarTranslucent;
            navBar.barStyle = _returnToNavigationBarStyle;
            navBar.tintColor = _returnToNavigationBarTint;
            [_returnToNavigationBarTint release];
            _returnToNavigationBarTint = nil;
            
            [UIView commitAnimations];
            
            if(_returnToNavigationBarHidden != self.navigationController.isNavigationBarHidden) {
                [self.navigationController setNavigationBarHidden:_returnToNavigationBarHidden 
                                                         animated:NO];
            }     
        }
    }
}


- (void)viewDidDisappear:(BOOL)animated
{    
    _viewIsDisappearing = NO;
}


- (void)viewDidUnload
{
    self.bookView = nil;
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    
    [tapDetector release];
    [tiltScroller release];
    
    self.bookView = nil;
    self.book = nil;
    self.pageJumpView = nil;
    self.pieButton = nil;
    self.managedObjectContext = nil;
	[super dealloc];
}


- (void)_fadeDidEnd
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        self.navigationController.toolbarHidden = YES;
        self.navigationController.navigationBar.hidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    _fadeState = BookViewControlleUIFadeStateNone;
}


- (void)_fadeWillStart
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];    
    } 
}

- (void)toggleToolbars
{
    if(_fadeState == BookViewControlleUIFadeStateNone) {
        if(self.navigationController.toolbarHidden == YES) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; 
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
            self.navigationController.navigationBarHidden = NO;
            self.navigationController.navigationBar.hidden = NO;
            self.navigationController.toolbarHidden = NO;
            self.navigationController.toolbar.alpha = 0;
            _fadeState = BookViewControlleUIFadeStateFadingIn;
        } else {
            _fadeState = BookViewControlleUIFadeStateFadingOut;
        }
                
        // Durations below taken from trial-and-error comparison with the 
        // Photos application.
        [UIView beginAnimations:@"ToolbarsFade" context:nil];
        
        if(_fadeState == BookViewControlleUIFadeStateFadingIn) {
            [UIView setAnimationDuration:0.0];
            self.navigationController.toolbar.alpha = 1;          
            self.pageJumpView.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        } else {
            [UIView setAnimationDuration:1.0/3.0];
            self.navigationController.toolbar.alpha = 0;
            self.pageJumpView.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
        }
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_fadeDidEnd)];
        [UIView setAnimationWillStartSelector:@selector(_fadeWillStart)];
        
        [UIView commitAnimations];        
    }
}


- (void)observeTouch:(UITouch *)touch
{
    UITouchPhase phase = touch.phase;
        
    if(touch != _touch) {
        [_touch release];
        _touch = nil;
        if(phase == UITouchPhaseBegan) {
            _touch = [touch retain];
            _touchMoved = NO;
        }
    } else if(touch == _touch) {
        if(phase == UITouchPhaseMoved) { 
            _touchMoved = YES;
            if(!self.navigationController.toolbarHidden) {
                [self toggleToolbars];
            }
        } else if(phase == UITouchPhaseEnded) {
            if(!_touchMoved) {
                [self toggleToolbars];
            }
            [_touch release];
            _touch = nil;
        } else if(phase == UITouchPhaseCancelled) {
            [_touch release];
            _touch = nil;
            NSLog(@"UITouchPhaseCancelled");
        }
    }
}

- (void) togglePageJumpPanel
{ 
    CGPoint navBarBottomLeft = CGPointMake(0.0, self.navigationController.navigationBar.frame.size.height);
    CGPoint xt = [self.view convertPoint:navBarBottomLeft fromView:self.navigationController.navigationBar];
    
    if(!_pageJumpView) {
        self.pageJumpView = [[UIView alloc] init];
        [self.pageJumpView release];
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        [_pageJumpView setFrame:CGRectMake(xt.x, xt.y, screenSize.width, 46)];
        _pageJumpView.hidden = YES;
        _pageJumpView.opaque = NO;
        _pageJumpView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        
        CGRect labelFrame = _pageJumpView.bounds;
        labelFrame.size.height = 20;
        CGRect sliderFrame = _pageJumpView.bounds;
        sliderFrame.origin.y = 20;
        sliderFrame.origin.x = 4;
        sliderFrame.size.height = 24;
        sliderFrame.size.width -= 8;
        
        // the slider
        UISlider* slider = [[UISlider alloc] initWithFrame: sliderFrame];
        _pageJumpSlider = slider;
        
        UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
        leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:leftCapImage.size.height];
        [slider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
        
        UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
        rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
        [slider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
        
        UIImage *thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob-Small.png"];
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
        [slider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
        
        [slider addTarget:self action:@selector(_pageSliderSlid:) forControlEvents:UIControlEventValueChanged];
        
        slider.maximumValue = self.bookView.pageCount;
        slider.minimumValue = 1;
        [slider setValue:self.bookView.pageNumber];
        
        _pageJumpSliderTracking = NO;
        
        // feedback label
        _pageJumpLabel = [[UILabel alloc] initWithFrame:labelFrame];
        _pageJumpLabel.textAlignment = UITextAlignmentCenter;
        _pageJumpLabel.adjustsFontSizeToFitWidth = YES;
        _pageJumpLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        _pageJumpLabel.minimumFontSize = 8;
        _pageJumpLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _pageJumpLabel.shadowOffset = CGSizeMake(0, -1);
        
        _pageJumpLabel.backgroundColor = [UIColor clearColor];
        _pageJumpLabel.textColor = [UIColor whiteColor];
        
        [_pageJumpView addSubview:_pageJumpLabel];
        [_pageJumpView addSubview:slider];
        
        [self.view addSubview:_pageJumpView];
    }
    
    CGSize sz = _pageJumpView.bounds.size;
    BOOL hiding = !_pageJumpView.hidden;
    [self.pieButton setToggled:!hiding];
    
    if (!hiding) {
        _pageJumpView.alpha = 0.0;
        _pageJumpView.hidden = NO;
        [self _updatePageJumpLabelForPage:self.bookView.pageNumber];
        [_pageJumpView setFrame:CGRectMake(0, xt.y - sz.height, sz.width, sz.height)];
    }
    
    [UIView beginAnimations:@"pageJumpViewToggle" context:NULL];
    [UIView setAnimationDidStopSelector:@selector(_pageJumpPanelDidAnimate)];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3f];
    
    if (hiding) {
        _pageJumpView.alpha = 0.0;
        [_pageJumpView setFrame:CGRectMake(0, xt.y - sz.height, sz.width, sz.height)];
    } else {
        _pageJumpView.alpha = 1.0;
        [_pageJumpView setFrame:CGRectMake(0, xt.y, sz.width, sz.height)];
    }
    
    [UIView commitAnimations];
}

- (void) _pageJumpPanelDidAnimate
{
    if (_pageJumpView.alpha == 0.0) {
        _pageJumpView.hidden = YES;
    }
}

- (void) _pageSliderSlid: (id) sender
{
    UISlider* slider = (UISlider*) sender;
    NSInteger page = (NSInteger) slider.value;
    [self _updatePageJumpLabelForPage:page];
    
    if (slider.isTracking) {
        _pageJumpSliderTracking = YES;
    } else if (_pageJumpSliderTracking) {
        [self.bookView goToPageNumber:page animated:YES];
        _pageJumpSliderTracking = NO;
    }
    [self.pieButton setProgress:_pageJumpSlider.value/_pageJumpSlider.maximumValue];
    
    // When we come to set this later, after the page turn,
    // it's often a pixel out (due to rounding?), so set it here.
    [_pageJumpSlider setValue:page animated:NO];
}

- (void) _updatePageJumpLabelForPage:(NSInteger)page
{
    NSString* section = [self.bookView.contentsDataSource sectionUuidForPageNumber:page];
    THPair* chapter = [self.bookView.contentsDataSource presentationNameAndSubTitleForSectionUuid:section];
    NSString* pageStr = [self.bookView.contentsDataSource displayPageNumberForPageNumber:page];
    
    if (section && chapter.first) {
        if (pageStr) {
            _pageJumpLabel.text = [NSString stringWithFormat:@"Page %@ - %@", pageStr, chapter.first];
        } else {
            _pageJumpLabel.text = [NSString stringWithFormat:@"%@", chapter.first];
        }
    } else {
        if (pageStr) {
            _pageJumpLabel.text = [NSString stringWithFormat:@"Page %@ of %d", pageStr, self.bookView.pageCount];
        } else {
            _pageJumpLabel.text = self.book.title;
        }
    } // of no section name
}

#pragma mark -
#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _touchMoved = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    _touchMoved = YES;
    if(!self.navigationController.toolbarHidden)
        [self toggleToolbars];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!_touchMoved)
        [self toggleToolbars];
}

#pragma mark -
#pragma mark AccelerometerControl Methods

- (void)setupTiltScrollerWithBookView {
    if ([self.bookView isKindOfClass:[BlioLayoutView class]]) {
        [(BlioLayoutView *)self.bookView setTiltScroller:tiltScroller];
    }    
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acc {    
    if (!motionControlsEnabled) return;
    
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]]) {
        if (![(BlioLayoutView *)bookViewController.bookView tiltScroller]) [self setupTiltScrollerWithBookView];
        [tiltScroller accelerometer:accelerometer didAccelerate:acc];        
    } else {
        [tapDetector updateFilterWithAcceleration:acc];
    }
    
    /*    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
     [tapDetector updateHistoryWithX:acc.x Y:acc.y Z:acc.z];
     } else if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
     [tiltScroller accelerometer:accelerometer didAccelerate:acc];
     }
     */    
}

- (void)tapToNextPage {
    if ([self.bookView isKindOfClass:[BlioEPubView class]]) {
        int currentPage = [self.bookView pageNumber] + 1;
        if (currentPage >= [self.bookView pageCount]) currentPage = [self.bookView pageCount];

        [self.bookView goToPageNumber:currentPage animated:YES];
    }
}

#pragma mark -
#pragma mark BookController State Methods

- (NSString *)currentPageNumber {
    UIView<BlioBookView> *bookView = [(BlioBookViewController *)self.navigationController.topViewController bookView];
    if ([bookView respondsToSelector:@selector(pageNumber)]) {
        NSInteger currentPage = (NSInteger)[bookView performSelector:@selector(pageNumber)];
        if ([[bookView contentsDataSource] respondsToSelector:@selector(displayPageNumberForPageNumber:)])
            return [[bookView contentsDataSource] displayPageNumberForPageNumber:currentPage];
    }
    return nil;
}

- (BlioPageLayout)currentPageLayout {
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]])
        return kBlioPageLayoutPageLayout;
    else if([bookViewController.bookView isKindOfClass:[BlioSpeedReadView class]])
        return kBlioPageLayoutSpeedRead;
    else
        return kBlioPageLayoutPlainText;
}

- (void)changePageLayout:(id)sender {
    
    BlioPageLayout newLayout = (BlioPageLayout)[sender selectedSegmentIndex];
    
    BlioPageLayout currentLayout = self.currentPageLayout;
    if(currentLayout != newLayout) {        
		if (self.audioPlaying) {
			UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
			[item setImage:[UIImage imageNamed:@"icon-play.png"]];
			[self stopAudio];
			self.audioPlaying = NO;  
		}
        if (newLayout == kBlioPageLayoutPlainText && [self.book bookPath]) {
            BlioEPubView *ePubView = [[BlioEPubView alloc] initWithBook:self.book animated:NO];
            [ePubView goToBookmarkPoint:self.bookView.pageBookmarkPoint animated:NO];
            self.bookView = ePubView;
            [ePubView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPlainText forKey:kBlioLastLayoutDefaultsKey];    
        } else if (newLayout == kBlioPageLayoutPageLayout && [self.book pdfPath]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithBook:self.book animated:NO];
            [layoutView goToBookmarkPoint:self.bookView.pageBookmarkPoint animated:NO];
            self.bookView = layoutView;            
            [layoutView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPageLayout forKey:kBlioLastLayoutDefaultsKey];    
        } else if (newLayout == kBlioPageLayoutSpeedRead && [self.book bookPath]) {
            BlioSpeedReadView *speedReadView = [[BlioSpeedReadView alloc] initWithBook:self.book animated:NO];
            self.bookView = speedReadView;     
            [speedReadView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutSpeedRead forKey:kBlioLastLayoutDefaultsKey];
        }
    }
}

- (BOOL)shouldShowPageAttributeSettings {
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout)
        return NO;
    else
        return YES;
}

- (BlioFontSize)currentFontSize {
    BlioFontSize fontSize = kBlioFontSizeMedium;
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    id<BlioBookView> bookView = bookViewController.bookView;
    
    if([bookView respondsToSelector:(@selector(fontPointSize))]) {
        CGFloat actualFontSize = bookView.fontPointSize;
        CGFloat bestDifference = CGFLOAT_MAX;
        BlioFontSize bestFontSize = kBlioFontSizeMedium;
        for(BlioFontSize i = kBlioFontSizeVerySmall; i <= kBlioFontSizeVeryLarge; ++i) {
            CGFloat thisDifference = fabsf(kBlioFontPointSizeArray[i] - actualFontSize);
            if(thisDifference < bestDifference) {
                bestDifference = thisDifference;
                bestFontSize = i;
            }
        }
        fontSize = bestFontSize;
    } 
    return fontSize;
}

- (void)changeFontSize:(id)sender {
    BlioFontSize newSize = (BlioFontSize)[sender selectedSegmentIndex];
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    id<BlioBookView> bookView = bookViewController.bookView;
    if([bookView respondsToSelector:(@selector(setFontPointSize:))]) {        
        if([self currentFontSize] != newSize) {
            bookView.fontPointSize = kBlioFontPointSizeArray[newSize];
            [[NSUserDefaults standardUserDefaults] setInteger:newSize forKey:kBlioLastFontSizeDefaultsKey];
        }
    }
}

- (void)setCurrentPageColor:(BlioPageColor)newColor
{
    if(newColor != self.currentPageColor) {
        UIView<BlioBookView> *bookView = self.bookView;
        if([bookView respondsToSelector:(@selector(setPageTexture:isDark:))]) {
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:kBlioFontPageTextureNamesArray[newColor]
                                                                  ofType:@""];
            UIImage *pageTexture = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:imagePath]];
            [bookView setPageTexture:pageTexture isDark:kBlioFontPageTexturesAreDarkArray[newColor]];
        }  
        _currentPageColor = newColor;
    }
}

- (void)changePageColor:(id)sender {
    self.currentPageColor = (BlioPageColor)[sender selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentPageColor forKey:kBlioLastPageColorDefaultsKey];
}

- (BlioRotationLock)currentLockRotation {
    return kBlioRotationLockOff;
}

- (void)changeLockRotation:(id)sender {
    // This is just a placeholder check. Obviously we shouldn't be checking against the string.
    BlioRotationLock newLock = (BlioRotationLock)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Unlock Rotation"];
    if([self currentLockRotation] != newLock) {
        [[NSUserDefaults standardUserDefaults] setInteger:newLock forKey:kBlioLastLockRotationDefaultsKey];
    }
}

- (BlioTapTurn)currentTapTurn {
    return motionControlsEnabled;

}

- (void)changeTapTurn:(id)sender {
    if (motionControlsEnabled == kBlioTapTurnOff) {
        motionControlsEnabled = kBlioTapTurnOn;
        [tiltScroller resetAngle];
        [self setupTiltScrollerWithBookView];
        
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 40)];
        [[UIAccelerometer sharedAccelerometer] setDelegate:self];   
    } else {
        motionControlsEnabled = kBlioTapTurnOff;
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
        [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:motionControlsEnabled forKey:kBlioLastTapAdvanceDefaultsKey];
}

#pragma mark -
#pragma mark KVO Callback

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"pageNumber"]) {
        [self updatePageJumpPanelAnimated:YES];
        [self updatePieButtonAnimated:YES];
        
        // This should be more generally handled for both types of bookview
        if ([self.bookView isKindOfClass:[BlioLayoutView class]]) {
            [self.book setLayoutPageNumber:[change objectForKey:NSKeyValueChangeNewKey]];
        }    
    }
    
    if ([keyPath isEqual:@"pageCount"]) {
        [self updatePageJumpPanelAnimated:YES];
        [self updatePieButtonAnimated:YES];
    }
}

#pragma mark -
#pragma mark Action Callback Methods

- (void)showContents:(id)sender {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    BlioContentsTabViewController *aContentsTabView = [[BlioContentsTabViewController alloc] initWithBookView:self.bookView book:self.book];
    aContentsTabView.delegate = self;
    [self presentModalViewController:aContentsTabView animated:YES];
    [aContentsTabView release];    
}

- (void)showAddMenu:(id)sender {
    UIActionSheet *aActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Add Notes", nil];
    aActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    aActionSheet.delegate = self;
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aActionSheet showFromToolbar:toolbar];
    [aActionSheet release];
}

- (void)showViewSettings:(id)sender {
    BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aSettingsSheet showFromToolbar:toolbar];
    [aSettingsSheet release];
}


- (void)speakNextPargraph:(NSTimer*)timer {
	if ( _acapelaTTS.textToSpeakChanged ) {	
		[_acapelaTTS setTextToSpeakChanged:NO];
		[_acapelaTTS startSpeaking:[_acapelaTTS.paragraphWords componentsJoinedByString:@" "]];
	}
}

- (void) prepareTextToSpeak:(BOOL)continuingSpeech {
    // THIS IS DUMMY CODE TO TEST TTS IN LAYOUT VIEW
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
        id paragraphId;
        NSUInteger wordOffset;
        if ( continuingSpeech ) {
            // Continuing to speak, we just need more text.
			while ( true ) {
				paragraphId = [(BlioLayoutView *)self.bookView paragraphIdForParagraphAfterParagraphWithId:_acapelaTTS.currentParagraph];
				wordOffset = 0;
				[_acapelaTTS setCurrentWordOffset:wordOffset];
				[_acapelaTTS setCurrentParagraph:paragraphId];
				[_acapelaTTS setParagraphWords:[(BlioLayoutView *)self.bookView paragraphWordsForParagraphWithId:[_acapelaTTS currentParagraph]]];
				if ( _acapelaTTS.paragraphWords == nil ) {
					// end of the book
					UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
					[item setImage:[UIImage imageNamed:@"icon-play.png"]];
					[self stopAudio];
					self.audioPlaying = NO;
					return;
				}
				else if ( [_acapelaTTS.paragraphWords count] == 0 ) {
					// empty paragraph, go to the next.
					continue;
				}
				else
					break;
			}
			if ( wordOffset != 0 ) 
				[_acapelaTTS adjustParagraphWords];
		}
        else {
            paragraphId = [(BlioLayoutView *)self.bookView getCurrentParagraphId];
            wordOffset = [(BlioLayoutView *)self.bookView getCurrentWordOffset];
            // Play button has just been pushed.
            if ([(BlioLayoutView *)self.bookView pageNumber] != [_acapelaTTS currentPage]) {
                // Starting speech for the first time, or for the first time since changing the 
                // page or book after stopping speech the last time (whew).
                [_acapelaTTS setCurrentPage:[(BlioLayoutView *)self.bookView pageNumber]]; // Not very robust page-identifier
                [_acapelaTTS setCurrentWordOffset:wordOffset];
                [_acapelaTTS setCurrentParagraph:paragraphId];
                [_acapelaTTS setParagraphWords:[(BlioLayoutView *)self.bookView paragraphWordsForParagraphWithId:[_acapelaTTS currentParagraph]]];
				if ( wordOffset != 0 ) 
					// The first paragraphs words displayed on this page are not at 
					// the beginning of the paragraph.
					[_acapelaTTS adjustParagraphWords];
            }
			else
				// use the current word and paragraph, which is where we last stopped.
				// edge case:  what if you stopped speech right after the end of the paragraph?
				[_acapelaTTS adjustParagraphWords];
        }
        [_acapelaTTS setTextToSpeakChanged:YES];
        
    } else {
        BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
        BlioEPubView *bookView = (BlioEPubView *)bookViewController.bookView;
        EucEPubBook *book = (EucEPubBook*)bookView.book;
        uint32_t paragraphId, wordOffset;
        if ( continuingSpeech ) {
            // Continuing to speak, we just need more text.
			while ( true ) {
				paragraphId = [book paragraphIdForParagraphAfterParagraphWithId:(uint32_t)_acapelaTTS.currentParagraph];
				wordOffset = 0;
				[_acapelaTTS setCurrentWordOffset:wordOffset];
				[_acapelaTTS setCurrentParagraph:(id)paragraphId];
				[_acapelaTTS setParagraphWords:[book paragraphWordsForParagraphWithId:(uint32_t)[_acapelaTTS currentParagraph]]];
				if ( _acapelaTTS.paragraphWords == nil ) {
					// end of the book
					UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
					[item setImage:[UIImage imageNamed:@"icon-play.png"]];
					[self stopAudio];
					self.audioPlaying = NO;
					return;
				}
				else if ( [_acapelaTTS.paragraphWords count] == 0 ) {
					// empty paragraph, go to the next.
					continue;
				}
				else
					break;
			}
			if ( wordOffset != 0 ) 
				[_acapelaTTS adjustParagraphWords];
		}
        else {
            [book getCurrentParagraphId:&paragraphId wordOffset:&wordOffset];
            // Play button has just been pushed.
            if ( (paragraphId + wordOffset)!=[_acapelaTTS currentPage] ) {
                // Starting speech for the first time, or for the first time since changing the 
                // page or book after stopping speech the last time (whew).
                [_acapelaTTS setCurrentPage:(paragraphId + wordOffset)]; // Not very robust page-identifier
                [_acapelaTTS setCurrentWordOffset:wordOffset];
                [_acapelaTTS setCurrentParagraph:(id)paragraphId];
                [_acapelaTTS setParagraphWords:[book paragraphWordsForParagraphWithId:(uint32_t)[_acapelaTTS currentParagraph]]];
				if ( wordOffset != 0 ) 
					// The first paragraphs words displayed on this page are not at 
					// the beginning of the paragraph.
					[_acapelaTTS adjustParagraphWords];
            }
			else
				// use the current word and paragraph, which is where we last stopped.
				// edge case:  what if you stopped speech right after the end of the paragraph?
				[_acapelaTTS adjustParagraphWords];
        }
        [_acapelaTTS setTextToSpeakChanged:YES];
	}
}

- (BOOL)isEucalyptusWord:(NSRange)characterRange ofString:(NSString*)string {
	// For testing
	NSString* thisWord = [string substringWithRange:characterRange];
	NSLog(@"%@", thisWord);
	
	BOOL wordIsNotPunctuation = ([string rangeOfCharacterFromSet:[[NSCharacterSet punctuationCharacterSet] invertedSet]
                                                         options:0 
                                                           range:characterRange].location != NSNotFound);
	// Hacks to get around Acapela bugs.
	BOOL wordIsNotRepeated = ([[string substringWithRange:characterRange] compare:[_acapelaTTS currentWord]] != NSOrderedSame)
    && ([[[NSString stringWithString:@"\""] stringByAppendingString:[string substringWithRange:characterRange]] compare:[_acapelaTTS currentWord]] != NSOrderedSame)
    && ([[[NSString stringWithString:@"“"] stringByAppendingString:[string substringWithRange:characterRange]] compare:[_acapelaTTS currentWord]] != NSOrderedSame); // E.g. "I and I 
	
	BOOL wordDoesNotBeginWithApostrophe = ([[[string substringWithRange:characterRange] substringToIndex:1] compare:@"'"] != NSOrderedSame)
	&& ([[[string substringWithRange:characterRange] substringToIndex:1] compare:@"’"] != NSOrderedSame);  
	
	/* Acapela does assemble hyphenated words, so I'm keeping this condition around
     just in case it turns out they slip up sometimes.
     // possible problem:  hyphen as a pause ("He waited- and then spoke.")
     NSRange lastCharacter;
     lastCharacter.length = 1;
     lastCharacter.location = characterRange.location + characterRange.length -1;
     BOOL wordIsNotHyphenated = ([[string substringWithRange:lastCharacter] compare:@"-"] != NSOrderedSame);
	 */
	
	return wordIsNotPunctuation && wordIsNotRepeated && wordDoesNotBeginWithApostrophe;
}

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	if (finishedSpeaking) {
		// Reached end of paragraph.  Start on the next.
		[self prepareTextToSpeak:YES]; 
	}
	//else stop button pushed before end of paragraph.
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
    if(characterRange.location + characterRange.length <= string.length) {
		if ( [self isEucalyptusWord:characterRange ofString:string] ) {
            BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
            BlioEPubView *bookView = (BlioEPubView *)bookViewController.bookView;
            [bookView highlightWordAtParagraphId:(uint32_t)_acapelaTTS.currentParagraph wordOffset:_acapelaTTS.currentWordOffset];
            [_acapelaTTS setCurrentWordOffset:[_acapelaTTS currentWordOffset]+1];
			[_acapelaTTS setCurrentWord:[string substringWithRange:characterRange]];  
        }
    }
}

- (void)stopAudio {			
		if (![self.book audioRights]) 
			[_acapelaTTS stopSpeaking];
		else if ([self.book audiobookFilename] != nil) 
			[_audioBookManager stopAudio];
}

- (void)pauseAudio {			
	if (![self.book audioRights]) 
		[_acapelaTTS stopSpeaking]; // TODO: Acapela pause may not do here
	else if ([self.book audiobookFilename] != nil) 
		[_audioBookManager pauseAudio];
}
	
/* For multiple timing files, temporary handling as resources
- (BOOL)findTimingFile:(NSInteger)layoutPage {
	switch (layoutPage) {
		case 5:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath5]];
			return YES;
		case 6:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath6]];
			return YES;
		case 7:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath7]];
			return YES;
		case 8:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath8]];
			return YES;
		case 9:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath9]];
			return YES;
		case 11:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath11]];
			return YES;
		case 12:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath12]];
			return YES;
		case 14:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath14]];
			return YES;
		case 16:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath16]];
			return YES;
		case 17:
			[_audioBookManager setAudioTiming:[self.book audiotimingPath17]];
			return YES;
		default:
			return NO;
	}
}
 */

- (void)toggleAudio:(id)sender {
	if ([self currentPageLayout] == kBlioPageLayoutPlainText || [self currentPageLayout] == kBlioPageLayoutPageLayout) {
		UIBarButtonItem *item = (UIBarButtonItem *)sender;
		
		UIImage *audioImage = nil;
		if (self.audioPlaying) {
			[self pauseAudio];
			audioImage = [UIImage imageNamed:@"icon-play.png"];
		} else { 
			if (!self.navigationController.toolbarHidden) {
                [self toggleToolbars];
            }
			if (![self.book audioRights]) {
				if (_acapelaTTS == nil) {
					_acapelaTTS = [[AcapelaTTS alloc] init];
					[_acapelaTTS initTTS];
					[_acapelaTTS setDelegate:self];
					[_acapelaTTS setRate:180];   // Will get from settings.
					[_acapelaTTS setVolume:70];  // Likewise.
					[_acapelaTTS setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(speakNextPargraph:) userInfo:nil repeats:YES]];
				}
				[self prepareTextToSpeak:NO];
			}
			else if ([self.book audiobookFilename] != nil) {
				if ( _audioBookManager == nil || _audioBookManager.startedPlaying == NO ) { 
					// Temporary.  If multiple timing files, will match page number to lowest numbered filename.
					if ( [self.bookView.pageBookmarkPoint layoutPage] != 5 )  {
						// Must be on right page to start reading.  This assumes we can only start playing at the beginning of an mp3,
						// don't know of an audio api where we could start at a selected word.
						// Alternative is to go that page; don't think so.
						return;
					}
					if ( _audioBookManager == nil )
						_audioBookManager = [[BlioAudioBookManager alloc] initWithAudioBook:[self.book audiobookPath] audioTiming:[self.book audiotimingPath]]; 
					else {
						if ( ![_audioBookManager setAudioBook:[self.book audiobookPath]] ) {
							NSLog(@"Audio player could not be initialized.");
							return;
						}
						[_audioBookManager setAudioTiming:[self.book audiotimingPath]];
					}
					[_audioBookManager setStartedPlaying:YES];
				}
				[_audioBookManager playAudio];
			}
			audioImage = [UIImage imageNamed:@"icon-pause.png"];
		}
		self.audioPlaying = !self.audioPlaying;  
		[item setImage:audioImage];
	} 
}


- (void)dummyShowParsedText:(id)sender {
    if ([self.bookView isKindOfClass:[BlioLayoutView class]]) {
        UITextView *aTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
        [aTextView setEditable:NO];
        [aTextView setContentInset:UIEdgeInsetsMake(10, 0, 10, 0)];
        NSInteger pageIndex = self.bookView.pageNumber - 1;
        [aTextView setText:[[self.book textFlow] stringForPageAtIndex:pageIndex]];
        [aTextView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        UIViewController *aVC = [[UIViewController alloc] init];
        aVC.view = aTextView;
        [aTextView release];
        UINavigationController *aNC = [[UINavigationController alloc] initWithRootViewController:aVC];
        [self presentModalViewController:aNC animated:YES];
        aVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dummyDismissParsedText:)];                                                 
        aVC.navigationItem.title = [NSString stringWithFormat:@"Page %d Text", self.bookView.pageNumber];
        aNC.navigationBar.tintColor = _returnToNavigationBarTint;
        [aVC release];
        [aNC release];
    } else {
        BlioLightSettingsViewController *controller = [[BlioLightSettingsViewController alloc] initWithNibName:@"Lighting"
                                                                                                        bundle:[NSBundle mainBundle]];
        controller.pageTurningView = [(BlioEPubView *)self.bookView pageTurningView];
        [self.navigationController presentModalViewController:controller animated:YES];
        [controller release];
    }
}
                                                  
- (void)dummyDismissParsedText:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Add ActionSheet Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == kBlioLibraryAddNoteAction) {
        if (_pageJumpView && !_pageJumpView.hidden) [self performSelector:@selector(togglePageJumpPanel)];
        UIView *container = self.navigationController.visibleViewController.view;
        NSString *pageNumber = [self currentPageNumber];
        BlioNotesView *aNotesView = [[BlioNotesView alloc] initWithPage:pageNumber];
        [aNotesView setDelegate:self];
        [aNotesView showInView:container];
        [aNotesView release];
    } else if (buttonIndex == kBlioLibraryAddBookmarkAction) {
        BlioBookmarkPoint *currentBookmark = self.bookView.pageBookmarkPoint;
        
        NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
        NSManagedObject *existingBookmark = nil;
        
        for (NSManagedObject *bookmark in bookmarks) {
            if (([[bookmark valueForKey:@"layoutPage"] integerValue] == currentBookmark.layoutPage) &&
                ([[bookmark valueForKey:@"ePubParagraphId"] integerValue] == currentBookmark.ePubParagraphId) &&
                ([[bookmark valueForKey:@"ePubWordOffset"] integerValue] == currentBookmark.ePubWordOffset) &&
                ([[bookmark valueForKey:@"ePubHyphenOffset"] integerValue] == currentBookmark.ePubHyphenOffset)) {
                existingBookmark = bookmark;
                break;
            }
        }
        
        if (nil != existingBookmark) return;
        
        NSString *bookmarkText = nil;
        if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
            EucEPubBook *book = (EucEPubBook*)[(BlioEPubView *)self.bookView book];
            uint32_t paragraphId, wordOffset;
            [book getCurrentParagraphId:&paragraphId wordOffset:&wordOffset];
            bookmarkText = [[book paragraphWordsForParagraphWithId:paragraphId] componentsJoinedByString:@" "];
        } else if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
            NSInteger pageIndex = self.bookView.pageNumber - 1;
            bookmarkText = [[self.book textFlow] stringForPageAtIndex:pageIndex];
        }
        
        NSManagedObject *newBookmark = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"Bookmark"
                                     inManagedObjectContext:[self managedObjectContext]];
        
        [newBookmark setValue:[NSNumber numberWithInteger:currentBookmark.layoutPage] forKey:@"layoutPage"];
        [newBookmark setValue:[NSNumber numberWithInteger:currentBookmark.ePubParagraphId] forKey:@"ePubParagraphId"];
        [newBookmark setValue:[NSNumber numberWithInteger:currentBookmark.ePubWordOffset] forKey:@"ePubWordOffset"];
        [newBookmark setValue:[NSNumber numberWithInteger:currentBookmark.ePubHyphenOffset] forKey:@"ePubHyphenOffset"];
        [newBookmark setValue:bookmarkText forKey:@"bookmarkText"];
        [bookmarks addObject:newBookmark];
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
    }
}

- (void)notesViewCreateNote:(BlioNotesView *)notesView {
    BlioBookmarkPoint *currentBookmark = self.bookView.pageBookmarkPoint;
    
    NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
        
    NSManagedObject *newNote = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Note"
                                    inManagedObjectContext:[self managedObjectContext]];
    
    [newNote setValue:[NSNumber numberWithInteger:currentBookmark.layoutPage] forKey:@"layoutPage"];
    [newNote setValue:[NSNumber numberWithInteger:currentBookmark.ePubParagraphId] forKey:@"ePubParagraphId"];
    [newNote setValue:[NSNumber numberWithInteger:currentBookmark.ePubWordOffset] forKey:@"ePubWordOffset"];
    [newNote setValue:[NSNumber numberWithInteger:currentBookmark.ePubHyphenOffset] forKey:@"ePubHyphenOffset"];
    [newNote setValue:notesView.textView.text forKey:@"noteText"];
    [notes addObject:newNote];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
}

- (void)notesViewUpdateNote:(BlioNotesView *)notesView {
    if (nil != notesView.note) {
        [notesView.note setValue:notesView.textView.text forKey:@"noteText"];
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
    }
}

#pragma mark -
#pragma mark Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
	// Return YES for supported orientations
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView beginAnimations:@"rotateBookView" context:nil];
    [UIView setAnimationDuration:duration];
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [self.bookView setFrame:CGRectMake(0,0,320,480)];
    } else {
        [self.bookView setFrame:CGRectMake(0,0,480,320)];
    }
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark BlioContentsTabViewControllerDelegate

- (void)dismissContentsTabView:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showNote:(NSManagedObject *)note animated:(BOOL)animated {
    if (_pageJumpView && !_pageJumpView.hidden) [self performSelector:@selector(togglePageJumpPanel)];
    UIView *container = self.navigationController.visibleViewController.view;
    NSString *pageNumber = [self currentPageNumber];
    
    BlioNotesView *aNotesView = [[BlioNotesView alloc] initWithPage:pageNumber note:note];
    [aNotesView setDelegate:self];
    [aNotesView showInView:container animated:animated];
    [aNotesView release];
}

- (void)goToContentsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    NSInteger newPageNumber = [self.bookView pageNumberForBookmarkPoint:bookmarkPoint];
    
    [self updatePageJumpPanelForPage:newPageNumber animated:animated];
    [self updatePieButtonForPage:newPageNumber animated:animated];
    [_bookView goToBookmarkPoint:bookmarkPoint animated:animated];
}

- (void)goToContentsUuid:(NSString *)sectionUuid animated:(BOOL)animated {
    NSInteger newPageNumber = [[self.bookView contentsDataSource] pageNumberForSectionUuid:sectionUuid];

    [self updatePageJumpPanelForPage:newPageNumber animated:animated];
    [self updatePieButtonForPage:newPageNumber animated:animated];
    [_bookView goToUuid:sectionUuid animated:animated];
}

- (void)deleteNote:(NSManagedObject *)note {
    NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
    [notes removeObject:note];
    [[self managedObjectContext] deleteObject:note];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
}

- (void)deleteBookmark:(NSManagedObject *)bookmark {
    NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
    [bookmarks removeObject:bookmark];
    [[self managedObjectContext] deleteObject:bookmark];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
}

@end
