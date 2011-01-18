//
//  THStringRenderer.m
//  libEucalyptus
//
//  Created by James Montgomerie on 12/12/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THStringRenderer.h"
#import "THLog.h"
#import "THPair.h"
#import "THTimer.h"
#import "THCache.h"
#import "th_just_with_floats.h"

#import <pthread.h>

static THCache *sFontNamesAndFlagsToMapsAndFonts = nil;
static pthread_mutex_t sFontCacheMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_key_t sGraphicsContextKey;

@implementation THStringRenderer

@synthesize fauxBoldStrokeWidth = _fauxBoldStrokeWidth;
@synthesize lineSpacingScaling = _lineSpacingScaling;

static inline CGFloat PointsToPixels(CGFloat points)
{
    return points;// / 160.0f) * 72.0f;
}

static inline CGFloat GlyphSpaceToPixels(CGFloat glyphSize, CGFloat pointSize, CGFloat unitsPerEm)
{
    return ((glyphSize / unitsPerEm) * pointSize);// / 160.0f) * 72.0f;
}

static void _NSDataReleaseCallback(void *info, const void *data, size_t size) 
{
    [(NSData *)info release];
}

+ (void)initialize
{
    if(self == [THStringRenderer class]) {
        pthread_key_create(&sGraphicsContextKey, (void (*)(void *))CFRelease);
    }
}

- (id)initWithFontName:(NSString *)fontName styleFlags:(THStringRendererFontStyleFlags)styleFlags lineSpacingScaling:(CGFloat)lineSpacing
{
    if((self = [super init])) {   
        THPair *mapAndFont;
        
        THPair *fontKey = [THPair pairWithFirst:fontName second:[NSNumber numberWithInteger:styleFlags]];
        
        pthread_mutex_lock(&sFontCacheMutex);
        {
            if(!sFontNamesAndFlagsToMapsAndFonts) {
                sFontNamesAndFlagsToMapsAndFonts = [[THCache alloc] init];
            }
            
            NSUInteger glyphMapLength = (UINT16_MAX + 1) * sizeof(uint16_t);
            mapAndFont = [sFontNamesAndFlagsToMapsAndFonts objectForKey:fontKey];
            
            if(!mapAndFont) {
				THTimer *timer = [THTimer timerWithName:[NSString stringWithFormat:@"Create %@ renderer", fontName]];
				
                // Look up the font in the bundle, and cache it.
                NSString *fullBundleFontName;;
                
                if(styleFlags) {
                    NSMutableString *mutableBundleFontName = [fontName mutableCopy];
                    [mutableBundleFontName appendString:@"-"];
                    if(styleFlags & THStringRendererFontStyleFlagBold) {
                        [mutableBundleFontName appendString:@"Bold"];
                    }
                    if(styleFlags & THStringRendererFontStyleFlagItalic) {
                        [mutableBundleFontName appendString:@"Italic"];
                    }    
                    fullBundleFontName = [mutableBundleFontName autorelease];
                } else {
                    fullBundleFontName = fontName;
                }
                
                NSString *bundleFontPath = [[NSBundle mainBundle] pathForResource:fullBundleFontName ofType:@"thfont"];
                if(!bundleFontPath) {
                    bundleFontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"thfont"];
                }
                if(bundleFontPath) {
                    NSData *fontData = [[NSData alloc] initWithContentsOfMappedFile:bundleFontPath];
                    if(fontData) {
                        NSUInteger fontDataLength = fontData.length;
                        const void *fontBytes = fontData.bytes;
                    
                        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithData([fontData retain],
                                                                                          fontBytes + glyphMapLength, 
                                                                                          fontDataLength - glyphMapLength, 
                                                                                          _NSDataReleaseCallback);
                        CGFontRef font = CGFontCreateWithDataProvider(fontDataProvider);
                        CGDataProviderRelease(fontDataProvider);  
                        
                        if(font) {
                            /*
                            CFArrayRef table = CGFontCopyTableTags(font);
                            
                            NSLog(@"Font: %@", fontName);
                            for(int i = 0; i < CFArrayGetCount(table); ++i) {
                                uint32_t tag = CFSwapInt32BigToHost((uint32_t)(uintptr_t)CFArrayGetValueAtIndex(table, i));
                                NSLog(@"Tag: %.4s", (char *)&tag);
                            }
                            
                           // CGFontCopyTableForTag(font, CFSwapInt32HostToBig('GSUB'));
                            
                            NSLog(@"%@", CGFontCopyTableForTag(font, 'GSUB'));
                            
                            CFRelease(table);
                            */
                            mapAndFont = [THPair pairWithFirst:fontData second:(id)font];
                            [sFontNamesAndFlagsToMapsAndFonts cacheObject:mapAndFont forKey:fontKey];
                            CGFontRelease(font);
                        }
                        [fontData release];
                    }
                }
                
                if(!mapAndFont) {
					CGFontRef font = nil;
					NSString *bundleFontPath = [[NSBundle mainBundle] pathForResource:fullBundleFontName ofType:@"otf"];
					if(!bundleFontPath) {
						bundleFontPath = [[NSBundle mainBundle] pathForResource:fullBundleFontName ofType:@"ttf"];
					}
                    if(!bundleFontPath) {
						bundleFontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"otf"];
					}
                    if(!bundleFontPath) {
						bundleFontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"ttf"];
					}
					if(bundleFontPath) {
						NSData *fontData = [[NSData alloc] initWithContentsOfMappedFile:bundleFontPath];
						CGDataProviderRef fontDataProvider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
						font = CGFontCreateWithDataProvider(fontDataProvider);
						CGDataProviderRelease(fontDataProvider);  
						[fontData release];
					}
					if(!font) {
						// See if we can use a system font.            
                        NSArray *familyNames;
                        
#if TARGET_OS_IPHONE
                        familyNames = [UIFont familyNames];
#else
                        familyNames = [[NSFontManager sharedFontManager] availableFontFamilies];
#endif
                        
                        if([familyNames containsObject:fontName]) {
                            NSArray *specificFontNames;
#if TARGET_OS_IPHONE
                            specificFontNames = [UIFont fontNamesForFamilyName:fontName];
#else
                            {
                                NSArray *specifics = [[NSFontManager sharedFontManager] availableMembersOfFontFamily:fontName];
                                NSMutableArray *buildSpecificFontNames = [NSMutableArray arrayWithCapacity:specifics.count];
                                for(NSArray *specific in specifics) {
                                    [buildSpecificFontNames addObject:[specific objectAtIndex:0]];
                                }
                                specificFontNames = buildSpecificFontNames;
                            }
#endif
                            NSInteger specificFontCount = specificFontNames.count;
                            if(specificFontCount) {
                                // The idea here is to rate the specific font names
                                // with positive or negative points depending on 
                                // for the attributed we can detect within them,
                                // then choose the highest rated font name.
                                NSInteger points[specificFontCount];
                                memset(points, 0, specificFontCount * sizeof(NSUInteger));
                                
                                NSUInteger specificFontIndex = 0;
                                for(NSString *specificFontName in specificFontNames) {
                                    if([specificFontName rangeOfString:@"bold" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                        points[specificFontIndex] += (styleFlags & THStringRendererFontStyleFlagBold) ? 1 : -1;
                                    }
                                    if([specificFontName rangeOfString:@"italic" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                                       [specificFontName rangeOfString:@"oblique" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                        points[specificFontIndex] += (styleFlags & THStringRendererFontStyleFlagItalic) ? 1 : -1;
                                    }
                                    ++specificFontIndex;
                                }
                                
                                NSUInteger bestFontIndex = 0;
                                NSInteger bestFontPoints = NSIntegerMin;
                                for(specificFontIndex = 0; specificFontIndex < specificFontCount; ++specificFontIndex) {
                                    if(points[specificFontIndex] > bestFontPoints) {
                                        bestFontPoints = points[specificFontIndex];
                                        bestFontIndex = specificFontIndex;
                                    }
                                }
                                font = CGFontCreateWithFontName((CFStringRef)[specificFontNames objectAtIndex:bestFontIndex]);
                            }
                        }
					}
                    if(font) {
                        NSData *fontTable = (NSData *)CGFontCopyTableForTag(font, 'cmap');
                        if(fontTable) {
                            // We'll build a direct UCS-2 to glyph map (as
                            // would be in the file for our custom fonts)
                            // from the sparse table (hopefully) included in 
                            // the font.
                            // http://developer.apple.com/textfonts/ttrefman/rm06/Chap6cmap.html
                    
                            const void *fontTableBytes = [fontTable bytes];
                            
                            //uint16_t version = CFSwapInt16BigToHost(*((uint16_t *)fontTableBytes));
                            uint16_t subtablesCount = CFSwapInt16BigToHost(*((uint16_t *)(fontTableBytes + 2)));
                            
                            // Look for the unicode mapping.
                            uint32_t offset = 0;
                            const void *subtableCursor = fontTableBytes + 4;
                            for(uint16_t i = 0; i < subtablesCount; ++i) {
                                uint16_t platformId = CFSwapInt16BigToHost(*((uint16_t *)(subtableCursor)));
                                uint16_t platformSpecificID = CFSwapInt16BigToHost(*((uint16_t *)(subtableCursor + 2)));
                                if((platformId == 0 && platformSpecificID == 3)
                                   || (platformId == 3 && platformSpecificID == 1)
                                    ) {
                                    // Mac Unicode
                                    offset = CFSwapInt32BigToHost(*((uint32_t *)(subtableCursor + 4)));
                                    break;
                                }
                                subtableCursor += 8;
                            }
                            
                            if(offset) {                                
                                const void *mapping = fontTableBytes + offset;
                                uint16_t format = CFSwapInt16BigToHost(*((uint16_t *)mapping));
                                if(format == 4) {
                                    // UCS-2 Unicode!
                                    NSMutableData *glyphMapData = [[NSMutableData alloc] initWithCapacity:glyphMapLength];
                                    if(glyphMapData) {
                                        [glyphMapData setLength:glyphMapLength]; 
                                        uint16_t *glyphMapBytes = (uint16_t *)[glyphMapData mutableBytes];                                                        
                                        
                                        //uint16_t length = CFSwapInt16BigToHost(*((uint16_t *)(mapping + 2)));
                                        
                                        uint16_t segCountX2 =  CFSwapInt16BigToHost(*((uint16_t *)(mapping + 6)));
                                        
                                        const uint16_t *endCodes = (mapping + 14);
                                        const uint16_t *startCodes = (mapping + 14 + segCountX2 + 2);
                                        const uint16_t *idDeltas = (mapping + 14 + segCountX2 * 2 + 2);
                                        const uint16_t *idRangeOffsets = (mapping + 14 + segCountX2 * 3 + 2);
                                        //const uint16_t *glyphIdArray = (mapping + 14 + segCountX2 * 4 + 2);
                                        
                                        uint16_t segCount = segCountX2 / 2;
                                        for(uint16_t i = 0; i < segCount; ++i) {
                                            uint16_t startCode = CFSwapInt16BigToHost(startCodes[i]);
                                            uint16_t endCode = CFSwapInt16BigToHost(endCodes[i]);
                                            uint16_t idDelta = CFSwapInt16BigToHost(idDeltas[i]);
                                            uint16_t idRangeOffset = CFSwapInt16BigToHost(idRangeOffsets[i]);
                                            
                                            // Strange loop below is because :                          
                                            //   for(uint16_t code = startCode; code <= endCode; ++code) {
                                            // would fail if endCode == 0xFFFF.
                                            
                                            uint16_t code = startCode - 1;
                                            do {
                                                ++code;
                                                if(idRangeOffset == 0) {
                                                    glyphMapBytes[code] = CFSwapInt32HostToLittle(code + idDelta);
                                                } else {
                                                    glyphMapBytes[code] = CFSwapInt16(*( &idRangeOffsets[i] + idRangeOffset / 2 + (code - startCode) ));
                                                }
                                            }  while(code != endCode);
                                        }
                                        
                                        mapAndFont = [THPair pairWithFirst:glyphMapData second:(id)font];
                                        [sFontNamesAndFlagsToMapsAndFonts cacheObject:mapAndFont forKey:fontKey];
                                            
                                    }
                                    [glyphMapData release];
                                }
                            }
                        }
                        
                        [fontTable release];
                        CGFontRelease(font);
                    }
                }
				[timer report];
            }
        }
        pthread_mutex_unlock(&sFontCacheMutex);
        
        if(!mapAndFont) {
            [self release];
            return nil;
        }
        
        _fontName = [fontName retain];
        _fontMap = [mapAndFont.first retain];
        _glyphMap = _fontMap.bytes;
        _font = CGFontRetain((CGFontRef)mapAndFont.second);
        
        _unitsPerEm = CGFontGetUnitsPerEm(_font);
                
        _lineSpacingScaling = lineSpacing;

        _fauxBoldStrokeWidth = 0.5f;
        
        _textTransform = CGAffineTransformMakeRotation(M_PI); // 8
        _textTransform = CGAffineTransformScale(_textTransform, -1, 1);
    }
    
    return self;
}

- (id)initWithFontName:(NSString *)fontName styleFlags:(THStringRendererFontStyleFlags)styleFlags
{
    return [self initWithFontName:fontName styleFlags:styleFlags lineSpacingScaling:1.0f];
}

- (id)initWithFontName:(NSString *)fontName lineSpacingScaling:(CGFloat)lineSpacing 
{
    return [self initWithFontName:fontName styleFlags:THStringRendererFontStyleFlagRegular lineSpacingScaling:lineSpacing];
}

- (id)initWithFontName:(NSString *)fontName
{
    return [self initWithFontName:fontName lineSpacingScaling:1.0f];
}

- (CGFloat)leadingForPointSize:(CGFloat)pointSize
{
    CGFloat leading = GlyphSpaceToPixels(CGFontGetLeading(_font), pointSize, _unitsPerEm);

    if(_lineSpacingScaling != 1.0f) {
        CGFloat mainPart = [self ascenderForPointSize:pointSize] - [self descenderForPointSize:pointSize];
        return roundf((mainPart + leading) * _lineSpacingScaling) - mainPart;
    } else {
        return roundf(leading);
    }
}

- (CGFloat)lineSpacingForPointSize:(CGFloat)pointSize
{
    return [self ascenderForPointSize:pointSize] 
            - [self descenderForPointSize:pointSize] 
            + [self leadingForPointSize:pointSize];
}

- (CGFloat)ascenderForPointSize:(CGFloat)pointSize
{
    return roundf(GlyphSpaceToPixels(CGFontGetAscent(_font), pointSize, _unitsPerEm));
}

- (CGFloat)descenderForPointSize:(CGFloat)pointSize
{
    return -roundf(-GlyphSpaceToPixels(CGFontGetDescent(_font), pointSize, _unitsPerEm));
}

- (CGFloat)xHeightForPointSize:(CGFloat)pointSize
{
    return -roundf(-GlyphSpaceToPixels(CGFontGetXHeight(_font), pointSize, _unitsPerEm));
}


- (CGContextRef)measuringContext
{
    CGContextRef measuringContext = (CGContextRef)pthread_getspecific(sGraphicsContextKey);
    if(!measuringContext) {
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
        measuringContext = CGBitmapContextCreate(NULL, 1, 1, 8, 4, colorspace, 0);
        CGColorSpaceRelease(colorspace);
        pthread_setspecific(sGraphicsContextKey, measuringContext);
        // Context will be released on thread destruction.
        
        CGContextSetTextDrawingMode(measuringContext, kCGTextInvisible);
        CGContextSetTextMatrix(measuringContext, _textTransform);             
    }
    if(_glyphMap) {
        CGContextSetFont(measuringContext, _font);
    } else {
        CGContextSelectFont(measuringContext,
                            [_fontName UTF8String],
                            1, kCGEncodingMacRoman);  
    }    
    return measuringContext;
}

- (void)_clearCachedArrays
{
    if(_lastStringAddress) {
        _lastStringAddress = nil;
    }
    
    _lastPointSize = 0.0f;
    _lastMaxWidth = 0.0f;
    _lastSize = CGSizeZero;
    
    if(_lastEncodedWords) {
        free(_lastEncodedWords);
        _lastEncodedWords = NULL;
    }
    
    if(_lastEncodedWordBuffer) {
        free(_lastEncodedWordBuffer);
        _lastEncodedWordBuffer = NULL;
    }
    
    
    if(_lastBreaks) {
        free(_lastBreaks);
        _lastBreaks = NULL;
    }
    
    _lastBreakCount = 0;
    
    if(_lastUsedBreaksIndexes) {
        free(_lastUsedBreaksIndexes);
        _lastUsedBreaksIndexes = 0;
    }
}


- (void)dealloc
{
    [self _clearCachedArrays];
    if(_font) {
        CGFontRelease(_font);
    }
    [_fontMap release];
    [_fontName release];
    //[_widthCache release];
    [super dealloc];
}

- (void)_setupFontForRenderingInContext:(CGContextRef)context pointSize:(CGFloat)pointSize flags:(THStringRendererFlags)flags
{
    if(_glyphMap) {
        CGContextSetFont(context, _font);
    } else {
        CGContextSelectFont(context,
                            [_fontName UTF8String],
                            1, kCGEncodingMacRoman);  
    }
    CGContextSetFontSize(context, PointsToPixels(pointSize));
    if((flags & THStringRendererFlagFauxBold) != 0) {
        CGContextSetLineWidth(context, _fauxBoldStrokeWidth);
        CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    } else if((flags & THStringRendererFlagNoHinting) != 0) {
        CGContextSetLineWidth(context, 0); 
        CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    } else {
        CGContextSetTextDrawingMode(context, kCGTextFill);
    }
    
    CGContextSetTextMatrix(context, _textTransform);     
}


- (CGSize)sizeForString:(NSString *)string inContext:(CGContextRef)context pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags
{
    if(_lastStringAddress == (void *)string && _lastPointSize == pointSize && _lastMaxWidth == maxWidth) {
        return _lastSize;
    }
    
    [self _clearCachedArrays];
    
    _lastStringAddress = string;
    _lastPointSize = pointSize;
    _lastMaxWidth = maxWidth;
    
    CGContextSaveGState(context);

    CGContextSetTextDrawingMode (context, kCGTextInvisible);
    
    if(_glyphMap) {
        CGContextSetFont(context, _font);
    } else {
        CGContextSelectFont(context,
                            [_fontName UTF8String],
                            1, kCGEncodingMacRoman);  
    }
    
    CGContextSetFontSize(context, PointsToPixels(pointSize));
    CGContextSetTextPosition(context, 0.0f, 0.0f);
    if(_glyphMap) {
        CGGlyph space = CFSwapInt16LittleToHost(_glyphMap[' ']);
        CGContextShowGlyphs(context, &space, 1);
    } else {
        CGContextShowText(context, " ", 1);
    }
    CGPoint endPoint = CGContextGetTextPosition(context);
    int spaceWidth = endPoint.x;
    
    _lastBreakCount = 0;
    
    NSArray *lines = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *wordsByLine = [[NSMutableArray alloc] init];
    for(NSString *line in lines) {
        NSArray *lineWords = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        _lastBreakCount += lineWords.count;
        [wordsByLine addObject:lineWords];
    }
    
    _lastBreaks = malloc(_lastBreakCount * sizeof(THBreak));
    _lastEncodedWords = malloc((_lastBreakCount + 1) * sizeof(void *));
    _lastEncodedWordBuffer = malloc(string.length * (_glyphMap ? sizeof(CGGlyph) : sizeof(char)));
    void *nextEncodedWordPointer = _lastEncodedWordBuffer;    
    
    THBreak *breakAt = _lastBreaks;
    void **lastEncodedWordsAt = _lastEncodedWords;
    int lineSoFarWidth = 0;
    
    int intermediateBufferLength = 0;
    UniChar *intermediateBuffer = NULL;
    for(NSArray *lineWords in wordsByLine) {
        for(NSString *word in lineWords) {
            size_t wordLength = word.length;
            void *thisEncodedWord = nextEncodedWordPointer;
            *lastEncodedWordsAt = thisEncodedWord;
            
            CGContextSetTextPosition(context, 0.0f, 0.0f);
            
            if(_glyphMap) {
                const UniChar *stringBuffer = CFStringGetCharactersPtr((CFStringRef)word);
                if(!stringBuffer) {
                    if(wordLength > intermediateBufferLength) {
                        intermediateBufferLength = wordLength;
                        intermediateBuffer = realloc(intermediateBuffer, sizeof(UniChar) * intermediateBufferLength);
                    }
                    stringBuffer = intermediateBuffer;
                    CFStringGetCharacters((CFStringRef)word, CFRangeMake(0, wordLength), (UniChar *)stringBuffer);
                }
                
                for(int i = 0; i < wordLength; ++i) {
                    *((CGGlyph *)nextEncodedWordPointer) = CFSwapInt16LittleToHost(_glyphMap[stringBuffer[i]]); 
                    nextEncodedWordPointer += sizeof(CGGlyph);
                }
                
                CGContextShowGlyphs(context, (CGGlyph *)thisEncodedWord, wordLength);
            } else {
                CFIndex usedBufLen;
                CFStringGetBytes((CFStringRef)word, CFRangeMake(0, wordLength), kCFStringEncodingMacRoman, '_', FALSE, thisEncodedWord, wordLength, &usedBufLen);
                nextEncodedWordPointer += sizeof(char) * usedBufLen;
                
                CGContextShowText(context, thisEncodedWord, usedBufLen);
            }
            
            endPoint = CGContextGetTextPosition(context);

            int wordWidth = endPoint.x;
            
            lineSoFarWidth += wordWidth;
            
            breakAt->x0 = lineSoFarWidth;
            
            if(wordLength) {
                lineSoFarWidth += spaceWidth;
            }
            
            breakAt->x1 = lineSoFarWidth;
            breakAt->penalty = 0;
            breakAt->flags = TH_JUST_WITH_FLOATS_FLAG_ISSPACE;
            
            ++breakAt;
            ++lastEncodedWordsAt;
        }
        (breakAt - 1)->flags |= TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
    }
    [wordsByLine release];
    if(intermediateBuffer) {
        free(intermediateBuffer);
    }
    
    *lastEncodedWordsAt = nextEncodedWordPointer;
    
    if((flags & THStringRendererFlagFairlySpaceLastLine) != 0) {
        // Remove the hard break from the end to make the justifier
        // justify fully all the lines equally.
        _lastBreaks[_lastBreakCount - 1].flags &= (!TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK); // Remove the hard break 
    }
    
    _lastUsedBreaksIndexes = malloc(_lastBreakCount * sizeof(int));
    _lastUsedBreakCount = th_just_with_floats(_lastBreaks, _lastBreakCount, 0, floorf(maxWidth), 0, _lastUsedBreaksIndexes);
    
    int longestLineLength = 0;
    int previousLineStart = 0;
    CGFloat lineHeight = [self lineSpacingForPointSize:pointSize];
    CGFloat halfLineHeight = roundf(lineHeight * 0.5f);
    CGFloat totalHeight = 0.0f;
    for(int i = 0; i < _lastUsedBreakCount; ++i) {
        int index = _lastUsedBreaksIndexes[i];
        int lineLength = _lastBreaks[index].x0 - previousLineStart;
        
        if(lineLength > longestLineLength) {
            longestLineLength = lineLength;
        }
        previousLineStart = _lastBreaks[index].x1;
        
        if((_lastBreaks[index].flags & TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) == TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK &&
           _lastBreaks[index].x1 - _lastBreaks[index].x0 == 0 &&
           index >= 1 && index < _lastBreakCount - 1 ) {
            // This is a blank line.
            totalHeight += halfLineHeight;
        } else {
            totalHeight += lineHeight;
        }            
    }
    
    _lastSize = CGSizeMake(ceilf(longestLineLength), totalHeight);
    
    CGContextRestoreGState(context);
    
    _lastFlags = flags;
    
    return _lastSize;
}


- (CGSize)sizeForString:(NSString *)string pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags
{
    return [self sizeForString:string inContext:[self measuringContext] pointSize:pointSize maxWidth:maxWidth flags:flags];
}

- (CGPoint)drawString:(NSString *)string inContext:(CGContextRef)context atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize
{
    CGFloat lineOffset = [self leadingForPointSize:pointSize] * 0.5f + [self ascenderForPointSize:pointSize];
    CGPoint point = [self drawString:string inContext:context atBaselinePoint:CGPointMake(originPoint.x, originPoint.y + lineOffset) pointSize:pointSize];
    point.y -= lineOffset;
    return point;
}

- (CGPoint)drawString:(NSString *)string inContext:(CGContextRef)context atBaselinePoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize
{
    CGContextSaveGState(context);
    
    [self _setupFontForRenderingInContext:context pointSize:pointSize flags:0];
        
    CGContextSetTextPosition(context, originPoint.x, originPoint.y);
    
    CFIndex length = CFStringGetLength((CFStringRef)string);
    
    if(_glyphMap) {
        CGGlyph glyphs[length];

        const UniChar *stringBuffer = CFStringGetCharactersPtr((CFStringRef)string);        
        if(!stringBuffer) {
            stringBuffer = alloca(sizeof(UniChar) * length);
            CFStringGetCharacters((CFStringRef)string, CFRangeMake(0, length), (UniChar *)stringBuffer);
        }
/*                
        CFIndex glyphLength = 0;
        int i = 0;
        for(; i < length; ++i) {
            if(stringBuffer[i] == 'f' && i < length - 1) {
                if(stringBuffer[i+1] == 'i') {
                    CGGlyph fi = _glyphMap[0xFB01];
                    if(fi) {
                        glyphs[glyphLength++] = fi;
                        ++i;
                        continue;
                    }
                } else if(stringBuffer[i+1] == 'f' && 
                          i < length - 2 && stringBuffer[i+2] == 'i') {
                    CGGlyph fi = _glyphMap[0xFB03];
                    if(fi) {
                        glyphs[glyphLength++] = fi;
                        i+= 2;
                        continue;
                    }                    
                }
            }
            glyphs[glyphLength++] = _glyphMap[stringBuffer[i]];
        }
        
        CGContextShowGlyphs(context, glyphs, glyphLength);
*/

        for(int i = 0; i < length; ++i) {
            glyphs[i] = CFSwapInt16LittleToHost(_glyphMap[stringBuffer[i]]); 
        }
        
        CGContextShowGlyphs(context, glyphs, length);

    } else {
        CFIndex maxMacRomanByteLength = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingMacRoman);
        CFIndex usedMacRomanByteLength = 0;
        UInt8 macRomanString[maxMacRomanByteLength];
        
        CFStringGetBytes((CFStringRef)string, CFRangeMake(0, length), kCFStringEncodingMacRoman, '_', FALSE, macRomanString, maxMacRomanByteLength, &usedMacRomanByteLength);

        CGContextShowText(context, (const char *)macRomanString, usedMacRomanByteLength);
    }   
    
    CGPoint point = CGContextGetTextPosition(context);
        
    CGContextRestoreGState(context);
    
    return point;
}

- (CGFloat)widthOfString:(NSString *)string pointSize:(CGFloat)pointSize
{
    //if(!_widthCache) {
    //    _widthCache = [[THStringAndCGFloatToCGFloatCache alloc] init];
    //}
    //CGFloat ret = [_widthCache cgFloatForStringKey:string cgFloatKey:pointSize];
    // if(!ret) {
        CGContextRef context = [self measuringContext];
        
        CGContextSetFontSize(context, PointsToPixels(pointSize));

        CGContextSetTextPosition(context, 0, 0);
        
        CFIndex length = CFStringGetLength((CFStringRef)string);
        
        if(_glyphMap) {
            CGGlyph glyphs[length];
            
            const UniChar *stringBuffer = CFStringGetCharactersPtr((CFStringRef)string);        
            if(!stringBuffer) {
                stringBuffer = alloca(sizeof(UniChar) * length);
                CFStringGetCharacters((CFStringRef)string, CFRangeMake(0, length), (UniChar *)stringBuffer);
            }
    /*        
            CFIndex glyphLength = 0;
            int i = 0;
            for(; i < length; ++i) {
                if(stringBuffer[i] == 'f' && i < length - 1) {
                    if(stringBuffer[i+1] == 'i') {
                        CGGlyph fi = _glyphMap[0xFB01];
                        if(fi) {
                            glyphs[glyphLength++] = fi;
                            ++i;
                            continue;
                        }
                    } else if(stringBuffer[i+1] == 'f' && 
                              i < length - 2 && stringBuffer[i+2] == 'i') {
                        CGGlyph fi = _glyphMap[0xFB03];
                        if(fi) {
                            glyphs[glyphLength++] = fi;
                            i+= 2;
                            continue;
                        }                    
                    }
                }
                glyphs[glyphLength++] = _glyphMap[stringBuffer[i]];
            }
            
            CGContextShowGlyphs(context, glyphs, glyphLength);
    */
            for(int i = 0; i < length; ++i) {
                glyphs[i] = CFSwapInt16LittleToHost(_glyphMap[stringBuffer[i]]); 
            }
            
            CGContextShowGlyphs(context, glyphs, length);
        } else {
            CFIndex maxMacRomanByteLength = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingMacRoman);
            CFIndex usedMacRomanByteLength = 0;
            UInt8 macRomanString[maxMacRomanByteLength];
            
            CFStringGetBytes((CFStringRef)string, CFRangeMake(0, length), kCFStringEncodingMacRoman, '_', FALSE, macRomanString, maxMacRomanByteLength, &usedMacRomanByteLength);
            
            CGContextShowText(context, (const char *)macRomanString, usedMacRomanByteLength);
        }   
        
        CGPoint point = CGContextGetTextPosition(context);
            
        CGFloat ret = point.x;
        
    //    [_widthCache cacheCGFloat:ret forStringKey:string cgFloatKey:pointSize];
    // }
    return ret;
}    

- (CGFloat)roundedWidthOfString:(NSString *)string pointSize:(CGFloat)pointSize
{
    return roundf([self widthOfString:string pointSize:pointSize]);
}


#define THStringRendererNonMetricsModifyingFlags (THStringRendererFlagCenter | THStringRendererFlagFauxBold | THStringRendererFlagRightJustify | THStringRendererFlagRoughJustify | THStringRendererFlagNoHinting)

- (CGSize)drawString:(NSString *)string inContext:(CGContextRef)context atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags {
    if(_lastStringAddress != (void *)string || 
       _lastPointSize != pointSize || 
       _lastMaxWidth != maxWidth ||
       (_lastFlags | THStringRendererNonMetricsModifyingFlags) != (flags | THStringRendererNonMetricsModifyingFlags)) {
        [self sizeForString:string inContext:context pointSize:pointSize maxWidth:maxWidth flags:flags];
    }
    
    CGContextSaveGState(context);
    
    [self _setupFontForRenderingInContext:context pointSize:pointSize flags:flags];
    
    CGFloat drawOffset = [self leadingForPointSize:pointSize] * 0.5f + [self ascenderForPointSize:pointSize];
    CGPoint drawPosition = CGPointMake(originPoint.x, originPoint.y + drawOffset);
    int nextBreakIndexIndex = 0;
    int nextBreakIndex = _lastUsedBreaksIndexes[nextBreakIndexIndex++];
    int wordCount = 0;
    int lineStart = 0;
    int justificationOffset = 0;
    
    unsigned randomSeed;
    THStringRendererFlags justificationFlags = flags & (THStringRendererFlagCenter | THStringRendererFlagRightJustify | THStringRendererFlagRoughJustify);
    if(justificationFlags == THStringRendererFlagCenter) {
        justificationOffset = roundf((maxWidth - _lastBreaks[_lastUsedBreaksIndexes[0]].x0) * 0.5f);
    } else if(justificationFlags == THStringRendererFlagRightJustify) {
        justificationOffset = roundf((maxWidth - _lastBreaks[_lastUsedBreaksIndexes[0]].x0));
    } else if(justificationFlags == THStringRendererFlagRoughJustify) {
        randomSeed = (unsigned)((intptr_t)self);
        justificationOffset = roundf((maxWidth - _lastBreaks[_lastUsedBreaksIndexes[0]].x0) * ((CGFloat)rand_r(&randomSeed) / (CGFloat)(RAND_MAX)) / 2.0f);
    }

    CGFloat maxRandomJustification = CGFLOAT_MAX;
    if(justificationFlags == THStringRendererFlagRoughJustify) {
        for(int i = 0; i < _lastUsedBreakCount; ++i) {
            nextBreakIndex = _lastUsedBreaksIndexes[i];
            int extraSpace = (maxWidth - (_lastBreaks[nextBreakIndex].x0 - lineStart));
            if(extraSpace < maxRandomJustification) {
                maxRandomJustification = extraSpace;
            }
            lineStart = _lastBreaks[nextBreakIndex].x1;
        }
        
        nextBreakIndex = _lastUsedBreaksIndexes[nextBreakIndexIndex - 1];
        lineStart = 0;
    }
    
    CGFloat lineHeight = [self lineSpacingForPointSize:pointSize];
    CGFloat halfLineHeight = roundf(lineHeight * 0.5f);
    BOOL lineHadWords = NO;
    for(int i = 0; i < _lastBreakCount; ++i) {
        if(wordCount == nextBreakIndex + 1) {
            drawPosition.y += lineHadWords ? lineHeight : halfLineHeight;
            drawPosition.x = originPoint.x;
            lineStart = _lastBreaks[nextBreakIndex].x1;
            nextBreakIndex = _lastUsedBreaksIndexes[nextBreakIndexIndex++];
            if(justificationFlags == THStringRendererFlagCenter) {
                justificationOffset = roundf((maxWidth - (_lastBreaks[nextBreakIndex].x0 - lineStart)) * 0.5f);
            } else if(justificationFlags == THStringRendererFlagRightJustify) {
                justificationOffset = roundf((maxWidth - (_lastBreaks[nextBreakIndex].x0 - lineStart)));
            } else if(justificationFlags == THStringRendererFlagRoughJustify) {
                justificationOffset = roundf(maxRandomJustification * ((CGFloat)rand_r(&randomSeed) / (CGFloat)(RAND_MAX)));
            }
            lineHadWords = NO;
        }
        CGContextSetTextPosition(context, drawPosition.x + justificationOffset, drawPosition.y);
        
        size_t length;
        if(_glyphMap) {
            length = (_lastEncodedWords[i + 1] - _lastEncodedWords[i]) / sizeof(CGGlyph);
            CGContextShowGlyphs(context, (const CGGlyph *)(_lastEncodedWords[i]), length);        
        } else {
            length = (_lastEncodedWords[i + 1] - _lastEncodedWords[i]) / sizeof(char);
            CGContextShowText(context, (const char *)(_lastEncodedWords[i]), length);
        }
        if(!lineHadWords && length) {
            lineHadWords = YES;
        }
        
        drawPosition.x = originPoint.x + (_lastBreaks[wordCount].x1 - lineStart);
        ++wordCount;
    }
    
    if(THWillLog()) {
        CGFloat drawnHeight = drawPosition.y + lineHeight - originPoint.y - drawOffset;
        NSParameterAssert(abs(drawnHeight - _lastSize.height) < 1);
    }
    
    CGContextRestoreGState(context);
    
    return _lastSize;
}

- (CGSize)drawString:(NSString *)string atPoint:(CGPoint)originPoint pointSize:(CGFloat)pointSize maxWidth:(CGFloat)maxWidth flags:(THStringRendererFlags)flags
{
#if TARGET_OS_IPHONE
    return [self drawString:string inContext:UIGraphicsGetCurrentContext() atPoint:originPoint pointSize:pointSize maxWidth:maxWidth flags:flags];
#else
    return [self drawString:string inContext:[[NSGraphicsContext currentContext] graphicsPort] atPoint:originPoint pointSize:pointSize maxWidth:maxWidth flags:flags];
#endif
}

@end