//
//  BookTextStyle.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/10/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucBookTextStyle, THStringRenderer;

// DON'T RENUMBER THESE!
// Some older Euclayptus apps have these numbers archived to disk,
// and the must be the same when reloaded.
typedef enum {
    EucBookTextStyleFlagNone                 = 0,
    EucBookTextStyleFlagNonBreaking          = 0x001,
    EucBookTextStyleFlagHardBreak            = 0x002,
    EucBookTextStyleFlagZeroSpace            = 0x004,
    EucBookTextStyleFlagDontHyphenate        = 0x008,
    EucBookTextStyleFlagLineIsTitle          = 0x040,
    EucBookTextStyleFlagLineIsContentsLine   = 0x080,
    EucBookTextStyleFlagLineForceBreakAtEnd  = 0x100,
    
    _LegacyBookTextAttributeFlagItalic    = 0x010,
    _LegacyBookTextAttributeFlagHyperlink = 0x020,
} EucBookTextStyleFlag;

@interface EucBookTextStyle : NSObject <NSCopying> {
    EucBookTextStyleFlag _flags;
        
    CGFloat _fontSizePercentage;
    
    NSMutableDictionary *_cssStyles;
    NSMutableDictionary *_attributes;
    UIImage *_image;
    
    THStringRenderer *_cachedRenderer;
    
    CGFloat _cachedSpaceWidth;
    CGFloat _cachedSpaceWidthIsForPointSize;
}

@property (nonatomic, readonly) EucBookTextStyleFlag flags;

+ (NSString *)defaultFontFamilyName;
+ (CGFloat)defaultFontPointSize;

- (id)initWithFlag:(EucBookTextStyleFlag)flags;
+ (EucBookTextStyle *)bookTextStyleWithFlag:(EucBookTextStyleFlag)flags;

- (EucBookTextStyle *)styleBySettingFlag:(EucBookTextStyleFlag)flag;
- (EucBookTextStyle *)styleByUnsettingFlag:(EucBookTextStyleFlag)flag;
- (EucBookTextStyle *)styleByTogglingingFlag:(EucBookTextStyleFlag)flag;

- (EucBookTextStyle *)styleByCombiningStyle:(EucBookTextStyle *)otherStyle;

- (void)setFlag:(EucBookTextStyleFlag)flag;
- (void)unsetFlag:(EucBookTextStyleFlag)flag;
- (void)toggleFlag:(EucBookTextStyleFlag)flag;

typedef enum  {
    EucBookTextStyleTextAlignNormal,
    EucBookTextStyleTextAlignRight,
    EucBookTextStyleTextAlignCenter
} EucBookTextStyleTextAlign;

typedef enum  {
    EucBookTextStyleFontStyleNormal,
    EucBookTextStyleFontStyleItalic,
} EucBookTextStyleFontStyle;

typedef enum  {
    EucBookTextStyleFontWeightNormal,
    EucBookTextStyleFontWeightBold,
} EucBookTextStyleFontWeight;

@property (readonly) BOOL isNonDefault;
@property (readonly) BOOL wantsFullBleed;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, readonly) NSDictionary *attributes;

- (THStringRenderer *)stringRenderer;

- (void)setStyle:(NSString *)cssStyleName to:(NSString *)value;
- (void)setAttribute:(NSString *)attribute to:(NSString *)value;

@property (nonatomic, readonly) EucBookTextStyleFontStyle fontStyle;
@property (nonatomic, readonly) EucBookTextStyleFontStyle fontWeight;
@property (nonatomic, readonly) EucBookTextStyleTextAlign textAlign;
@property (nonatomic, readonly) BOOL shouldPageBreakBefore;

- (CGFloat)fontPointSizeForPointSize:(CGFloat)pointSize;
- (CGFloat)lineHeightForPointSize:(CGFloat)pointSize;
- (CGFloat)spaceWidthForPointSize:(CGFloat)pointSize;
- (CGFloat)imageWidthForPointSize:(CGFloat)pointSize;

- (CGFloat)marginTopForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width;
- (CGFloat)marginBottomForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width;
- (CGFloat)marginLeftForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width;
- (CGFloat)marginRightForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width;

- (CGFloat)textIndentForPointSize:(CGFloat)pointSize inWidth:(CGFloat)width;

@end