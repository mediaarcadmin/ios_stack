//
//  BlioTOCEntry.m
//  BlioApp
//
//  Created by Matt Farrugia on 01/12/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTOCEntry.h"

@implementation BlioTOCEntry

@synthesize name, startPage, level;

- (void)dealloc {
    self.name = nil;
    [super dealloc];
}

@end
