//
//  BlioSpeedReadView.m
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BlioSpeedReadView.h"
#import "BlioBookManager.h"
#import "BlioBookmark.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/THPair.h>
#import "BlioBook.h"
#import "BlioParagraphSource.h"

@interface BlioSpeedReadView ()

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) NSArray *fontSizes;
@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;

@property (nonatomic, retain) id currentParagraphID;
@property (nonatomic) int32_t currentWordOffset;
@property (nonatomic, retain) NSArray *textArray;
@property (nonatomic, retain) BlioBookmarkPoint *currentBookmarkPoint;

@property (nonatomic) float speed;
@property (nonatomic, retain) NSTimer *nextWordTimer;
@property (nonatomic, retain) UILabel *bigTextLabel;
@property (nonatomic, retain) UILabel *sampleTextLabel;
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;

@property (nonatomic, assign) BOOL tallScreen;

- (void)updateCurrentBookmarkPoint;

- (float)speedForYValue:(float)y;
- (float)calculateFingerXValueFromY:(float)y;
- (BOOL)fillArrayWithNextBlock;
- (BOOL)fillArrayWithCurrentBlock;

@end

@implementation BlioSpeedReadView

@synthesize bookID, fontSizes, currentBookmarkPoint, currentWordOffset, currentParagraphID, bigTextLabel, sampleTextLabel, speed, textArray, nextWordTimer, paragraphSource, tallScreen;
@synthesize delegate;

- (void)dealloc {
    [textArray release]; textArray = nil;
    [sampleTextLabel release]; sampleTextLabel = nil;
    [bigTextLabel release]; bigTextLabel = nil;
    [fingerImageHolder release]; fingerImageHolder = nil;
    [currentParagraphID release]; currentParagraphID = nil;
    
    [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:bookID];
    [paragraphSource release]; paragraphSource = nil;
    
    [fontSizes release]; fontSizes = nil;
    [bookID release]; bookID = nil;
    
	// Don't release as was not retained
	delegate = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
           delegate:(id<BlioBookViewDelegate>)delegateIn
             bookID:(NSManagedObjectID *)bookIDIn
           animated:(BOOL)animated {
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {    
        self.bookID = bookIDIn;
        self.delegate = delegateIn;
        self.tallScreen = (fabs([UIScreen mainScreen].bounds.size.height - (double)568) < DBL_EPSILON);
        
        paragraphSource = [[[BlioBookManager sharedBookManager] checkOutParagraphSourceForBookWithID:bookID] retain];
        
        [self setMultipleTouchEnabled:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
        
        fingerImageHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 93, 93)];
        fingerImage = [CALayer layer];
        [fingerImage setContents:(id)[[UIImage imageNamed:@"speedread-thumb.png"] CGImage]];
        [fingerImage setFrame:CGRectMake(0, 0, 93, 93)];
        [fingerImageHolder.layer addSublayer:fingerImage];
        
        backgroundImage = [CALayer layer];
        if (self.tallScreen) {
            [backgroundImage setFrame:CGRectMake(0, 0, 320, 568)];
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-portrait-tall.png"] CGImage]];
        }
        else {
            [backgroundImage setFrame:CGRectMake(0, 0, 320, 480)];
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-portrait.png"] CGImage]];
            
        }
        [self.layer addSublayer:backgroundImage];
        
        backgroundImageLandscape = [CALayer layer];
        if (self.tallScreen) {
            [backgroundImageLandscape setFrame:CGRectMake(0, 248, 568, 320 )];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-landscape-tall.png"] CGImage]];
        }
        else {
            [backgroundImageLandscape setFrame:CGRectMake(0, 160, 480, 320 )];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-landscape.png"] CGImage]];
        }
        [self.layer addSublayer:backgroundImageLandscape];
        
        roundCorners = [CALayer layer];
        if (self.tallScreen) {
            [roundCorners setFrame:CGRectMake(0, 0, 320, 568)];
            [roundCorners setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/roundcorners-portrait-tall.png"] CGImage]];
        }
        else {
            [roundCorners setFrame:CGRectMake(0, 0, 320, 480)];
            [roundCorners setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/roundcorners-portrait.png"] CGImage]];
        }
        [self.layer addSublayer:roundCorners];
        
        roundCornersLandscape = [CALayer layer];
        if (self.tallScreen) {
            [roundCornersLandscape setFrame:CGRectMake(0, 248, 568, 320)];
            [roundCornersLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/roundcorners-landscape-tall.png"] CGImage]];
        }
        else {
            [roundCornersLandscape setFrame:CGRectMake(0, 160, 480, 320)];
            [roundCornersLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/roundcorners-landscape.png"] CGImage]];
        }
        [self.layer addSublayer:roundCornersLandscape];
        
        bigTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 100, 290, 240)];
        [bigTextLabel setTextColor:[UIColor blackColor]];
        [bigTextLabel setBackgroundColor:[UIColor clearColor]];
        [bigTextLabel setNumberOfLines:1];
        [bigTextLabel setAdjustsFontSizeToFitWidth:YES];
        
        [self addSubview:bigTextLabel];
        
        sampleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 100, 2000, 240)];
        [sampleTextLabel setTextColor:[UIColor blackColor]];
        [sampleTextLabel setBackgroundColor:[UIColor clearColor]];
        [sampleTextLabel setNumberOfLines:1];
        [sampleTextLabel setAdjustsFontSizeToFitWidth:NO];
        [sampleTextLabel setText:NSLocalizedString(@"Sample",@"\"Sample\" text label for speed read view")];
        [sampleTextLabel setAlpha:0.0f];
        
        [self addSubview:sampleTextLabel];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
        
        fingerImage.transform = CATransform3DMakeScale(0.01, 0.01, 1);
        [fingerImage setOpacity:0.0f];
        [CATransaction commit];
        
        [self addSubview:fingerImageHolder];
        
        fontSizes = [[self.delegate fontSizesForBlioBookView:self] retain];
        
        speed = 0;
        currentWordOffset = 0;
        
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:[[fontSizes objectAtIndex:(fontSizes.count - 1) / 2] floatValue]];
        sampleTextLabel.font = font;        
        bigTextLabel.font = font;        
        
        [self goToBookmarkPoint:[[BlioBookManager sharedBookManager] bookWithID:bookID].implicitBookmarkPoint animated:NO];	
        [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
        
        initialTouchDifference = 0;
        
        zooming = NO;
        
        self.autoresizesSubviews = YES;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    }    
    return self;
}

- (void)didMoveToWindow {
    UIInterfaceOrientation i = [[UIApplication sharedApplication] statusBarOrientation]; 
    
    if (UIInterfaceOrientationIsLandscape(i)) {
        //if (self.tallScreen)
        //    self.frame = CGRectMake(0, -160, 568, 568);
        //else
            self.frame = CGRectMake(0, -160, 480, 480);
    }
}

- (NSString *)fontName
{
    return [bigTextLabel.font familyName];
}
- (void)setFontName:(NSString *)fontName
{
    if([fontName isEqualToString:kBlioOriginalFontName]) {
        fontName = @"Helvetica";
    }
    UIFont *newFont = [UIFont fontWithName:fontName size:bigTextLabel.font.pointSize];
    bigTextLabel.font = newFont;
    sampleTextLabel.font = newFont;
}


- (NSUInteger)fontSizeIndex {
    CGFloat actualFontSize = bigTextLabel.font.pointSize;
    CGFloat bestDifference = CGFLOAT_MAX;
    NSUInteger bestFontSizeIndex = 0;
    
    NSUInteger i = 0;
    for(NSNumber *size in fontSizes) {
        CGFloat thisDifference = fabsf(size.floatValue - actualFontSize);
        if(thisDifference < bestDifference) {
            bestDifference = thisDifference;
            bestFontSizeIndex = i;
        }
        ++i;
    }
    return bestFontSizeIndex;
}

- (void)setFontSizeIndex:(NSUInteger)fontSizeIndex
{
    CGFloat newFontSize = [[fontSizes objectAtIndex:fontSizeIndex] floatValue];
    UIFont *newFont = [bigTextLabel.font fontWithSize:newFontSize];
    bigTextLabel.font = newFont;
    sampleTextLabel.font = newFont;
}

- (void)setColor:(BlioPageColor)newColor {
    if (newColor == kBlioPageColorWhite) {
        if (self.tallScreen) {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-light-portrait-tall.png"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-light-landscape-tall.png"] CGImage]];
        }
        else {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-light-portrait"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-light-landscape.png"] CGImage]];
        }
        self.backgroundColor = [UIColor whiteColor];
        [bigTextLabel setTextColor:[UIColor blackColor]];
        [sampleTextLabel setTextColor:[UIColor blackColor]];
    } else if (newColor == kBlioPageColorBlack) {
        if (self.tallScreen) {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-portrait-tall.png"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-landscape-tall.png"] CGImage]];
        }
        else {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-portrait.png"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-black-landscape.png"] CGImage]];
        }
        self.backgroundColor = [UIColor blackColor];
        [bigTextLabel setTextColor:[UIColor whiteColor]];        
        [sampleTextLabel setTextColor:[UIColor whiteColor]];        
    } else if (newColor == kBlioPageColorNeutral) {
        if (self.tallScreen) {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-neutral-portrait-tall.png"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-neutral-landscape-tall.png"] CGImage]];
        }
        else {
            [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-neutral-portrait.png"] CGImage]];
            [backgroundImageLandscape setContents:(id)[[UIImage imageNamed:@"speedreaderBackgroundImages/background-neutral-landscape.png"] CGImage]];
        }
        self.backgroundColor = [UIColor colorWithRed:253.0f/255.0f green:235.0f/255.0f blue:213.0f/255.0f alpha:1];
        [bigTextLabel setTextColor:[UIColor blackColor]];        
        [sampleTextLabel setTextColor:[UIColor blackColor]];                
    }
}

- (void)layoutLandscape {
    if (self.tallScreen) {
        bigTextLabel.frame = CGRectMake(15, 244, 430, 240);
        sampleTextLabel.frame = CGRectMake(15, 244, 2000, 240);
    } else {
        bigTextLabel.frame = CGRectMake(15, 200, 430, 240);
        sampleTextLabel.frame = CGRectMake(15, 200, 2000, 240);
    }
    
    [backgroundImageLandscape setHidden:NO];    
    [backgroundImage setHidden:YES];        
}

- (void)layoutPortrait {
    if (self.tallScreen) {
        bigTextLabel.frame = CGRectMake(15, 144, 290, 240);
        sampleTextLabel.frame = CGRectMake(15, 144, 2000, 240);
    } else {
        bigTextLabel.frame = CGRectMake(15, 100, 290, 240);
        sampleTextLabel.frame = CGRectMake(15, 100, 2000, 240);
    }
    
    
    [backgroundImageLandscape setHidden:YES];
    [backgroundImage setHidden:NO];            
}

- (void)layoutSubviews {
    UIInterfaceOrientation i = [[UIApplication sharedApplication] statusBarOrientation]; 
    
    
    if(UIInterfaceOrientationIsLandscape(i)) {
        
        [self layoutLandscape];
        [roundCorners setHidden:YES];
        [roundCornersLandscape setHidden:NO];        
    } else {
        
        [self layoutPortrait];
        [roundCorners setHidden:NO];
        [roundCornersLandscape setHidden:YES];
    }}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [roundCorners setHidden:YES];
    [roundCornersLandscape setHidden:YES];
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self layoutLandscape];
    } else {
        [self layoutPortrait];
        
    }
    
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        [roundCornersLandscape setHidden:NO];
        
    } else {
        [roundCorners setHidden:NO];    
        
    }
    
}

- (BOOL)fillArrayWithNextBlock {
    if (textArray) {
        [textArray release];
        textArray = nil;
    }
    
    id newId = [paragraphSource nextParagraphIdForParagraphWithID:self.currentParagraphID];
    if(newId) {
        self.currentParagraphID = newId;
        self.currentWordOffset = 0;
        
        return [self fillArrayWithCurrentBlock];
    } else {
        return NO;
    }
}

- (BOOL)fillArrayWithCurrentBlock {
    BOOL ret = NO;
    
    if (textArray) {
        [textArray release];
        textArray = nil;
    }
    
    self.textArray = [paragraphSource wordsForParagraphWithID:self.currentParagraphID];
    if (textArray.count) {
        ret = YES;
        [self updateCurrentBookmarkPoint];
    } else {
        ret = [self fillArrayWithNextBlock];
    } 
    
    return ret;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[[event allTouches] allObjects] count] > 1) {
        CGPoint first = [[[[event allTouches] allObjects] objectAtIndex:0] locationInView:nil];
        CGPoint second = [[[[event allTouches] allObjects] objectAtIndex:1] locationInView:nil];
        CGFloat deltaX = second.x - first.x;
        CGFloat deltaY = second.y - first.y;
        initialTouchDifference = sqrt(deltaX*deltaX + deltaY*deltaY);
        
        zooming = YES;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.25];
        bigTextLabel.alpha = 0.0f;
        sampleTextLabel.alpha = 0.5f;              
        [UIView commitAnimations];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.25f] forKey:kCATransactionAnimationDuration];
        fingerImage.opacity = 0.0f;
        fingerImage.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        [CATransaction commit];
        
    } else {
        
        float xOffset = 0;
        float yOffset = 0;
        
        float loc = [[[touches allObjects] objectAtIndex:0] locationInView:self].y;
        float fingerImageYValue = loc-46;        
        
        float phoneHeightDifference = self.frame.size.height - 480;
        
        UIInterfaceOrientation i = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (UIInterfaceOrientationIsLandscape(i)){
            xOffset = 147 + phoneHeightDifference;
            yOffset = -80 - phoneHeightDifference/2;
        }
        
        [fingerImageHolder setFrame:CGRectMake([self calculateFingerXValueFromY:fingerImageYValue+yOffset]+xOffset, fingerImageYValue+phoneHeightDifference/2, 93, 93)];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.25f] forKey:kCATransactionAnimationDuration];
        fingerImage.opacity = 1.0f;
        fingerImage.transform = CATransform3DMakeScale(1.2, 1.2, 1);
        [CATransaction commit];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];
        backgroundImageLandscape.opacity = 0.35f;
        backgroundImage.opacity = 0.35f;
        [CATransaction commit];
        
        speed = [self speedForYValue:loc];

        
        if (speed == 0) {
            if (nextWordTimer) {
                [nextWordTimer invalidate];
                nextWordTimer = nil;
            }
        } else if (!nextWordTimer) nextWordTimer = [NSTimer scheduledTimerWithTimeInterval:fabs(speed) target:self selector:@selector(nextWord:) userInfo:nil repeats:YES];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ([[[event allTouches] allObjects] count] > 1) {
        CGPoint first = [[[[event allTouches] allObjects] objectAtIndex:0] locationInView:nil];
        CGPoint second = [[[[event allTouches] allObjects] objectAtIndex:1] locationInView:nil];
        CGFloat deltaX = second.x - first.x;
        CGFloat deltaY = second.y - first.y;
        float newDifference = sqrt(deltaX*deltaX + deltaY*deltaY);
        
        CGFloat oldFontSize = sampleTextLabel.font.pointSize;
        CGFloat newFontSize = (int)(bigTextLabel.font.pointSize + (newDifference - initialTouchDifference)/2.5);
        if (newFontSize < 20) newFontSize = 20.0;
        if (newFontSize > 120) newFontSize = 120.0;
        newFontSize = newFontSize - (int)newFontSize%5;
        if (oldFontSize != newFontSize) {
            sampleTextLabel.font = [sampleTextLabel.font fontWithSize:newFontSize];
        }
        
    } else {
        float xOffset = 0;
        float yOffset = 0;
        
        int oldSpeed = speed;
        float loc = [[[touches allObjects] objectAtIndex:0] locationInView:self].y;
        float fingerImageYValue = loc-46;        
        
        float phoneHeightDifference = self.frame.size.height - 480;
        
        UIInterfaceOrientation i = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (UIInterfaceOrientationIsLandscape(i)){
            xOffset = 147 + phoneHeightDifference;
            yOffset = -80 - phoneHeightDifference/2;
        }
        
        [fingerImageHolder setFrame:CGRectMake([self calculateFingerXValueFromY:fingerImageYValue+yOffset]+xOffset, fingerImageYValue+phoneHeightDifference/2, 93, 93)];
        
        speed = [self speedForYValue:loc];

        if (speed != oldSpeed) {
            if (speed == 0) {
                if (nextWordTimer) {
                    [nextWordTimer invalidate];
                    nextWordTimer = nil;
                }
            } else if (!nextWordTimer) nextWordTimer = [NSTimer scheduledTimerWithTimeInterval:fabs(speed) target:self selector:@selector(nextWord:) userInfo:nil repeats:YES];
            
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    zooming = NO;
	
    if ([[[event allTouches] allObjects] count] == 2) {
        [self willChangeValueForKey:@"fontSizeIndex"];
        [self didChangeValueForKey:@"fontSizeIndex"];

        bigTextLabel.font = sampleTextLabel.font;
        
        UITouch *firstTouch = [[[event allTouches] allObjects] objectAtIndex:0];
        UITouch *secondTouch = [[[event allTouches] allObjects] objectAtIndex:1];        
        
        if (firstTouch.phase == 3 && secondTouch.phase == 3) {
            if (nextWordTimer) {
                [nextWordTimer invalidate];
                nextWordTimer = nil;
            }
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2];
        bigTextLabel.alpha = 1.0f;
        sampleTextLabel.alpha = 0.0f;              
        [UIView commitAnimations];
        
        if (firstTouch.phase != 3 || secondTouch.phase != 3) {
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithFloat:0.25f] forKey:kCATransactionAnimationDuration];
            fingerImage.opacity = 1.0f;
            fingerImage.transform = CATransform3DMakeScale(1.2, 1.2, 1);
            [CATransaction commit];   
        }
        
    } else {
        
        if (nextWordTimer) {
            [nextWordTimer invalidate];
            nextWordTimer = nil;
        }
        
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.25f] forKey:kCATransactionAnimationDuration];
        fingerImage.opacity = 0.0f;
        fingerImage.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        [CATransaction commit];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];
        backgroundImageLandscape.opacity = 1.0f;        
        backgroundImage.opacity = 1.0f;
        [CATransaction commit];
        
    }
    
}


- (float)speedForYValue:(float)y {
    UIInterfaceOrientation i = [[UIApplication sharedApplication] statusBarOrientation];
    if (tallScreen) {
        /* it seems like we're getting y values of about -20 to 538 in portrait
           and 228 - 538 in landscape
           these are adjusted accordingly */
        
        if (UIInterfaceOrientationIsPortrait(i)) {
            if (y > 538-88) {
                //if over 450, then return -1 (480) to 0 (568)
                //this moves the text backwards
                return ((538-y)/88)*-1;
            }
            //if their finger is between 400 and 450, speed is 0
            if (y > 400) return 0;
            //if their finger is under 130, .06
            if (y < 130) return .06;
            
            //if it's between 130 and 400, then .06 -> 1.06
            y = (y-130)/270+.06;
            
        } else {
            if (y > 498) {
                return ((538-y)/40)*-1;
            }
            //458 to 498 is stationary
            if (y > 458) return 0;
            //0 to 278 is .06
            if (y < 278) return .06;
            
            //278 to 458 is 0.6 -> 1.06
            y = (y-278)/180+.06;
        }
    } else {
        if (UIInterfaceOrientationIsPortrait(i)) {
            if (y > 400) {
                //if over 400, then return -1 (400) to 0 (480)
                //this moves the text backwards
                return ((480-y)/80)*-1;
            }
            //if their finger is between 350 and 400, 0
            if (y > 350) return 0;
            //if their finger is under 100, .06
            if (y < 100) return .06;
            
            //if it's between 100 and 350, then .06 -> 1.06
            y = (y-100)/250+.06;
            
        } else {
            //440 to 480 = -1->0 (moving backwards)
            if (y > 440) {
                return ((480-y)/40)*-1;
            }
            //380 to 440 is stationary
            if (y > 380) return 0;
            //0 to 220 is .06
            if (y < 220) return .06;
            
            //220 to 380 is 0.6 -> 1.06
            y = (y-220)/160+.06;
        }
    }
    
    return y;
}

- (float)calculateFingerXValueFromY:(float)y {
    if (y > 194) y = 388-y;
    float normalizedY = (180-(y - 14))/420;
    float normalizedX = sqrtf(1-normalizedY*normalizedY);
    
    return (1-normalizedX)*420 + 228;
}


- (void)nextWord:(id)sender {
    if (zooming) return;
    
	if (speed == 0) return;
	if (speed > 0) {
		currentWordOffset ++;
	} else currentWordOffset--; 
	
	if (currentWordOffset < 0) currentWordOffset = 0;
	if (currentWordOffset >= [textArray count]) {
        currentWordOffset = 0;
        [self fillArrayWithNextBlock];
    }
	
	[bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
    
    if (nextWordTimer) {
        if (fabs([nextWordTimer timeInterval] - speed) > 0.01) {
            [nextWordTimer invalidate];
            nextWordTimer = nil;
            nextWordTimer = [NSTimer scheduledTimerWithTimeInterval:fabs(speed) target:self selector:@selector(nextWord:) userInfo:nil repeats:YES];
        }
    }
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    BlioBookmarkPoint *bookmarkPoint = [self.paragraphSource bookmarkPointForSectionUuid:uuid];
    return [self goToBookmarkPoint:bookmarkPoint animated:animated];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkPoint animated:animated saveToHistory:YES];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save
{
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    
    id paragraphId = nil;
    uint32_t wordOffset = 0;
    [paragraphSource bookmarkPoint:bookmarkPoint toParagraphID:&paragraphId wordOffset:&wordOffset];
    
    self.currentParagraphID = paragraphId;
    self.currentWordOffset = wordOffset;
    
    [self fillArrayWithCurrentBlock];
    [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
    [self updateCurrentBookmarkPoint];
}

- (void)updateCurrentBookmarkPoint {
    self.currentBookmarkPoint = [paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:self.currentWordOffset];
}

#pragma mark -
#pragma mark Back Button History

- (void)pushCurrentBookmarkPoint {
    BlioBookmarkPoint *bookmarkPoint = [self currentBookmarkPoint];
    if (bookmarkPoint) {
        [self.delegate pushBookmarkPoint:bookmarkPoint];
    }
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    if(bookmarkPoint) {
        [self goToBookmarkPoint:bookmarkPoint animated:animated];
    }
}

- (BOOL)wantsTouchesSniffed {
    return YES;
}

- (CGRect)firstPageRect {
    return [[UIScreen mainScreen] bounds];
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

#pragma mark -
#pragma mark BlioBookView

- (NSString *)currentUuid
{
    return [self.paragraphSource sectionUuidForBookmarkPoint:self.currentBookmarkPoint];
}

- (BOOL)currentPageContainsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self.currentBookmarkPoint isEqual:bookmarkPoint];
}

- (BlioBookmarkRange *)bookmarkRangeForCurrentPage
{
    return [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:self.currentBookmarkPoint];
}

- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self.paragraphSource presentationNameAndSubTitleForSectionUuid:[self.paragraphSource sectionUuidForBookmarkPoint:bookmarkPoint]].first;
}

- (NSString *)displayPageNumberForPercentage:(float)percentage
{
    return [NSString stringWithFormat:NSLocalizedString(@"%lu%%", @"Percentage through book (used when formatting 'page numbers' in speedread view)"), (long)roundf((float)percentage * 100.0f)];
}

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self displayPageNumberForPercentage:[self.paragraphSource estimatedPercentageForBookmarkPoint:bookmarkPoint]];
}

- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self.paragraphSource estimatedPercentageForBookmarkPoint:bookmarkPoint];
}

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage
{
    return [self.paragraphSource estimatedBookmarkPointForPercentage:percentage];
}

- (void)decrementPage
{
    float percentage = [self percentageForBookmarkPoint:self.currentBookmarkPoint];
    BlioBookmarkPoint *newBookmarkPoint = [self bookmarkPointForPercentage:MIN(1.0f, percentage + 1.0f)];
    [self goToBookmarkPoint:newBookmarkPoint animated:YES];
}

- (void)incrementPage
{
    float percentage = [self percentageForBookmarkPoint:self.currentBookmarkPoint];
    BlioBookmarkPoint *newBookmarkPoint = [self bookmarkPointForPercentage:MAX(0.0f, percentage - 1.0f)];
    [self goToBookmarkPoint:newBookmarkPoint animated:YES];
}

- (void)goToContentsSectionIdentifier:(id)identifier animated:(BOOL)animated
{
}

- (UIImage *)dimPageImage
{
    return nil;
}

- (BlioJustification)justification
{
    return kBlioJustificationLeft;
}

- (BlioTwoUp)twoUp
{
    return kBlioTwoUpNever;
}

- (BOOL)shouldTapZoom
{
    return NO;
}

- (BlioExtraBoldness)extraBoldness
{
    return kBlioExtraBoldnessNone;
}

- (id)currentContentsSectionIdentifier
{
    return nil;
}

#pragma mark -
#pragma mark EucBookContentsTableViewControllerDataSource

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return self;
}

- (NSArray *)contentsTableViewControllerSectionUuids:(EucBookContentsTableViewController *)contentsTableViewController {
    return [self.paragraphSource sectionUuids];
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
                      levelForSectionUuid:(NSString *)sectionUuid
{
    return [self.paragraphSource levelForSectionUuid:sectionUuid];
}

- (THPair *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid {
    return [self.paragraphSource presentationNameAndSubTitleForSectionUuid:sectionUuid];
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController pageIndexForSectionUuid:(NSString *)sectionUuid {
    return (NSUInteger)([self.paragraphSource estimatedPercentageForBookmarkPoint:[self.paragraphSource bookmarkPointForSectionUuid:sectionUuid]] * 1000.0f);
}

- (NSString *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController displayPageNumberForPageIndex:(NSUInteger)page
{
    return [self displayPageNumberForPercentage:(float)page / 1000.0f];
}

- (NSArray *)contentsTableViewControllerSectionIdentifiers:(EucBookContentsTableViewController *)contentsTableViewController {
    return [self.contentsDataSource contentsTableViewControllerSectionIdentifiers:contentsTableViewController];
}

- (THPair *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
presentationNameAndSubTitleForSectionIdentifier:(id)sectionIdentifier {
    return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                presentationNameAndSubTitleForSectionIdentifier:sectionIdentifier];
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
            pageIndexForSectionIdentifier:(id)sectionIdentifier {
    
    return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                                  pageIndexForSectionIdentifier:sectionIdentifier];
}

@end
