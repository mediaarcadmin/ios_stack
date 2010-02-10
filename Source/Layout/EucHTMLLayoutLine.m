//
//  EucHTMLLayoutLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayoutLine.h"
#import "EucHTMLDocumentNode.h"
#import "EucHTMLLayoutDocumentRun.h"
#import "THPair.h"

@implementation EucHTMLLayoutLine

@synthesize documentRun = _documentRun;

@synthesize startComponentOffset = _startComponentOffset;
@synthesize startHyphenOffset = _startHyphenOffset;
@synthesize endComponentOffset = _endComponentOffset;
@synthesize endHyphenOffset = _endHyphenOffset;

@synthesize origin = _origin;
@synthesize size = _size;

- (void)sizeToFitInWidth:(CGFloat)width;
{
    CGFloat maxAscender = 0;
    CGFloat maxDescenderAndLineHeightAddition = 0;
    
    id spaceMarker = [EucHTMLLayoutDocumentRun singleSpaceMarker];
    Class NSStringClass = [NSString class];
    
    for(uint32_t offset = _startComponentOffset; offset < _endComponentOffset; ++offset) {
        id component = _documentRun.components[offset];
        
        if([component isKindOfClass:NSStringClass] ||
           component == spaceMarker) {
            EucHTMLLayoutDocumentRunComponentInfo info =  _documentRun.componentInfos[offset];
            if(info.ascender > maxAscender) {
                maxAscender = info.ascender;
            }
            CGFloat descenderAndLineHeightAddition = info.lineHeight - info.ascender;
            if(descenderAndLineHeightAddition > maxDescenderAndLineHeightAddition) {
                maxDescenderAndLineHeightAddition = descenderAndLineHeightAddition;
            }
        }
    }
    _baseline = maxAscender;
    _size = CGSizeMake(width, maxAscender + maxDescenderAndLineHeightAddition);
}

@end
