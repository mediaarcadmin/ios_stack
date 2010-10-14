//
//  BlioLayoutHyperlink.m
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioLayoutHyperlink.h"


@implementation BlioLayoutHyperlink

@synthesize link, rect;

- (void)dealloc {
    [link release];
    [rectValue release];
    [super dealloc];
}

- (id)initWithLink:(NSString *)aLink rect:(CGRect)aRect {
    if ((self = [super init])) {
        link = [aLink retain];
        rectValue = [[NSValue valueWithCGRect:aRect] retain];
    }
    return self;
}

- (void)setRect:(CGRect)aRect {
    rectValue = [[NSValue valueWithCGRect:aRect] retain];
}

- (CGRect)rect {
    return [rectValue CGRectValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ : %@>", self.link, NSStringFromCGRect(self.rect)];
}

@end
