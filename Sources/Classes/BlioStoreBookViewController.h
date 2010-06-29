//
//  BlioStoreEntityController.h
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreBooksSourceParser.h"
#import "BlioStoreFeed.h"
#import <CoreData/CoreData.h>

static const CGFloat kBlioBookDetailFieldYMargin = 20;
static const CGFloat kBlioStoreDisabledButtonAlpha = .66;
static const NSUInteger kBlioStoreDownloadButtonStateInitial = 0;
static const NSUInteger kBlioStoreDownloadButtonStateConfirm = 1;
static const NSUInteger kBlioStoreDownloadButtonStateInProcess = 2;
static const NSUInteger kBlioStoreDownloadButtonStateDone = 3;
static const NSUInteger kBlioStoreDownloadButtonStateNoDownload = 4;
extern NSString * const kBlioStoreDownloadButtonStateLabelInitial;
extern NSString * const kBlioStoreDownloadButtonStateLabelConfirm;
extern NSString * const kBlioStoreDownloadButtonStateLabelInProcess;
extern NSString * const kBlioStoreDownloadButtonStateLabelDone;
extern NSString * const kBlioStoreDownloadButtonStateLabelNoDownload;
extern NSString * const BlioProcessingOperationCompleteNotification;

@protocol BlioProcessingDelegate;

@interface BlioStoreBookViewController : UIViewController {
    NSOperationQueue *fetchThumbQueue;
	BlioStoreFeed *feed;
    BlioStoreParsedEntity *entity;
    UIScrollView *scroller;
    UIView *container;
    UIView *downloadButtonContainer;
    UIImageView *downloadButtonBackgroundView;
    UIImageView *bookThumb;
    UIImageView *bookShadow;
    UIView *bookPlaceholder;
    UILabel *bookTitle;
    UILabel *authors;
    UIButton *download;
    UILabel *summary;
    UIView *belowSummaryDetails;
    UILabel *releaseDate;
    UILabel *publicationDate;
    UILabel *pages;
    UILabel *publisher;
    IBOutlet UILabel *releaseDateLabel;
    IBOutlet UILabel *publicationDateLabel;
    IBOutlet UILabel *pagesLabel;
    IBOutlet UILabel *publisherLabel;
    NSUInteger downloadState;
	NSArray * downloadStateLabels;
	UILabel *noBookSelectedView;
    id <BlioProcessingDelegate> processingDelegate;
	NSManagedObjectContext *managedObjectContext;

	UIImageView * _jumpingView;

}

@property (nonatomic, retain) NSOperationQueue *fetchThumbQueue;
@property (nonatomic, retain) BlioStoreFeed *feed;
@property (nonatomic, assign) BlioStoreParsedEntity *entity;
@property (nonatomic, retain) IBOutlet UIScrollView *scroller;
@property (nonatomic, retain) IBOutlet UIView *container;
@property (nonatomic, retain) IBOutlet UIView *downloadButtonContainer;
@property (nonatomic, retain) IBOutlet UIImageView *downloadButtonBackgroundView;
@property (nonatomic, retain) IBOutlet UIImageView *bookThumb;
@property (nonatomic, retain) IBOutlet UIImageView *bookShadow;
@property (nonatomic, retain) IBOutlet UIView *bookPlaceholder;
@property (nonatomic, retain) IBOutlet UILabel *bookTitle;
@property (nonatomic, retain) IBOutlet UILabel *authors;
@property (nonatomic, retain) IBOutlet UIButton *download;
@property (nonatomic, retain) IBOutlet UILabel *summary;
@property (nonatomic, retain) IBOutlet UIView *belowSummaryDetails;
@property (nonatomic, retain) IBOutlet UILabel *releaseDate;
@property (nonatomic, retain) IBOutlet UILabel *publicationDate;
@property (nonatomic, retain) IBOutlet UILabel *pages;
@property (nonatomic, retain) IBOutlet UILabel *publisher;
@property (nonatomic, retain) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, retain) IBOutlet UILabel *publicationDateLabel;
@property (nonatomic, retain) IBOutlet UILabel *pagesLabel;
@property (nonatomic, retain) IBOutlet UILabel *publisherLabel;
@property (nonatomic, retain) IBOutlet UILabel *noBookSelectedView;
@property (nonatomic, retain) NSArray *downloadStateLabels;

@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (IBAction)downloadButtonPressed:(id)sender;
- (void) setDownloadState:(NSUInteger)state animated:(BOOL)animationStatus;

@end
