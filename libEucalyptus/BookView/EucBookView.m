//
//  EucBookView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 17/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBookView.h"

#import "EucPageTurningView.h"
#import "EucPageLayoutController.h"
#import "EucBook.h"
#import "EucBookReference.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookTitleView.h"

#import "THUIViewAdditions.h"
#import "THRoundRectView.h"
#import "THCopyWithCoder.h"
#import "THAlertViewWithUserInfo.h"
#import "THScalableSlider.h"
#import "THGeometryUtils.h"
#import "THPair.h"
#import "THRegex.h"
#import "THLog.h"

#define kBookFontPointSizeDefaultsKey @"EucBookFontPointSize"

@interface EucBookView ()
- (THPair *)_pageViewAndIndexPointForBookPageNumber:(NSInteger)pageNumber;
- (NSInteger)_sliderByteToPage:(float)byte;
- (float)_pageToSliderByte:(NSInteger)page;
- (void)_updateSliderByteToPageRatio;
- (void)_updatePageNumberLabel;
@end


@implementation EucBookView

@synthesize delegate = _delegate;
@synthesize book = _book;

@synthesize undimAfterAppearance = _undimAfterAppearance;
@synthesize appearAtCoverThenOpen = _appearAtCoverThenOpen;

@synthesize pageLayoutController = _pageLayoutController;


- (id)initWithFrame:(CGRect)frame book:(EucBookReference<EucBook> *)book 
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = YES;
        
        _book = [book retain];
        
        _pageViewToIndexPoint = [[NSMutableDictionary alloc] init];
        _pageViewToIndexPointCounts = [[NSCountedSet alloc] init];
        
        CGFloat desiredPointSize = [[NSUserDefaults standardUserDefaults] floatForKey:kBookFontPointSizeDefaultsKey];
        if(desiredPointSize == 0) {
            desiredPointSize = [EucBookTextStyle defaultFontPointSize];
        }
        
        /* if(!_bookIndex.isFinal) {
         [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(_bookPaginationProgress:)
         name:BookPaginationProgressNotification
         object:nil];            
         [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(_bookPaginationComplete:)
         name:BookPaginationCompleteNotification
         object:nil];
         }       */ 
        
        _pageLayoutController = [[[_book pageLayoutControllerClass] alloc] initWithBook:_book fontPointSize:desiredPointSize];  
        
        _pageTurningView = [[EucPageTurningView alloc] initWithFrame:self.bounds];
        _pageTurningView.delegate = self;
        [self addSubview:_pageTurningView];
        
        EucBookPageIndexPoint *indexPoint;
        if(_appearAtCoverThenOpen) {
            indexPoint = [[[EucBookPageIndexPoint alloc] init] autorelease];
        } else {
            indexPoint = [_book currentPageIndexPoint];
        }
        NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:indexPoint];
        THPair *currentPageViewAndIndexPoint = [self _pageViewAndIndexPointForBookPageNumber:pageNumber];
        
        NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:currentPageViewAndIndexPoint.first];
        [_pageViewToIndexPoint setObject:currentPageViewAndIndexPoint.second forKey:nonRetainedPageView];
        [_pageViewToIndexPointCounts addObject:nonRetainedPageView];
        _pageTurningView.currentPageView = currentPageViewAndIndexPoint.first;
        _pageNumber = pageNumber;
        [self _updatePageNumberLabel];

        _pageTurningView.dimQuotient = _dimQuotient;
        
        self.opaque = YES;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    if(self.appearAtCoverThenOpen) {
        EucBookPageIndexPoint *indexPoint = [_book currentPageIndexPoint];
        [self setPageNumber:[_pageLayoutController pageNumberForIndexPoint:indexPoint] animated:YES];
        self.appearAtCoverThenOpen = NO;
    } 
    if(self.undimAfterAppearance) {
        self.undimAfterAppearance = NO;
        NSNumber *timeNow = [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()];
        [self performSelector:@selector(updateDimQuotientForTimeAfterAppearance:) withObject:timeNow afterDelay:1.0/30.0];
    }
}    

- (void)stopAnimation
{
    [_pageTurningView stopAnimation];
}

- (UIImage *)currentPageImage
{
    return [_pageTurningView screenshot];
}

- (CGFloat)dimQuotient
{
    return _dimQuotient;
}

- (void)setDimQuotient:(CGFloat)dimQuotient 
{
    _dimQuotient = dimQuotient;
    _pageTurningView.dimQuotient = dimQuotient;  
}

- (void)updateDimQuotientForTimeAfterAppearance:(NSNumber *)appearanceTime
{
    CFAbsoluteTime duration = 1;
    CFAbsoluteTime start = [appearanceTime doubleValue];
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    
    CFAbsoluteTime elapsed = (now - start) / duration;
    
    if(elapsed > 1) {
        self.dimQuotient = 0.0f;
    } else {
        self.dimQuotient = (cosf(((CGFloat)M_PI) * ((CGFloat)elapsed)) + 1.0f) * 0.5f;
        [self performSelector:@selector(updateDimQuotientForTimeAfterAppearance:) withObject:appearanceTime afterDelay:1.0/30.0];
    }
}

- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated
{
    NSInteger oldPageNumber = self.pageNumber;
    if(oldPageNumber != pageNumber) {
        THPair *newPageViewAndIndexPoint = [self _pageViewAndIndexPointForBookPageNumber:pageNumber];
        
        UIView *newPageView = newPageViewAndIndexPoint.first;
        EucBookPageIndexPoint *newPageIndexPoint = newPageViewAndIndexPoint.second;
        
        NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:newPageView];
        [_pageViewToIndexPoint setObject:newPageIndexPoint forKey:nonRetainedPageView];
        [_pageViewToIndexPointCounts addObject:nonRetainedPageView];
        
        if(animated) {
            NSInteger count = oldPageNumber - pageNumber;
            if(count < 0) {
                count = -count;
            }
            [_pageTurningView turnToPageView:newPageView forwards:oldPageNumber < pageNumber pageCount:count];
        } else {
            _pageTurningView.currentPageView = newPageView;
            [_pageTurningView drawView];
            [self pageTurningView:_pageTurningView didTurnToView:newPageView];
        }
        
        [_pageSlider setScaledValue:[self _pageToSliderByte:pageNumber] animated:animated];
        _pageNumber = pageNumber;
        
        [self _updatePageNumberLabel];
    }
}


- (void)setPageNumber:(NSInteger)pageNumber
{
    [self setPageNumber:pageNumber animated:NO];
}

- (NSInteger)pageNumber
{
    return _pageNumber;
}

- (NSString *)displayPageNumber
{
    return [_pageLayoutController displayPageNumberForPageNumber:self.pageNumber];
}

- (NSString *)pageDescription
{
    return [_pageLayoutController pageDescriptionForPageNumber:self.pageNumber];
}


- (void)jumpToPage:(NSInteger)newPageNumber
{
    NSInteger currentPageNumber = self.pageNumber;
    if(newPageNumber != currentPageNumber) {
        [self setPageNumber:newPageNumber animated:YES];
        _savedJumpPage = currentPageNumber;
        _directionalJumpCount = newPageNumber > currentPageNumber ? 1 : -1;
        _jumpShouldBeSaved = YES;
    }
}

- (void)jumpToUuid:(NSString *)uuid
{
    [self jumpToPage:[_pageLayoutController pageNumberForSectionUuid:uuid]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex) {
        UIApplication *application = [UIApplication sharedApplication];
        
        // Looks nice if we leave time for the sheet's fading to fade out.
        [application beginIgnoringInteractionEvents];
        [application performSelector:@selector(openURL:) withObject:((THAlertViewWithUserInfo *)alertView).userInfo afterDelay:0];
    }
}

- (void)_hyperlinkTapped:(NSDictionary *)attributes
{
    NSString *URLString = [attributes objectForKey:@"href"];
    if(URLString) {
        NSURL *url = [NSURL URLWithString:URLString];
        if(url) {
            NSString *scheme = url.scheme;
            if(scheme) {
                NSString *message = nil;
                if([scheme caseInsensitiveCompare:@"internal"] == NSOrderedSame) {
                    // This is an internal link - jump to the specified section.
                    [self jumpToUuid:url.resourceSpecifier];
                } else {
                    // See if our delegate wants to handle the link.
                    if(![_delegate respondsToSelector:@selector(bookView:shouldHandleTapOnHyperlink:withAttributes:)] ||
                       [_delegate bookView:self shouldHandleTapOnHyperlink:url withAttributes:attributes]) {
                        if([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame) {
                            NSString *absolute = url.absoluteString;
                            if([absolute matchPOSIXRegex:@"(itunes|phobos).*\\.com" flags:REG_EXTENDED | REG_ICASE]) {
                                if([absolute matchPOSIXRegex:@"(viewsoftware|[/]app[/])" flags:REG_EXTENDED | REG_ICASE]) {
                                    message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped points to an app in the App Store.\n\nDo you want to switch to the App Store to view it now?", @"Message for sheet in book view askng if the user wants to open a clicked app hyperlink in the App Store"), url.host];
                                } else {
                                    message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped will open iTunes.\n\nDo you want to switch to iTunes now?", @"Message for sheet in book view asking if the user wants to open a clicked URL hyperlink in iTunes"), url.host];
                                }
                            } else {
                                message = [NSString stringWithFormat:NSLocalizedString(@"The link you tapped points to a page at “%@”, on the Internet.\n\nDo you want to switch to Safari to view it now?", @"Message for sheet in book view askng if the user wants to open a clicked URL hyperlink in Safari"), url.host];
                            }
                        } else if([scheme caseInsensitiveCompare:@"mailto"] == NSOrderedSame) {
                            message = [NSString stringWithFormat:NSLocalizedString(@"Do you want to switch to the Mail application to write an email to “%@” now?", @"Message for sheet in book view askng if the user wants to open a clicked mailto hyperlink in Mail"), url.resourceSpecifier];
                        } 
                        
                        if(message) {
                            THAlertViewWithUserInfo *alertView = [[THAlertViewWithUserInfo alloc] initWithTitle:nil
                                                                                                        message:message
                                                                                                       delegate:self
                                                                                              cancelButtonTitle:NSLocalizedString(@"Don’t Switch", @"Button to cancel opening of a clicked hyperlink") 
                                                                                              otherButtonTitles:NSLocalizedString(@"Switch", @"Button to confirm opening of a clicked hyperlink"), nil];
                            alertView.userInfo = url;
                            [alertView show];
                            [alertView release];
                        }
                    }
                }
            }
        }
    }
}

- (void)jumpForwards
{    
    if(_directionalJumpCount == -1) {
        // If the last page turn we did was a jump on the opposite direction,
        // jump back to the position we used to be at.
        [self setPageNumber:_savedJumpPage animated:YES];
        return;
    }  
    
    // Only save the 'jump back' page if it is not multiple times in a row that
    // the button has been hit.
    NSInteger jumpCount = _directionalJumpCount;
    
    NSInteger currentPageNumber = self.pageNumber;
    NSInteger newPageNumber = [_pageLayoutController nextSectionPageNumberForPageNumber:currentPageNumber];
    
    if(newPageNumber != currentPageNumber) {
        [self setPageNumber:newPageNumber animated:YES];
        // Save our previous position so that we can jump back to it if the user
        // taps the next section button.
        ++jumpCount;
        _directionalJumpCount = jumpCount;
        if(jumpCount == 1) {
            _savedJumpPage = currentPageNumber;
        }     
        _jumpShouldBeSaved = YES;
    }
}

- (void)jumpBackwards
{
    if(_directionalJumpCount == 1) {
        // If the last page turn we did was a jump on the opposite direction,
        // jump back to the position we used to be at.
        [self setPageNumber:_savedJumpPage animated:YES];
        return;
    }
    
    // Only save the 'jump back' page if it is not multiple times in a row that
    // the button has been hit.
    NSInteger jumpCount = _directionalJumpCount;
    
    // This is much harder than skipping forwards, because we don't just want
    // to go the previous section, we want to go the start of the /current/
    // section if we're not in the first page.
    NSInteger currentPageNumber = self.pageNumber;
    
    NSInteger newPageNumber = [_pageLayoutController previousSectionPageNumberForPageNumber:currentPageNumber];
    
    if(newPageNumber != currentPageNumber) {
        [self setPageNumber:newPageNumber animated:YES];
        // Save our previous position so that we can jump back to it if the user
        // taps the next section button.
        --jumpCount;
        _directionalJumpCount = jumpCount;
        if(jumpCount == -1) {
            _savedJumpPage = currentPageNumber;
        }     
        _jumpShouldBeSaved = YES;
    }
}

- (THPair *)_pageViewAndIndexPointForBookPageNumber:(NSInteger)pageNumber
{          
    THPair *ret = [_pageLayoutController viewAndIndexPointForPageNumber:pageNumber];
    if([ret.first isKindOfClass:[EucPageView class]]) {
        // Hrm, this is a bit messy...
        ((EucPageView *)ret.first).delegate = self;
    }
    
    return ret;
}


- (void)pageView:(EucPageView *)bookTextView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes
{
   /* if(_touch) {
        // Stop tracking the touch - we don't want to show/hide the toolbar on a
        // tap if it was on a hyperlink.
        [_touch release];
        _touch = nil;
    }*/
    THLog(@"BookViewController received tap on hyperlink: %@", attributes);
    [self _hyperlinkTapped:attributes];
}


- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView previousViewForView:(UIView *)view
{
    EucBookPageIndexPoint *pageIndexPoint = [_pageViewToIndexPoint objectForKey:[NSValue valueWithNonretainedObject:view]];
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    if(pageNumber > 1) {
        THPair *newPageViewAndIndexPoint = [self _pageViewAndIndexPointForBookPageNumber:pageNumber - 1];
        if(newPageViewAndIndexPoint) {
            EucPageView *newPageView = newPageViewAndIndexPoint.first;
            EucBookPageIndexPoint *newIndexPoint = newPageViewAndIndexPoint.second;
            
            NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:newPageView];
            [_pageViewToIndexPoint setObject:newIndexPoint forKey:nonRetainedPageView];
            [_pageViewToIndexPointCounts addObject:nonRetainedPageView];
            
            return newPageView;
        }
    }
    return nil;
}

- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView nextViewForView:(UIView *)view
{
    EucBookPageIndexPoint *pageIndexPoint = [_pageViewToIndexPoint objectForKey:[NSValue valueWithNonretainedObject:view]];
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    THPair *newPageViewAndIndexPoint = [self _pageViewAndIndexPointForBookPageNumber:pageNumber + 1];
    if(newPageViewAndIndexPoint) {
        EucPageView *newPageView = newPageViewAndIndexPoint.first;
        EucBookPageIndexPoint *newIndexPoint = newPageViewAndIndexPoint.second;
        
        NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:newPageView];
        [_pageViewToIndexPoint setObject:newIndexPoint forKey:nonRetainedPageView];
        [_pageViewToIndexPointCounts addObject:nonRetainedPageView];
        
        return newPageView;
    } else {
        return nil;
    }
}


static void LineFromCGPointsCGRectIntersectionPoints(CGPoint points[2], CGRect bounds, CGPoint returnedPoints[2]) 
{
    // Y = mX + n;
    // X = (Y - n) / m;
    CGPoint lineVector = CGPointMake(points[1].x - points[0].x, points[1].y - points[0].y);
    CGFloat lineXMultiplier = lineVector.y / lineVector.x;
    CGFloat lineConstantYAddition = points[0].y - (points[0].x * lineXMultiplier);
    
    CGPoint lineRectEdgeIntersections[4];
    lineRectEdgeIntersections[0] = CGPointMake(0, lineConstantYAddition);
    lineRectEdgeIntersections[1] = CGPointMake(bounds.size.width, lineXMultiplier * bounds.size.width + lineConstantYAddition);
    lineRectEdgeIntersections[2] = CGPointMake(-lineConstantYAddition / lineXMultiplier, 0);
    lineRectEdgeIntersections[3] = CGPointMake((bounds.size.height - lineConstantYAddition) / lineXMultiplier, bounds.size.height);
    
    for(NSInteger i = 0, j = 0; i < 4 && j < 2; ++i) {
        if(lineRectEdgeIntersections[i].x >= 0 && lineRectEdgeIntersections[i].x <= bounds.size.width &&
           lineRectEdgeIntersections[i].y >= 0 && lineRectEdgeIntersections[i].y <= bounds.size.height) {
            returnedPoints[j++] = lineRectEdgeIntersections[i];
        }
    }    
}


- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView 
          scaledViewForView:(UIView *)view 
             pinchStartedAt:(CGPoint[])pinchStartedAt 
                 pinchNowAt:(CGPoint[])pinchNowAt 
          currentScaledView:(UIView *)currentScaledView
{
    CFAbsoluteTime start = 0;
    if(THWillLog()) {
        start = CFAbsoluteTimeGetCurrent();   
    }
    
    UIView *ret = nil;
    
    if(!_scaleUnderway) {
        _scaleUnderway = YES;
        _scaleStartPointSize = _pageLayoutController.fontPointSize;
        _scaleCurrentPointSize = _pageLayoutController.fontPointSize;
    }
    
    CGRect bounds = view.bounds;
    
    // We base the scale on the percentage of the screen "taken up"
    // by the initial pinch, and the percentage of the screen "taken up"
    
    CGFloat startLineLength = CGPointDistance(pinchStartedAt[0], pinchStartedAt[1]);
    CGFloat nowLineLength = CGPointDistance(pinchNowAt[0], pinchNowAt[1]);
    
    CGPoint startLineBoundsIntersectionPoints[2];
    LineFromCGPointsCGRectIntersectionPoints(pinchStartedAt, bounds, startLineBoundsIntersectionPoints);
    CGFloat startLineMaxLength = CGPointDistance(startLineBoundsIntersectionPoints[0], startLineBoundsIntersectionPoints[1]);
    
    CGPoint nowLineBoundsIntersectionPoints[2];
    LineFromCGPointsCGRectIntersectionPoints(pinchNowAt, bounds, nowLineBoundsIntersectionPoints);
    CGFloat nowLineMaxLength = CGPointDistance(nowLineBoundsIntersectionPoints[0], nowLineBoundsIntersectionPoints[1]);
    
    
    CGFloat startLinePercentage = startLineLength / startLineMaxLength;
    CGFloat nowLinePercentage = nowLineLength / nowLineMaxLength;
    
    NSArray *availablePointSizes = _pageLayoutController.availablePointSizes;
    CGFloat minPointSize = [[availablePointSizes objectAtIndex:0] doubleValue];
    CGFloat maxPointSize = [[availablePointSizes lastObject] doubleValue];
    
    CGFloat scaledPointSize;
    if(nowLinePercentage < startLinePercentage) {
        minPointSize -= (maxPointSize - minPointSize) / availablePointSizes.count; 
        //NSLog(@"min: %f", minPointSize);
        scaledPointSize = minPointSize + ((nowLinePercentage / startLinePercentage) * (_scaleStartPointSize - minPointSize));
    } else {
        maxPointSize += (maxPointSize - minPointSize) / availablePointSizes.count; 
        //NSLog(@"max: %f", maxPointSize);
        scaledPointSize = _scaleStartPointSize + (((nowLinePercentage - startLinePercentage) / (1 - nowLinePercentage)) * (maxPointSize - _scaleStartPointSize));
    }
    CGFloat difference = CGFLOAT_MAX;
    CGFloat foundSize = _scaleCurrentPointSize;
    for(NSNumber *sizeNumber in availablePointSizes) {
        CGFloat thisSize = [sizeNumber doubleValue];
        CGFloat thisDifference = fabsf(thisSize - scaledPointSize);
        if(thisDifference < difference) {
            difference = thisDifference;
            foundSize = thisSize;
        }
    }
    if(foundSize != _scaleCurrentPointSize) {
        EucBookPageIndexPoint *oldIndexPoint = [_pageViewToIndexPoint objectForKey:[NSValue valueWithNonretainedObject:view]];
        [_pageLayoutController setFontPointSize:foundSize];
        NSInteger newPageNumber = [_pageLayoutController pageNumberForIndexPoint:oldIndexPoint];
        THPair *viewAndIndexPoint = [_pageLayoutController viewAndIndexPointForPageNumber:newPageNumber];
        
        ret = viewAndIndexPoint.first;
        
        NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:ret];
        [_pageViewToIndexPoint setObject:viewAndIndexPoint.second forKey:nonRetainedPageView];
        [_pageViewToIndexPointCounts addObject:nonRetainedPageView];        
        
        _scaleCurrentPointSize = foundSize;
        
        if(THWillLog()) {
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            ++_scaleCount;
            _accumulatedScaleTime += (end - start);
            
            if(fmodf(_scaleCount, 20.0) == 0) {
                THLog(@"Scale generation rate: %f scaled views/s", (_scaleCount / _accumulatedScaleTime))
            }            
        }
    }
    
    return ret;
}

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didTurnToView:(UIView *)view
{
    EucBookPageIndexPoint *pageIndexPoint = [_pageViewToIndexPoint objectForKey:[NSValue valueWithNonretainedObject:view]];
    NSInteger pageNumber = [_pageLayoutController pageNumberForIndexPoint:pageIndexPoint];
    
    [_book setCurrentPageIndexPoint:pageIndexPoint];
    if(!_jumpShouldBeSaved) {
        _directionalJumpCount = 0;
    } else {
        _jumpShouldBeSaved = NO;
    }
    _pageSlider.scaledValue = [self _pageToSliderByte:pageNumber];
    _pageNumber = pageNumber;   
    [self _updatePageNumberLabel];
}

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didScaleToView:(UIView *)view
{
    _scaleUnderway = NO;
    _scaleStartPointSize = 0;
    _scaleCurrentPointSize = 0;
    
    [[NSUserDefaults standardUserDefaults] setFloat:_pageLayoutController.fontPointSize forKey:kBookFontPointSizeDefaultsKey];
    [_book setCurrentPageIndexPoint:[_pageViewToIndexPoint objectForKey:[NSValue valueWithNonretainedObject:view]]];
}

- (void)pageTurningView:(EucPageTurningView *)pageTurningView discardingView:(UIView *)view
{
    NSValue *nonRetainedPageView = [NSValue valueWithNonretainedObject:view];
    [_pageViewToIndexPointCounts removeObject:nonRetainedPageView];
    if([_pageViewToIndexPointCounts countForObject:nonRetainedPageView] == 0) {
        [_pageViewToIndexPoint removeObjectForKey:[NSValue valueWithNonretainedObject:view]];
    }
}


- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView viewEdgeIsRigid:(UIView *)view
{
    return [_pageLayoutController viewShouldBeRigid:view];
}


- (void)_addButtonToView:(UIView *)view withImageNamed:(NSString *)name centerPoint:(CGPoint)centerPoint target:(id)target action:(SEL)action
{
    UIButton *button;
    button = [[UIButton alloc] init];
    button.showsTouchWhenHighlighted = YES;
    UIImage *image = [UIImage imageNamed:name];
    [button setImage:image forState:UIControlStateNormal];
    [button sizeToFit];
    CGSize boundsSize = button.bounds.size;
    if((((NSInteger)boundsSize.width) % 2) == 1) {
        centerPoint.x += 0.5;
    }
    if((((NSInteger)boundsSize.height) % 2) == 1) {
        centerPoint.y += 0.5;
    }
    button.center = centerPoint;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
    
    [button release];    
}

- (UIToolbar *)bookNavigationToolbar
{
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.translucent = YES;
    
    [toolbar sizeToFit];
    CGFloat toolbarMarginHeight = 12.0f;
    CGFloat toolbarNonMarginHeight = [toolbar frame].size.height - 2.0f * toolbarMarginHeight;
    
    CGFloat toolbarHeight = floorf(toolbarMarginHeight * 3.0f + 2.0f * toolbarNonMarginHeight);
    [toolbar setFrame:CGRectMake(mainScreenBounds.origin.x,
                                 mainScreenBounds.origin.y + mainScreenBounds.size.height - toolbarHeight,
                                 mainScreenBounds.size.width,
                                 toolbarHeight)];
    [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
    
    CGRect toolbarBounds = toolbar.bounds;
    CGFloat centerY = floorf(toolbarMarginHeight * 2.0f + toolbarNonMarginHeight * 1.5f);
    
    UIFont *pageNumberFont = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize] + 1];
    _pageNumberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _pageNumberLabel.font = pageNumberFont;
    _pageNumberLabel.textAlignment = UITextAlignmentCenter;
    _pageNumberLabel.adjustsFontSizeToFitWidth = YES;
    
    _pageNumberLabel.backgroundColor = [UIColor clearColor];
    _pageNumberLabel.textColor = [UIColor whiteColor];
    _pageNumberLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    _pageNumberLabel.shadowOffset = CGSizeMake(0, -1);
    
    CGRect pageNumberFrame = _pageNumberLabel.frame;
    pageNumberFrame.size.width = ceilf(toolbarBounds.size.width / 3.0f);
    pageNumberFrame.size.height = ceilf(toolbarBounds.size.height / 3.0f);
    if(!((NSUInteger)pageNumberFrame.size.width % 2) == 0) {
        --pageNumberFrame.size.width;
    }
    if(!((NSUInteger)pageNumberFrame.size.height % 2) == 0) {
        --pageNumberFrame.size.height;
    }
    _pageNumberLabel.frame = pageNumberFrame;
    _pageNumberLabel.center = CGPointMake(toolbarBounds.size.width * 0.5f, centerY);
    [toolbar addSubview:_pageNumberLabel];
    
    /*[self _addButtonToView:toolbar 
     withImageNamed:@"UIBarButtonBugButton.png" 
     centerPoint:CGPointMake(floorf(toolbarBounds.size.width * 0.075f), centerY)
     target:self
     action:@selector(_bugButtonTapped)];
     */
    [self _addButtonToView:toolbar 
            withImageNamed:@"UIBarButtonSystemItemRewind.png" 
               centerPoint:CGPointMake(floorf(toolbarBounds.size.width * 0.3f), centerY)
                    target:self
                    action:@selector(jumpBackwards)];
    
    [self _addButtonToView:toolbar 
            withImageNamed:@"UIBarButtonSystemItemFastForward.png" 
               centerPoint:CGPointMake(ceilf(toolbarBounds.size.width * 0.7f), centerY)
                    target:self
                    action:@selector(jumpForwards)];
    /*
     [self _addButtonToView:toolbar 
     withImageNamed:@"UIBarButtonSystemItemTrash.png" 
     centerPoint:CGPointMake(ceilf(toolbarBounds.size.width * 0.935f) , centerY)
     target:self
     action:@selector(_trashButtonTapped)];
     */
    
    _pageSlider = [[THScalableSlider alloc] initWithFrame:toolbarBounds];
    _pageSlider.backgroundColor = [UIColor clearColor];	
    
    UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
    leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:leftCapImage.size.height];
    [_pageSlider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
    
    UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
    rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    [_pageSlider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
    
    UIImage *thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob.png"];
    [_pageSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [_pageSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
    
    [_pageSlider addTarget:self action:@selector(_pageSliderSlid:) forControlEvents:UIControlEventValueChanged];
    
    CGRect pageSliderFrame = CGRectZero;
    pageSliderFrame.size.width = toolbarBounds.size.width - 18;
    pageSliderFrame.size.height = thumbImage.size.height + 8;
    _pageSlider.frame = pageSliderFrame;
    
    _pageSlider.center = CGPointMake(toolbarBounds.size.width / 2.0f, toolbarMarginHeight + toolbarNonMarginHeight * 0.5f);
    
    pageSliderFrame = _pageSlider.frame;
    
    
    UIProgressView *behindSlider = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    CGRect behindSliderFrame = behindSlider.frame;
    behindSliderFrame.size.width = pageSliderFrame.size.width - 4;
    behindSlider.frame = behindSliderFrame;
    
    CGPoint pageSliderCenter = _pageSlider.center;
    pageSliderCenter.y += 1.5;
    behindSlider.center = pageSliderCenter;
    
    [toolbar addSubview:behindSlider];
    [behindSlider release];
    
    [toolbar addSubview:_pageSlider];
    
    _pageSlider.minimumValue = 0;
    _pageSlider.maximumValue = [_pageLayoutController globalPageCount] - 1;
    //_pageSlider.maximumValue = NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + _book.bytesInReadableSections + _book.licenceAppendix.bytesInReadableSections;
    _pageSlider.scaledValue = self.pageNumber;
    
    [_pageSlider layoutSubviews];
    
    //if(_bookIndex.isFinal) {
    _paginationIsComplete = YES;
    //}
    [self _updateSliderByteToPageRatio];    
    [self _updatePageNumberLabel];

    return toolbar;
}    


- (void)_updatePageNumberLabel
{
    if(_pageNumberLabel) {
        float sliderByte = _pageSlider.scaledValue;
        NSInteger pageNumber;
        if(_pageSliderIsTracking) {
            pageNumber = [self _sliderByteToPage:sliderByte];
        } else {
            pageNumber = self.pageNumber;
        }
        _pageNumberLabel.text = [_pageLayoutController pageDescriptionForPageNumber:pageNumber];
        
        if(_pageSliderIsTracking) {
            // If the slider is tracking, we'll place a HUD view showing chapter
            // and page information about the drag point.
            
            const CGFloat margin = 6.0f;
            const CGFloat width = 184.0f;
            
            UILabel *pageSliderNumberLabel = nil;
            UILabel *pageSliderChapterLabel = nil;
            if(!_pageSliderTrackingInfoView) {
                pageSliderChapterLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                pageSliderChapterLabel.backgroundColor = [UIColor clearColor];
                pageSliderChapterLabel.textColor = [UIColor whiteColor];
                pageSliderChapterLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
                pageSliderChapterLabel.shadowOffset = CGSizeMake(0, -1);
                pageSliderChapterLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] * (1.0f + (1.0f / 3.0f))];
                pageSliderChapterLabel.textAlignment = UITextAlignmentCenter;
                pageSliderChapterLabel.tag = 1;
                
                pageSliderChapterLabel.text = @"Hg";
                
                [pageSliderChapterLabel sizeToFit];
                CGRect pageSliderChapterLabelFrame = pageSliderChapterLabel.frame;
                pageSliderChapterLabelFrame.size.width = width - 2 * margin;
                pageSliderChapterLabelFrame.origin.x = margin;
                pageSliderChapterLabelFrame.origin.y = margin;
                pageSliderChapterLabel.frame = pageSliderChapterLabelFrame;
                pageSliderChapterLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                
                pageSliderNumberLabel = [pageSliderChapterLabel copyWithCoder];
                pageSliderNumberLabel.tag = 2;
                
                CGRect pageSliderNumberLabelFrame = pageSliderNumberLabel.frame;
                pageSliderNumberLabelFrame.origin.y += pageSliderChapterLabelFrame.size.height;
                pageSliderNumberLabel.frame = pageSliderNumberLabelFrame;
                
                _pageSliderTrackingInfoView = [[THRoundRectView alloc] initWithFrame:CGRectMake(0, 0, width, 2 * margin + pageSliderChapterLabelFrame.size.height + pageSliderNumberLabelFrame.size.height)];
                _pageSliderTrackingInfoView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
                ((THRoundRectView *)_pageSliderTrackingInfoView).cornerRadius = 10.0f;
                
                [_pageSliderTrackingInfoView addSubview:pageSliderChapterLabel];
                [_pageSliderTrackingInfoView addSubview:pageSliderNumberLabel];
                
                [_pageTurningView addSubview:_pageSliderTrackingInfoView];
                [_pageSliderTrackingInfoView centerInSuperview];
                
                [pageSliderChapterLabel release];
                [pageSliderNumberLabel release];
            } else {
                pageSliderChapterLabel = (UILabel *)[_pageSliderTrackingInfoView viewWithTag:1];
                pageSliderNumberLabel = (UILabel *)[_pageSliderTrackingInfoView viewWithTag:2];
            }
            
            NSString *chapterTitle = [_pageLayoutController presentationNameAndSubTitleForSectionUuid:[_pageLayoutController sectionUuidForPageNumber:pageNumber]].first;
            
            pageSliderChapterLabel.text = chapterTitle;
            pageSliderNumberLabel.text = _pageNumberLabel.text;
            
            // Nicely size the view to accomodate longer names;
            CGRect viewBounds = _pageTurningView.bounds;
            CGSize allowedSize = viewBounds.size;
            allowedSize.width -= 12 * margin;
            
            CGFloat pageSliderChapterLabelWantsWidth = [pageSliderChapterLabel sizeThatFits:allowedSize].width;
            CGFloat pageSliderNumberLabelWantsWidth = [pageSliderNumberLabel sizeThatFits:allowedSize].width;
            
            CGRect frame = _pageSliderTrackingInfoView.frame;
            frame.size.width = MAX(pageSliderNumberLabelWantsWidth, pageSliderChapterLabelWantsWidth) + 4 * margin;
            frame.size.width = MAX(width, frame.size.width);
            frame.size.width = MIN(allowedSize.width + 4 * margin, frame.size.width);
            frame.origin.x = floorf((viewBounds.size.width - frame.size.width) / 2);
            _pageSliderTrackingInfoView.frame = frame;
            
            if(!chapterTitle) {
                // If there's no title, we center the "X of X" vertically
                [pageSliderNumberLabel centerInSuperview];
            } else {
                // Otherwise, place it below the chapter title.
                CGRect pageSliderNumberLabelFrame = pageSliderNumberLabel.frame;
                CGRect pageSliderChapterLabelFrame = pageSliderChapterLabel.frame;
                CGFloat wantedOriginY = pageSliderChapterLabelFrame.origin.y + pageSliderChapterLabelFrame.size.height;
                if(pageSliderNumberLabelFrame.origin.y != wantedOriginY) {
                    pageSliderNumberLabelFrame.origin.y = wantedOriginY;
                    pageSliderNumberLabel.frame = pageSliderNumberLabelFrame;
                }
            }
        } else {
            // The slider is not dragging, remove the HUD display if it's there.
            if(_pageSliderTrackingInfoView) {
                [_pageSliderTrackingInfoView removeFromSuperview];
                [_pageSliderTrackingInfoView release];
                _pageSliderTrackingInfoView = nil;
            }
        }
    }
}



- (void)_pageSliderSlid:(THScalableSlider *)sender
{
    if(!sender.isTracking) {
        if(!_pageSliderIsTracking) {
            _pageSliderIsTracking = YES; // We get a non-tracking event as the
            // first event of a drag too, so ignore 
            // it.
        } else {
            // After delay so that the UI gets redrawn with the slider knob in its
            // final position and the page number label updated before we begin
            // the process of setting the page (which takes long enough that if
            // we do it here, there's a noticable delay in the UI updating).
            _pageSliderIsTracking = NO;
            float sliderByte = sender.scaledValue;
            [_pageSlider setScaledValue:[self _pageToSliderByte:[self _sliderByteToPage:sliderByte]] animated:NO]; // To avoid jerkiness later.
            [self performSelector:@selector(_afterPageSliderSlid:) withObject:sender afterDelay:0];
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        }
    } else {
        [self _updatePageNumberLabel];
    }
}


- (void)_afterPageSliderSlid:(THScalableSlider *)sender
{
    [self setPageNumber:[self _sliderByteToPage:sender.scaledValue] animated:YES];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

#pragma mark -
#pragma mark Rework below to allow pagination again!

- (void)_updateSliderByteToPageRatio
{
    _sliderByteToPageRatio = 1;
    _pageSlider.maximumAvailable = [_pageLayoutController globalPageCount];
    /*
     if(_paginationIsComplete) {
     _sliderByteToPageRatio = (CGFloat)(NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + _book.bytesInReadableSections + _book.licenceAppendix.bytesInReadableSections) / 
     (CGFloat)(1 + _bookIndex.lastPageNumber + _licenceAppendixIndex.lastPageNumber);
     _pageSlider.maximumAvailable = -1;
     } else {
     _sliderByteToPageRatio = (CGFloat)(NON_TEXT_PAGE_FAKE_BYTE_COUNT * 2 + (_bookIndex.lastOffset - _book.firstSection.startOffset)  + _book.licenceAppendix.bytesInReadableSections) / 
     (CGFloat)(1 + _bookIndex.lastPageNumber + _licenceAppendixIndex.lastPageNumber);
     _pageSlider.maximumAvailable =  [self _pageToSliderByte:_bookIndex.lastPageNumber];
     }*/
}

- (NSInteger)_sliderByteToPage:(float)byte
{
    NSInteger page = (NSInteger)floorf(byte / _sliderByteToPageRatio);
    //page -= 1;
    page += 1;
    return page;
}

- (float)_pageToSliderByte:(NSInteger)page
{
    //page += 1;
    page -= 1;
    return ceilf((float)page * _sliderByteToPageRatio);
}

- (void)_bookPaginationComplete:(NSNotification *)notification
{
    _paginationIsComplete = YES;
    
    [self _updateSliderByteToPageRatio];
    [self _updatePageNumberLabel];
    
    //NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    //[defaultCenter removeObserver:self name:BookPaginationProgressNotification object:nil];
    //   [defaultCenter removeObserver:self name:BookPaginationCompleteNotification object:nil];                
}

- (void)_bookPaginationProgress:(NSNotification *)notification
{
    [self _updateSliderByteToPageRatio];
    [self _updatePageNumberLabel];
}

@end
