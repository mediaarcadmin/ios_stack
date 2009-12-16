//
//  BookTitleView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 12/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EucBookTitleView : UIView {
    UILabel *_title;
    UILabel *_author;
}

- (id)init;
- (void)setTitle:(NSString *)title;
- (void)setAuthor:(NSString *)author;

@end
