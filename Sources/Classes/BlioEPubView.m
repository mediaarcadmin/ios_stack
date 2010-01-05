//
//  BlioEPubView.m
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubView.h"


@implementation BlioEPubView

// Supplied by the libEucalyptus superclass.
@dynamic pageNumber;
@dynamic pageCount;
@dynamic contentsDataSource;

- (CGRect)firstPageRect
{
    return [[UIScreen mainScreen] bounds];
}

@end
