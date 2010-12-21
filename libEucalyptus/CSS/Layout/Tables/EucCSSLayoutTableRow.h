//
//  EucCSSLayoutTableRow.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@interface EucCSSLayoutTableRow : EucCSSLayoutTableBox {
    NSArray *_cells;
}

@property (nonatomic, retain) NSArray *cells;

@end
