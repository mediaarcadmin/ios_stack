//
//  BookTextStyle.m
//  Eucalyptus
//
//  Created by James Montgomerie on 21/10/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "EucBookTextStyle.h"
#import "THStringRenderer.h"

#define DEFAULT_FONT_SIZE 18.0f

@implementation EucBookTextStyle

+ (NSString *)defaultFontFamilyName
{
    return @"LinuxLibertine";
}

+ (CGFloat)defaultFontPointSize
{
    return DEFAULT_FONT_SIZE;
}

@synthesize flags = _flags;
@synthesize image = _image;
@synthesize attributes = _attributes;

- (id)init
{
    if((self = [super init])) {
        _fontSizePercentage = 1.0f;
        
        //CGFloat randomaddition = rand() % 200;
        //_fontSizePercentage *= randomaddition / 100.0f;
    }
    return self;
}

- (id)initWithFlag:(EucBookTextStyleFlag)flags
{
    if([self init]) {
        _flags = flags;
    }
    return self;    
}

+ (id)bookTextStyleWithFlag:(EucBookTextStyleFlag)flags
{
    return [[[self alloc] initWithFlag:flags] autorelease];
}

- (EucBookTextStyle *)styleBySettingFlag:(EucBookTextStyleFlag)flag
{
    EucBookTextStyle *newStyle = [[self copy] autorelease];
    [newStyle setFlag:flag];
    return newStyle;
}

- (EucBookTextStyle *)styleByUnsettingFlag:(EucBookTextStyleFlag)flag
{
    EucBookTextStyle *newStyle = [[self copy] autorelease];
    [newStyle unsetFlag:flag];
    return newStyle;
}

- (EucBookTextStyle *)styleByTogglingingFlag:(EucBookTextStyleFlag)flag
{
    EucBookTextStyle *newStyle = [[self copy] autorelease];
    [newStyle toggleFlag:flag];
    return newStyle;
}

- (EucBookTextStyle *)styleByCombiningStyle:(EucBookTextStyle *)otherStyle
{
    EucBookTextStyle *newStyle = [[self copy] autorelease];
    [newStyle setFlag:otherStyle->_flags];
    [newStyle->_attributes addEntriesFromDictionary:otherStyle->_attributes];
    [newStyle->_cssStyles addEntriesFromDictionary:otherStyle->_cssStyles];
    newStyle->_fontSizePercentage *= otherStyle->_fontSizePercentage;
    return newStyle;
}

- (void)setFlag:(EucBookTextStyleFlag)flag
{
    _flags |= flag;
}

- (void)unsetFlag:(EucBookTextStyleFlag)flag
{
    _flags &= !flag;
}

- (void)toggleFlag:(EucBookTextStyleFlag)flag
{
    _flags ^= flag;
}


- (id)initByCopying:(EucBookTextStyle *)oldStyle
{
    if((self = [super init])) {
        _flags = oldStyle->_flags;
        _cssStyles = [oldStyle->_cssStyles mutableCopy];
        _attributes = [oldStyle->_attributes mutableCopy];
        _fontSizePercentage = oldStyle->_fontSizePercentage;
        _image = [oldStyle->_image retain];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[EucBookTextStyle alloc] initByCopying:self];
}

- (void)dealloc
{
    [_cssStyles release];
    [_attributes release];
    [_cachedRenderer release];
    [_image release];
    [super dealloc];
}


- (BOOL)isNonDefault
{
    return _flags || _attributes || [_cssStyles count] || _fontSizePercentage != 1.0f || _image;
}

- (THStringRenderer *)stringRenderer
{
    if(!_cachedRenderer) {
        CGFloat lineSpacingScaling = 1.0f;
        
        NSString *fontName = @"LinuxLibertine";
        NSString *specifiedFace = [_cssStyles objectForKey:@"font-family"];
        if([@"sans-serif" isEqualToString:specifiedFace]) {
            fontName = @"Helvetica";
            lineSpacingScaling = 1.2;
        }
        
        if([self fontStyle] == EucBookTextStyleFontStyleItalic) {
            if([self fontWeight] == EucBookTextStyleFontWeightBold) {
                _cachedRenderer = [[THStringRenderer alloc] initWithFontName:[fontName stringByAppendingString:@"-BoldItalic"] lineSpacingScaling:lineSpacingScaling];
                if(!_cachedRenderer) {
                    _cachedRenderer = [[THStringRenderer alloc] initWithFontName:[fontName stringByAppendingString:@"-BoldOblique"] lineSpacingScaling:lineSpacingScaling];
                }
            } else {
                _cachedRenderer = [[THStringRenderer alloc] initWithFontName:[fontName stringByAppendingString:@"-Italic"] lineSpacingScaling:lineSpacingScaling];
                if(!_cachedRenderer) {
                    _cachedRenderer = [[THStringRenderer alloc] initWithFontName:[fontName stringByAppendingString:@"-Oblique"] lineSpacingScaling:lineSpacingScaling];
                }
            }
        } else if([self fontWeight] == EucBookTextStyleFontWeightBold) {
            _cachedRenderer = [[THStringRenderer alloc] initWithFontName:[fontName stringByAppendingString:@"-Bold"] lineSpacingScaling:lineSpacingScaling];
        } else{
            _cachedRenderer = [[THStringRenderer alloc] initWithFontName:fontName lineSpacingScaling:lineSpacingScaling];
        }
    }
    return _cachedRenderer;
}

- (void)setStyle:(NSString *)cssStyleName to:(NSString *)value
{        
    cssStyleName = [cssStyleName lowercaseString];
    if(!value) {
        [_cssStyles removeObjectForKey:cssStyleName];
        return;
    }    
    
    value = [value lowercaseString];
    if([cssStyleName isEqualToString:@"font-size"]) {
        if(value) {
            NSInteger length = [value length];
            if(length) {
                if([value characterAtIndex:length - 1] == '%') {
                    CGFloat ret = [[value substringToIndex:length-1] floatValue];
                    if(ret) {
                        _fontSizePercentage *= (ret / 100.0f); 
                    }
                } else {
                    CGFloat ret = [value floatValue];
                    if(ret) {
                        _fontSizePercentage = ret / DEFAULT_FONT_SIZE;
                    }
                }
            }
        } else {
            _fontSizePercentage = 1.0f;
        }
    }
    
    if(_cachedRenderer && [cssStyleName hasPrefix:@"font-"] && 
       ([cssStyleName hasSuffix:@"style"] || [cssStyleName hasSuffix:@"weight"])) {
        [_cachedRenderer release];
        _cachedRenderer = nil;
        _cachedSpaceWidthIsForPointSize = 0;
    }
    
    if(![value isEqualToString:@"inherit"]) {
        if(!_cssStyles) {
            _cssStyles = [[NSMutableDictionary alloc] init];
        }
        if([value isEqualToString:@"none"] || [value isEqualToString:@"0"]) {
            [_cssStyles setObject:@"0" forKey:cssStyleName];
        } else {
            [_cssStyles setObject:value forKey:cssStyleName]; 
        }
    } else {
        [_cssStyles removeObjectForKey:cssStyleName];
        if(_cssStyles.count == 0) {
            [_cssStyles release];
            _cssStyles = nil;
        }
    }
}

- (void)setAttribute:(NSString *)attributeName to:(NSString *)value
{
    if(value.length) {
        if(!_attributes) {
            _attributes = [[NSMutableDictionary alloc] init];
        }
        [_attributes setObject:value forKey:attributeName];
    } else {
        [_attributes removeObjectForKey:attributeName];
        if(!_attributes.count) {
            [_attributes release];
            _attributes = nil;
        }
    }
}

- (EucBookTextStyleFontStyle)fontStyle
{
    if(_cssStyles) {
        NSString *cssValue = [_cssStyles objectForKey:@"font-style"];
        if(cssValue && [cssValue isEqualToString:@"italic"]) {
            return EucBookTextStyleFontStyleItalic;
        } 
    }
    return EucBookTextStyleFontStyleNormal;
}

- (EucBookTextStyleFontStyle)fontWeight
{
    if(_cssStyles) {
        NSString *cssValue = [_cssStyles objectForKey:@"font-weight"];
        if(cssValue && [cssValue isEqualToString:@"bold"]) {
            return EucBookTextStyleFontWeightBold;
        } 
    }
    return EucBookTextStyleFontWeightNormal;
}

- (EucBookTextStyleTextAlign)textAlign
{
    if(_cssStyles) {
        NSString *cssValue = [_cssStyles objectForKey:@"text-align"];
        if(cssValue) {
            if([cssValue isEqualToString:@"center"]) {
                return EucBookTextStyleTextAlignCenter;
            } else if([cssValue isEqualToString:@"right"]) {
                return EucBookTextStyleTextAlignRight;
            } 
        } 
    }
    return EucBookTextStyleFontWeightNormal;
}

- (CGFloat)fontPointSizeForPointSize:(CGFloat)pointSize
{
    return pointSize * _fontSizePercentage;
}

- (CGFloat)lineHeightForPointSize:(CGFloat)pointSize
{
    if(_image) {
        // Don't just use font_size_percentage, because that also takes into 
        // font-size, which shouldn't be used for images.
        return [_image size].height * (pointSize / DEFAULT_FONT_SIZE);
    }
    return ceilf([self.stringRenderer lineSpacingForPointSize:pointSize * _fontSizePercentage]);
}

- (CGFloat)imageWidthForPointSize:(CGFloat)pointSize
{
    if(_image) {
        // Don't just use font_size_percentage, because that also takes into 
        // font-size, which shouldn't be used for images.
        return [_image size].width * (pointSize / DEFAULT_FONT_SIZE);
    }
    return 0;
}


- (CGFloat)_emsToPixels:(CGFloat)ems forPointSize:(CGFloat)pointSize
{
    return roundf([self.stringRenderer lineSpacingForPointSize:pointSize * _fontSizePercentage] * ems);
}

- (CGFloat)_parseValue:(NSString *)value forPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    CGFloat ret = 0;
    if(value) {
        if([value hasSuffix:@"em"]) {
            ret =  [self _emsToPixels:[[value substringToIndex:value.length - 2] floatValue] forPointSize:pointSize];
        } else if([value hasSuffix:@"%"]) {
            ret = [[value substringToIndex:value.length - 1] floatValue] / 100;
            ret = roundf(ret * width);
        } else if([value hasSuffix:@"pt"] | [value hasSuffix:@"px"]) {
            ret = roundf([[value substringToIndex:value.length - 2] floatValue] * (pointSize / DEFAULT_FONT_SIZE));
        }            
    }
    return ret;
}

- (CGFloat)marginTopForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    return [self _parseValue:[_cssStyles objectForKey:@"margin-top"] forPointSize:pointSize inWidth:width];
}

- (CGFloat)marginRightForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    return [self _parseValue:[_cssStyles objectForKey:@"margin-right"] forPointSize:pointSize inWidth:width];
}
            
- (CGFloat)marginBottomForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    return [self _parseValue:[_cssStyles objectForKey:@"margin-bottom"] forPointSize:pointSize inWidth:width];
}

- (CGFloat)marginLeftForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    return [self _parseValue:[_cssStyles objectForKey:@"margin-left"] forPointSize:pointSize inWidth:width];
}

- (CGFloat)textIndentForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width
{
    return [self _parseValue:[_cssStyles objectForKey:@"text-indent"] forPointSize:pointSize inWidth:width];
}


- (CGFloat)spaceWidthForPointSize:(CGFloat)pointSize
{
    if(_cachedSpaceWidthIsForPointSize != pointSize) {
        _cachedSpaceWidth = roundf([self.stringRenderer widthOfString:@" " pointSize:pointSize * _fontSizePercentage]);
    }
    return _cachedSpaceWidth;
}

- (BOOL)shouldPageBreakBefore
{
    NSString *style = [_cssStyles objectForKey:@"page-break-before"];
    if(style) {
        return [[_cssStyles objectForKey:@"page-break-before"] isEqualToString:@"always"] ||
               [[_cssStyles objectForKey:@"page-break-before"] isEqualToString:@"left"] ||
               [[_cssStyles objectForKey:@"page-break-before"] isEqualToString:@"right"];
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"flags: %lx, fontSizePercentage: %f, attributes: %@, %@", (long)_flags, _fontSizePercentage, _attributes, _cssStyles];
}

@end



@interface BookTextAttribute : EucBookTextStyle <NSCoding> {}
@end

@implementation BookTextAttribute

- (id)initWithCoder:(NSCoder *)coder
{
    if((self = [super init])) {     
        _flags = [coder decodeIntegerForKey:@"flags"];
        if((_flags & _LegacyBookTextAttributeFlagItalic) != 0) {
            [self setStyle:@"font-style" to:@"italic"];
            _flags &= !_LegacyBookTextAttributeFlagItalic;
        }
        if((_flags & _LegacyBookTextAttributeFlagHyperlink) != 0) {
            NSString *hyperlink = [coder decodeObjectForKey:@"object"];
            if(hyperlink) {
                [self setAttribute:@"href" to:hyperlink];
            }
            _flags &= !_LegacyBookTextAttributeFlagHyperlink;
        }
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{       
    [NSException raise:NSInternalInconsistencyException format:@"Archiving BookTextAttribute is no longer supported."];
}    

@end
