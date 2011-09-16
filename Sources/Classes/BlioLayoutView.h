//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioTextFlow.h"
#import "BlioBookView.h"
#import "BlioSelectableBookView.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucSelector.h>
#import "BlioLayoutDataSource.h"
#import "BlioXPSProvider.h"
#import <libEucalyptus/EucIndexBasedPageTurningView.h>

@class BlioGestureSuppressingView;

@interface BlioLayoutView : BlioSelectableBookView <EucPageTurningViewDelegate, EucIndexBasedPageTurningViewDataSource, BlioBookView, EucSelectorDataSource, EucSelectorDelegate, UIWebViewDelegate, UIGestureRecognizerDelegate> {
    NSManagedObjectID *bookID;
    EucIndexBasedPageTurningView *pageTurningView;
    
    BOOL twoUpLandscape;
    BOOL shouldTapZoom;
    
    BlioTextFlow *textFlow;
    
    EucSelector *selector;
    NSMutableDictionary *pageCropsCache;
    NSMutableDictionary *viewTransformsCache;
    
    NSInteger pageNumber;
    NSInteger pageCount;
    CGRect firstPageCrop;
    CGSize pageSize;

    BlioBookmarkPoint *currentBookmarkPoint;
    
    BlioXPSProvider *xpsProvider;
    id<BlioLayoutDataSource> dataSource;
    
    NSLock *layoutCacheLock;
    NSLock *hyperlinksCacheLock;
	NSLock *enhancedContentCacheLock;
	
    BOOL pageViewIsTurning;
	BOOL suppressHistoryAfterTurn;
	BlioBookmarkRange *temporaryHighlightRange;
    
    BlioTextFlowBlock *lastBlock;
    NSUInteger blockRecursionDepth;
    
    BOOL performingAccessibilityZoom;
	
	NSArray *accessibilityElements;
	UIAccessibilityElement *prevZone;
	UIAccessibilityElement *nextZone;
	UIAccessibilityElement *pageZone;
    
    NSMutableArray *accessibilityLinesCache;
    
	NSMutableArray *mediaViews;
	NSMutableArray *webViews;
	
	UIImage *pageAlphaMask;
	UIColor *pageMultiplyColor;
    BlioGestureSuppressingView *overlay;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) EucIndexBasedPageTurningView *pageTurningView;

@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) NSMutableDictionary *pageCropsCache;
@property (nonatomic, retain) NSMutableDictionary *viewTransformsCache;
@property (nonatomic, retain) NSMutableDictionary *hyperlinksCache;

@end
