//
//  EucEPubLocalBookReference.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBUpeLocalBookReference.h"
#import "EucBookIndex.h"
#import "THNSFileManagerAdditions.h"


@implementation EucBUpeLocalBookReference

@synthesize title = _title;
@synthesize author = _author;
@synthesize etextNumber = _etextNumber;
@synthesize cacheDirectoryPath = _cacheDirectoryPath;

- (id)initWithTitle:(NSString *)title author:(NSString *)author etextNumber:(NSString *)etextNumber path:(NSString *)path
{
    if((self = [super init])) {
        if([title length]) _title = [title copy]; else _title = @"";
        if([author length]) _author = [author copy]; else _author = @"";
        if([etextNumber length]) _etextNumber = [etextNumber copy]; else _author = @"";
    }
    return self;
}

- (BOOL)paginationIsComplete
{
    return [EucBookIndex indexesAreConstructedForBookBundle:self.cacheDirectoryPath];
}

- (CGFloat)percentThroughBook
{
    return 0;
}

- (CGFloat)percentPaginated
{
    if(self.paginationIsComplete) {
        return 100;
    } else {
        return 0;
    }
}

- (void)dealloc
{
    [_title release];
    [_author release];
    [_etextNumber release];
    [_cacheDirectoryPath release];
    
    [super dealloc];
}

@end
