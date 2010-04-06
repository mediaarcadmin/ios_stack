//
//  THStringRenderer.h
//  libEucalyptus
//
//  Created by James Montgomerie on 12/12/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

struct THBreak;

typedef enum THStringRendererFlags {
    THStringRendererFlagFairlySpaceLastLine    = 0x01,
    THStringRendererFlagCenter                 = 0x02,
    THStringRendererFlagRightJustify           = 0x04,
    THStringRendererFlagRoughJustify           = 0x08,
    THStringRendererFlagFauxBold               = 0x10,
    THStringRendererFlagNoHinting              = 0x20,
} THStringRendererFlags;

typedef enum THStringRendererFontStyleFlags {
    THStringRendererFontStyleFlagRegular = 0,
    THStringRendererFontStyleFlagItalic  = 0x01,
    THStringRendererFontStyleFlagBold    = 0x02,
} THStringRendererFontStyleFlags;

@interface THStringRenderer : NSObject {
    NSString *_fontName;
    CGFontRef _font;
    
    int _unitsPerEm;
    int _lineSpacing;
    int _firstLineOffset;
    
    NSData *_fontMap;
    const uint16_t *_glyphMap;
    
    void *_lastStringAddress;
    CGFloat _lastPointSize;
    CGFloat _lastMaxWidth;
    CGSize _lastSize;
    
    void **_lastEncodedWords;
    void *_lastEncodedWordBuffer;
    
    struct THBreak *_lastBreaks;
    int _lastBreakCount;
    int _lastUsedBreakCount;
    int *_lastUsedBreaksIndexes;
    THStringRendererFlags _lastFlags;
    CGFloat _fauxBoldStrokeWidth;
    
    CGAffineTransform _textTransform;
}

@property (nonatomic, assign) CGFloat fauxBoldStrokeWidth; // Default if 0.5f.


- (id)initWithFontName:(NSString *)fontName;
- (id)initWithFontName:(NSString *)fontName lineSpacingScaling:(CGFloat)lineSpacing;
- (id)initWithFontName:(NSString *)fontName styleFlags:(THStringRendererFontStyleFlags)styleFlags;
- (id)initWithFontName:(NSString *)fontName styleFlags:(THStringRendererFontStyleFlags)styleFlags lineSpacingScaling:(CGFloat)lineSpacing;


- (CGFloat)lineSpacingForPointSize:(CGFloat)pointSize;
- (CGFloat)ascenderForPointSize:(CGFloat)pointSize;
- (CGFloat)descenderForPointSize:(CGFloat)pointSize;


- (CGFloat)widthOfString:(NSString *)string pointSize:(CGFloat)pointSize;
- (CGFloat)roundedWidthOfString:(NSString *)string pointSize:(CGFloat)pointSize;
- (CGPoint)drawString:(NSString *)string inContext:(CGContextRef)context atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize;


- (CGSize)sizeForString:(NSString *)string pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags;
- (CGSize)drawString:(NSString *)string atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags;
- (CGSize)sizeForString:(NSString *)string inContext:(CGContextRef)context pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags;
- (CGSize)drawString:(NSString *)string inContext:(CGContextRef)context atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags;

@end
