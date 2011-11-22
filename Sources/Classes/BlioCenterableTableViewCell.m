//
//  BlioCenterableTableViewCell.m
//  BlioApp
//
//  Created by James Montgomerie on 22/11/2011.
//  Copyright (c) 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioCenterableTableViewCell.h"

@implementation BlioCenterableTableViewCell

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    CGFloat selfWidth = self.bounds.size.width;
    
    CGRect textLabelFrame = [self convertRect:self.textLabel.bounds fromView:self.textLabel];
    CGFloat labelWidth = selfWidth - textLabelFrame.origin.x * 2;

    textLabelFrame.size.width = labelWidth;
    self.textLabel.frame = [self convertRect:textLabelFrame toView:self.textLabel.superview];
    
    CGRect detailTextLabelFrame = [self convertRect:self.detailTextLabel.bounds fromView:self.detailTextLabel];
    detailTextLabelFrame.origin.x = textLabelFrame.origin.x;
    detailTextLabelFrame.size.width = labelWidth;    
    self.detailTextLabel.frame = [self convertRect:detailTextLabelFrame toView:self.detailTextLabel.superview];
    
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.backgroundColor = [UIColor clearColor];
}

@end
