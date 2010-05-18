//
//  EucHighlight.h
//  libEucalyptus
//
//  Created by James Montgomerie on 13/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucBookPageIndexPoint;

@interface EucHighlightRange : NSObject <NSCopying> {
    EucBookPageIndexPoint *_startPoint;
    EucBookPageIndexPoint *_endPoint;
    UIColor *_color;
}

@property (nonatomic, retain) EucBookPageIndexPoint *startPoint;
@property (nonatomic, retain) EucBookPageIndexPoint *endPoint;
@property (nonatomic, retain) UIColor *color;

@end
