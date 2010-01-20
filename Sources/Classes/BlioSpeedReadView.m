//
//  BlioSpeedReadView.m
//  BlioApp
//
//  Created by David Keay on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BlioSpeedReadView.h"
#import "BlioBookmarkPoint.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>
#import <libEucalyptus/EucEPubBook.h>

@implementation BlioSpeedReadView

@synthesize pageCount, pageNumber, currentWordOffset, currentParagraph, currentPage, book, fingerImage, backgroundImage, fingerImageHolder, bigTextLabel, speed, font, textArray, nextWordTimer;

- (id)initWithFrame:(CGRect)frame book:(EucBookReference<EucBook> *)eucBook {
    self = [super initWithFrame:frame];
    
    book = [eucBook retain];



    
    [self setMultipleTouchEnabled:NO];
    [self setBackgroundColor:[UIColor blackColor]];


    
    fingerImageHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 93, 93)];
    fingerImage = [[CALayer alloc] init];
    [fingerImage setContents:(id)[[UIImage imageNamed:@"speedread-thumb.png"] CGImage]];
    [fingerImage setFrame:CGRectMake(0, 0, 93, 93)];
    [fingerImageHolder.layer addSublayer:fingerImage];
    
    backgroundImage = [[CALayer alloc] init];
    [backgroundImage setFrame:CGRectMake(0, 0, 320, 480)];
    [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedread-background-dark-portrait.png"] CGImage]];
    [self.layer addSublayer:backgroundImage];
    
    bigTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 200, 290, 40)];
    [bigTextLabel setTextColor:[UIColor whiteColor]];
    [bigTextLabel setBackgroundColor:[UIColor clearColor]];
    
    [self addSubview:bigTextLabel];
    
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
    
    fingerImage.transform = CATransform3DMakeScale(0.01, 0.01, 1);
    [fingerImage setOpacity:0.0f];
    [CATransaction commit];

    [self addSubview:fingerImageHolder];
    
    font = [UIFont fontWithName:@"Helvetica" size:32.0];
    
	speed = 0;
	currentWordOffset = 0;
	[bigTextLabel setFont:font];
    
    [self fillArrayWithCurrentParagraph];	
	[bigTextLabel setText:[textArray objectAtIndex:0]];


    return self;
}

- (void)fillArrayWithNextParagraph {
 
    if (textArray) {
        [textArray release];
        textArray = nil;
    }
 
    currentParagraph = [(EucEPubBook *)book paragraphIdForParagraphAfterParagraphWithId:currentParagraph];
    if (currentParagraph) {
        textArray  = [[NSMutableArray alloc] initWithArray:[(EucEPubBook *)book paragraphWordsForParagraphWithId:currentParagraph]];
        if ([textArray count] == 0) {
            [self fillArrayWithNextParagraph];
        }
    }
}

- (void)fillArrayWithCurrentParagraph {
    [(EucEPubBook*)book getCurrentParagraphId:&currentParagraph wordOffset:&currentWordOffset];
    if (currentParagraph) {
        if (textArray) {
            [textArray release];
            textArray = nil;
        }
        textArray  = [[NSMutableArray alloc] initWithArray:[(EucEPubBook *)book paragraphWordsForParagraphWithId:currentParagraph]];
        if ([textArray count] == 0) {
            [self fillArrayWithNextParagraph];
        }
    }
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
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
    
	//}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

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


- (float)speedForYValue:(float)y {
    
    
    //    330 = 1?
    if (y > 400) {
        return ((480-y)/80)*-1;
    }
    if (y > 350) return 0;
    if (y < 100) return .06;
    
    y = (y-100)/250+.06;
    
    return y;
}

- (float)calculateFingerXValueFromY:(float)y {
    //at 194, it should be 228, at 14 and 374 it should be 320
    if (y > 194) y = 388-y;
    float normalizedY = (180-(y - 14))/420;//180;
    float normalizedX = sqrtf(1-normalizedY*normalizedY);
    
    return (1-normalizedX)*420 + 228;
}


- (void)nextWord:(id)sender {
	if (speed == 0) return;
	if (speed > 0) {
		currentWordOffset ++;
	} else currentWordOffset--; 
	
	if (currentWordOffset < 0) currentWordOffset = 0;
	if (currentWordOffset >= [textArray count]) {
        currentWordOffset = 0;//[textArray count]-1;
        [self fillArrayWithNextParagraph];
    }
	
	[bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
	
	if (fabs([nextWordTimer timeInterval] - speed) > 0.01) {
		[nextWordTimer invalidate];
		nextWordTimer = nil;
		nextWordTimer = [NSTimer scheduledTimerWithTimeInterval:fabs(speed) target:self selector:@selector(nextWord:) userInfo:nil repeats:YES];
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

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    return bookmarkPoint.layoutPage;
}

- (BlioBookmarkPoint *)pageBookmarkPoint
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];

}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    currentParagraph = bookmarkPoint.ePubParagraphId;
    currentWordOffset = bookmarkPoint.ePubWordOffset;
    [self fillArrayWithCurrentParagraph];
    [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
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
    [textArray release];
    [bigTextLabel release];
    [fingerImage release];
    [fingerImageHolder release];
    [backgroundImage release];
    [book release];
    [super dealloc];
}


@end
