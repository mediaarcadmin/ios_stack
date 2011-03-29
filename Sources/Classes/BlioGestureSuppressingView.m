//
//  BlioGestureSuppressingView.m
//  BlioApp
//
//  Created by Matt Farrugia on 22/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioGestureSuppressingView.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface BlioSuppressingGestureRecognizer : UIGestureRecognizer {}
@property (nonatomic, retain) NSArray *allowedGestureRecognizers;
@end

@implementation BlioGestureSuppressingView

@synthesize suppressingGestureRecognizer;

- (void)dealloc
{
    [suppressingGestureRecognizer release], suppressingGestureRecognizer = nil;
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        suppressingGestureRecognizer = [[BlioSuppressingGestureRecognizer alloc] initWithTarget:nil action:nil];
        suppressingGestureRecognizer.allowedGestureRecognizers = [NSArray arrayWithObjects:[UITapGestureRecognizer class], nil];
        [self addGestureRecognizer:suppressingGestureRecognizer];
        
    }
    return self;
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    self.state = UIGestureRecognizerStateRecognized;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateCancelled;
}

@end

