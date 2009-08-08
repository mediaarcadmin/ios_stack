//
//  NameAndPageNumberView.h
//  Eucalyptus
//
//  Created by James Montgomerie on 23/01/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EucNameAndPageNumberView : UIView {
    NSString *_name;
    NSString *_subTitle;
    NSString *_pageNumber;
    UIColor *_textColor;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *subTitle;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) NSString *pageNumber;

+ (CGFloat)heightForWidth:(CGFloat)width withName:(NSString *)name subTitle:(NSString *)subTitle pageNumber:(NSString *)pageNumber;

@end
