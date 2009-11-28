//
//  NameAndPageNumberView.m
//  Eucalyptus
//
//  Created by James Montgomerie on 23/01/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "EucNameAndPageNumberView.h"

#define FONT_SIZE 17.0f

@implementation EucNameAndPageNumberView

@synthesize name = _name;
@synthesize subTitle = _subTitle;
@synthesize pageNumber = _pageNumber;
@synthesize textColor = _textColor;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = YES;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)dealloc
{
    [_name release];
    [_pageNumber release];
    [_textColor release];
    [super dealloc];
}


+ (CGFloat)heightForWidth:(CGFloat)width withName:(NSString *)name subTitle:(NSString *)subTitle pageNumber:(NSString *)pageNumber
{    
    CGSize pageNumberSize = CGSizeZero;
    CGSize minimumDotsSize = CGSizeZero;

    if(pageNumber) {
        UIFont *pageNumberFont = [UIFont italicSystemFontOfSize:FONT_SIZE];
        pageNumberSize = [pageNumber sizeWithFont:pageNumberFont];
        pageNumberSize.width += 1; // Seems to clip the edge of the italics if we don't do this.
    }
    
    UIFont *nameFont = [UIFont boldSystemFontOfSize:FONT_SIZE];
    minimumDotsSize = [@"." sizeWithFont:nameFont];
    CGSize constraintSize = CGSizeMake(width - pageNumberSize.width - minimumDotsSize.width, CGFLOAT_MAX);
    CGSize stringSize = [name sizeWithFont:nameFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap]; 
    
    CGSize subTitleSize = CGSizeZero;
    if(subTitle) {
        UIFont *subTitleFont = [UIFont boldSystemFontOfSize:FONT_SIZE * (2.0f/3.0f)];
        subTitleSize = [subTitle sizeWithFont:subTitleFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap]; 
    }
    
     // +1 to avoid descender clipping (seems like that it shouldn't be necessary...
    return ceilf(stringSize.height + subTitleSize.height + 1);
}
    

- (void)drawRect:(CGRect)rect
{
    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    
    [self.backgroundColor setFill];
    
    CGRect bounds = self.bounds;
    
    // In case our backgroundcolor is a pattern, set its phase to match
    // its use in the cell we're in.
    CGPoint origin = self.frame.origin;
    CGContextSetPatternPhase(cgContext, CGSizeMake(-origin.x, -origin.y));
    CGContextFillRect(cgContext, bounds);
    
    UIFont *nameFont = [UIFont boldSystemFontOfSize:FONT_SIZE];

    // Bit of a hack here, but it's a lot easier than creating special
    // subclasses to pass the state aroud properly.
    UITableViewCell *cell = (UITableViewCell *)self.superview.superview;
    if([cell isKindOfClass:[UITableViewCell class]] &&
       (cell.isHighlighted || cell.isSelected)) {
        [[UIColor whiteColor] setFill];
    } else {
        [_textColor ? _textColor : [UIColor blackColor] setFill];
    }
    
    CGSize pageNumberSize = CGSizeZero;
    CGSize minimumDotsSize = CGSizeZero;
    
    UIFont *pageNumberFont = nil;
    if(_pageNumber) {
        pageNumberFont = [UIFont italicSystemFontOfSize:FONT_SIZE];
        pageNumberSize = [_pageNumber sizeWithFont:pageNumberFont];
        pageNumberSize.width += 1; // Seems to clip the edge of the italics if we don't do this.
    }
    
    minimumDotsSize = [@"." sizeWithFont:nameFont];
    CGSize constraintSize = CGSizeMake(bounds.size.width - pageNumberSize.width - minimumDotsSize.width, CGFLOAT_MAX);
    CGSize stringSize = [_name sizeWithFont:nameFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap]; 
    
    [_name drawInRect:CGRectMake(0, 0, stringSize.width, stringSize.height) 
             withFont:nameFont
        lineBreakMode:UILineBreakModeWordWrap]; 
    
    CGSize subTitleSize = CGSizeZero;
    UIFont *subTitleFont = nil;
    if(_subTitle) {
        subTitleFont = [UIFont boldSystemFontOfSize:FONT_SIZE * (2.0f/3.0f)];
        subTitleSize = [_subTitle sizeWithFont:subTitleFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap]; 
        [_subTitle drawInRect:CGRectMake(0, stringSize.height, subTitleSize.width, subTitleSize.height)
                     withFont:subTitleFont 
                lineBreakMode:UILineBreakModeWordWrap];
    }
    
    if(_pageNumber) {
        CGFloat baselineCorrection = 0;
        if(_subTitle) {
            baselineCorrection = floorf(subTitleFont.descender - pageNumberFont.descender);
        }
        [_pageNumber drawInRect:CGRectMake(bounds.size.width - pageNumberSize.width, baselineCorrection + stringSize.height + subTitleSize.height - pageNumberSize.height, pageNumberSize.width, pageNumberSize.height)
                             withFont:pageNumberFont 
                        lineBreakMode:UILineBreakModeClip];
    }
}


- (void)setName:(NSString *)name
{
    if(![_name isEqualToString:name]) {
        [_name release];
        _name = [name retain];
        [self setNeedsDisplay]; 
    }
}


- (void)setSubTitle:(NSString *)subTitle
{
    if(![_subTitle isEqualToString:subTitle]) {
        [_subTitle release];
        _subTitle = [subTitle retain];
        [self setNeedsDisplay]; 
    }
}


- (void)setPageNumber:(NSString *)pageNumber
{
    if(![pageNumber isEqualToString:_pageNumber]) {
        [_pageNumber release];
        _pageNumber = [pageNumber copy];
        [self setNeedsDisplay]; 
    }
}

@end
