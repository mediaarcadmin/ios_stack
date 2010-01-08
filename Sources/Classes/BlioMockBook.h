//
//  MockBook.h
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BlioMockBook : NSManagedObject {
    UIImage *coverThumb;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *coverFilename;
@property (nonatomic, retain) NSString *epubFilename;
@property (nonatomic, retain) NSString *pdfFilename;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *proportionateSize;
@property (nonatomic, retain) NSNumber *position;
@property (nonatomic, retain) NSNumber *layoutPageNumber;

- (UIImage *)coverImage;
- (UIImage *)coverThumbForGrid;
- (UIImage *)coverThumbForList;
- (NSString *)bookPath;
- (NSString *)pdfPath;

@end
