//
//  BlioViewSettingsFontAndSizeContentsView.m
//  BlioApp
//
//  Created by James Montgomerie on 21/11/2011.
//  Copyright (c) 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioViewSettingsFontAndSizeContentsView.h"
#import "BlioCenterableTableViewCell.h"
#import "BlioViewSettingsMetrics.h"

#import "BlioUIImageAdditions.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

@interface BlioViewSettingsFontAndSizeContentsView ()

@property (nonatomic, assign) id<BlioViewSettingsContentsViewDelegate> delegate;

@property (nonatomic, assign) BOOL refreshingSettings;

@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *justificationLabel;

@property (nonatomic, retain) BlioAccessibilitySegmentedControl *fontSizeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *justificationSegment;

@property (nonatomic, retain) UIView *fontTableViewContainer;
@property (nonatomic, retain) UITableView *fontTableView;

@property (nonatomic, assign, readonly) CGFloat rowHeight;

- (NSInteger)currentSelectedFontRowIndex;

@end


@implementation BlioViewSettingsFontAndSizeContentsView

@synthesize refreshingSettings;

@synthesize fontSizeLabel;
@synthesize justificationLabel;

@synthesize fontSizeSegment;
@synthesize justificationSegment;

@synthesize fontTableViewContainer;
@synthesize fontTableView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.fontSizeLabel = nil;
    self.justificationLabel = nil;
    
    self.fontSizeSegment = nil;
    self.justificationSegment = nil;
    
    self.fontTableViewContainer = nil;
    
    self.fontTableView.delegate = nil;
    self.fontTableView.dataSource = nil;
    self.fontTableView = nil;

    [super dealloc];
}

- (void)refreshSettings {
    self.refreshingSettings = YES;
    
    [self.fontTableView reloadData];
    
    if ([self.delegate shouldShowFontSizeSettings]) {
        self.fontSizeLabel.enabled = YES;
        self.fontSizeLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.fontSizeSegment.enabled = YES;
        self.fontSizeSegment.alpha = 1.0f;
        self.fontSizeSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        [self.fontSizeSegment setSelectedSegmentIndex:[self.delegate currentFontSizeIndex]];
    } else {
        self.fontSizeLabel.enabled = NO;
        self.fontSizeLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        self.fontSizeSegment.enabled = NO;
        self.fontSizeSegment.alpha = 0.35f;
        self.fontSizeSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        [self.fontSizeSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}
    
    if ([self.delegate shouldShowJustificationSettings]) {
        self.justificationLabel.enabled = YES;
        self.justificationLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.justificationSegment.enabled = YES;
        self.justificationSegment.alpha = 1.0f;
        self.justificationSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        
        NSUInteger segmentToSelect;
        switch([self.delegate currentJustification]) {
            case kBlioJustificationOriginal:
                segmentToSelect = 0;
                break;
            case kBlioJustificationLeft:
                segmentToSelect = 1;
                break;
            default:
            case kBlioJustificationFull:
                segmentToSelect = 2;
                break;
        }
        [self.justificationSegment setSelectedSegmentIndex:segmentToSelect];
    } else {
        self.justificationLabel.enabled = NO;
        self.justificationLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        self.justificationSegment.enabled = NO;
        self.justificationSegment.alpha = 0.35f;
        self.justificationSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        [self.justificationSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	} 
    
    self.refreshingSettings = NO;
    
    if(self.window) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

- (id)initWithDelegate:(id)newDelegate {
    
	if ((self = [super initWithDelegate:newDelegate])) {
        UIColor *whiteColor = [UIColor whiteColor];
        UIColor *clearColor = [UIColor clearColor];
        UIColor *tintColor;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            tintColor = [UIColor darkGrayColor];
        } else {
            tintColor = kBlioViewSettingsPopverBlueButton;
        }
        
        UIFont *defaultFont = [UIFont boldSystemFontOfSize:12.0f];
                
        //////// FONTS TABLE
        UIView *aFontTableViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        aFontTableViewContainer.layer.masksToBounds = YES;
        aFontTableViewContainer.layer.cornerRadius = 5.0f;

        UITableView *aFontsTableView = [[UITableView alloc] initWithFrame:aFontTableViewContainer.bounds style:UITableViewStylePlain];
        aFontsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        aFontsTableView.delegate = self;
        aFontsTableView.dataSource = self;
        [aFontTableViewContainer addSubview:aFontsTableView];
        self.fontTableView = aFontsTableView;
        [aFontsTableView release];
        
        UIView *aShadowView = [[UIView alloc] initWithFrame:CGRectInset(aFontTableViewContainer.bounds, -7, -7)];
        aShadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        CALayer *shadowLayer = aShadowView.layer;
        shadowLayer.masksToBounds = YES;
        shadowLayer.cornerRadius = 12.0f;        
        shadowLayer.borderColor = [tintColor CGColor];
        shadowLayer.borderWidth = 8.0f;
        shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
        shadowLayer.shadowOffset = CGSizeMake(0, 1);
        shadowLayer.shadowOpacity = 2.0f / 3.0f;
        shadowLayer.shadowRadius = 2.0;
        aShadowView.userInteractionEnabled = NO;
        [aFontTableViewContainer addSubview:aShadowView];
        [aShadowView release];
        
        self.fontTableViewContainer = aFontTableViewContainer;
        [self addSubview:aFontTableViewContainer];
        [aFontTableViewContainer release];
        
		//////// FONT SIZE
        
        UILabel *aFontSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aFontSizeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aFontSizeLabel.textColor = whiteColor;
        aFontSizeLabel.backgroundColor = clearColor;
        aFontSizeLabel.text = NSLocalizedString(@"Font Size",@"Settings Label for Font Size segmented control.");
        [self addSubview:aFontSizeLabel];
        self.fontSizeLabel = aFontSizeLabel;
        [aFontSizeLabel release];
        
        NSString *letter = NSLocalizedString(@"A",@"Sample letter used for showing font sizes");
        
        // Sizes and offsets for the font size buttons chosen to look 'right' visually
        // rather than being completly accurate to the book view technically.
        CGSize size = CGSizeMake(20, 23);
        
        NSUInteger fontSizeCount = [self.delegate fontSizeCount];
        NSArray *fontSizeTitles;
        if(fontSizeCount == 5) {
            CGFloat baseline = 19;
            fontSizeTitles = [NSMutableArray arrayWithObjects:
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:10.5] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:13] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:15] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:19] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:23] size:size baseline:baseline color:whiteColor],
                              nil];
        } else {
            CGFloat baseline = 22;
            NSParameterAssert(fontSizeCount == 6);
            fontSizeTitles = [NSMutableArray arrayWithObjects:
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:10.5] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:13] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:15] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:19] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:23] size:size baseline:baseline color:whiteColor],
                              [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:29] size:size baseline:baseline color:whiteColor],
                              nil];
        }  
        
        BlioAccessibilitySegmentedControl *aFontSizeSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:fontSizeTitles];    
        aFontSizeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aFontSizeSegmentedControl.tintColor = tintColor;
        
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Smaller font size", @"Accessibility label for View Settings Smaller Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Small font size", @"Accessibility label for View Settings Smaller Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Medium font size", @"Accessibility label for View Settings Normal Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:3] setAccessibilityLabel:NSLocalizedString(@"Large font size", @"Accessibility label for View Settings Larger Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:4] setAccessibilityLabel:NSLocalizedString(@"Larger font size", @"Accessibility label for View Settings Largest Font Size button")];
        if(fontSizeCount == 6) {
            [[aFontSizeSegmentedControl imageForSegmentAtIndex:5] setAccessibilityLabel:NSLocalizedString(@"Extra-large font size", @"Accessibility label for View Settings Largest Font Size button")];
        }
        
        [self addSubview:aFontSizeSegmentedControl];
        self.fontSizeSegment = aFontSizeSegmentedControl;
        [aFontSizeSegmentedControl release];
        
        [self.fontSizeSegment addTarget:self action:@selector(changeFontSize:) forControlEvents:UIControlEventValueChanged];
        
        //////// JUSTIFICATION
		
        UILabel *aJustificationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aJustificationLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aJustificationLabel.textColor = whiteColor;
        aJustificationLabel.backgroundColor = clearColor;
        aJustificationLabel.text = NSLocalizedString(@"Justification",@"Settings Label for Justification segmented control.");
        [self addSubview:aJustificationLabel];
        self.justificationLabel = aJustificationLabel;
        [aJustificationLabel release];
        
        NSArray *justificationTitles = [NSArray arrayWithObjects:
                                        NSLocalizedString(@"Original",@"\"Original\" segment label (for Reading Settings justification control)"),
                                        NSLocalizedString(@"Left",@"\"Left\" segment label (for Reading Settings justification control)"),
                                        NSLocalizedString(@"Full",@"\"Full\" segment label (for Reading Settings justification control)"),
                                        nil];
        
        BlioAccessibilitySegmentedControl *aJustificationSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:justificationTitles];
        aJustificationSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aJustificationSegmentedControl.tintColor = tintColor;
        
		// these lines don't seem to have effect because segmented control is not image-driven...
        [[aJustificationSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Left justified", @"Accessibility label for Reading Settings justification control")];
        [[aJustificationSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Fully justified", @"Accessibility label for Reading Settings justification control")];
        [[aJustificationSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Original justification from book", @"Accessibility label for Reading Settings justification control")];
        
        [self addSubview:aJustificationSegmentedControl];
        self.justificationSegment = aJustificationSegmentedControl;
        [aJustificationSegmentedControl release];
        
        [self.justificationSegment addTarget:self action:@selector(changeJustification:) forControlEvents:UIControlEventValueChanged];
        

        [self refreshSettings];
	}
	return self;
}

- (CGFloat)rowHeight
{
    [self.justificationSegment sizeToFit];
    return self.justificationSegment.frame.size.height;
}

- (void)layoutSubviews 
{
    CGFloat xInset, yInset, rowHeight, rowSpacing;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        xInset = kBlioViewSettingsXInsetIPhone;
        yInset = kBlioViewSettingsYInsetIPhone;
        rowSpacing = kBlioViewSettingsRowSpacingIPhone;
        [self.justificationSegment sizeToFit];
        rowHeight = self.justificationSegment.frame.size.height;
    } else {
        xInset = kBlioViewSettingsXInsetIPad;
        yInset = kBlioViewSettingsYInsetIPad;
        rowHeight = kBlioViewSettingsSegmentButtonHeight;
        rowSpacing = kBlioViewSettingsRowSpacingIPad;
    }
    
    CGRect bounds = self.bounds;
    
    CGFloat innerWidth = CGRectGetWidth(bounds) - 2 * xInset;
    CGFloat innerWidthWithoutSlider = innerWidth;
    
    CGFloat labelWidth = kBlioViewSettingsLabelWidth;
    
    CGFloat segmentX = labelWidth + xInset;
    CGFloat segmentWidth = innerWidthWithoutSlider - segmentX + xInset;
    
    CGFloat rowStride = rowSpacing + rowHeight;
    CGFloat currentY = CGRectGetHeight(bounds) - yInset;
        
    currentY -= rowHeight;
    [self.justificationLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.justificationSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];

    currentY -= rowStride;
    [self.fontSizeLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.fontSizeSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    
    currentY -= rowSpacing;
    [self.fontTableViewContainer setFrame:CGRectMake(xInset, yInset, innerWidth, currentY - yInset)];
    
    [self.fontTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self currentSelectedFontRowIndex] inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle 
                                      animated:NO];
    
    [super layoutSubviews];
}


- (void)changeFontSize:(id)sender {
    if(!self.refreshingSettings) {
        [self.delegate changeFontSizeIndex:((UISegmentedControl*)sender).selectedSegmentIndex];
    }
}

- (void)changeJustification:(id)sender {
    if(!self.refreshingSettings) {
        BlioJustification newJustifiction;
        switch(((UISegmentedControl*)sender).selectedSegmentIndex) {
            case 0:
                newJustifiction = kBlioJustificationOriginal;
                break;
            case 1:
                newJustifiction = kBlioJustificationLeft;
                break;
            default:
            case 2:
                newJustifiction = kBlioJustificationFull;
                break;
        }
        [self.delegate changeJustification:newJustifiction];
    }
}

- (void)dismiss:(id)sender {
    [self.delegate dismissViewSettingsInterface:self];
}

- (CGSize)preferredSize {
    CGSize size;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        size.width = kBlioViewSettingsWidthIPhone;
        size.height = self.rowHeight * 8;
    } else {
        size.width = kBlioViewSettingsWidthIPad;
        size.height = self.rowHeight * 10;
    }

    return size;
}

- (NSString *)navigationItemTitle
{
    return NSLocalizedString(@"Font Settings", "Title for Font Settings Popover");
}

- (void)flashScrollIndicators
{
    [self.fontTableView flashScrollIndicators];
}

#pragma mark -
#pragma mark Fonts Table 

- (UIColor *)selectedCellBackgroundColorWithHeight:(CGFloat)height
{
    CGFloat locationRefs[] = { 0.0f, 1.0f };
    if([[UIDevice currentDevice] compareSystemVersion:@"4"] == NSOrderedAscending) {
        locationRefs[0] = 1.0f;
        locationRefs[1] = 0.0f;
    }
    CGFloat colorRefs[] = { 223.0f / 255.0f, 230.0f / 255.0f, 236.0 / 255.0f, 1.0f,
        187.0f / 255.0f, 194 / 255.0f, 200.0 / 255.0f, 1.0f };
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgbColorSpace, colorRefs, locationRefs, 2);   
    CGColorSpaceRelease(rgbColorSpace);
    UIGraphicsBeginImageContext(CGSizeMake(1, height + 1));
    CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, height + 1), 0);
    CGGradientRelease(gradient);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:gradientImage];
}

- (NSInteger)currentSelectedFontRowIndex
{
    NSString *currentFont = [self.delegate currentFontName];
    NSString *fontDisplayName = [self.delegate fontNameToFontDisplayName:currentFont];    
    return [self.delegate.fontDisplayNames indexOfObject:fontDisplayName];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return self.delegate.fontDisplayNames.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) {
        return self.justificationSegment.frame.size.height + 16;
    } else {
        return self.justificationSegment.frame.size.height + 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isOriginal = NO;
    
    NSString *fontDisplayName = [self.delegate.fontDisplayNames objectAtIndex:indexPath.row];
    NSString *fontUseName = [self.delegate fontDisplayNameToFontName:fontDisplayName];
    if([fontUseName isEqualToString:kBlioOriginalFontName]) {
        fontUseName = [[UIFont systemFontOfSize:0] familyName];
        isOriginal = YES;
    }

    BOOL isSelected = indexPath.row == [self currentSelectedFontRowIndex];
    
    NSString *cellIdentifier;
    if(isOriginal) {
        cellIdentifier = @"original";
    } else {
        cellIdentifier = @"defined";
    }
    if(isSelected) {
        cellIdentifier = [cellIdentifier stringByAppendingString:@"-selected"];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell) {
        if(isOriginal) {
            cell = [[[BlioCenterableTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
            cell.detailTextLabel.text = NSLocalizedString(@"Use fonts specified by the book\u2019s publisher.", @"Explanation for 'original' font selection");
            cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        } else {        
            cell = [[[BlioCenterableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        }
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        
        if(isSelected) {
            UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
            backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
            backgroundView.backgroundColor = [self selectedCellBackgroundColorWithHeight:height];
            cell.backgroundView = backgroundView;
            [backgroundView release];
            
            cell.accessibilityTraits |= UIAccessibilityTraitSelected;
        }
    }
            
    cell.textLabel.text = fontDisplayName;
    cell.textLabel.font = [UIFont fontWithName:fontUseName size:isOriginal ? 18 : 24];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate changeFontName:[self.delegate fontDisplayNameToFontName:[self.delegate.fontDisplayNames objectAtIndex:indexPath.row]]];
    [tableView reloadData];
}

@end
