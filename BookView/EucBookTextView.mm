//
//  EucBookTextView.m
//  Eucalyptus
//
//  Created by James Montgomerie on 27/06/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "EucBookTextView.h"
#import "THLog.h"
#import "THPair.h"
#import "EucSharedHyphenator.h"
#import "THStringRenderer.h"
#import "THIntegerCache.h"
#import "THLowMemoryDictionaryEmptier.h"
#import "thjust.h"

using namespace std;
using namespace Hyphenate;

@implementation EucBookTextView

@synthesize delegate = _delegate;
@synthesize pointSize = _pointSize;
@synthesize leftMargin = _leftMargin;
@synthesize rightMargin = _rightMargin;
@synthesize textIndent = _textIndent;
@synthesize allowScaledImageDistortion = _allowScaledImageDistortion;

// We piggy-back some info on the justifier's flags.
#define BOOKTEXTVIEW_JUST_FLAG_IS_ZERO_WIDTH (TH_JUST_FLAG_ISHARDBREAK << 1)

- (id)initWithFrame:(CGRect)frame pointSize:(CGFloat)pointSize
{
	if((self = [super initWithFrame:frame])) {
        _pointSize = pointSize;
        
        _stringsCapacity = 256;
        _stringsCount = 0;
        _stringsWithAttributes = (NSString **)malloc(_stringsCapacity * sizeof(id));
        _stringPositions = (CGPoint *)malloc(_stringsCapacity * sizeof(CGPoint));
	
        _sharedHyphenator = (void *)SharedHyphenator::sharedHyphenator();
        
        EucBookTextStyle *style = [[EucBookTextStyle alloc] init];
        _lineHeight = ceilf([[style stringRenderer] lineSpacingForPointSize:_pointSize]);
        _spaceWidth = roundf([[style stringRenderer] widthOfString:@" " pointSize:_pointSize]);
        _emWidth = roundf([[style stringRenderer] widthOfString:@"\u2003" pointSize:_pointSize]);
        [style release];
        
        self.opaque = NO;
        self.clearsContextBeforeDrawing = NO;
    }
	return self;
}

- (void)dealloc 
{
    [_touch release];
    
    for(NSUInteger i = 0; i < _stringsCount; ++i) {
        [_stringsWithAttributes[i] release];
    }
    free(_stringsWithAttributes);
    free(_stringPositions);
        
	[super dealloc];
}

- (void)drawRect:(CGRect)rect inContext:(CGContextRef)cgContext
{
    CGContextSaveGState(cgContext);
    CGContextSetLineWidth(cgContext, 0.5);
    
    Class NSStringClass = [NSString class];
    
    BOOL inHyperlink = NO;
    id hyperlinkObject = nil;
    CGPoint hyperlinkStartPoint = CGPointZero;
    CGPoint previousStringPoint = CGPointZero;
    CGFloat previousStringWidth = 0;

    EucBookTextStyle *defaultAttribute = [[EucBookTextStyle alloc] init];
    THStringRenderer *defaultRenderer = [defaultAttribute stringRenderer];
    EucBookTextStyle *previousAttribute = defaultAttribute;
    
    for(NSUInteger i = 0; i < _stringsCount; ++i) {
        CGPoint point = _stringPositions[i];
        point.y += _pageYOffset;
        
        id stringWithAttribute = _stringsWithAttributes[i];
        if([stringWithAttribute isKindOfClass:NSStringClass]) {
            [defaultRenderer drawString:(NSString *)stringWithAttribute inContext:cgContext atPoint:point pointSize:_pointSize];
            previousAttribute = defaultAttribute;
        } else {
            EucBookTextStyle *attribute = ((THPair *)stringWithAttribute).second;
            id stringOrImage = ((THPair *)stringWithAttribute).first;
            if([stringOrImage isKindOfClass:NSStringClass]) {
                NSString *string = (NSString *)stringOrImage;
                            
                CGPoint afterDrawingPoint = [[attribute stringRenderer] drawString:string inContext:cgContext atPoint:point pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                CGFloat stringWidth = afterDrawingPoint.x - point.x;
                
                NSString *wordHyperlink = [attribute.attributes objectForKey:@"href"];
                
                if(inHyperlink && (!wordHyperlink || ![hyperlinkObject isEqual:wordHyperlink])) {
                    // Draw link up to previous word.
                    CGFloat lineY = floorf(hyperlinkStartPoint.y + [[previousAttribute stringRenderer] ascenderForPointSize:[previousAttribute fontPointSizeForPointSize:_pointSize]] + 2) - 0.5;
                    CGPoint lineEnds[2];
                    lineEnds[0] = CGPointMake(hyperlinkStartPoint.x, lineY);
                    lineEnds[1] = CGPointMake(previousStringPoint.x + previousStringWidth, lineY);
                    CGContextStrokeLineSegments(cgContext, lineEnds, 2);
                    
                    // We'll take care of starting the new link below, if necessary.
                    inHyperlink = NO;         
                }                
                
                if(wordHyperlink) {
                    if(inHyperlink) {
                        if(point.y != hyperlinkStartPoint.y) {                        
                            // Draw link to end of line.
                            CGFloat lineY = floorf(hyperlinkStartPoint.y + [[previousAttribute stringRenderer] ascenderForPointSize:[previousAttribute fontPointSizeForPointSize:_pointSize]] + 2) - 0.5;
                            CGPoint lineEnds[2];
                            lineEnds[0] = CGPointMake(hyperlinkStartPoint.x, lineY);
                            lineEnds[1] = CGPointMake(previousStringPoint.x + previousStringWidth, lineY);
                            CGContextStrokeLineSegments(cgContext, lineEnds, 2);
                            
                            // Move the start point to the next line.
                            hyperlinkStartPoint = point;
                        }
                    } else {                    
                        hyperlinkStartPoint = point;
                        hyperlinkObject = [attribute.attributes objectForKey:@"href"];
                        inHyperlink = YES;
                    }     
                    
                    previousStringWidth = stringWidth;
                    previousStringPoint = point;
                }
            } else {
                if(inHyperlink) {
                    // Draw link up to previous word.
                    CGFloat lineY = floorf(hyperlinkStartPoint.y + [[previousAttribute stringRenderer] ascenderForPointSize:[previousAttribute fontPointSizeForPointSize:_pointSize]] + 2) - 0.5;
                    CGPoint lineEnds[2];
                    lineEnds[0] = CGPointMake(hyperlinkStartPoint.x, lineY);
                    lineEnds[1] = CGPointMake(previousStringPoint.x + previousStringWidth, lineY);
                    CGContextStrokeLineSegments(cgContext, lineEnds, 2);
                    
                    // We'll take care of starting the new link below, if necessary.
                    inHyperlink = NO;         
                }                
                
                CGRect bounds = [self bounds];
                CGImageRef image = [(UIImage *)stringOrImage CGImage];
                CGContextSaveGState(cgContext);
                
                CGFloat width = [attribute imageWidthForPointSize:_pointSize];
                CGFloat height = [attribute lineHeightForPointSize:_pointSize];
                
                if(!_allowScaledImageDistortion) {
                    if(width > bounds.size.width || height > bounds.size.height) {
                        CGFloat widthMultiplier = bounds.size.width / width;
                        CGFloat heightMultiplier = bounds.size.height / height;
                        CGFloat multiplier = MIN(widthMultiplier, heightMultiplier);
                        width *= multiplier;
                        height *= multiplier;
                    }
                } else {
                    width = MIN(width, bounds.size.width);
                    height = MIN(height, bounds.size.height);
                }
                
                CGFloat fitX = bounds.size.width - width;
                CGFloat fitY = bounds.size.height - height;
                CGFloat myX = MIN(fitX, point.x);
                myX = MAX(0, myX);
                CGFloat myY = MIN(fitY, point.y);
                
                CGContextScaleCTM(cgContext, 1.0f, -1.0f);
                CGContextTranslateCTM(cgContext, myX, -(myY+height));
                CGContextSetBlendMode(cgContext, kCGBlendModeMultiply);
                CGContextSetInterpolationQuality(cgContext, kCGInterpolationHigh);
                CGContextDrawImage(cgContext, CGRectMake(0, 0, width, height), image);
                CGContextRestoreGState(cgContext);
            }
            previousAttribute = attribute;
        }
    }
    
    if(inHyperlink) {
        // Draw link up to previous word.
        CGFloat lineY = floorf(hyperlinkStartPoint.y + [[previousAttribute stringRenderer] ascenderForPointSize:[previousAttribute fontPointSizeForPointSize:_pointSize]] + 2) - 0.5;
        CGPoint lineEnds[2];
        lineEnds[0] = CGPointMake(hyperlinkStartPoint.x, lineY);
        lineEnds[1] = CGPointMake(previousStringPoint.x + previousStringWidth, lineY);
        CGContextStrokeLineSegments(cgContext, lineEnds, 2);        
    }                
    
    [defaultAttribute release];
    CGContextRestoreGState(cgContext);
}

- (void)drawRect:(CGRect)rect 
{
    [self drawRect:rect inContext:UIGraphicsGetCurrentContext()];
}    

static CFMutableDictionaryRef sHyphenationPointCache = nil;
static pthread_mutex_t sHyphenationPointCacheMutex = PTHREAD_MUTEX_INITIALIZER;
static THLowMemoryDictionaryEmptier *sHyphenationPointCacheLowMemoryEmptier;

static void _deleteVectorCallback(CFAllocatorRef allocator, const void *value)
{
    delete (vector<const HyphenationRule*> *)value;
}

// The sHyphenationPointCacheMutex mutex MUST be locked before a call to 
// this method, and MUST NOT be released until after the caller has finished
// using the returned vector.
- (vector<const HyphenationRule*> *)_hyphenationPointsForWord:(NSString *)word
{    
    if(!sHyphenationPointCache) {
        CFDictionaryValueCallBacks vectorDeleteCallbacks;
        vectorDeleteCallbacks.version = 0;
        vectorDeleteCallbacks.retain = NULL;
        vectorDeleteCallbacks.release = _deleteVectorCallback;
        vectorDeleteCallbacks.copyDescription = NULL;
        vectorDeleteCallbacks.equal = NULL;
        sHyphenationPointCache = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                           256, 
                                                           &kCFCopyStringDictionaryKeyCallBacks, 
                                                           &vectorDeleteCallbacks);
        sHyphenationPointCacheLowMemoryEmptier = [[THLowMemoryDictionaryEmptier alloc] initWithDictionary:sHyphenationPointCache
                                                                                                  mutex:&sHyphenationPointCacheMutex];
    }
    vector<const HyphenationRule*> *ret = (vector<const HyphenationRule*> *)CFDictionaryGetValue(sHyphenationPointCache, word);
    if(!ret) {
        ret = ((SharedHyphenator *)_sharedHyphenator)->applyHyphenationRules((CFStringRef)word).release();
        CFDictionarySetValue(sHyphenationPointCache, word, (void *)ret);
    }
    
    return ret;
}

- (void)addWord:(NSString *)word atPoint:(CGPoint)point attributes:(EucBookTextStyle *)attributes
{
    if(_stringsCount == _stringsCapacity) {
        _stringsCapacity *= 2;
        _stringsWithAttributes = (NSString **)realloc(_stringsWithAttributes, _stringsCapacity * sizeof(id));
        _stringPositions = (CGPoint *)realloc(_stringPositions, _stringsCapacity * sizeof(CGPoint));
    }
    if(attributes.isNonDefault) {
        _stringsWithAttributes[_stringsCount] = [[THPair alloc] initWithFirst:word second:attributes];
    } else {
        _stringsWithAttributes[_stringsCount] = [word retain];
    }
    _stringPositions[_stringsCount] = point;
    ++_stringsCount;
}

- (EucBookTextViewEndPosition)addParagraphWithWords:(NSArray *)words 
                                      attributes:(NSArray *)attributes 
              hyphenationPointsPassedInFirstWord:(NSUInteger)hyphensAlreadyPassed
                             indentBrokenLinesBy:(CGFloat)indentBrokenLinesBy
                                          center:(BOOL)center
                                         justify:(BOOL)justify
                                 justifyLastLine:(BOOL)justifyLastLine
                                       hyphenate:(BOOL)hyphenate
{
    pthread_mutex_lock(&sHyphenationPointCacheMutex);
    
    BOOL allowWidows = NO;
    BOOL widowsImpossible = NO;
    
    EucBookTextViewEndPosition ret = {0, 0, 0, _stringsCount};
    THLogVerbose(@"Adding words: %@", words);

    CGFloat startingY;
    
    // If we've already added some words to this page, start on the next
    // line (otherwise, start at the top of the page).
    startingY = _nextLineY;
        
    if(hyphensAlreadyPassed) {
        NSMutableArray *mutableWords = [[words mutableCopy] autorelease];
        NSString *firstWord = [words objectAtIndex:0];

        NSUInteger rulesPassed = 0;
        vector<const HyphenationRule*> *hyphenationPoints = [self _hyphenationPointsForWord:firstWord];
        vector<const HyphenationRule*>::const_iterator endAt = hyphenationPoints->end();
        int strPos = 0;
        for(vector<const HyphenationRule*>::const_iterator it = hyphenationPoints->begin();
            it != endAt;
            ++it, ++strPos) {
            const HyphenationRule *rule = *it;
            if(rule != NULL) {
                ++rulesPassed;
                if(rulesPassed == hyphensAlreadyPassed) {
                    std::pair<CFStringRef, int> applied = rule->create_applied_string_second(NULL);
                    NSUInteger skip = applied.second;                    

                    if(applied.first) {
                        NSString *afterBreak = (NSString *)applied.first;
                        [mutableWords replaceObjectAtIndex:0 withObject:
                          [afterBreak stringByAppendingString:[firstWord substringFromIndex:strPos + skip]]];
                        [afterBreak release];
                    } else {
                        [mutableWords replaceObjectAtIndex:0 withObject:[firstWord substringFromIndex:strPos + skip]];
                    }
                    break;
                }
            }
        }
        words = mutableWords;
    }
    
    NSInteger linesAdded = 0;
    // If can fit at least one line of text in, break the lines up. 
    CGRect frame = self.frame;
    CGFloat maxY = frame.size.height;
    if(startingY <= maxY) {     
        NSInteger wordCount = [words count];
        NSInteger breaksCapacity = wordCount * 2;
        THBreak *breaks = (THBreak *)malloc(breaksCapacity * sizeof(THBreak));
        int *wordWidths = (int *)malloc(wordCount * sizeof(int));
        // We'll cache the hyphenation points for each word in here for use
        // during layout.
        vector<const HyphenationRule*> * *hyphenationPointsForWords = (vector<const HyphenationRule*> * *)malloc(sizeof(vector<const HyphenationRule*> *) * wordCount);
        
        // The justifier takes input as if we have one long logical line.
        // As an optimisation, we calculate the maximum length of all the lines
        // left on the page, and will stop calculating breaks for the justifier
        // when we reach this length, since subsequent words could not fit on 
        // the page anyway.
        int xWidth = self.innerWidth;
        //int widthLeftOnPage = ((int)(ceilf((maxY - startingY) / paragraphLineHeight)) + 1) * xWidth;
        
        // Calculate the possible break points.
        int breakIndex = 0;
        int lineSoFarWidth = _textIndent;
        NSUInteger laidOutWordsCount = 0;
        for(NSString *word in words) {
            EucBookTextStyle *attribute = [attributes objectAtIndex:laidOutWordsCount];
            EucBookTextStyleFlag attributeFlags = attribute.flags;
            THStringRenderer *renderer = [attribute stringRenderer];
            UIImage *image = attribute.image;
            
            int wordWidth;
            if(image) {
                wordWidth = [attribute imageWidthForPointSize:_pointSize];
            } else {
                wordWidth = [renderer roundedWidthOfString:word pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
            }
            
            if(!hyphenate || [word length] < 5 || indentBrokenLinesBy || (attributeFlags & EucBookTextStyleFlagDontHyphenate) != 0 || image) {
                // No use hyphenating words this small.
                hyphenationPointsForWords[laidOutWordsCount] = NULL;
            } else {
                // Calculate the hyphenation points.
                // An auto_ptr is returned.  We release() its ownership, and store
                // the vector in a plain C array (hyphenationPointsForWords) for
                // later use.  The vecors are deleted at the end of this method
                // before the array is freed.
                vector<const HyphenationRule*> *hyphenationPoints = [self _hyphenationPointsForWord:word];
                hyphenationPointsForWords[laidOutWordsCount] = hyphenationPoints;
                
                // For each found hyphenation point, there will be a rule for
                // the hyphenation at that point in the returned hyphenationPoints 
                // vector.
                // Use these rule to calculate the properties for breaks at these 
                // points for the justification routine.
                vector<const HyphenationRule*>::const_iterator endAt = hyphenationPoints->end();
                int strPos = 0;
                for(vector<const HyphenationRule*>::const_iterator it = hyphenationPoints->begin();
                    it != endAt;
                    ++it, ++strPos) {
                    // If there's a possible hyphenation at this point in the word.
                    const HyphenationRule *rule = *it;
                    if(rule != NULL) {
                        // Apply the rule to get the before-and-after strings 
                        // around the line break.
                        NSString *beforeBreak = (NSString *)rule->create_applied_string_first((CFStringRef)[word substringToIndex:strPos], CFSTR("-"));
                        
                        std::pair<CFStringRef, int> applied = rule->create_applied_string_second(NULL);
                        NSUInteger skip = applied.second;
                        NSString *afterBreak;
                        if(applied.first) {
                            NSString *afterBreakStart = (NSString *)applied.first;
                            afterBreak = [afterBreakStart stringByAppendingString:[word substringFromIndex:strPos + skip]];
                            [afterBreakStart release];
                        } else {
                            afterBreak = [word substringFromIndex:strPos + skip];
                        }
                        
                        // Get the widths of the strings, and use these to set up 
                        // break points for justification.
                        int beforeWidth = [renderer roundedWidthOfString:beforeBreak pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                        int afterWidth = [renderer roundedWidthOfString:afterBreak pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                        
                        THLogVerbose(@"Hyphenation break for word %@ - %@=%@", word, beforeBreak, afterBreak);
                        [beforeBreak release];

                        // x0 and x1 definitions from the justification routine docs.
                        
                        // x0 = first line width
                        //    = line so far width + before hyphen width
                        breaks[breakIndex].x0 = lineSoFarWidth + beforeWidth;
                        
                        // x1 = first line width + unbroken width - (first line width + second line width);
                        //    = first line width + unbroken width - first line width - second line width
                        //    = unbroken line width - second line width
                        //    = first line width + second line width - additional space taken by hyphenation - second line width
                        //    = first line width - additional space taken by hyphenation
                        //    = line so far width + before hyphen width - (before hyphen width + after hyphen width - regular word width)
                        //    = line so far width - after hyphen width + regular word width
                        breaks[breakIndex].x1 = lineSoFarWidth - afterWidth + wordWidth;

                        breaks[breakIndex].penalty = 0;
                        breaks[breakIndex].flags = TH_JUST_FLAG_ISHYPHEN;
                        ++breakIndex;
                        
                        // Resize the breaks array if we've reached the end 
                        // (probably will not happen).
                        if(breakIndex >= breaksCapacity) {
                            breaksCapacity += wordCount;
                            breaks = (THBreak *)realloc(breaks, breaksCapacity * sizeof(THBreak));
                        }
                    }
                }
            }
                        
            // Set up a break point for the regular break at the end of the word.
            lineSoFarWidth += wordWidth;
            breaks[breakIndex].x0 = lineSoFarWidth;
            breaks[breakIndex].flags = TH_JUST_FLAG_ISSPACE;
            if((attributeFlags & EucBookTextStyleFlagNonBreaking) != 0) {
                breaks[breakIndex].penalty = xWidth;
            } else  {
                breaks[breakIndex].penalty = 0;
            }
            
            if((attributeFlags & EucBookTextStyleFlagHardBreak) != 0) {
                breaks[breakIndex].flags |= TH_JUST_FLAG_ISHARDBREAK;
            }
            
            if((attributeFlags & EucBookTextStyleFlagZeroSpace) != 0) {
                breaks[breakIndex].flags |= BOOKTEXTVIEW_JUST_FLAG_IS_ZERO_WIDTH;
            } else {
                lineSoFarWidth += [attribute spaceWidthForPointSize:_pointSize]; 
            }
            
            breaks[breakIndex].x1 = lineSoFarWidth;
            if(indentBrokenLinesBy &&
               (attributeFlags & EucBookTextStyleFlagHardBreak) == 0) {
                breaks[breakIndex].x1 -= indentBrokenLinesBy;
            }
            ++breakIndex;

            wordWidths[laidOutWordsCount] = wordWidth;
            ++laidOutWordsCount;
            
            // No use in continuing if we couldn't fit more on the page.
           // if(lineSoFarWidth > widthLeftOnPage && 
           //    (attributeFlags & EucBookTextStyleFlagNonBreaking) == 0) {
           //     widowsImpossible = YES;
           //     break;
           // } 
            
            // Resize the breaks array if we've reached the end 
            // (probably will not happen).
            if(breakIndex >= breaksCapacity) {
                breaksCapacity += wordCount;
                breaks = (THBreak *)realloc(breaks, breaksCapacity * sizeof(THBreak));
            }
        } 
        
        // Fix up the last break - there's no real break after the last word,
        // but the justifier still needs to know about it becaue it's the
        // end of the paragraph.
        breaks[breakIndex-1].x1 = breaks[breakIndex-1].x0;
        if(!justifyLastLine) {
            breaks[breakIndex-1].flags = TH_JUST_FLAG_ISHARDBREAK;
        }
        
        // Finally, run the break finding algorithm.
        int *usedBreakIndices = (int *)malloc(breakIndex * sizeof(int));
        int usedBreakCount = th_just(breaks, breakIndex, (int)xWidth, 0/*11 * (int)paragraphSpaceWidth*/, usedBreakIndices);
                
        if(!allowWidows) {
            if(usedBreakCount == 3) {
                // If we don't allow widows in three-line paragraph, what happens
                // is that the second-last line gets puched onto the next page,
                // then the first line is an orphan, and gets pushed there too.
                // This leaves too much whitespace on the page, so we just give
                // up if this is a three-line paragraph.
                allowWidows = YES;
            }
        }
        
        THLogVerbose(@"Used break count is %d", usedBreakCount);
        if(THWillLogVerbose()) {
            int jj = 0;
            for(int ii = 0; ii < breakIndex; ++ii) {
                printf("Break: {%d, %d, %d, %x}", breaks[ii].x0, breaks[ii].x1, breaks[ii].penalty, breaks[ii].flags);
                if(usedBreakIndices[jj] == ii) {
                    ++jj;
                    printf(" USED\n");
                } else {
                    printf("\n");
                }
            }
        }
                
        // Using the breaks returned by the justification algorithm,
        // calculate the position of the words, justifying to fill the line:        
        int breakBeforeThisLineIndex = -1;
        CGFloat currentY = startingY;
        int lastUsedBreakIndexIndex = usedBreakCount - 1;
        
        
        // How many potential hyphens in the current word have we passed?
        int hyphenCountInWord = 0;             
        
        // Updated when adding words in the loop.
        // When the loop exits, this will contain the index of the last added word.
        int hyphenCountAtEndOfLastLine = 0;              
                
        // The index of the next word to add.
        int wordToAddIndex = 0;
        int beforeLineWordToAddIndex = 0;
        NSUInteger beforeLineStringsCount = 0;
        int beforeLineHyphenCountAtEndOfLastLine = 0;              
        int usedBreakIndexIndex = 0;
        
        int lastPostHardBreakStringCount = 0;
        int lastPostHardBreakWordToAddIndex = 0;
        CGFloat lastPostHardBreakY = currentY;
        CGFloat newLineHeight = 0;
        CGFloat currentLineHeight = 0;
        // For each found break (and therefore, for each found line):
        for(; usedBreakIndexIndex <= lastUsedBreakIndexIndex; ++usedBreakIndexIndex) { 
            EucBookTextStyle *firstWordStyle = [attributes objectAtIndex:wordToAddIndex];
            newLineHeight = [firstWordStyle lineHeightForPointSize:_pointSize];
            if(firstWordStyle.image && newLineHeight >= maxY) {
                newLineHeight = maxY;
                if(currentY + newLineHeight > maxY) {
                    break;
                }                
            } else {
                if(currentY + newLineHeight >= maxY) {
                    break;
                }
            }
            currentLineHeight = newLineHeight;
            CGFloat currentLineSpaceWidth = [firstWordStyle spaceWidthForPointSize:_pointSize];

            BOOL rightJustify = firstWordStyle.textAlign == EucBookTextStyleTextAlignRight;
            
            beforeLineStringsCount = _stringsCount;
            beforeLineWordToAddIndex = wordToAddIndex;
            beforeLineHyphenCountAtEndOfLastLine = hyphenCountAtEndOfLastLine;
            
            int breakEndingThisLineIndex = usedBreakIndices[usedBreakIndexIndex];
            
            THLogVerbose(@"Line has %d inner breaks (%d - %d)", breakEndingThisLineIndex - breakBeforeThisLineIndex + 1, breakBeforeThisLineIndex+1 , breakEndingThisLineIndex);
                        
            // Calculate the total space used by the words on the line 
            // preceeding the break.
            int lineWordsPixelWidth = 0;            
            
            // Work out how much space the spaces must use up, in total,
            // on this line.
            int spacesRequiredOnLine = 0;
            int spacesMustTakeUpPixels = 0;     
            NSString *trailingHyphenatedPart = nil; // From the last line. 
            NSString *lastWordOnLineBeforeHyphenPortion = nil;
            int firstWordOnNextLineIndex = wordToAddIndex;
            
            // Count the space taken by whole words.
            // Also, keep track of how many hyphens in the last hyphenated
            // word we pass, so that we know where to hyphenate if the break
            // is a hyphen.
            int breakIndex;
            BOOL skipCountingLengthForNextBreak = hyphenCountAtEndOfLastLine != 0;
            for(breakIndex = breakBeforeThisLineIndex + 1; breakIndex <= breakEndingThisLineIndex; ++breakIndex) {
                int breakFlags = breaks[breakIndex].flags;
                if((breakFlags & TH_JUST_FLAG_ISHYPHEN) != 0) {
                    ++hyphenCountInWord;
                } else { 
                    hyphenCountInWord = 0;
                    if(skipCountingLengthForNextBreak) {
                        // Don't count the space taken by the whole of 
                        // the partially hyphenated word, if we started
                        // off inside one.
                        skipCountingLengthForNextBreak = NO;
                    } else {
                        if((breakFlags & TH_JUST_FLAG_ISSPACE) != 0 &&
                           (breakFlags & BOOKTEXTVIEW_JUST_FLAG_IS_ZERO_WIDTH) == 0) {
                            ++spacesRequiredOnLine;
                        }                            
                        lineWordsPixelWidth += wordWidths[firstWordOnNextLineIndex];
                    } 
                    hyphenCountInWord = 0;
                    ++firstWordOnNextLineIndex;                        
                }  
            }
                        
            if(wordToAddIndex == 0) {
                lineWordsPixelWidth += _textIndent;
            }
            if((indentBrokenLinesBy && breakBeforeThisLineIndex >= 0 && ((breaks[breakBeforeThisLineIndex].flags & TH_JUST_FLAG_ISHARDBREAK) == 0))) {
                lineWordsPixelWidth += indentBrokenLinesBy;
            }
            
            
            int breakEndingThisLineFlags = breaks[breakEndingThisLineIndex].flags;
            if((breakEndingThisLineFlags & TH_JUST_FLAG_ISSPACE) != 0 &&
               (breakEndingThisLineFlags & BOOKTEXTVIEW_JUST_FLAG_IS_ZERO_WIDTH) == 0) {
                --spacesRequiredOnLine; // Don't count a space after the last word.
            }   
            
            // If we stopped on a hyphen:
            if(hyphenCountInWord != 0) {
                // Work out the leading part of the hyphenated word (at firstWordOnNextLineIndex).
                vector<const HyphenationRule*> *hyphenationPoints = hyphenationPointsForWords[firstWordOnNextLineIndex];

                // Hyphenation rules are returned by the hyphenation
                // routine in a vector of the same length as the word, with
                // NULL in the positions where hyphenation is not possible,
                // and a rule object in the positions where it is.  We need
                // to map to the correct rule object by iterating through the
                // vector and counting the rules we pass to find the 
                // hyphenCountInWord-th rule.
                // We also keep track of the index into the array, to work 
                // out the character index to break the word string at.
                const HyphenationRule *rule = NULL;
                int foundRuleIndex = 0;
                int indexOfCharacterForBreak = -1;
                for(vector<const HyphenationRule*>::const_iterator it = hyphenationPoints->begin();
                    foundRuleIndex < hyphenCountInWord;
                    ++it) {
                    rule = *it;
                    if(rule) {
                        ++foundRuleIndex;
                    }
                    ++indexOfCharacterForBreak;
                }
                
                lastWordOnLineBeforeHyphenPortion = (NSString *)rule->create_applied_string_first((CFStringRef)[[words objectAtIndex:firstWordOnNextLineIndex] substringToIndex:indexOfCharacterForBreak], CFSTR("-"));
                [lastWordOnLineBeforeHyphenPortion autorelease];
                // Store it in lastWordOnLineBeforeHyphenPortion
                
                // Work out its width and add it to the line width.
                EucBookTextStyle *attribute = [attributes objectAtIndex:firstWordOnNextLineIndex];
                THStringRenderer *renderer = [attribute stringRenderer];
                lineWordsPixelWidth += [renderer roundedWidthOfString:lastWordOnLineBeforeHyphenPortion pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
            }

            // If we start on a hyphen
            if(hyphenCountAtEndOfLastLine != 0) {
                NSString *wordToHyphenate;
                // If it's the same word as the ending word.
                if(wordToAddIndex == firstWordOnNextLineIndex) {
                    // use the previously worked out lastWordOnLineBeforeHyphenPortion as the root word.
                    wordToHyphenate = lastWordOnLineBeforeHyphenPortion;
                    lastWordOnLineBeforeHyphenPortion = nil;
                } else {
                    // use the word at wordToAddIndex.
                    wordToHyphenate = [words objectAtIndex:wordToAddIndex];
                }
                
                vector<const HyphenationRule*> *hyphenationPoints = hyphenationPointsForWords[wordToAddIndex];
                const HyphenationRule *rule = NULL;
                int foundRuleIndex = 0;
                int indexOfCharacterForBreak = -1;
                for(vector<const HyphenationRule*>::const_iterator it = hyphenationPoints->begin();
                    foundRuleIndex < hyphenCountAtEndOfLastLine;
                    ++it) {
                    rule = *it;
                    if(rule) {
                        ++foundRuleIndex;
                    }
                    ++indexOfCharacterForBreak;
                }
                
                // work out the trailing hyphenated word, store it in trailingHyphenatedPart.
                std::pair<CFStringRef, int> applied = rule->create_applied_string_second(NULL);
                NSUInteger skip = applied.second;
                if(applied.first) {
                    NSString *afterBreakStart = (NSString *)applied.first;
                    trailingHyphenatedPart = [afterBreakStart stringByAppendingString:[wordToHyphenate substringFromIndex:indexOfCharacterForBreak + skip]];
                    [afterBreakStart release];
                } else {
                    trailingHyphenatedPart = [wordToHyphenate substringFromIndex:indexOfCharacterForBreak + skip];
                }
                                
                // we need an extra space before it.
                // Work out its width and add it to the line width.
                EucBookTextStyle *attribute = [attributes objectAtIndex:wordToAddIndex];

                THStringRenderer *renderer = [attribute stringRenderer];
                lineWordsPixelWidth += [renderer roundedWidthOfString:trailingHyphenatedPart pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                spacesRequiredOnLine++;
            }
                                        
            THLogVerbose(@"%d pixels used by words (inc. hyphenated words)", lineWordsPixelWidth);

            // How much space remains available for spaces?
            if(usedBreakIndexIndex != lastUsedBreakIndexIndex && !center && justify && 
               !rightJustify && (breakEndingThisLineFlags & TH_JUST_FLAG_ISHARDBREAK) == 0) {
                spacesMustTakeUpPixels = xWidth - lineWordsPixelWidth;
            } else {
                spacesMustTakeUpPixels = spacesRequiredOnLine * currentLineSpaceWidth;
            }
            
            // Now, lay out the words on the line using the calculated 
            // spacing information.
            THLogVerbose(@"Laying out line of %d words", firstWordOnNextLineIndex - wordToAddIndex);
            
            int currentX = _leftMargin;
            if(wordToAddIndex == 0) {
                currentX += _textIndent;
            }
            if((indentBrokenLinesBy && breakBeforeThisLineIndex >= 0 && ((breaks[breakBeforeThisLineIndex].flags & TH_JUST_FLAG_ISHARDBREAK) == 0))) {
                currentX += indentBrokenLinesBy;
            }
            if(center) {
                currentX += ((xWidth - currentX) - (lineWordsPixelWidth + spacesMustTakeUpPixels) + 1) / 2;
            }
            if(rightJustify) {
                currentX += (xWidth - (lineWordsPixelWidth + spacesMustTakeUpPixels));
            }
            
            int spacesRemainingOnLine = spacesRequiredOnLine;
     
            // We'll update this during layout, dividing it at eash word by the 
            // number of spaces still to lay out on this line. 
            // We do it this way because if we were to calculate pixels-per-
            // space now by division, layout could be wrong because of rounding 
            // errors.
            int remainingSpacesMustTakeUpPixels = spacesMustTakeUpPixels;
            
            // Once again, we'll use the data in the breaks array to work out
            // the word widths instead of recalculating them.
            // This stores the index to the break after the last printed word
            // so that we can read where it ended on the giant "logical
            // paragraph line".
            int breakAfterLastAddedWordIndex = breakBeforeThisLineIndex;
            
            // First, lay out the trailing hyphenated part-word from the
            // previous line, if any.
            if(trailingHyphenatedPart) {
                EucBookTextStyle *attribute = [attributes objectAtIndex:wordToAddIndex];

                THStringRenderer *renderer = [attribute stringRenderer];
                int wordWidth = [renderer roundedWidthOfString:trailingHyphenatedPart pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                
                [self addWord:trailingHyphenatedPart 
                      atPoint:CGPointMake(currentX, currentY) 
                   attributes:attribute];
                
                if(spacesRemainingOnLine && 
                   (attribute.flags & EucBookTextStyleFlagZeroSpace) == 0) {
                    int paragraphSpaceWidth = remainingSpacesMustTakeUpPixels / spacesRemainingOnLine;
                    currentX += paragraphSpaceWidth + wordWidth;
                    remainingSpacesMustTakeUpPixels -= paragraphSpaceWidth;
                    spacesRemainingOnLine -= 1; 
                } else {
                    currentX += wordWidth;
                }
                if(wordToAddIndex != firstWordOnNextLineIndex) {
                    ++wordToAddIndex;
                    while((breaks[++breakAfterLastAddedWordIndex].flags & TH_JUST_FLAG_ISHYPHEN) == TH_JUST_FLAG_ISHYPHEN);
                }
            }
                        
            // Next, lay out the remaining whole words.
            for(; wordToAddIndex < firstWordOnNextLineIndex; ++wordToAddIndex) {
                while((breaks[++breakAfterLastAddedWordIndex].flags & TH_JUST_FLAG_ISHYPHEN) == TH_JUST_FLAG_ISHYPHEN);
                int wordWidth = wordWidths[wordToAddIndex];
                
                EucBookTextStyle *stringAttribute = [attributes objectAtIndex:wordToAddIndex];
                
                if(stringAttribute.image) {
                    [self addWord:(NSString *)stringAttribute.image 
                          atPoint:CGPointMake(currentX, currentY) 
                       attributes:stringAttribute];                                        
                } else {
                    [self addWord:[words objectAtIndex:wordToAddIndex] 
                          atPoint:CGPointMake(currentX, currentY) 
                       attributes:stringAttribute];                    
                }
                
                if(spacesRemainingOnLine && 
                   (stringAttribute.flags & EucBookTextStyleFlagZeroSpace) == 0) {
                    int paragraphSpaceWidth = remainingSpacesMustTakeUpPixels / spacesRemainingOnLine;
                    currentX += paragraphSpaceWidth + wordWidth;
                    remainingSpacesMustTakeUpPixels -= paragraphSpaceWidth;
                    spacesRemainingOnLine -= 1; 
                } else {
                    currentX += wordWidth;
                }
            }
            
            // Lay out the before-line-break portion of the hyphenated word 
            // ending this line, if any.
            if(lastWordOnLineBeforeHyphenPortion) {
                [self addWord:lastWordOnLineBeforeHyphenPortion 
                      atPoint:CGPointMake(currentX, currentY) 
                   attributes:[attributes objectAtIndex:wordToAddIndex]];                
            }

            // Get ready for the next iteration
            hyphenCountAtEndOfLastLine = hyphenCountInWord;
            breakBeforeThisLineIndex = breakEndingThisLineIndex;
            currentY += currentLineHeight;
            ++linesAdded;
            
            if((breaks[breakAfterLastAddedWordIndex].flags & TH_JUST_FLAG_ISHARDBREAK)) {
                lastPostHardBreakStringCount = _stringsCount;
                lastPostHardBreakY = currentY;
                lastPostHardBreakWordToAddIndex = wordToAddIndex;
            }            
        }
    
        if(!widowsImpossible && !allowWidows && usedBreakCount > 1 && usedBreakIndexIndex == lastUsedBreakIndexIndex) {
            if(currentY + newLineHeight >= maxY) {
                // We have a widow.  Backtrack to remove it.
                wordToAddIndex = beforeLineWordToAddIndex;
                hyphenCountAtEndOfLastLine = beforeLineHyphenCountAtEndOfLastLine;
                _stringsCount = beforeLineStringsCount;
                currentY -= currentLineHeight;
                --linesAdded;
            }
        }
        
        if(indentBrokenLinesBy && usedBreakIndexIndex != lastUsedBreakIndexIndex) {
            -- usedBreakIndexIndex;
            while(usedBreakIndexIndex >= 0 && (breaks[usedBreakIndices[usedBreakIndexIndex]].flags & TH_JUST_FLAG_ISHARDBREAK) == 0) {
                --usedBreakIndexIndex;
                --linesAdded;
            }
            _stringsCount = lastPostHardBreakStringCount;
            currentY = lastPostHardBreakY;
            wordToAddIndex = lastPostHardBreakWordToAddIndex;
            hyphenCountAtEndOfLastLine = 0;
        }
        
        free(hyphenationPointsForWords);
        free(breaks);
        free(wordWidths);
        free(usedBreakIndices);
        
        _nextLineY = currentY;
        
        // wordToAddIndex contains the index of the next word to add.
        ret.completeWordCount = wordToAddIndex;
        ret.hyphenationPointsPassedInNextWord = hyphenCountAtEndOfLastLine;
    } else { 
        ret.hyphenationPointsPassedInNextWord = hyphensAlreadyPassed;
    }
    
    if(hyphensAlreadyPassed && [words count] == 1) {
        ret.hyphenationPointsPassedInNextWord += hyphensAlreadyPassed;
    }
    
    ret.completeLineCount = linesAdded;
    
    pthread_mutex_unlock(&sHyphenationPointCacheMutex);
    
    return ret;
}

- (BOOL)addString:(NSString *)string 
           center:(BOOL)center 
          justify:(BOOL)justify
           italic:(BOOL)italic
{
    BOOL ret = YES;
    EucBookTextViewEndPosition endPosition;
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    id italicAttribute = nil;
    id nullAttribute = nil;
    for(NSString *line in lines) {
        BOOL mutableWords = NO;
        NSArray *words = [line componentsSeparatedByString:@" "];
        NSMutableArray *attributes = nil;
        
        NSInteger count = words.count;
        
        if(italic) {
            if(!italicAttribute) {
                italicAttribute = [[EucBookTextStyle alloc] init];
                [italicAttribute setStyle:@"font-style" to:@"italic"];
            }
            
            id italicAttributes[count];
            for(NSInteger i = 0; i < count; ++i) {
                italicAttributes[i] = italicAttribute;
            }
            
            attributes = [NSMutableArray arrayWithObjects:italicAttributes count:count];
        } else {
            if(!nullAttribute) {
                nullAttribute = [EucBookTextStyle bookTextStyleWithFlag:EucBookTextStyleFlagNone];
            }
            
            id nullAttributes[count];
            for(NSInteger i = 0; i < count; ++i) {
                nullAttributes[i] = nullAttribute;
            }
            
            attributes = [NSMutableArray arrayWithObjects:nullAttributes count:count];                                
        }
        
        for(NSInteger wordIndex = 0; wordIndex < count; ++wordIndex) {
            NSString *word = [words objectAtIndex:wordIndex];
            
            NSRange linkMarkRange = [word rangeOfString:@"§"];
            if(linkMarkRange.location != NSNotFound) {
                NSString *link = [word substringFromIndex:linkMarkRange.location + linkMarkRange.length];
                word = [word substringToIndex:linkMarkRange.location];
                
                EucBookTextStyle *hyperlinkedStyle = [[attributes objectAtIndex:wordIndex] copy];
                [hyperlinkedStyle setAttribute:@"href" to:link];
                [attributes replaceObjectAtIndex:wordIndex withObject:hyperlinkedStyle];
                [hyperlinkedStyle release];
                if(!mutableWords) {
                    words = [words mutableCopy];
                }
                [(NSMutableArray *)words replaceObjectAtIndex:wordIndex withObject:word];
            }
            
            if([word hasPrefix:@"~"]) {
                if(!mutableWords) {
                    words = [words mutableCopy];
                }
                [(NSMutableArray *)words replaceObjectAtIndex:wordIndex withObject:[word substringFromIndex:1]];     
                [attributes replaceObjectAtIndex:wordIndex-1 withObject:[(EucBookTextStyle *)[attributes objectAtIndex:wordIndex-1] styleBySettingFlag:(EucBookTextStyleFlag)(EucBookTextStyleFlagNonBreaking | EucBookTextStyleFlagZeroSpace)]];
            }
            
            if([word hasPrefix:@"¡"]) {
                if(!mutableWords) {
                    words = [words mutableCopy];
                }
                [(NSMutableArray *)words replaceObjectAtIndex:wordIndex withObject:[word substringFromIndex:1]];     
                [attributes replaceObjectAtIndex:wordIndex withObject:[(EucBookTextStyle *)[attributes objectAtIndex:wordIndex] styleBySettingFlag:(EucBookTextStyleFlag)(EucBookTextStyleFlagDontHyphenate)]];
            }            
        }
        
        endPosition = [self addParagraphWithWords:words
                                       attributes:attributes
               hyphenationPointsPassedInFirstWord:0
                              indentBrokenLinesBy:0
                                           center:center
                                          justify:justify
                                  justifyLastLine:NO
                                        hyphenate:NO];
            
        if(endPosition.completeWordCount != words.count) {
            [self removeFromCookie:endPosition.removalCookie];
            ret = NO;
        }
    }
    return ret;
}

- (void)addBlankLines:(CGFloat)blankLineCount
{
    _nextLineY += blankLineCount * _lineHeight;
}

- (void)addVerticalSpace:(CGFloat)verticalSpace;
{
    _nextLineY += verticalSpace;
}

- (CGFloat)outerWidth 
{
    return self.frame.size.width;
}

- (CGFloat)innerWidth 
{
    return self.frame.size.width - _leftMargin - _rightMargin;
}

- (void)setIndentation:(NSUInteger)indentationCount
{
    _rightMargin = indentationCount * _emWidth * 0.75; 
    _leftMargin = indentationCount * _emWidth * 0.75; 
}

- (CGFloat)textIndentForEms:(CGFloat)textIndent
{
    return textIndent * _emWidth;
}

// This moves the page content be centered around 1/4 of the page down, but 
// getting closer to 1/2 of the page down as the content grows vertically,
// accelerating towards 1/2 as the content nears page height
// (so content that's bigger will be closer to 1/2 of the way down than it
// would be just using a straight ratio).
//
// Originally, I centered the content vertically, but that just looked weird,
// this seems more pleasing on the eye.
- (void)pleasinglyDistributeContentVertically
{
    if(_stringsCount) {
        CGFloat minY = _stringPositions[0].y;
        CGFloat maxY = _stringPositions[_stringsCount-1].y + _lineHeight;
        CGFloat contentHeight = maxY - minY;
        CGFloat frameHeight = self.frame.size.height;

        CGFloat contentToFrameRatio = contentHeight / frameHeight;
        CGFloat centrePointFraction = sinf(contentToFrameRatio * (M_PI_2)) / 4 + 0.25;

        CGFloat newMinY = (centrePointFraction * frameHeight) - (contentHeight / 2);
        
        _pageYOffset = ceilf(newMinY - minY);
        if(_pageYOffset < _lineHeight) {
            _pageYOffset = 0;
        }
    }
}

- (void)removeFromCookie:(NSUInteger)removalCookie
{
    for(NSUInteger i = removalCookie; i < _stringsCount; ++i) {
        [_stringsWithAttributes[i] release];
    }
    _stringsCount = removalCookie;
}

- (void)clear
{
    for(NSUInteger i = 0; i < _stringsCount; ++i) {
        [_stringsWithAttributes[i] release];
    }
    _stringsCount = 0;
    _nextLineY = 0;
    _leftMargin = 0;
    _rightMargin = 0;
    _pageYOffset = 0;
}


- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location
{
    if(!_touch) {
        _touch = [touch retain];
        _trackingWord = NO;
        
        Class THPairClass = [THPair class];
        for(NSUInteger i = 0; i < _stringsCount; ++i) {
            THPair *potentialStringWithAttibutes = _stringsWithAttributes[i];
            if([potentialStringWithAttibutes isKindOfClass:THPairClass]) {
                EucBookTextStyle *attribute = potentialStringWithAttibutes.second;
                if([attribute.attributes objectForKey:@"href"]) {
                    CGRect hotArea;
                    hotArea.origin.x = _stringPositions[i].x - _spaceWidth / 2;
                    hotArea.origin.y = _stringPositions[i].y + _pageYOffset;
                    if(attribute.image) {
                        hotArea.size.width = [attribute imageWidthForPointSize:_pointSize];
                    } else {
                        hotArea.size.width = [[attribute stringRenderer] roundedWidthOfString:potentialStringWithAttibutes.first 
                                                                                    pointSize:[attribute fontPointSizeForPointSize:_pointSize]];
                    }
                    hotArea.size.width += _spaceWidth;
                    hotArea.size.height = [attribute lineHeightForPointSize:_pointSize];
                    
                    if(CGRectContainsPoint(hotArea, location)) {
                        _trackingRect = CGRectInset(hotArea, -10, -10);;
                        _trackingWordIndex = i;
                        _trackingWord = YES;
                        break;
                    }
                }
            }            
        }
    }
}


- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location
{
    if(touch == _touch) {
    }
}

- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location
{
    if(touch == _touch) { 
        [touch retain]; // In case we're released as a result of handling this.
        [_touch release];
        _touch = nil;
        if(_trackingWord) {
            if(CGRectContainsPoint(_trackingRect, location)) {
                NSDictionary *linkAttributes = ((EucBookTextStyle *)((THPair *)_stringsWithAttributes[_trackingWordIndex]).second).attributes;
                THLog(@"Tapped hyperlink with attributes: %@", linkAttributes);
                if(_delegate && [_delegate respondsToSelector:@selector(bookTextView:didReceiveTapOnHyperlinkWithAttributes:)]) {
                    [_delegate bookTextView:self didReceiveTapOnHyperlinkWithAttributes:linkAttributes];
                }
            }
        } else {
            if(_delegate && [_delegate respondsToSelector:@selector(bookTextViewDidReceiveTapOnPage:)]) {
                [_delegate bookTextViewDidReceiveTapOnPage:self];
            }            
        }
        [touch release];
    }    
}

- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location
{
    if(touch == _touch) {
        [_touch release];
        _touch = nil;
        _trackingWord = NO;
    }
}

@end
