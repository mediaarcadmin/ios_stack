//
//  BlioStoreEntityController.h
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreBooksSourceParser.h"

@interface BlioStoreBookViewController : UIViewController {
    NSOperationQueue *fetchThumbQueue;
    BlioStoreParsedEntity *entity;
    UIScrollView *scroller;
    UIView *container;
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
}

@property (nonatomic, retain) NSOperationQueue *fetchThumbQueue;
@property (nonatomic, retain) BlioStoreParsedEntity *entity;
@property (nonatomic, retain) IBOutlet UIScrollView *scroller;
@property (nonatomic, retain) IBOutlet UIView *container;
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

@end
