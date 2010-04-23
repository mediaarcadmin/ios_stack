//
//  BlioBookViewControllerProgressPieButton.h
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioBookViewControllerProgressPieButton : UIControl {
    CGFloat progress;
    UIColor *tintColor;
    BOOL toggled;
    CGRect backgroundFrame;
}

@property (nonatomic) CGFloat progress;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic) BOOL toggled;

@end
