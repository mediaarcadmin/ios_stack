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

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated
{
    return [self jumpToUuid:uuid];
}

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated
{
    return [self setPageNumber:pageNumber animated:animated];
}


@end
