//
//  BookTitleView.m
//  Eucalyptus
//
//  Created by James Montgomerie on 12/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "EucBookTitleView.h"


@implementation EucBookTitleView


-(id)init
{
    CGRect baseFrame = CGRectMake(0, 0, 320, 30);
	if((self = [super initWithFrame:baseFrame])) {
        CGRect labelFrame = baseFrame;
        labelFrame.size.height -= baseFrame.size.height / 2;
        
        _author = [[UILabel alloc] initWithFrame:labelFrame];
        _author.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] - 1];
        _author.textAlignment = UITextAlignmentCenter;
        _author.adjustsFontSizeToFitWidth = YES;
        _author.minimumFontSize = 8;

        _author.backgroundColor = [UIColor clearColor];
        _author.textColor = [UIColor whiteColor];
        _author.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _author.shadowOffset = CGSizeMake(0, -1);
        _author.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_author];
        
        labelFrame.origin.y = baseFrame.size.height / 2 - 1;
        _title = [[UILabel alloc] initWithFrame:labelFrame];
        
        _title.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] + 1];
        _title.textAlignment = UITextAlignmentCenter;
        _title.adjustsFontSizeToFitWidth = YES;
        _title.minimumFontSize = 8;

        _title.backgroundColor = [UIColor clearColor];
        _title.textColor = [UIColor whiteColor];
        _title.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _title.shadowOffset = CGSizeMake(0, -1);
        _title.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_title];
    }
	return self;
}

/*
- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
}
 */

- (void)dealloc
{
    [_title release];
    [_author release];
	[super dealloc];
}

- (void)setTitle:(NSString *)title;
{
    _title.text = title;
}

- (void)setAuthor:(NSString *)author
{
    _author.text = author;
}


@end
