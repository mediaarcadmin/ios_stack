//
//  BookContentsTableViewCellBackground.h
//  libEucalyptus
//
//  Created by James Montgomerie on 23/01/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

//  Portions from:
//  http://stackoverflow.com/questions/400965/how-to-customize-the-background-border-colors-of-a-grouped-table-view
//  Created by Mike Akers on 11/21/08.

#import <UIKit/UIKit.h>

typedef enum  {
    EucBookContentsTableViewCellPositionTop, 
    EucBookContentsTableViewCellPositionMiddle, 
    EucBookContentsTableViewCellPositionBottom,
    EucBookContentsTableViewCellPositionSingle
} EucBookContentsTableViewCellPosition;

@interface EucBookContentsTableViewCellBackground : UIView {
    UIColor *borderColor;
    UIColor *fillColor;
    EucBookContentsTableViewCellPosition position;
}

@property(nonatomic, retain) UIColor *borderColor, *fillColor;
@property(nonatomic) EucBookContentsTableViewCellPosition position;
@end