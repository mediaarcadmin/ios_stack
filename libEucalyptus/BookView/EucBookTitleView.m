//
//  BookTitleView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 12/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBookTitleView.h"


@implementation EucBookTitleView


-(id)init
{
    CGRect baseFrame = CGRectMake(0, 0, 320, 30);
	if((self = [super initWithFrame:baseFrame])) {
        CGRect labelFrame = baseFrame;
        labelFrame.size.height -= baseFrame.size.height / 2;
        
        _authorLabel = [[UILabel alloc] initWithFrame:labelFrame];
        _authorLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] - 1];
        _authorLabel.textAlignment = UITextAlignmentCenter;
        _authorLabel.adjustsFontSizeToFitWidth = YES;
        _authorLabel.minimumFontSize = 8;

        _authorLabel.backgroundColor = [UIColor clearColor];
        _authorLabel.textColor = [UIColor whiteColor];
        _authorLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _authorLabel.shadowOffset = CGSizeMake(0, -1);
        _authorLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_authorLabel];
        
        labelFrame.origin.y = baseFrame.size.height / 2 - 1;
        _titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        
        _titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] + 1];
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumFontSize = 8;

        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _titleLabel.shadowOffset = CGSizeMake(0, -1);
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_titleLabel];
    }
	return self;
}

- (void)dealloc
{
    [_title release];
    [_titleLabel release];
    [_author release];
    [_authorLabel release];
	[super dealloc];
}

- (void)setTitle:(NSString *)title;
{
    if(title != _title) {
        [_title release];
        _title = [title retain];
        _titleLabel.text = title;
    }
}

- (void)setAuthor:(NSString *)author
{
    if(author != _author) {
        [_author release];
        _author = [author retain];
        _authorLabel.text = author;
    }
}

- (NSString *)accessibilityLabel
{
    if(!_author) {
        if(_title) {
            return _title;
        } else {
            return NSLocalizedString(@"Unknown book", @"Accessibilty label for book view navigation bar field with no title or author");
        }
    } else {
        if (!_title) {
            return [NSString stringWithFormat:NSLocalizedString(@"Book by %@",  @"Accessibilty label for book view navigation bar field with no title"), _author];
        } else {
            return [NSString stringWithFormat:NSLocalizedString(@"%@ by %@",  @"Accessibilty label for book view navigation bar field"), _title, _author];
        }
    }
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitStaticText;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

@end
