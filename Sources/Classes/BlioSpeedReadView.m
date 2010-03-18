//
//  BlioSpeedReadView.m
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BlioSpeedReadView.h"
#import "BlioBookmark.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>
#import <libEucalyptus/EucBUpeBook.h>
#import "BlioMockBook.h"

@implementation BlioSpeedReadView

@synthesize pageCount, pageNumber, currentWordOffset, currentBlock, currentPage, book, fingerImage, backgroundImage, fingerImageHolder, bigTextLabel, sampleTextLabel, speed, font, textArray, nextWordTimer;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    EucBUpeBook *aEPubBook = [[EucBUpeBook alloc] initWithPath:[aBook ePubPath]];
    if (nil == aEPubBook) return nil;
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {    
        book = [aEPubBook retain];
        
        [self setMultipleTouchEnabled:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
        
        fingerImageHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 93, 93)];
        fingerImage = [[CALayer alloc] init];
        [fingerImage setContents:(id)[[UIImage imageNamed:@"speedread-thumb.png"] CGImage]];
        [fingerImage setFrame:CGRectMake(0, 0, 93, 93)];
        [fingerImageHolder.layer addSublayer:fingerImage];
        
        backgroundImage = [[CALayer alloc] init];
        [backgroundImage setFrame:CGRectMake(0, 0, 320, 480)];
        [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedread-background-light-portrait.png"] CGImage]];
        [self.layer addSublayer:backgroundImage];
        
        CALayer *roundedCorners = [[CALayer alloc] init];
        [roundedCorners setFrame:CGRectMake(0, 0, 320, 480)];
        [roundedCorners setContents:(id)[[UIImage imageNamed:@"roundedcorners.png"] CGImage]];
        [self.layer addSublayer:roundedCorners];
        [roundedCorners release];
        
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
        [sampleTextLabel setText:@"Sample"];
        [sampleTextLabel setAlpha:0.0f];
        
        [self addSubview:sampleTextLabel];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
        
        fingerImage.transform = CATransform3DMakeScale(0.01, 0.01, 1);
        [fingerImage setOpacity:0.0f];
        [CATransaction commit];
        
        [self addSubview:fingerImageHolder];
        
        currentFontSize = 90.0;
        font = [UIFont fontWithName:@"Helvetica" size:currentFontSize];
        
        speed = 0;
        currentWordOffset = 0;
        [bigTextLabel setFont:font];
        [sampleTextLabel setFont:font];        
        
        
        
        
        [self fillArrayWithCurrentBlock];	
        [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
        
        initialTouchDifference = 0;
        
        zooming = NO;
    }
    
    [aEPubBook release];
    return self;
}

- (void)fillArrayWithNextBlock {
    
    if (textArray) {
        [textArray release];
        textArray = nil;
    }
    
    /*currentBlock = [(EucBUpeBook *)book blockIdForBlockAfterBlockWithId:currentBlock];
    if (currentBlock) {
        textArray  = [[NSMutableArray alloc] initWithArray:[(EucEPubBook *)book blockWordsForBlockWithId:currentBlock]];
        if ([textArray count] == 0) {
            [self fillArrayWithNextBlock];
        }
    }*/
    
    
}

- (void)fillArrayWithCurrentBlock {
    //[(EucBUpeBook*)book getCurrentBlockId:&currentBlock wordOffset:&currentWordOffset];
    if (currentBlock) {
        if (textArray) {
            [textArray release];
            textArray = nil;
        }
        //textArray  = [[NSMutableArray alloc] initWithArray:[(EucEPubBook *)book blockWordsForBlockWithId:currentBlock]];
        if ([textArray count] == 0) {
            [self fillArrayWithNextBlock];
        }
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[[event allTouches] allObjects] count] > 1) {
        CGPoint first = [[[[event allTouches] allObjects] objectAtIndex:0] locationInView:nil];
        CGPoint second = [[[[event allTouches] allObjects] objectAtIndex:1] locationInView:nil];
        CGFloat deltaX = second.x - first.x;
        CGFloat deltaY = second.y - first.y;
        initialTouchDifference = sqrt(deltaX*deltaX + deltaY*deltaY);
        
        initialFontSize = currentFontSize;
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
        
        float loc = [[[touches allObjects] objectAtIndex:0] locationInView:nil].y;
        
        float fingerImageYValue = [[[touches allObjects] objectAtIndex:0] locationInView:nil].y-46;
        [fingerImageHolder setFrame:CGRectMake([self calculateFingerXValueFromY:fingerImageYValue], fingerImageYValue, 93, 93)];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.25f] forKey:kCATransactionAnimationDuration];
        fingerImage.opacity = 1.0f;
        fingerImage.transform = CATransform3DMakeScale(1.2, 1.2, 1);
        [CATransaction commit];
        
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];
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
        
        float oldFontSize = currentFontSize;
        currentFontSize = (int)(initialFontSize + (newDifference - initialTouchDifference)/2.5);
        if (currentFontSize < 20) currentFontSize = 20.0;
        if (currentFontSize > 120) currentFontSize = 120.0;
        currentFontSize = currentFontSize - (int)currentFontSize%5;
        if (oldFontSize != currentFontSize) {
            sampleTextLabel.font = [font fontWithSize:currentFontSize];
        }
        
    } else {
        
        int oldSpeed = speed;
        float loc = [[[touches allObjects] objectAtIndex:0] locationInView:nil].y;
        float fingerImageYValue = [[[touches allObjects] objectAtIndex:0] locationInView:nil].y-46;
        
        [fingerImageHolder setFrame:CGRectMake([self calculateFingerXValueFromY:fingerImageYValue], fingerImageYValue, 93, 93)];
        
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
        bigTextLabel.font = [font fontWithSize:currentFontSize];
        
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
        backgroundImage.opacity = 1.0f;
        [CATransaction commit];
        
    }
    
}


- (float)speedForYValue:(float)y {
    
    if (y > 400) {
        return ((480-y)/80)*-1;
    }
    if (y > 350) return 0;
    if (y < 100) return .06;
    
    y = (y-100)/250+.06;
    
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



- (NSString *)extractWordFromLongString:(NSString*)currentWordToExtract withString:(NSString*)longString {
	NSRange spaceRange = [longString rangeOfString:@" "];
	if (spaceRange.length > 0) {
		NSString *longerWord = [currentWordToExtract stringByAppendingString:[[longString substringToIndex:spaceRange.location] stringByAppendingString:@" "]];
        
		if ([longerWord sizeWithFont:font].width < 290) {
            
			return [self extractWordFromLongString:longerWord withString:[longString substringFromIndex:spaceRange.location+1]];
		} else {
            
			return currentWordToExtract == @"" ? longerWord : currentWordToExtract;
		}
		
	} else {
        
		return currentWordToExtract;
	}
}

- (NSString *)checkPhraseLength:(NSString*)currentWordToExtract withArray:(NSArray*)a atIndex:(int)i {
    
	if (i >= [a count]-1) return currentWordToExtract;
	NSString *longerString = [currentWordToExtract stringByAppendingString:[@" " stringByAppendingString:[a objectAtIndex:i]]];
	if ([longerString sizeWithFont:font].width < 400) {
		return [self checkPhraseLength:longerString withArray:a atIndex:i+1];
	} else return currentWordToExtract;
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    
}

- (void)gotoCurrentPageAnimated {
    [self goToPageNumber:self.pageNumber animated:YES];
    
}

- (void)goToPageNumber:(NSInteger)aPageNumber animated:(BOOL)animated {
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint {
    return bookmarkPoint.layoutPage;
}

- (BlioBookmarkAbsolutePoint *)pageBookmarkPoint
{
    BlioBookmarkAbsolutePoint *ret = [[BlioBookmarkAbsolutePoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
    
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    currentBlock = bookmarkPoint.ePubBlockId;
    currentWordOffset = bookmarkPoint.ePubWordOffset;
    [self fillArrayWithCurrentBlock];
    [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
}

- (BOOL)wantsTouchesSniffed {
    return YES;
}

- (CGRect)firstPageRect {
    return [[UIScreen mainScreen] bounds];
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
    return nil;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
    //[(EucBUpeBook*)book setCurrentBlockId:currentBlock wordOffset:currentWordOffset];    
    [textArray release];
    [sampleTextLabel release];
    [bigTextLabel release];
    [fingerImage release];
    [fingerImageHolder release];
    [backgroundImage release];
    [book release];
    [super dealloc];
}


@end
