//
//  BlioLightSettingsViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 18/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucPageTurningView.h>

@interface BlioLightSettingsViewController : UIViewController <UIScrollViewDelegate> {
    EucPageTurningView *_pageTurningView;

    UIScrollView *_containerScrollView;
    UIView *_scrollContentView;
    
    UITextField *_specularColorR;
    UITextField *_specularColorG;
    UITextField *_specularColorB;
    UITextField *_specularColorA;
    
    UITextField *_shininess;

    UITextField *_ambientColorR;
    UITextField *_ambientColorG;
    UITextField *_ambientColorB;
    UITextField *_ambientColorA;
    
    UITextField *_diffuseColorR;
    UITextField *_diffuseColorG;
    UITextField *_diffuseColorB;
    UITextField *_diffuseColorA;
    
    UITextField *_constantAttenuation;
    UITextField *_linearAttenuation;
    UITextField *_quadraticAttenuation;
    
    UITextField *_lightX;
    UITextField *_lightY;
    UITextField *_lightZ;
    
    BOOL _keyboardVisible;
}

@property (nonatomic, retain) EucPageTurningView *pageTurningView;

@property (nonatomic, retain) IBOutlet UIScrollView *containerScrollView;
@property (nonatomic, retain) IBOutlet UIView *scrollContentView;

@property (nonatomic, retain) IBOutlet UITextField *specularColorR;
@property (nonatomic, retain) IBOutlet UITextField *specularColorG;
@property (nonatomic, retain) IBOutlet UITextField *specularColorB;
@property (nonatomic, retain) IBOutlet UITextField *specularColorA;

@property (nonatomic, retain) IBOutlet UITextField *shininess;

@property (nonatomic, retain) IBOutlet UITextField *ambientColorR;
@property (nonatomic, retain) IBOutlet UITextField *ambientColorG;
@property (nonatomic, retain) IBOutlet UITextField *ambientColorB;
@property (nonatomic, retain) IBOutlet UITextField *ambientColorA;

@property (nonatomic, retain) IBOutlet UITextField *diffuseColorR;
@property (nonatomic, retain) IBOutlet UITextField *diffuseColorG;
@property (nonatomic, retain) IBOutlet UITextField *diffuseColorB;
@property (nonatomic, retain) IBOutlet UITextField *diffuseColorA;

@property (nonatomic, retain) IBOutlet UITextField *constantAttenuation;
@property (nonatomic, retain) IBOutlet UITextField *linearAttenuation;
@property (nonatomic, retain) IBOutlet UITextField *quadraticAttenuation;

@property (nonatomic, retain) IBOutlet UITextField *lightX;
@property (nonatomic, retain) IBOutlet UITextField *lightY;
@property (nonatomic, retain) IBOutlet UITextField *lightZ;

- (IBAction)done:(id)sender;

@end
