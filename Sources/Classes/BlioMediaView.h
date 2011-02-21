//
//  BlioMediaView.h
//  multiplevideo
//
//  Created by Don Shin on 2/18/11.
//  Copyright 2011 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

static NSString * const BlioMediaViewWillPlayMovieNotification = @"BlioMediaViewWillPlayMovieNotification";

@interface BlioMediaView : UIView {
	MPMoviePlayerController * moviePlayerController;
	UIImageView * thumbnailView;
	UIButton * playButton;
	UIActivityIndicatorView * activityIndicatorView;
	BOOL isActive;

}
- (id)initWithFrame:(CGRect)frame contentURL:(NSURL*)url;
- (void)pauseMediaPlayer;
   
@property (nonatomic, retain) MPMoviePlayerController * moviePlayerController;
@property (nonatomic, retain) UIImageView * thumbnailView;
@property (nonatomic, retain) UIButton * playButton;
@property (nonatomic, retain) UIActivityIndicatorView * activityIndicatorView;


@end
