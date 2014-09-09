//
//  BlioMedia.h
//  StackApp
//
//  Created by Arnold Chien on 6/10/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <CoreData/CoreData.h>

static const CGFloat kBlioCoverListThumbWidth = 42;
static const CGFloat kBlioCoverListThumbHeight = 64;
static const CGFloat kBlioCoverGridThumbWidthPhone = 84;
static const CGFloat kBlioCoverGridThumbHeightPhone = 118;
static const CGFloat kBlioCoverGridThumbWidthPad = 140;
static const CGFloat kBlioCoverGridThumbHeightPad = 210;

static NSString * const BlioBookThumbnailsDir = @"thumbnails";
static NSString * const BlioBookThumbnailPrefix = @"thumbnail";

@interface BlioMedia : NSManagedObject

@property (nonatomic, retain) NSNumber *libraryPosition;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *processingState;
@property (nonatomic, retain) NSNumber *sourceID;
@property (nonatomic, retain) NSString *sourceSpecificID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *titleSortable;
@property (nonatomic, retain) NSNumber *transactionType;

// TODO relevance of userNum, siteNum in stack?
@property (nonatomic, retain) NSNumber *siteNum;
@property (nonatomic, retain) NSNumber *userNum;

@property (nonatomic, assign, readonly) NSString* cacheDirectory;
@property (nonatomic, assign, readonly) NSString* tempDirectory;

// TODO will need version of this that works for non-books
//@property (nonatomic, assign, readonly) BOOL hasCoverImage;

- (UIImage *)coverImage:(NSData*)imageData;
- (UIImage *)coverThumbForGrid:(NSData*)imageData;
- (UIImage *)coverThumbForList:(NSData*)imageData;
- (BOOL)hasAppropriateCoverThumbForGrid:(NSData*)imageData;
- (BOOL)hasAppropriateCoverThumbForList:(NSData*)imageData;

- (NSString*)getPixelSpecificKeyForGrid;
- (NSString*)getPixelSpecificKeyForList;
- (NSString *)fullPathOfFileSystemItemAtPath:(NSString *)path;
- (NSData *)dataFromFileSystemAtPath:(NSString *)path;

@end
