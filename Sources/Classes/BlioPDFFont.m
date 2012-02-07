//
//  BlioPDFFont.m
//  BlioApp
//
//  Created by Matt Farrugia on 05/02/2012.
//  Copyright (c) 2012 BitWink. All rights reserved.
//

#import "BlioPDFFont.h"

@implementation BlioPDFFont

@synthesize key;
@synthesize baseFont;
@synthesize type;
@synthesize widths;
@synthesize notdef;
@synthesize missingWidth;
@synthesize hasUnicodeMapping;

- (id)initWithKey:(NSString *)fontKey {
    
    if ((self = [super init])) {
        key = [fontKey copy];
        widths = [[NSMutableDictionary alloc] initWithCapacity:256];
    }
    
    return self;
}

- (void)dealloc {
    [key release], key = nil;
    [baseFont release], baseFont = nil;
    [type release], type = nil;
    [widths release], widths = nil;
    
    [super dealloc];
}

- (NSInteger)glyphWidthForCharacter:(unichar)character {
    NSNumber *glyphWidth = [self.widths objectForKey:[NSNumber numberWithInteger:character]];
    
    if (!glyphWidth && self.notdef) {
        glyphWidth = [self.widths objectForKey:[NSNumber numberWithInteger:self.notdef]];
    }
    
    if (glyphWidth) {
        return [glyphWidth integerValue];
    } else {
        //NSLog(@"Warning: character not in widths: %C [%d]", character, character);
        return self.missingWidth;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<BlioPDFFont: %p %@:%@>", self, self.key, self.baseFont];
}

@end
