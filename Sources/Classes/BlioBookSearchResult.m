//
//  BlioBookSearchResult.m
//  BlioApp
//
//  Created by matt on 11/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchResult.h"


@implementation BlioBookSearchResult

@synthesize prefix, match, suffix, bookmarkRange;

- (void)dealloc {
    self.prefix = nil;
    self.match = nil;
    self.suffix = nil;
    self.bookmarkRange = nil;
    [super dealloc];
}

@end
