//
//  BlioViewSettingsContentsView.h
//  BlioApp
//
//  Created by James Montgomerie on 01/10/2012.
//
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"

@protocol BlioViewSettingsContentsViewDelegate;

@interface BlioViewSettingsContentsView : UIView

@property (nonatomic, assign, readonly) id<BlioViewSettingsContentsViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize preferredSize;
@property (nonatomic, retain, readonly) NSString *navigationItemTitle;

- (id)initWithDelegate:(id)delegate;

- (void)refreshSettings;
- (void)flashScrollIndicators;

@end

@protocol BlioViewSettingsContentsViewDelegate <NSObject>
@required
- (BOOL)shouldShowFontSettings;
- (BOOL)shouldShowFontSizeSettings;
- (BOOL)shouldShowJustificationSettings;
- (BOOL)shouldShowPageColorSettings;
- (BOOL)shouldShowtapZoomsSettings;
- (BOOL)shouldShowTwoUpLandscapeSettings;

- (BOOL)shouldPresentBrightnessSliderVerticallyInPageSettings;
- (BOOL)shouldShowDoneButtonInPageSettings;

- (void)changePageLayout:(BlioPageLayout)newLayout;
- (void)changeFontName:(NSString *)fontName;
- (void)changeFontSizeIndex:(NSUInteger)newSize;
- (void)changeJustification:(BlioJustification)sender;
- (void)changePageColor:(BlioPageColor)sender;
- (void)changeTapZooms:(BOOL)newTabZooms;
- (void)changeTwoUpLandscape:(BOOL)shouldBeTwoUp;

- (BOOL)reflowEnabled;
- (BOOL)fixedViewEnabled;

- (BlioPageLayout)currentPageLayout;
- (NSString *)currentFontName;
- (NSUInteger)fontSizeCount;
- (NSUInteger)currentFontSizeIndex;
- (BlioJustification)currentJustification;
- (BlioPageColor)currentPageColor;
- (BOOL)currentTapZooms;
- (BOOL)currentTwoUpLandscape;

- (NSArray *)fontDisplayNames;
- (NSString *)fontDisplayNameToFontName:(NSString *)fontDisplayName;
- (NSString *)fontNameToFontDisplayName:(NSString *)fontDisplayName;

- (void)dismissViewSettingsInterface:(id)sender;

@end
