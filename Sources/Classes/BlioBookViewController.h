//
//  BookViewController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
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

@protocol BlioViewSettingsDelegate <NSObject>
@required
- (BOOL)shouldShowFontSizeSettings;
- (BOOL)shouldShowJustificationSettings;
- (BOOL)shouldShowPageColorSettings;
- (BOOL)shouldShowTapZoomsToBlockSettings;
- (BOOL)shouldShowTwoUpLandscapePageSettings;

- (BOOL)shouldPresentBrightnessSliderVerticallyInPageSettings;
- (BOOL)shouldShowDoneButtonInPageSettings;

- (void)changePageLayout:(BlioPageLayout)newLayout;
- (void)changeFontSizeIndex:(NSUInteger)newSize;
- (void)changeJustification:(BlioJustification)sender;
- (void)changePageColor:(BlioPageColor)sender;
- (void)changeTapZooms:(BOOL)newTabZooms;
- (void)changeTwoUpLandscapePage:(BOOL)shouldBeTwoUp;
- (void)toggleRotationLock;

- (BOOL)reflowEnabled;
- (BOOL)fixedViewEnabled;
- (BlioJustification)currentJustification;
- (BlioPageLayout)currentPageLayout;
- (BlioPageColor)currentPageColor;
- (NSUInteger)currentFontSizeIndex;
- (NSUInteger)fontSizeCount;
- (BOOL)isRotationLocked;

- (void)dismissViewSettings:(id)sender;
- (void)viewSettingsDidDismiss:(id)sender;
@end

@class BlioBookViewControllerProgressPieButton, BlioModalPopoverController, BlioBookSlider, BlioBookSliderPreview;
@protocol EucBook, BlioBookView;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface BlioBookViewController : UIViewController <BlioBookViewDelegate, THEventCaptureObserver,UIActionSheetDelegate,UIAccelerometerDelegate, BlioNotesViewDelegate, BlioContentsTabViewControllerDelegate, BlioViewSettingsDelegate, AVAudioPlayerDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate> {
    BOOL _firstAppearance;
    
    UIView *_rootView;
    
    BlioBook *_book;
    
    UIView<BlioBookView> *_bookView;
    
    BookViewControllerUIFadeState _fadeState;
    
    UIToolbar *_toolbar;
    UIView *_pauseMask;
    UIButton *_pauseButton;
    
    UITouch *_touch;
    BOOL _touchMoved;
    
    BOOL _viewIsDisappearing;
        
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
	BOOL _audioEnabled;
    
    id<BlioParagraphSource> _audioParagraphSource;
        
    BlioPageColor _currentPageColor;
    
    UIBarButtonItem* _pageJumpButton;
    UIView* _pageJumpView;
    UILabel* _pageJumpLabel;
    BlioBookSlider* _pageJumpSlider;
    BlioBookViewControllerProgressPieButton *_pieButton;
    NSManagedObjectContext *_managedObjectContext;
    BOOL rotationLocked;
    
    NSUInteger _toolbarState;
    NSUInteger _beforeModalOverlayToolbarState;
    
    BlioBookSearchViewController *searchViewController;
    id <BlioCoverViewDelegate> delegate;
    BlioCoverView *coverView;
    
    BOOL bookReady;
    BOOL coverReady;
    BOOL firstPageReady;
    BOOL coverOpened;
    
    BlioViewSettingsSheet *viewSettingsSheet;
    BlioModalPopoverController *viewSettingsPopover;
    BlioModalPopoverController *contentsPopover;
    BlioModalPopoverController *searchPopover;
    UIBarButtonItem* contentsButton;
    UIBarButtonItem* viewSettingsButton;
    UIBarButtonItem* searchButton;
	UIBarButtonItem* backButton;
    BOOL shouldDisplaySearchAfterRotation;
    
    UIPopoverController *wordToolPopoverController;
    
    NSMutableArray *historyStack;
	BlioBookSliderPreview *thumbPreview;
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
@property (nonatomic, assign) BOOL audioEnabled;

@property (nonatomic, retain) BlioBookViewControllerProgressPieButton *pieButton;
@property (nonatomic, retain) UIView *pauseMask;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, getter=isRotationLocked) BOOL rotationLocked;

@property (nonatomic, assign) id <BlioCoverViewDelegate> delegate;
@property (nonatomic, retain) BlioCoverView *coverView;

@property (nonatomic, retain, readonly) UIImage *dimPageImage;

- (void)stopAudio;
- (void)pauseAudio;
- (void)toggleAudio:(id)sender;

- (void)incrementPage;
- (void)decrementPage;

@end