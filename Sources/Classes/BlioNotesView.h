//
//  BlioNotesView.h
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "BlioBookmark.h"

@class BlioNotesView;

@protocol BlioNotesViewDelegate <NSObject>

@optional

- (void)notesViewCreateNote:(BlioNotesView *)notesView;
- (void)notesViewUpdateNote:(BlioNotesView *)notesView;
- (void)notesViewDismissed;
@end


@interface BlioNotesView : UIView {
    UITextView *textView;
    NSString *page;
    id<BlioNotesViewDelegate> delegate;
    NSManagedObject *note;
    BlioBookmarkRange *range;
}

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) NSString *page;
@property (nonatomic, assign) id<BlioNotesViewDelegate> delegate;
@property (nonatomic, retain) NSManagedObject *note;
@property (nonatomic, retain) BlioBookmarkRange *range;

- (id)initWithRange:(BlioBookmarkRange *)range note:(NSManagedObject *)aNote;
- (void)showInView:(UIView *)view;
- (void)showInView:(UIView *)view animated:(BOOL)animated;

@end
