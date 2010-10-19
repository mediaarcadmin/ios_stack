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
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/THPair.h>
#import "BlioBook.h"
#import "BlioParagraphSource.h"

@interface BlioSpeedReadView ()

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, retain) id currentParagraphID;
@property (nonatomic) uint32_t currentWordOffset;
@property (nonatomic, retain) NSArray *textArray;

@end

@implementation BlioSpeedReadView

@synthesize pageNumber, currentWordOffset, currentParagraphID, bigTextLabel, sampleTextLabel, speed, font, textArray, nextWordTimer;
@synthesize delegate;

- (void)dealloc {
    [textArray release]; textArray = nil;
    [sampleTextLabel release]; sampleTextLabel = nil;
    [bigTextLabel release]; bigTextLabel = nil;
    [fingerImageHolder release]; fingerImageHolder = nil;
    [currentParagraphID release]; currentParagraphID = nil;
    [paragraphSource release]; paragraphSource = nil;
    
	// Don't release as was not retained
	delegate = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
             bookID:(NSManagedObjectID *)bookID 
           animated:(BOOL)animated {
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {    
        BlioBook *aBook = [[BlioBookManager sharedBookManager] bookWithID:bookID];
        paragraphSource = [aBook.paragraphSource retain];
        
        [self setMultipleTouchEnabled:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
        
        fingerImageHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 93, 93)];
        fingerImage = [CALayer layer];
        [fingerImage setContents:(id)[[UIImage imageNamed:@"speedread-thumb.png"] CGImage]];
        [fingerImage setFrame:CGRectMake(0, 0, 93, 93)];
        [fingerImageHolder.layer addSublayer:fingerImage];
        
        backgroundImage = [CALayer layer];
        [backgroundImage setFrame:CGRectMake(0, 0, 320, 480)];
        [backgroundImage setContents:(id)[[UIImage imageNamed:@"speedread-background-light-portrait.png"] CGImage]];
        [self.layer addSublayer:backgroundImage];
        
        CALayer *roundedCorners = [CALayer layer];
        [roundedCorners setFrame:CGRectMake(0, 0, 320, 480)];
        [roundedCorners setContents:(id)[[UIImage imageNamed:@"roundedcorners.png"] CGImage]];
        [self.layer addSublayer:roundedCorners];
        
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
        
        [self goToBookmarkPoint:aBook.implicitBookmarkPoint animated:NO];	
        [bigTextLabel setText:[textArray objectAtIndex:currentWordOffset]];
        
        initialTouchDifference = 0;
        
        zooming = NO;
    }    
    return self;
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
    } else {
        ret = [self fillArrayWithNextBlock];
    } 
    
    if (ret) {
        self.pageNumber = [self pageNumberForBookmarkPoint:[paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:self.currentWordOffset]];
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

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    return [self goToPageNumber:[self.contentsDataSource pageNumberForSectionUuid:uuid]
                       animated:animated];
}

- (void)goToPageNumber:(NSInteger)aPageNumber animated:(BOOL)animated {
    return [self goToBookmarkPoint:[paragraphSource bookmarkPointForPageNumber:aPageNumber] animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    return [paragraphSource pageNumberForBookmarkPoint:bookmarkPoint];
}

- (NSInteger)pageCount {
    return [paragraphSource pageCount];
}

- (BlioBookmarkPoint *)currentBookmarkPoint {
    BlioBookmarkPoint *bookmarkPoint = [paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID
                                                                          wordOffset:self.currentWordOffset];
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = bookmarkPoint.layoutPage;
    ret.blockOffset = bookmarkPoint.blockOffset;
    ret.wordOffset = bookmarkPoint.wordOffset;
    ret.elementOffset = bookmarkPoint.elementOffset;
    return [ret autorelease];
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
}

#pragma mark -
#pragma mark Back Button History

- (void)pushCurrentBookmarkPoint {
    BlioBookmarkPoint *bookmarkPoint = [self currentBookmarkPoint];
    if (bookmarkPoint) {
        [self.delegate pushBookmarkPoint:bookmarkPoint];
    }
}

- (NSString *)pageLabelForPageNumber:(NSInteger)page {
    NSString *ret = nil;
    
    id<EucBookContentsTableViewControllerDataSource> contentsSource = self.contentsDataSource;
    NSString* section = [contentsSource sectionUuidForPageNumber:page];
    THPair* chapter = [contentsSource presentationNameAndSubTitleForSectionUuid:section];
    NSString* pageStr = [contentsSource displayPageNumberForPageNumber:page];
    
    if(chapter.first) {
        ret = [NSString stringWithFormat:@"%@ \u2013 %@", pageStr, chapter.first];
    } else {
        ret = pageStr;
    } 
    
    return ret;
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(bookmarkPoint) {
        [self goToBookmarkPoint:bookmarkPoint animated:NO];
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
#pragma mark EucBookContentsTableViewControllerDataSource

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return self;
}

- (NSArray *)sectionUuids {
    return paragraphSource.contentsDataSource.sectionUuids;
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page {
    return [paragraphSource.contentsDataSource sectionUuidForPageNumber:page];
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid {
    return [paragraphSource.contentsDataSource presentationNameAndSubTitleForSectionUuid:sectionUuid];
}

- (NSUInteger)pageNumberForSectionUuid:(NSString *)sectionUuid {
    return [paragraphSource.contentsDataSource pageNumberForSectionUuid:sectionUuid];
}

- (NSString *)displayPageNumberForPageNumber:(NSUInteger)page
{
    float percentage = 100.0f * ((float)(page - 1) / (float)self.pageCount);
    unsigned long intPercentage = roundf(percentage);
    return [NSString stringWithFormat:@"%lu%%", intPercentage];
}

@end
