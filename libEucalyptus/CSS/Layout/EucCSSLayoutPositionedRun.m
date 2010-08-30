//
//  EucCSSLayoutPositionedRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"

@implementation EucCSSLayoutPositionedRun

@synthesize documentRun = _documentRun;

- (id)initWithDocumentRun:(EucCSSLayoutDocumentRun *)documentRun
{
    if((self = [super init])) {
        _documentRun = [documentRun retain];
    }
    return self;
}


- (void)dealloc
{
    [_documentRun release];
    
    [super dealloc];
}

- (CGFloat)minimumWidth
{
    CGFloat largestLineWidth = 0;
    for(EucCSSLayoutPositionedLine *line in self.children) {
        CGFloat lineMinimum = line.minimumWidth + line.frame.origin.x;
        if(lineMinimum > largestLineWidth) {
            largestLineWidth = lineMinimum;
        }
    }
    return largestLineWidth; 
}

- (void)sizeToFitInWidth:(CGFloat)width
{
    CGFloat difference = self.frame.size.width - width;
    for(EucCSSLayoutPositionedLine *line in self.children) {
        [line sizeToFitInWidth:line.frame.size.width - difference];
    }
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


@end
