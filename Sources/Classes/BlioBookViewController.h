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
#import "AcapelaTTS.h"
#import "BlioAudioBookManager.h"
#import "BlioMockBook.h"
#import "BlioBookView.h"
#import "BlioViewSettingsSheet.h"
#import "BlioNotesView.h"
#import "BlioContentsTabViewController.h"
#import "BlioWebToolsViewController.h"
#import "MSTiltScroller.h"
#import "MSTapDetector.h"

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
- (BOOL)shouldShowPageAttributeSettings;
- (void)dismissViewSettings:(id)sender;
- (BOOL)isRotationLocked;
- (void)changeLockRotation;
- (BlioPageLayout)currentPageLayout;
- (BlioTapTurn)currentTapTurn;
- (void)changeTapTurn;
- (BlioPageColor)currentPageColor;
- (BlioFontSize)currentFontSize;
@end

@class EucBookContentsTableViewController, BlioBookViewControllerProgressPieButton;
@protocol EucBook, BlioBookView;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface BlioBookViewController : UIViewController <BlioBookDelegate, THEventCaptureObserver,UIActionSheetDelegate,UIAccelerometerDelegate, BlioNotesViewDelegate, BlioContentsTabViewControllerDelegate, BlioViewSettingsDelegate, AVAudioPlayerDelegate> {
    BOOL _firstAppearance;
    
    BlioMockBook *_book;
    
    UIView<BlioBookView> *_bookView;
    
    BookViewControllerUIFadeState _fadeState;
    
    UIToolbar *_toolbar;
    
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
    
	AcapelaTTS* _acapelaTTS;
	BlioAudioBookManager* _audioBookManager;
    BOOL _audioPlaying;
    
    MSTiltScroller *tiltScroller;
    MSTapDetector *tapDetector;
    BOOL motionControlsEnabled;
    
    BlioPageColor _currentPageColor;
    
    UIBarButtonItem* _pageJumpButton;
    UIView* _pageJumpView;
    UILabel* _pageJumpLabel;
    UISlider* _pageJumpSlider;
    BlioBookViewControllerProgressPieButton *_pieButton;
    NSManagedObjectContext *_managedObjectContext;
    BOOL rotationLocked;
}

// Designated initializers.
- (id)initWithBook:(BlioMockBook *)newBook;

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@property (nonatomic, assign) BlioPageColor currentPageColor;

@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) BOOL audioPlaying;

@property (nonatomic, retain) MSTiltScroller *tiltScroller;
@property (nonatomic, retain) MSTapDetector *tapDetector;
@property (nonatomic, assign) BOOL motionControlsEnabled;

@property (nonatomic, retain) UIView *pageJumpView;
@property (nonatomic, retain) BlioBookViewControllerProgressPieButton *pieButton;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, getter=isRotationLocked) BOOL rotationLocked;

- (void)setupTiltScrollerWithBookView;
- (void)tapToNextPage;
- (void)stopAudio;

+ (AcapelaTTS**)getTTSEngine;

@end