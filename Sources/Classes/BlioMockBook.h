//
//  MockBook.h
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BlioMockBook : NSObject {
    NSString *title;
    NSString *author;
    NSString *coverPath;
    NSString *bookPath;
    NSString *pdfPath;
    CGFloat progress;
    CGFloat proportionateSize;
    UIImage *coverThumb;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *coverPath;
@property (nonatomic, retain) NSString *bookPath;
@property (nonatomic, retain) NSString *pdfPath;
@property (nonatomic) CGFloat progress;
@property (nonatomic) CGFloat proportionateSize;

- (UIImage *)coverImage;
- (UIImage *)coverThumb;

@end
