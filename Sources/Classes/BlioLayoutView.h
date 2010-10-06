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
#import <libEucalyptus/EucPageTurningView.h>

@interface BlioLayoutView : BlioSelectableBookView <THEventCaptureObserver, EucPageTurningViewDelegate, EucPageTurningViewBitmapDataSource, BlioBookView, EucSelectorDataSource, EucSelectorDelegate> {
    NSManagedObjectID *bookID;
    EucPageTurningView *pageTurningView;
    UIImage *pageTexture;
    BOOL pageTextureIsDark;
    
    BlioTextFlow *textFlow;
    CGPDFDocumentRef pdf;
    
    EucSelector *selector;
    NSMutableDictionary *pageCropsCache;
    NSMutableDictionary *viewTransformsCache;
    
    NSInteger pageNumber;
    NSInteger pageCount;
    CGRect firstPageCrop;
    CGSize pageSize;
       
    BlioXPSProvider *xpsProvider;
    id<BlioLayoutDataSource> dataSource;
    
    NSLock *layoutCacheLock;
    NSLock *hyperlinksCacheLock;
    CGPoint startTouchPoint;
    BOOL hyperlinkTapped;
    
    BlioTextFlowBlock *lastBlock;
    NSUInteger blockRecursionDepth;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) EucPageTurningView *pageTurningView;

@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) NSMutableDictionary *pageCropsCache;
@property (nonatomic, retain) NSMutableDictionary *viewTransformsCache;
@property (nonatomic, retain) NSMutableDictionary *hyperlinksCache;

@end
