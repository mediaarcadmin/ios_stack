//
//  BlioSpeedReadView.h
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookView.h>
#import <CoreData/CoreData.h>
#import "BlioBookView.h"
#import "BlioBookViewController.h"

@protocol BlioParagraphSource;

@interface BlioSpeedReadView : UIView <BlioBookView, EucBookContentsTableViewControllerDataSource> {
    NSManagedObjectID *bookId;
    
    NSArray *fontSizes;
    BlioBookmarkPoint *currentIndexPoint;
    
    id<BlioParagraphSource> paragraphSource;
    id<BlioBookViewDelegate> delegate;
    id currentParagraphID;
	int32_t currentWordOffset;
    
    UIView *fingerImageHolder;
    CALayer *fingerImage;
    
    CALayer *backgroundImageLandscape;    
    CALayer *backgroundImage;
    CALayer *roundCornersLandscape;    
    CALayer *roundCorners;
    
    float initialTouchDifference;
    
    float zooming;
    
    UILabel *bigTextLabel;
	UILabel *sampleTextLabel;
    
	float speed;
	    
	NSArray *textArray;
	
	NSTimer *nextWordTimer;
}

- (void)setColor:(BlioPageColor)newColor;

@end
