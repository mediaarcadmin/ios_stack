//
//  BlioViewSettingsFontAndSizeContentsView.m
//  BlioApp
//
//  Created by James Montgomerie on 21/11/2011.
//  Copyright (c) 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioViewSettings.h"
#import "BlioViewSettingsFontAndSizeContentsView.h"
#import "BlioCenterableTableViewCell.h"

#import "BlioUIImageAdditions.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

@interface BlioViewSettingsFontAndSizeContentsView ()

@property (nonatomic, assign) id<BlioViewSettingsDelegate> delegate;

@property (nonatomic, assign) BOOL refreshingSettings;

@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *justificationLabel;

@property (nonatomic, retain) BlioAccessibilitySegmentedControl *fontSizeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *justificationSegment;

@property (nonatomic, retain) UITableView *fontTableView;

@property (nonatomic, retain) NSArray *fontDisplayNames;
@property (nonatomic, retain) NSDictionary *fontDisplayNameToFontName;

@end


@implementation BlioViewSettingsFontAndSizeContentsView

@synthesize delegate;

@synthesize refreshingSettings;

@synthesize fontSizeLabel;
@synthesize justificationLabel;

@synthesize fontSizeSegment;
@synthesize justificationSegment;

@synthesize fontTableView;

@synthesize fontDisplayNames;
@synthesize fontDisplayNameToFontName;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
    
    self.fontSizeLabel = nil;
    self.justificationLabel = nil;
    
    self.fontSizeSegment = nil;
    self.justificationSegment = nil;
    
    self.fontTableView.delegate = nil;
    self.fontTableView.dataSource = nil;
    self.fontTableView = nil;
    
    fontDisplayNames = nil;
    fontDisplayNameToFontName = nil;

    [super dealloc];
}

- (void)refreshSettings {
    self.refreshingSettings = YES;
        
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
            case kBlioJustificationLeft:
                segmentToSelect = 0;
                break;
            default:
            case kBlioJustificationFull:
                segmentToSelect = 1;
                break;
            case kBlioJustificationOriginal:
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
    
	if ((self = [super initWithFrame:CGRectZero])) {
        self.delegate = newDelegate;
		
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
        
        UITableView *aFontsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        aFontsTableView.delegate = self;
        aFontsTableView.dataSource = self;
        [self addSubview:aFontsTableView];
        self.fontTableView = aFontsTableView;
        [aFontsTableView release];
        
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
        [justificationLabel release];
        
        NSArray *justificationTitles = [NSArray arrayWithObjects:
                                        NSLocalizedString(@"Left",@"\"Left\" segment label (for Reading Settings justification control)"),
                                        NSLocalizedString(@"Full",@"\"Full\" segment label (for Reading Settings justification control)"),
                                        NSLocalizedString(@"Original",@"\"Original\" segment label (for Reading Settings justification control)"),
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
    [self.fontTableView setFrame:CGRectMake(xInset, yInset, innerWidth, currentY - yInset)];
    
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
                newJustifiction = kBlioJustificationLeft;
                break;
            default:
            case 1:
                newJustifiction = kBlioJustificationFull;
                break;
            case 2:
                newJustifiction = kBlioJustificationOriginal;
                break;
        }
        [self.delegate changeJustification:newJustifiction];
    }
}

- (void)dismiss:(id)sender {
    [self.delegate dismissViewSettings:self];
}


#pragma mark -
#pragma mark Fonts Table 

- (void)prepareFontInformation {
    NSURL *fontInformationURL = [[NSBundle mainBundle] URLForResource:@"BlioFonts" withExtension:@"plist"];
    NSDictionary *fontInformation= [NSDictionary dictionaryWithContentsOfURL:fontInformationURL];
    self.fontDisplayNames = [fontInformation objectForKey:@"FontDisplayNames"];
    self.fontDisplayNameToFontName = [fontInformation objectForKey:@"FontDisplayNameToFontName"];
}

- (NSArray *)fontDisplayNames {
    if(!fontDisplayNames) {
        [self prepareFontInformation];
    }
    return fontDisplayNames;
}

- (NSDictionary *)fontDisplayNameToFontName {
    if(!fontDisplayNameToFontName) {
        [self prepareFontInformation];
    }
    return fontDisplayNameToFontName;
}

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
    
    NSString *fontDisplayName = [[self.fontDisplayNameToFontName keysOfEntriesPassingTest:
                                 ^(id key, id obj, BOOL *stop) {
                                     if([obj isEqual:currentFont]) {
                                         *stop = YES;
                                         return YES;
                                     }
                                     return NO;
                                 }] anyObject];
    
    return [self.fontDisplayNames indexOfObject:fontDisplayName];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return self.fontDisplayNames.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) {
        return self.justificationSegment.frame.size.height + 18;
    } else {
        return self.justificationSegment.frame.size.height + 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isOriginal = NO;
    
    NSString *fontDisplayName = [self.fontDisplayNames objectAtIndex:indexPath.row];
    NSString *fontUseName = [self.fontDisplayNameToFontName objectForKey:fontDisplayName];
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
            cell.detailTextLabel.text = NSLocalizedString(@"Use fonts specified by the book's publisher.", @"Explanation for 'original' font selection");
            cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
        } else {        
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        }
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        
        if(isSelected) {
            CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
            cell.backgroundColor = [self selectedCellBackgroundColorWithHeight:height];
        }
    }
            
    cell.textLabel.text = fontDisplayName;
    cell.textLabel.font = [UIFont fontWithName:fontUseName size:24];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate changeFontName:[self.fontDisplayNameToFontName objectForKey:[self.fontDisplayNames objectAtIndex:indexPath.row]]];
    [tableView reloadData];
}

@end
