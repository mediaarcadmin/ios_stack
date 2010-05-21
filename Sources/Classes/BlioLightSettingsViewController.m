#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

//
//  BlioLightSettingsViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 18/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioLightSettingsViewController.h"


@implementation BlioLightSettingsViewController

@synthesize pageTurningView = _pageTurningView;

@synthesize containerScrollView = _containerScrollView;
@synthesize scrollContentView = _scrollContentView;

@synthesize specularColorR = _specularColorR;
@synthesize specularColorG = _specularColorG;
@synthesize specularColorB = _specularColorB;
@synthesize specularColorA = _specularColorA;

@synthesize shininess = _shininess;

@synthesize ambientColorR = _ambientColorR;
@synthesize ambientColorG = _ambientColorG;
@synthesize ambientColorB = _ambientColorB;
@synthesize ambientColorA = _ambientColorA;

@synthesize diffuseColorR = _diffuseColorR;
@synthesize diffuseColorG = _diffuseColorG;
@synthesize diffuseColorB = _diffuseColorB;
@synthesize diffuseColorA = _diffuseColorA;

@synthesize constantAttenuation = _constantAttenuation;
@synthesize linearAttenuation = _linearAttenuation;
@synthesize quadraticAttenuation = _quadraticAttenuation;

@synthesize lightX = _lightX;
@synthesize lightY = _lightY;
@synthesize lightZ = _lightZ;

- (void)viewDidLoad
{
    [self.containerScrollView addSubview:self.scrollContentView];
    self.containerScrollView.contentSize = self.scrollContentView.frame.size;
    
    EucPageTurningView *pageTurningView = self.pageTurningView;
    
    UIColor *color = self.pageTurningView.specularColor;
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    self.specularColorR.text = [NSNumber numberWithFloat:components[0]].stringValue;
    self.specularColorG.text = [NSNumber numberWithFloat:components[1]].stringValue;
    self.specularColorB.text = [NSNumber numberWithFloat:components[2]].stringValue;
    self.specularColorA.text = [NSNumber numberWithFloat:components[3]].stringValue;
    
    self.shininess.text = [NSNumber numberWithFloat:pageTurningView.shininess].stringValue;
    
    color = self.pageTurningView.ambientLightColor;
    components = CGColorGetComponents(color.CGColor);
    
    self.ambientColorR.text = [NSNumber numberWithFloat:components[0]].stringValue;
    self.ambientColorG.text = [NSNumber numberWithFloat:components[1]].stringValue;
    self.ambientColorB.text = [NSNumber numberWithFloat:components[2]].stringValue;
    self.ambientColorA.text = [NSNumber numberWithFloat:components[3]].stringValue;
    
    color = self.pageTurningView.diffuseLightColor;
    components = CGColorGetComponents(color.CGColor);
    
    self.diffuseColorR.text = [NSNumber numberWithFloat:components[0]].stringValue;
    self.diffuseColorG.text = [NSNumber numberWithFloat:components[1]].stringValue;
    self.diffuseColorB.text = [NSNumber numberWithFloat:components[2]].stringValue;
    self.diffuseColorA.text = [NSNumber numberWithFloat:components[3]].stringValue;
    
    
    self.constantAttenuation.text = [NSNumber numberWithFloat:pageTurningView.constantAttenuationFactor].stringValue;
    self.linearAttenuation.text = [NSNumber numberWithFloat:pageTurningView.linearAttenutaionFactor].stringValue;
    self.quadraticAttenuation.text = [NSNumber numberWithFloat:pageTurningView.quadraticAttenuationFactor].stringValue;
    
    GLfloatTriplet lightPosition = pageTurningView.lightPosition;
    self.lightX.text = [NSNumber numberWithFloat:lightPosition.x].stringValue;
    self.lightY.text = [NSNumber numberWithFloat:lightPosition.y].stringValue;
    self.lightZ.text = [NSNumber numberWithFloat:lightPosition.z].stringValue;
}


- (IBAction)done:(id)sender
{
    EucPageTurningView *pageTurningView = self.pageTurningView;
    
    pageTurningView.specularColor = [UIColor colorWithRed:self.specularColorR.text.floatValue
                                                    green:self.specularColorG.text.floatValue
                                                     blue:self.specularColorB.text.floatValue
                                                    alpha:self.specularColorA.text.floatValue];
    
    pageTurningView.shininess = self.shininess.text.floatValue;
    
    pageTurningView.ambientLightColor = [UIColor colorWithRed:self.ambientColorR.text.floatValue
                                                        green:self.ambientColorG.text.floatValue
                                                         blue:self.ambientColorB.text.floatValue
                                                        alpha:self.ambientColorA.text.floatValue];
    pageTurningView.diffuseLightColor = [UIColor colorWithRed:self.diffuseColorR.text.floatValue
                                                        green:self.diffuseColorG.text.floatValue
                                                         blue:self.diffuseColorB.text.floatValue
                                                        alpha:self.diffuseColorA.text.floatValue];
    
    pageTurningView.constantAttenuationFactor = self.constantAttenuation.text.floatValue;
    pageTurningView.linearAttenutaionFactor = self.linearAttenuation.text.floatValue;
    pageTurningView.quadraticAttenuationFactor = self.quadraticAttenuation.text.floatValue;
    
    GLfloatTriplet lightPosition = {self.lightX.text.floatValue, self.lightY.text.floatValue, self.lightZ.text.floatValue};
    pageTurningView.lightPosition = lightPosition;
    
    [self dismissModalViewControllerAnimated:YES];
}


- (void)viewDidUnload 
{
    self.pageTurningView = nil;
    
    self.specularColorR = nil;
    self.specularColorG = nil;
    self.specularColorB = nil;
    self.specularColorA = nil;
    
    self.shininess = nil;
    
    self.ambientColorR = nil;
    self.ambientColorG = nil;
    self.ambientColorB = nil;
    self.ambientColorA = nil;
    
    self.diffuseColorR = nil;
    self.diffuseColorG = nil;
    self.diffuseColorB = nil;
    self.diffuseColorA = nil;
    
    self.constantAttenuation = nil;
    self.linearAttenuation = nil;
    self.quadraticAttenuation = nil;
    
    self.lightX = nil;
    self.lightY = nil;
    self.lightZ = nil;
    
    [super viewDidUnload];
}

- (void)dealloc 
{
    [_pageTurningView release];
    
    [_specularColorR release];
    [_specularColorG release];
    [_specularColorB release];
    [_specularColorA release];
    
    [_shininess release];
    
    [_ambientColorR release];
    [_ambientColorG release];
    [_ambientColorB release];
    [_ambientColorA release];
    
    [_diffuseColorR release];
    [_diffuseColorG release];
    [_diffuseColorB release];
    [_diffuseColorA release];
    
    [_constantAttenuation release];
    [_linearAttenuation release];
    [_quadraticAttenuation release];
    
    [_lightX release];
    [_lightY release];
    [_lightZ release];
    
    [super dealloc];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if(!_keyboardVisible) {
        UIScrollView *scrollView = self.containerScrollView;
        
		// N.B. - #pragma GCC diagnostic ignored "-Wdeprecated-declarations" is at the top to prevent a deprecated warning. Requires at least GCC 4.2.
        NSValue* sizeValue = [notification.userInfo objectForKey:UIKeyboardBoundsUserInfoKey];			
        CGSize keyboardSize = [sizeValue CGRectValue].size;
        
        CGRect viewFrame = scrollView.frame;
        viewFrame.size.height -= keyboardSize.height;
        scrollView.frame = viewFrame;
        
        _keyboardVisible = YES;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if(_keyboardVisible) {
        UIScrollView *scrollView = self.containerScrollView;
        
		// N.B. - #pragma GCC diagnostic ignored "-Wdeprecated-declarations" is at the top to prevent a deprecated warning. Requires at least GCC 4.2.
        NSValue* sizeValue = [notification.userInfo objectForKey:UIKeyboardBoundsUserInfoKey];			
        CGSize keyboardSize = [sizeValue CGRectValue].size;
        
        CGRect viewFrame = scrollView.frame;
        viewFrame.size.height += keyboardSize.height;
        scrollView.frame = viewFrame;    
        
        _keyboardVisible = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification object:self.view.window]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillHideNotification object:self.view.window]; 
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil]; 
}

@end
