//
//  THRoundRectView.h
//  Eucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THRoundRectView : UIView {
    CGFloat _radius;
}

@property (nonatomic, assign) CGFloat cornerRadius;

@end
