//
//  PageView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 03/06/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THLog.h"
#import "EucConfiguration.h"
#import "EucPageView.h"
#import "EucPageTextView.h"
#import "THStringRenderer.h"

@implementation EucPageView

@synthesize title = _title;
@synthesize pageNumberString = _pageNumber;
@synthesize delegate = _delegate;
@synthesize pageTextView = _pageTextView;
@synthesize titleLinePosition = _titleLinePosition;
@synthesize titleLineContents = _titleLineContents;
@synthesize fullBleed = _fullBleed;

+ (CGSize)_marginsForPointSize:(CGFloat)pointSize
{
    return CGSizeMake(roundf(pointSize / 0.9f), roundf(pointSize / 1.2f));
}

+ (CGRect)pageTextViewFrameForFrame:(CGRect)frame
                       forPointSize:(CGFloat)pointSize
{
    CGSize margins = [self _marginsForPointSize:pointSize];
    frame.origin.x += margins.width;
    frame.size.width -= margins.width + margins.width;
    frame.origin.y += margins.height + roundf(pointSize *  1.4f);
    frame.size.height -= frame.origin.y + margins.height;  
    return frame;
}

- (id)initWithFrame:(CGRect)frame
          pointSize:(CGFloat)pointSize 
          titleFont:(NSString *)titleFont 
titleFontStyleFlags:(THStringRendererFontStyleFlags)titleFontStyleFlags
     pageNumberFont:(NSString *)pageNumberFont 
pageNumberFontStyleFlags:(THStringRendererFontStyleFlags)pageNumberFontStyleFlags
     titlePointSize:(CGFloat)titlePointSize
      textViewClass:(Class)textViewClass
{
	if((self = [super initWithFrame:frame])) {
        self.clearsContextBeforeDrawing = YES;
        self.opaque = NO;
        
        _textPointSize = pointSize;
        _titlePointSize = titlePointSize;
        
        _margins = [[self class] _marginsForPointSize:pointSize];

        _pageNumberRenderer = [[THStringRenderer alloc] initWithFontName:pageNumberFont styleFlags:pageNumberFontStyleFlags];
        _titleRenderer = [[THStringRenderer alloc] initWithFontName:titleFont styleFlags:titleFontStyleFlags];

        _pageTextView = [[textViewClass alloc] initWithFrame:[[self class] pageTextViewFrameForFrame:frame 
                                                                                        forPointSize:_titlePointSize] 
                                                   pointSize:pointSize];

        _pageTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _pageTextView.backgroundColor = [UIColor clearColor];
        _pageTextView.opaque = NO;
        _pageTextView.delegate = self;
        
        //[self addSubview:_pageTextView];
        
        _titleLinePosition = EucPageViewTitleLinePositionTop;
        _titleLineContents = EucPageViewTitleLineContentsTitleAndPageNumber;
    }
	return self;
}

- (id)initWithFrame:(CGRect)frame
          pointSize:(CGFloat)pointSize 
      textViewClass:(Class)textViewClass;

{
    NSString *font = [EucConfiguration objectForKey:EucConfigurationDefaultFontFamilyKey];
	return [self initWithFrame:(CGRect)frame
                     pointSize:pointSize 
                     titleFont:font 
           titleFontStyleFlags:THStringRendererFontStyleFlagItalic
                pageNumberFont:font
      pageNumberFontStyleFlags:THStringRendererFontStyleFlagRegular
                titlePointSize:pointSize 
                 textViewClass:(Class)textViewClass];
}

- (id)initWithFrame:(CGRect)frame 
{
    THWarn(@"PageView initWithFrame: called - designated initializer is initWithPointSize");
    return [self init];
}

- (void)dealloc
{
    [_touch release];

    [_pageNumber release];
    [_pageNumberRenderer release];
    [_titleRenderer release];
    
    [_title release];
    [_pageTextView release];
    
    [_accessibilityElements release];

	[super dealloc];
}


- (void)setTitleLinePosition:(EucPageViewTitleLinePosition)position
{
    CGRect protoFrame = [[self class] pageTextViewFrameForFrame:self.frame
                                                   forPointSize:_textPointSize];
    if(position == EucPageViewTitleLinePositionTop) {
    } else if(position == EucPageViewTitleLinePositionBottom) {
        CGRect myBounds = self.bounds;
        protoFrame.origin.y = myBounds.size.height - (protoFrame.origin.y + protoFrame.size.height) - [_pageNumberRenderer descenderForPointSize:_titlePointSize] - 1;
    } else {
        CGRect myBounds = self.bounds;
        protoFrame.origin.y = ceilf((myBounds.size.height - protoFrame.size.height) / 2);
    }
    [_pageTextView setFrame:protoFrame];
    _titleLinePosition = position;
}

- (void)setFullBleed:(BOOL)fullBleed
{
    if(_fullBleed != fullBleed) {
        _fullBleed = fullBleed;
        if(fullBleed) {
            [_pageTextView setFrame:[self bounds]];
        } else {
            [self setTitleLinePosition:_titleLinePosition];
        }
    }
}

- (void)setTitle:(NSString *)title
{
    static NSCharacterSet *controlCharacters = nil;
    if(!controlCharacters) {
        controlCharacters = [[NSCharacterSet controlCharacterSet] retain];
    }
    NSRange range = [title rangeOfCharacterFromSet:controlCharacters];
    if(range.location != NSNotFound) {
        _title = [[title substringToIndex:range.location] retain];
    } else {
        _title = [title copy];
    }
}


- (void)drawRect:(CGRect)rect inContext:(CGContextRef)currentContext
{
    CGContextSaveGState(currentContext);

    CGRect bounds = [self bounds];
    
    CGPoint origin = _pageTextView.frame.origin;
    CGContextTranslateCTM(currentContext, origin.x, origin.y);
    [_pageTextView drawRect:rect inContext:currentContext];
    CGContextRestoreGState(currentContext);
    
    CGContextSaveGState(currentContext);
    
    static const CGFloat black[4] = { 0.1f, 0.1f, 0.1f, 1.0f };

    CGContextSetFillColor(currentContext, black);        
    CGContextSetBlendMode(currentContext, kCGBlendModeMultiply);
    
    if(!_fullBleed && _titleLinePosition != EucPageViewTitleLinePositionNone) {
        THStringRenderer *titleRenderer = _titleRenderer;
        THStringRenderer *pageNumberRenderer = _pageNumberRenderer;

        NSString *pageNumberString = _pageNumber ? _pageNumber : @"";
        NSString *titleString = self.title;
        CGFloat pageNumberWidth = [pageNumberRenderer widthOfString:pageNumberString pointSize:_titlePointSize];;
        CGFloat spaceWidth = [pageNumberRenderer widthOfString:@" " pointSize:_titlePointSize];        
        
        CGPoint pageNumberPoint;
        if(_titleLinePosition == EucPageViewTitleLinePositionBottom) {
            pageNumberPoint.y = bounds.size.height - (_margins.height + roundf(_titlePointSize *  1.4f)) - [_pageNumberRenderer descenderForPointSize:_titlePointSize];
        } else {
            pageNumberPoint.y = _margins.height;
        }                
        if(_titleLineContents == EucPageViewTitleLineContentsCenteredPageNumber) {
            pageNumberPoint.x = (bounds.size.width - pageNumberWidth) / 2;
        } else {
            // First, put the page number in the top-right.
            pageNumberPoint.x = bounds.size.width - pageNumberWidth - _margins.width;
            
            // Now, try to fit the title in.
            CGFloat titleWidth = 0;
            CGPoint titlePoint = CGPointMake(0, pageNumberPoint.y);
            BOOL triedRemovingToColon = NO;
            BOOL triedRemovingTheOrA = NO;
            while(titleString.length > 0) {
                titleWidth = [titleRenderer widthOfString:titleString pointSize:_titlePointSize];

                // Try centering the entire title.
                titlePoint.x = (((bounds.size.width - _margins.width - _margins.width) - titleWidth) / 2) + _margins.width;
                
                // If the title overlaps the page number (plus a space), move it to the left.
                if((titlePoint.x + titleWidth) > (pageNumberPoint.x - spaceWidth)) {
                    titlePoint.x = pageNumberPoint.x - spaceWidth - titleWidth;
                }
                
                // Does the title fit?
                if(titlePoint.x > _margins.width) {
                    break;
                } else {
                    // Try truncating.
                    if(!triedRemovingToColon) {
                        static NSCharacterSet *colonCharacters = nil;
                        if(!colonCharacters) {
                            colonCharacters = [[NSCharacterSet characterSetWithCharactersInString:@";:"] retain];
                        }
                        NSRange range = [titleString rangeOfCharacterFromSet:colonCharacters];
                        if(range.location != NSNotFound) {
                            titleString = [titleString substringToIndex:range.location];
                            continue;
                        } else {
                            triedRemovingToColon = YES;
                        }
                    }
                    
                    if(!triedRemovingTheOrA) {
                        triedRemovingTheOrA = YES;
                        if([titleString hasPrefix:@"The "]) {
                            titleString = [titleString substringFromIndex:4];
                            continue;
                        } else if([titleString hasPrefix:@"A "]) {
                            titleString = [titleString substringFromIndex:2];
                            continue;
                        }
                    }
                    
                    NSInteger lastRealCharacterIndex;
                    if([titleString hasSuffix:@"…"]) {
                        lastRealCharacterIndex = [titleString length] - 2;
                    } else {
                        lastRealCharacterIndex = [titleString length] - 1;
                    }
                    
                    NSString *characterToSearchFor;
                    switch([titleString characterAtIndex:lastRealCharacterIndex]) {
                        case ')':
                            characterToSearchFor = @"(";
                            break;
                        case '}':
                            characterToSearchFor = @"{";
                            break;
                        case ']':
                            characterToSearchFor = @"[";
                            break;
                        default:
                            characterToSearchFor = nil;
                    }
                            
                    NSRange searchRange = NSMakeRange(0, lastRealCharacterIndex+1);
                    NSInteger truncateToAtMost;
                    NSRange bracketsStartAt;
                    if(characterToSearchFor &&
                       ((bracketsStartAt = [titleString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:characterToSearchFor] 
                                                                        options:NSBackwardsSearch
                                                                          range:searchRange]).location != NSNotFound)) {
                        truncateToAtMost = bracketsStartAt.location;
                    } else {
                        // Try to remove an entire word.
                        NSRange secondLastWordEndsAt = [titleString rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] 
                                                                                    options:NSBackwardsSearch
                                                                                      range:searchRange];
                        if(secondLastWordEndsAt.location == NSNotFound) {
                            truncateToAtMost = 0;
                        } else {
                            truncateToAtMost = secondLastWordEndsAt.location;
                        }
                    }

                    // Now, truncate the string, including any trailing
                    // spaces or punctuation.
                    NSMutableCharacterSet *punctuationSetWithoutBrackets = [NSMutableCharacterSet punctuationCharacterSet]; 
                    [punctuationSetWithoutBrackets removeCharactersInString:@"]})"];
                    while(truncateToAtMost > 1 &&
                          ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[titleString characterAtIndex:truncateToAtMost - 1]] ||
                           [punctuationSetWithoutBrackets characterIsMember:[titleString characterAtIndex:truncateToAtMost - 1]])) {
                        --truncateToAtMost;
                    }
                    titleString = [[titleString substringToIndex:truncateToAtMost] stringByAppendingString:@"…"];
                
                }
            }
            
            
            
            if(titleString.length > 0) {
                [titleRenderer drawString:titleString
                                inContext:currentContext
                                  atPoint:titlePoint
                                pointSize:_titlePointSize];
            }
        }
        [pageNumberRenderer drawString:pageNumberString
                             inContext:currentContext
                               atPoint:pageNumberPoint
                             pointSize:_titlePointSize];
    }
    CGContextRestoreGState(currentContext);
}

- (void)drawRect:(CGRect)rect 
{
    [self drawRect:rect inContext:UIGraphicsGetCurrentContext()];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(!_touch) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self];
        
        if(CGRectContainsPoint([_pageTextView frame], location)) {
            _touch = [touch retain];
            
            CGPoint locationInTextView = [self convertPoint:location toView:_pageTextView];
            [_pageTextView handleTouchBegan:_touch atLocation:locationInTextView];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        [_pageTextView handleTouchMoved:_touch atLocation:[self convertPoint:[_touch locationInView:self] toView:_pageTextView]];

    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        [_pageTextView handleTouchCancelled:_touch atLocation:[self convertPoint:[_touch locationInView:self] toView:_pageTextView]];
        [_touch release];
        _touch = nil;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        UITouch *touch = [_touch retain]; // In case we're released as a result fo forwarding this
        [_touch release];
        _touch = nil;
        [_pageTextView handleTouchEnded:touch atLocation:[self convertPoint:[touch locationInView:self] toView:_pageTextView]];
        [touch release];
    }
}

- (void)pageTextView:(UIView<EucPageTextView> *)pageTextView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes
{
    if(_delegate && [_delegate respondsToSelector:@selector(pageView:didReceiveTapOnHyperlinkWithAttributes:)]) {
        [_delegate pageView:self didReceiveTapOnHyperlinkWithAttributes:attributes];
    }
}

- (NSArray *)accessibilityElements
{
    if(!_accessibilityElements) {
        if([_pageTextView respondsToSelector:@selector(accessibilityElements)]) {
            _accessibilityElements = [[_pageTextView performSelector:@selector(accessibilityElements)] retain];
        }
        for(UIAccessibilityElement *element in _accessibilityElements) {
            element.accessibilityContainer = self;
        }
    }
    return _accessibilityElements;
}

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSInteger)accessibilityElementCount
{
    return [[self accessibilityElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    return [[self accessibilityElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [[self accessibilityElements] indexOfObject:element];
}

@end
