//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

typedef enum {
  kBlioLibraryLayoutGrid = 0,
  kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

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

typedef enum {
  kBlioPageColorWhite = 0,
  kBlioPageColorBlack = 1,
  kBlioPageColorNeutral = 2,
} BlioPageColor;

typedef enum {
  kBlioRotationLockOff = 0,
  kBlioRotationLockOn = 1,
} BlioRotationLock;

typedef enum {
  kBlioTapTurnOff = 0,
  kBlioTapTurnOn = 1,
} BlioTapTurn;

@class BlioLibraryBookView;

@interface BlioLibraryViewController : UITableViewController <UIActionSheetDelegate> {
  BlioLibraryBookView *_currentBookView;
  NSString *_currentBookPath;
  NSString *_currentPdfPath;
  NSArray *_books;
  BlioLibraryLayout _libraryLayout;
  BOOL _audioPlaying;
}

@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) NSString *currentBookPath;
@property (nonatomic, retain) NSString *currentPdfPath;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic) BOOL audioPlaying;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;

@end
