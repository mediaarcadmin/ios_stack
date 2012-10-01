//
//  BlioViewSettingsInterface.m
//  BlioApp
//
//  Created by James Montgomerie on 01/10/2012.
//
//

#import "BlioViewSettingsInterface.h"

#import "BlioViewSettingsPopover.h"
#import "BlioViewSettingsSheet.h"

@interface BlioViewSettingsInterface ()

@property (nonatomic, assign) id<BlioViewSettingsInterfaceDelegate> delegate;
@property (nonatomic, retain) BlioViewSettingsContentsView *contentsView;

@end

@implementation BlioViewSettingsInterface

- (id)initWithDelegate:(id<BlioViewSettingsInterfaceDelegate>)delegate contentsView:(BlioViewSettingsContentsView *)contentsView
{
    if([self class] == [BlioViewSettingsInterface class]) {
        [self release];
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self = [[BlioViewSettingsPopover alloc] initWithDelegate:delegate contentsView:contentsView];
        } else {
            self = [[BlioViewSettingsSheet alloc] initWithDelegate:delegate contentsView:contentsView];
        }
    } else {
        if((self = [super init])) {
            self.delegate = delegate;
            self.contentsView = contentsView;
        }
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.contentsView = nil;
    
    [super dealloc];
}

- (void)presentFromBarButtonItem:(UIBarButtonItem *)item inToolbar:(UIToolbar *)toolbar forEvent:(UIEvent *)event {}
- (void)dismissAnimated:(BOOL)animated {}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {}

@end
