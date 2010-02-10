//
//  EucHTMLLayoutPositionedRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayoutPositionedRun.h"


@implementation EucHTMLLayoutPositionedRun

@synthesize documentRun = _documentRun;
@synthesize frame = _frame;
@synthesize lines = _lines;

- (id)initWithDocumentRun:(EucHTMLLayoutDocumentRun *)documentRun
                    lines:(NSArray *)lines
                    frame:(CGRect)frame
{
    if(self = [super init]) {
        _documentRun = [documentRun retain];
        _lines = [lines retain];
        _frame = frame;
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
