//
//  BlioNotesView.h
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioNotesView : UIView {
    UITextView *textView;
    NSString *page;
}

@property (nonatomic, retain) NSString *page;

- (id)initWithPage:(NSString *)pageNumber;
- (void)showInView:(UIView *)view;

@end
