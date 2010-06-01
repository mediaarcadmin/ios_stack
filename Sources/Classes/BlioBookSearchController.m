//
//  BlioBookSearchController.m
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchController.h"

@implementation BlioBookSearchController

@synthesize paragraphSource;

- (void)dealloc {
    self.paragraphSource = nil;
    [super dealloc];
}

- (id)initWithParagraphSource:(id<BlioParagraphSource>)aParagraphSource {
    if ((self = [super init])) {
        self.paragraphSource = aParagraphSource;
    }
    return self;
}

- (id)findString:(NSString *)string fromParagraphWithID:(id)startParagraphID {
    
}

@end
