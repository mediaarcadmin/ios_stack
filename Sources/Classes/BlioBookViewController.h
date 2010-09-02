//
//  BookViewController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/THEventCapturingWindow.h>
#import "BlioAcapelaAudioManager.h"
#import "BlioAudioBookManager.h"
#import "BlioBook.h"
#import "BlioBookView.h"
#import "BlioViewSettingsSheet.h"
#import "BlioNotesView.h"
#import "BlioContentsTabViewController.h"
#import "BlioWebToolsViewController.h"
#import "BlioBookSearchController.h"
#import "BlioBookSearchViewController.h"
#import "BlioCoverView.h"

typedef enum BlioPageColor {
    kBlioPageColorWhite = 0,
    kBlioPageColorBlack = 1,
    kBlioPageColorNeutral = 2,
} BlioPageColor;

typedef enum BlioPageLayout {
    kBlioPageLayoutPlainText = 0,
    kBlioPageLayoutPageLayout = 1,
    kBlioPageLayoutSpeedRead = 2,
} BlioPageLayout;

typedef enum BlioTapTurn {
    kBlioTapTurnOff = 0,
    kBlioTapTurnOn = 1,
} BlioTapTurn;

typedef enum BlioFontSize {
    kBlioFontSizeVerySmall = 0,
    kBlioFontSizeSmall = 1,
    kBlioFontSizeMedium = 2,
    kBlioFontSizeLarge = 3,
    kBlioFontSizeVeryLarge = 4,
} BlioFontSize;

@protocol BlioViewSettingsDelegate <NSObject>
@required
- (void)changePageLayout:(id)sender;
- (BOOL)shouldShowFontSizeSettings;
- (BOOL)shouldShowPageColorSettings;
- (void)dismissViewSettings:(id)sender;
- (BOOL)isRotationLocked;
- (void)changeLockRotation;
- (BlioPageLayout)currentPageLayout;
- (BlioPageColor)currentPageColor;
- (BlioFontSize)currentFontSize;
- (BOOL)reflowEnabled;
@end

@class EucBookContentsTableViewController, BlioBookViewControllerProgressPieButton;
@protocol EucBook, BlioBookView;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface BlioBookViewController : UIViewController <BlioBookViewDelegate, THEventCaptureObserver,UIActionSheetDelegate,UIAccelerometerDelegate, BlioNotesViewDelegate, BlioContentsTabViewControllerDelegate, BlioViewSettingsDelegate, AVAudioPlayerDelegate> {
    BOOL _firstAppearance;
    
    BlioBook *_book;
    
    UIView<BlioBookView> *_bookView;
    
    BookViewControllerUIFadeState _fadeState;
    
    UIToolbar *_toolbar;
    UIButton *_pauseButton;
    
    UITouch *_touch;
    BOOL _touchMoved;
            
    //EucBookContentsTableViewController *_contentsSheet;
    
    BOOL _viewIsDisappearing;
    NSUInteger _lastSavedPageNumber;
        
    UIBarStyle _returnToNavigationBarStyle;
    UIColor *_returnToNavigationBarTint;
    BOOL _returnToNavigationBarHidden;
    BOOL _returnToNavigationBarTranslucent;
    UIBarStyle _returnToToolbarStyle;
    UIColor *_returnToToolbarTint;
    BOOL _returnToToolbarTranslucent;
    
    UIStatusBarStyle _returnToStatusBarStyle;
    BOOL _returnToStatusBarHidden;
    
    BOOL _overrideReturnToNavigationBarStyle;
    BOOL _overrideReturnToStatusBarStyle;
    BOOL _overrideReturnToNavigationBarHidden;
    BOOL _overrideReturnToStatusBarHidden;
    
	BlioAcapelaAudioManager* _acapelaAudioManager;
    BOOL _TTSEnabled;
	BlioAudioBookManager* _audioBookManager;
    BOOL _audioPlaying;
    
    BOOL motionControlsEnabled;
    
    BlioPageColor _currentPageColor;
    
    UIBarButtonItem* _pageJumpButton;
    UIView* _pageJumpView;
    UILabel* _pageJumpLabel;
    UISlider* _pageJumpSlider;
    BlioBookViewControllerProgressPieButton *_pieButton;
    NSManagedObjectContext *_managedObjectContext;
    BOOL rotationLocked;
    
    BlioBookSearchViewController *searchViewController;
    id <BlioCoverViewDelegate> delegate;
    BlioCoverView *coverView;
    
    BOOL bookReady;
    BOOL coverReady;
    BOOL firstPageReady;
    BOOL coverOpened;
    
    UIActionSheet *viewSettingsSheet;
    UIPopoverController *viewSettingsPopover;
}

// Designated initializers.
- (id)initWithBook:(BlioBook *)newBook delegate:(id <BlioCoverViewDelegate>)aDelegate;

@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@property (nonatomic, assign) BlioPageColor currentPageColor;

@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) BOOL audioPlaying;

@property (nonatomic, assign) BOOL motionControlsEnabled;

@property (nonatomic, retain) UIView *pageJumpView;
@property (nonatomic, retain) BlioBookViewControllerProgressPieButton *pieButton;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, getter=isRotationLocked) BOOL rotationLocked;

@property (nonatomic, assign) id <BlioCoverViewDelegate> delegate;
@property (nonatomic, retain) BlioCoverView *coverView;

- (void)stopAudio;
- (void)pauseAudio;
- (void)toggleAudio:(id)sender;
- (void)incrementPage;
- (void)decrementPage;

@end