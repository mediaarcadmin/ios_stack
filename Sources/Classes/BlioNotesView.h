//
//  BlioNotesView.h
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class BlioNotesView;

@protocol BlioNotesViewDelegate <NSObject>

@optional

- (void)notesViewCreateNote:(BlioNotesView *)notesView;
- (void)notesViewUpdateNote:(BlioNotesView *)notesView;

@end


@interface BlioNotesView : UIView {
    UITextView *textView;
    NSString *page;
    id<BlioNotesViewDelegate> delegate;
    NSManagedObject *note;
}

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) NSString *page;
@property (nonatomic, assign) id<BlioNotesViewDelegate> delegate;
@property (nonatomic, retain) NSManagedObject *note;

- (id)initWithPage:(NSString *)pageNumber;
- (id)initWithPage:(NSString *)pageNumber note:(NSManagedObject *)aNote;
- (void)showInView:(UIView *)view;
- (void)showInView:(UIView *)view animated:(BOOL)animated;

@end
