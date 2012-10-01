//
//  BlioViewSettingsContentsView.m
//  BlioApp
//
//  Created by James Montgomerie on 01/10/2012.
//
//

#import "BlioViewSettingsContentsView.h"

@implementation BlioViewSettingsContentsView

@dynamic preferredSize, navigationItemTitle;

- (id)initWithDelegate:(id)delegate
{
    if((self = [super initWithFrame:CGRectZero])) {
        _delegate = delegate;
    }
    return self;
}

- (void)refreshSettings {};
- (void)flashScrollIndicators {};

@end
