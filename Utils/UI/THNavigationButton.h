//
//  THNavigationButton.h
//  Eucalyptus
//
//  Created by James Montgomerie on 08/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THNavigationButton : UIButton {
    UIBarStyle _barStyle;
    NSString *_firstLine;
    NSString *_secondLine;
}

@property (nonatomic, assign) UIBarStyle barStyle;

+ (id)rightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine;
+ (id)rightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine barStyle:(UIBarStyle)barStyle;

+ (id)leftNavigationButtonWithArrow;
+ (id)leftNavigationButtonWithArrowInBarStyle:(UIBarStyle)barStyle;

@end
