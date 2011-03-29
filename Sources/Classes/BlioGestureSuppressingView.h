//
//  BlioGestureSuppressingView.h
//  BlioApp
//
//  Created by Matt Farrugia on 22/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlioSuppressingGestureRecognizer;

@interface BlioGestureSuppressingView : UIView {
    
}

@property (nonatomic, retain) BlioSuppressingGestureRecognizer *suppressingGestureRecognizer;

@end
