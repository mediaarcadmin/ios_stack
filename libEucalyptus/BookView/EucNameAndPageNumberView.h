//
//  NameAndPageNumberView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 23/01/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EucNameAndPageNumberView : UIView {
    NSString *_name;
    NSString *_subTitle;
    NSString *_pageNumber;
    UIColor *_textColor;
    NSUInteger _indentationWidth;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *subTitle;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) NSString *pageNumber;
@property (nonatomic, assign) NSUInteger indentationWidth;

+ (CGFloat)heightForWidth:(CGFloat)width withName:(NSString *)name subTitle:(NSString *)subTitle pageNumber:(NSString *)pageNumber;

@end
