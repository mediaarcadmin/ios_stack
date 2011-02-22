//
//  BlioMediaView.m
//  multiplevideo
//
//  Created by Don Shin on 2/18/11.
//  Copyright 2011 CrossComm, Inc. All rights reserved.
//

#import "BlioMediaView.h"


@implementation BlioMediaView

@synthesize moviePlayerController,thumbnailView,playButton,activityIndicatorView;

- (id)initWithFrame:(CGRect)frame contentURL:(NSURL*)url {
    
    self = [super initWithFrame:frame];
    if (self) {
		CGFloat playButtonDiameter = 50.0f;
		self.backgroundColor = [UIColor grayColor];
        // Initialization code.
		moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:url];
		moviePlayerController.shouldAutoplay = NO;
		moviePlayerController.view.frame = [self bounds];
		[self addSubview:moviePlayerController.view];
		thumbnailView = [[UIImageView alloc] initWithFrame:[self bounds]];
		thumbnailView.backgroundColor = [UIColor blackColor];
		thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
		thumbnailView.image = [moviePlayerController thumbnailImageAtTime:4 timeOption:MPMovieTimeOptionNearestKeyFrame];
		[self addSubview:thumbnailView];
		playButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		playButton.frame = CGRectMake((self.bounds.size.width-playButtonDiameter)/2, (self.bounds.size.height-playButtonDiameter)/2, playButtonDiameter, playButtonDiameter);
		[playButton setBackgroundImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
		[playButton addTarget:self action:@selector(playMedia:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:playButton];
		activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicatorView.center = CGPointMake((self.bounds.size.width)/2, (self.bounds.size.height)/2);
		[self addSubview:activityIndicatorView];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMoviePlayerPlaybackStateDidChangeNotification:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMediaPlaybackIsPreparedToPlayDidChangeNotification:) name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:self.moviePlayerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBlioMediaViewWillPlayMovieNotification:) name:BlioMediaViewWillPlayMovieNotification object:nil];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/
-(void)playMedia:(UIControl*)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioMediaViewWillPlayMovieNotification object:self];
	playButton.hidden = YES;
	activityIndicatorView.hidden = NO;
	[activityIndicatorView startAnimating];
	isActive = YES;
	if (moviePlayerController.isPreparedToPlay) [moviePlayerController play];
	else [moviePlayerController prepareToPlay];
}
-(void)didReceiveMediaPlaybackIsPreparedToPlayDidChangeNotification:(NSNotification*)notification {
	//NSLog(@"moviePlayerController.currentPlaybackTime: %f",moviePlayerController.currentPlaybackTime);
	//NSLog(@"moviePlayerController.duration: %f",moviePlayerController.duration);
	if (isActive) [moviePlayerController play];
}
-(void)didReceiveMoviePlayerPlaybackStateDidChangeNotification:(NSNotification*)notification {
	//NSLog(@"moviePlayer: %@, moviePlayerController.playbackState: %i",moviePlayerController,moviePlayerController.playbackState);
	switch (moviePlayerController.playbackState) {
		case MPMoviePlaybackStatePlaying:
			[activityIndicatorView stopAnimating];
			activityIndicatorView.hidden = YES;
			thumbnailView.hidden = YES;
			playButton.hidden = YES;
			break;
		case MPMoviePlaybackStatePaused:
			if ((moviePlayerController.duration - moviePlayerController.currentPlaybackTime) < 0.1) {
				thumbnailView.image = [moviePlayerController thumbnailImageAtTime:4 timeOption:MPMovieTimeOptionNearestKeyFrame];
				moviePlayerController.currentPlaybackTime = 0;
				thumbnailView.hidden = NO;
				playButton.hidden = NO;
			}
			else {
				thumbnailView.image = [moviePlayerController thumbnailImageAtTime:moviePlayerController.currentPlaybackTime timeOption:MPMovieTimeOptionExact];
			}
			activityIndicatorView.hidden = YES;	
			break;
		case MPMoviePlaybackStateStopped:
			isActive = NO;
			thumbnailView.hidden = NO;
			playButton.hidden = NO;
			activityIndicatorView.hidden = YES;
			break;
		default:
			thumbnailView.hidden = NO;
			playButton.hidden = NO;
			activityIndicatorView.hidden = YES;
			break;
	}
	
}
-(void)didReceiveBlioMediaViewWillPlayMovieNotification:(NSNotification*)notification {
	if ([notification object] != self && isActive == YES) {
		if (moviePlayerController.playbackState != MPMoviePlaybackStatePaused) {
			[moviePlayerController pause];
		}
		isActive = NO;
	}
}

-(void)pauseMediaPlayer {
	if (moviePlayerController.playbackState != MPMoviePlaybackStatePaused) {
		[moviePlayerController pause];
	}
	isActive = NO;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.moviePlayerController = nil;
	self.thumbnailView = nil;
	self.playButton = nil;
	self.activityIndicatorView = nil;
    [super dealloc];
}


@end
