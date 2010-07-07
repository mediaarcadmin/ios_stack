//
//  BlioSpeedReadView.h
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookView.h>
#import "BlioBookView.h"

@protocol BlioParagraphSource;


@interface BlioSpeedReadView : UIView <BlioBookView, EucBookContentsTableViewControllerDataSource> {
    CGPDFDocumentRef pdf;
    UIScrollView *scrollView;
    UIView *containerView;
    NSMutableArray *pageViews;
    id navigationController;
    NSInteger visiblePageIndex;
    
    NSInteger pageNumber;
    NSInteger pageCount;
    
    id<BlioParagraphSource> paragraphSource;
    id currentParagraphID;
	uint32_t currentWordOffset;
        
    UIView *fingerImageHolder;
    CALayer *fingerImage;
    CALayer *backgroundImage;
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

@property (nonatomic, retain) UIView *fingerImageHolder;
@property (nonatomic, retain) CALayer *fingerImage;
@property (nonatomic, retain) CALayer *backgroundImage;

- (float)speedForYValue:(float)y;
- (float)calculateFingerXValueFromY:(float)y;
- (BOOL)fillArrayWithNextBlock;
- (BOOL)fillArrayWithCurrentBlock;

@property (nonatomic) float speed;

@property (nonatomic, retain) UIFont *font;


@property (nonatomic, retain) NSTimer *nextWordTimer;

@property (nonatomic, retain) UILabel *bigTextLabel;
@property (nonatomic, retain) UILabel *sampleTextLabel;


@end
