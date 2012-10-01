//
//  BlioViewSettingsInterface.h
//  BlioApp
//
//  Created by James Montgomerie on 01/10/2012.
//
//

#import <Foundation/Foundation.h>
#import "BlioBookView.h"

@protocol BlioViewSettingsInterfaceDelegate;
@class BlioViewSettingsContentsView;

@interface BlioViewSettingsInterface : NSObject

@property (nonatomic, assign, readonly) id<BlioViewSettingsInterfaceDelegate> delegate;
@property (nonatomic, retain, readonly) BlioViewSettingsContentsView *contentsView;

- (id)initWithDelegate:(id<BlioViewSettingsInterfaceDelegate>)delegate contentsView:(BlioViewSettingsContentsView *)contentsView;

- (void)presentFromBarButtonItem:(UIBarButtonItem *)item;
- (void)dismissAnimated:(BOOL)animated;

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end

@protocol BlioViewSettingsInterfaceDelegate <NSObject>
@required

- (void)dismissViewSettingsInterface:(id)sender;
- (void)viewSettingsInterfaceDidDismiss:(BlioViewSettingsInterface *)sender;

@end
