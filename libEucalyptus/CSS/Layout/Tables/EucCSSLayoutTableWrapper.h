//
//  EucCSSLayoutTableWrapper.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@class EucCSSLayoutTableCaption, EucCSSLayoutTableTable;

@interface EucCSSLayoutTableWrapper : EucCSSLayoutTableBox {
    EucCSSLayoutTableCaption *_caption;
    EucCSSLayoutTableTable *_table;
}

@property (nonatomic, retain) EucCSSLayoutTableCaption *caption;
@property (nonatomic, retain) EucCSSLayoutTableTable *table;

@end
