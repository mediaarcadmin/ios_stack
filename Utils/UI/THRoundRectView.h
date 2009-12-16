//
//  THRoundRectView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THRoundRectView : UIView {
    CGFloat _radius;
}

@property (nonatomic, assign) CGFloat cornerRadius;

@end
