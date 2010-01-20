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

@interface BlioSpeedReadView : UIView <BlioBookView> {
    CGPDFDocumentRef pdf;
    UIScrollView *scrollView;
    UIView *containerView;
    NSMutableArray *pageViews;
    id navigationController;
    NSInteger visiblePageIndex;


    NSInteger pageNumber;
    NSInteger pageCount;
    
    uint32_t currentParagraph;
	uint32_t currentWordOffset;
	uint32_t currentPage;

    EucBookReference<EucBook> *book;
    
    UIView *fingerImageHolder;
    CALayer *fingerImage;
    CALayer *backgroundImage;
    
    
    UILabel *bigTextLabel;
	
	float speed;
	
    
	UIFont* font;
    
	NSMutableArray *textArray;
	
	NSTimer *nextWordTimer;



    
}



- (id)initWithFrame:(CGRect)frame book:(EucBookReference<EucBook> *)eucBook;

@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) NSInteger pageNumber;

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;
@property (nonatomic, readonly) CGRect firstPageRect;

@property (nonatomic) uint32_t currentParagraph;
@property (nonatomic) uint32_t currentWordOffset;
@property (nonatomic) uint32_t currentPage;

@property (nonatomic, retain) EucBookReference<EucBook> *book;

@property (nonatomic, retain) UIView *fingerImageHolder;
@property (nonatomic, retain) CALayer *fingerImage;
@property (nonatomic, retain) CALayer *backgroundImage;

- (float)speedForYValue:(float)y;
- (float)calculateFingerXValueFromY:(float)y;
- (void)fillArrayWithNextParagraph;
- (void)fillArrayWithCurrentParagraph;

@property (nonatomic) float speed;

@property (nonatomic, retain) UIFont *font;

@property (nonatomic, retain) NSMutableArray *textArray;

@property (nonatomic, retain) NSTimer *nextWordTimer;

@property (nonatomic, retain) UILabel *bigTextLabel;


@end
