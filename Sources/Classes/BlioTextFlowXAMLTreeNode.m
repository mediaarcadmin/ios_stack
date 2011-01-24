//
//  BlioTextFlowXAMLTreeNode.m
//  BlioApp
//
//  Created by James Montgomerie on 29/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowXAMLTreeNode.h"

@implementation BlioTextFlowXAMLTreeNode

- (void)dealloc
{
    [_tag release];
    if(_constructedInlineStyle) {
        [_constructedInlineStyle release];
    }
    
    [super dealloc];
}

static inline uint32_t charToHex(uint8_t c)
{
	c -= '0';
    
	if (c > 9)
		c -= 'A' - '9' - 1;
    
	if (c > 15)
		c -= 'a' - 'A';
    
	return c;
}

static NSString *xamlColorToCSSColor(NSString *color)
{
    // TODO: Handle RGBA correctly - at the moment, it's not supported by libcss.
    if([color characterAtIndex:0] == '#') {
        NSUInteger length = color.length;
        if(length == 5) {
            const char *characters = [color UTF8String];
            //long a = charToHex(characters[1]);
            long r = charToHex(characters[2]);
            long g = charToHex(characters[2]);
            long b = charToHex(characters[2]);
            //if(a >= 0xf) {
                return [NSString stringWithFormat:@"rgb(%ld,%ld,%ld)", 
                        r * 16 + r, g * 16 + g, b * 16 + b];
            //} else {
            //    return [NSString stringWithFormat:@"rgba(%ld,%ld,%ld,%f)", 
            //            r * 16 + r, g * 16 + g, b * 16 + b, (float)a / (float)0xf];
            //}
        } else if (length == 9) {
            const char *characters = [color UTF8String];
            //long a = charToHex(characters[1]) * 16 + charToHex(characters[2]);
            long r = charToHex(characters[3]) * 16 + charToHex(characters[4]);
            long g = charToHex(characters[5]) * 16 + charToHex(characters[6]);
            long b = charToHex(characters[7]) * 16 + charToHex(characters[8]);
            //if(a >= 0xff) {
                return [NSString stringWithFormat:@"rgb(%ld,%ld,%ld)", 
                        r, g, b];
            //} else {
            //    return [NSString stringWithFormat:@"rgba(%ld,%ld,%ld,%f)", 
            //            r, g, b, (float)a / (float)0xff];
            //}
        } else {
            return color;
        }
    } else if([color hasPrefix:@"sc#"]) {
        NSArray *components = [[color substringFromIndex:3] componentsSeparatedByString:@","];
        if(components.count == 4) {
            NSMutableArray *mutableComponents = [components mutableCopy];
            [mutableComponents addObject:[components objectAtIndex:0]];
            [mutableComponents removeObjectAtIndex:0];
            components = mutableComponents;
            //return [NSString stringWithFormat:@"rgba(%@)", [components componentsJoinedByString:@","]];
        } 
        //else if(components.count == 3) 
        {
            return [NSString stringWithFormat:@"rgb(%@)", [components componentsJoinedByString:@","]];
        }
    }
    return [color lowercaseString];
}

- (NSString *)inlineStyle
{
    // Some XAML attributes are not directly compatible with being styled 
    // with CSS, so we convert them to an inline style here.
    // Other attributes are styled by the TextFlowXAML.css resource
    // file.
    if(self.hasAttributes) {
        NSMutableString *constructionString = [[NSMutableString alloc] init];
        NSString *value;
        if((value = [self attributeWithName:@"Margin"])) {
            // The margin attributes are in order left, top, right, bottom.
            // CSS margins are in order top, right, bottom, left...
            NSArray *elements = [value componentsSeparatedByString:@","];
            NSUInteger elementCount = [elements count];
            if(elementCount == 1) {
                [constructionString appendFormat:@"margin:%@px;", [elements objectAtIndex:0]];
            } else if(elementCount == 2) {
                [constructionString appendFormat:@"margin:%@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:0]];
            } else if(elementCount == 4) {
                [constructionString appendFormat:@"margin:%@px %@px %@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:2], [elements objectAtIndex:3], [elements objectAtIndex:0]];
            }                    
        } 
        if((value = [self attributeWithName:@"Padding"])) {
            // The padding attributes are in order left, top, right, bottom.
            // CSS padding are in order top, right, bottom, left...
            NSArray *elements = [value componentsSeparatedByString:@","];
            NSUInteger elementCount = [elements count];
            if(elementCount == 1) {
                [constructionString appendFormat:@"padding:%@px;", [elements objectAtIndex:0]];
            } else if(elementCount == 2) {
                [constructionString appendFormat:@"padding:%@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:0]];
            } else if(elementCount == 4) {
                [constructionString appendFormat:@"padding:%@px %@px %@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:2], [elements objectAtIndex:3], [elements objectAtIndex:0]];
            }                    
        } 
        if((value = [self attributeWithName:@"BorderThickness"])) {
            // The border attributes are in order left, top, right, bottom.
            // CSS border are in order top, right, bottom, left...
            NSArray *elements = [value componentsSeparatedByString:@","];
            NSUInteger elementCount = [elements count];
            if(elementCount == 1) {
                [constructionString appendFormat:@"border-width:%@px;", [elements objectAtIndex:0]];
            } else if(elementCount == 2) {
                [constructionString appendFormat:@"border-width:%@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:0]];
            } else if(elementCount == 4) {
                [constructionString appendFormat:@"border-width:%@px %@px %@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:2], [elements objectAtIndex:3], [elements objectAtIndex:0]];
            }                    
        } 
        if((value = [self attributeWithName:@"BorderBrush"])) {
            [constructionString appendFormat:@"border-color:%@;", xamlColorToCSSColor(value)];
        } 
        if((value = [self attributeWithName:@"FontSize"])) {
            [constructionString appendFormat:@"font-size:%@px;", value];
        } 
        if((value = [self attributeWithName:@"LineHeight"])) {
            [constructionString appendFormat:@"line-height:%@px;", value];
        } 
        if((value = [self attributeWithName:@"TextIndent"])) {
            [constructionString appendFormat:@"text-indent:%@px;", value];
        } 
        if((value = [self attributeWithName:@"Width"])) {
            [constructionString appendFormat:@"width:%@px;", value];
        } 
        if((value = [self attributeWithName:@"Height"])) {
            [constructionString appendFormat:@"height:%@px;", value];
        } 
        if((value = [self attributeWithName:@"Foreground"])) {
            [constructionString appendFormat:@"color:%@;", xamlColorToCSSColor(value)];
        } 
        if((value = [self attributeWithName:@"Background"])) {
            [constructionString appendFormat:@"background-color:%@;", xamlColorToCSSColor(value)];
        }                     
        if(constructionString.length) {
            //NSLog(@"<%@ style=\"%@\">", self.name, constructionString);
            [constructionString autorelease];
        } else {
            [constructionString release];
            constructionString = nil;
        }
        return constructionString;
    }
    return nil;
}

- (BOOL)isImageNode
{
    return [@"Image" isEqualToString:self.name];
}

- (NSString *)imageSourceURLString
{
    return [self attributeWithName:@"Source"];
}

- (BOOL)isHyperlinkNode
{
    return [@"Hyperlink" isEqualToString:self.name];
}

- (NSString *)hyperlinkURLString
{
    return [self attributeWithName:@"NavigateUri"];
}

- (NSString *)CSSID
{
    NSString *tag = [self tag];
    if(![tag hasPrefix:@"__"]) {
        return tag;
    }
    return nil;
}

- (NSString *)tag
{
    if(!_tag) {
        _tag = [[self attributeWithName:@"Tag"] retain];
        _tagFound = YES;
    }
    return _tag;
}

- (NSUInteger)columnSpan
{
    NSString *spanString = [self attributeWithName:@"ColumnSpan"];
    if(spanString) {
        NSUInteger ret = [spanString integerValue];
        if(ret != 0) {
            return ret;
        }
    }
    return 1;
}

- (NSUInteger)rowSpan
{
    NSString *spanString = [self attributeWithName:@"RowSpan"];
    if(spanString) {
        NSUInteger ret = [spanString integerValue];
        if(ret != 0) {
            return ret;
        }
    }
    return 1;
}

@end
