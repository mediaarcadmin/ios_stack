//
//  EucCSSLayoutPositionedRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedRun.h"


@implementation EucCSSLayoutPositionedRun

@synthesize documentRun = _documentRun;
@synthesize containingBlock = _containingBlock;
@synthesize frame = _frame;
@synthesize lines = _lines;

- (id)initWithDocumentRun:(EucCSSLayoutDocumentRun *)documentRun
{
    if(self = [super init]) {
        _documentRun = [documentRun retain];
    }
    return self;
}


- (void)dealloc
{
    [_lines release];
    [_documentRun release];
    
    [super dealloc];
}

@end
