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

@interface BlioLayoutView : BlioSelectableBookView <EucPageTurningViewDelegate, EucPageTurningViewBitmapDataSource, BlioBookView, EucSelectorDataSource, EucSelectorDelegate> {
    NSManagedObjectID *bookID;
    EucPageTurningView *pageTurningView;
    UIImage *pageTexture;
    BOOL pageTextureIsDark;
    
    BlioTextFlow *textFlow;
    CGPDFDocumentRef pdf;
    NSInteger pageNumber;
    NSInteger pageCount;
    EucSelector *selector;
    NSMutableDictionary *pageCropsCache;
    NSMutableDictionary *viewTransformsCache;
    CGRect firstPageCrop;
    UIImage *pageSnapshot;
    UIImage *highlightsSnapshot;
       
    BlioXPSProvider *xpsProvider;
    id<BlioLayoutDataSource> dataSource;
    
    NSLock *layoutCacheLock;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) EucPageTurningView *pageTurningView;

@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) NSMutableDictionary *pageCropsCache;
@property (nonatomic, retain) NSMutableDictionary *viewTransformsCache;

@end
