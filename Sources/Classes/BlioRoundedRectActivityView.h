//
//  BlioRoundedRectActivityView.h
//  BlioApp
//
//  Created by Don Shin on 9/21/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioRoundedRectActivityView : UIView {
	UIActivityIndicatorView * activityIndicator;
	UIColor * strokeColor;
	UIColor * fillColor;
}
@property (nonatomic,retain) UIActivityIndicatorView * activityIndicator;
@property (nonatomic,retain) UIColor * strokeColor;
@property (nonatomic,retain) UIColor * fillColor;

-(void)startAnimating;
-(void)stopAnimating;	
@end
