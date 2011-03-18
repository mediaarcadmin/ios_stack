//
//  BlioGestureSupressingContainerView.m
//  BlioApp
//
//  Created by Matt Farrugia on 16/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioGestureSupressingBlendView.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <QuartzCore/QuartzCore.h>

@interface BlioSuppressingGestureRecognizer : UIGestureRecognizer {}
@property (nonatomic, retain) NSArray *allowedGestureRecognizers;
@end

@implementation BlioGestureSupressingBlendView

+ (Class)layerClass {
	return [CAReplicatorLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        BlioSuppressingGestureRecognizer *supressor = [[[BlioSuppressingGestureRecognizer alloc] initWithTarget:nil action:nil] autorelease];
        supressor.allowedGestureRecognizers = [NSArray arrayWithObjects:[UITapGestureRecognizer class], nil];
        [self addGestureRecognizer:supressor];
        
    }
    return self;
}

- (void)dealloc
{
    for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
        [self removeGestureRecognizer:recognizer];
    }
    
    [super dealloc];
}

@end

@implementation BlioSuppressingGestureRecognizer

@synthesize allowedGestureRecognizers;

- (void)dealloc
{
    [allowedGestureRecognizers release], allowedGestureRecognizers = nil;    
    [super dealloc];
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    
    if ([self.allowedGestureRecognizers count]) {
        
        BOOL match = NO;
        
        for (Class recognizerClass in self.allowedGestureRecognizers) {
            if ([preventedGestureRecognizer isKindOfClass:recognizerClass]) {
                match = YES;
                break;
            }
        }
        
        if (match) {
            return NO;
        }
    }
    
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateRecognized;
}

@end
