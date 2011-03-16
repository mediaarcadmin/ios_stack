//
//  BlioSpeedReadView.h
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookView.h>
#import <CoreData/CoreData.h>
#import "BlioBookView.h"
#import "BlioBookViewController.h"

@protocol BlioParagraphSource;


@interface BlioSpeedReadView : UIView <BlioBookView, EucBookContentsTableViewControllerDataSource> {
    NSManagedObjectID *bookId;
    
    NSInteger pageNumber;
    NSInteger pageCount;
    
    id<BlioParagraphSource> paragraphSource;
    id<BlioBookViewDelegate> delegate;
    id currentParagraphID;
	int32_t currentWordOffset;
    
    UIView *fingerImageHolder;
    CALayer *fingerImage;
    
    CALayer *backgroundImageLandscape;    
    CALayer *backgroundImage;
    CALayer *roundCornersLandscape;    
    CALayer *roundCorners;
    
    float initialTouchDifference;
    
    float initialFontSize;
    float currentFontSize;
    float zooming;
    
    
    UILabel *bigTextLabel;
	UILabel *sampleTextLabel;
    
	float speed;
	
	UIFont* font;
    
	NSArray *textArray;
	
	NSTimer *nextWordTimer;
}

@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) NSInteger pageNumber;

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;
@property (nonatomic, readonly) CGRect firstPageRect;

- (float)speedForYValue:(float)y;
- (float)calculateFingerXValueFromY:(float)y;
- (BOOL)fillArrayWithNextBlock;
- (BOOL)fillArrayWithCurrentBlock;

- (void)setColor:(BlioPageColor)newColor;

@property (nonatomic) float speed;

@property (nonatomic, retain) UIFont *font;


@property (nonatomic, retain) NSTimer *nextWordTimer;

@property (nonatomic, retain) UILabel *bigTextLabel;
@property (nonatomic, retain) UILabel *sampleTextLabel;

@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;

@end
