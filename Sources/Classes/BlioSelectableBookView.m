//
//  BlioSelectableBookView.m
//  BlioApp
//
//  Created by James Montgomerie on 11/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioSelectableBookView.h"
#import "BlioBookView.h"
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/EucSelector.h>

static NSString * const kBlioLastHighlightColorKey = @"BlioLastHighlightColor";

@implementation BlioSelectableBookView

@synthesize delegate;

- (void)dealloc {   
    self.delegate = nil;
    
    // Don't just set this to nil, that will cause it to be nilled out in user
    // defaults too.
    [lastHighlightColor release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Selector Menu Setup. 

- (NSArray *)colorMenuItems {     
	
    EucMenuItem *orangeItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorOrange:)] autorelease];
    orangeItem.accessibilityLabel = NSLocalizedString(@"Orange", "Accessibility label for orange item in highlight color menu");
    orangeItem.color = [UIColor orangeColor]; 
    
    EucMenuItem *blueItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorBlue:)] autorelease];
    blueItem.accessibilityLabel = NSLocalizedString(@"Blue", "Accessibility label for yellow item in highlight color menu");
    blueItem.color = [UIColor blueColor];
    
    EucMenuItem *redItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorRed:)] autorelease];
    redItem.accessibilityLabel = NSLocalizedString(@"Red", "Accessibility label for yellow item in highlight color menu");
    redItem.color = [UIColor redColor];
    
    EucMenuItem *greenItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorGreen:)] autorelease];
    greenItem.accessibilityLabel = NSLocalizedString(@"Green", "Accessibility label for yellow item in highlight color menu");
    greenItem.color = [UIColor greenColor];
    
    NSArray *ret = [NSArray arrayWithObjects:orangeItem, blueItem, redItem, greenItem, nil];
    
    return ret;
}

- (NSArray *)webToolsMenuItems {    
    EucMenuItem *dictionaryItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Dictionary", "\"Dictionary\" option in popup menu")
                                                               action:@selector(dictionary:)] autorelease];
    
    //EucMenuItem *thesaurusItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Thesaurus", "\"Thesaurus\" option in popup menu")
    //                                                          action:@selector(thesaurus:)] autorelease];
    
    EucMenuItem *wikipediaItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Encyclopedia", "\"Encyclopedia\" option in popup menu")
                                                              action:@selector(encyclopedia:)] autorelease];
    
    EucMenuItem *searchItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Search", "\"Search\" option in popup menu")
                                                           action:@selector(search:)] autorelease];
    
    NSArray *ret = [NSArray arrayWithObjects:dictionaryItem/*, thesaurusItem*/, wikipediaItem, searchItem, nil];
    
    return ret;
}
	
- (NSArray *)highlightMenuItemsIncludingTextCpyItem:(BOOL)copy {
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu")                                                    
                                                            action:@selector(addNote:)] autorelease];

    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu")
                                                         action:@selector(copy:)] autorelease];
    
    EucMenuItem *colorItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Color", "\"Color\" option in popup menu")
                                                          action:@selector(showColorMenu:)] autorelease];
   
    EucMenuItem *showWebToolsItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Reference", "\"Reference\" option in popup menu")
                                                                 action:@selector(showWebTools:)] autorelease];

    EucMenuItem *removeItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", "\"Remove Highlight\" option in popup menu")
                                                           action:@selector(removeHighlight:)] autorelease];
    
    NSArray *ret;

	BOOL color = YES;
	if ([self.delegate respondsToSelector:@selector(hasNoteOverlappingSelectedRange)])  
		if ([self.delegate hasNoteOverlappingSelectedRange]) 
			color = NO;
	if (copy) {
		if (color)
			ret = [NSArray arrayWithObjects:removeItem, addNoteItem, copyItem, showWebToolsItem, colorItem, nil];
		else 
			ret = [NSArray arrayWithObjects:removeItem, addNoteItem, copyItem, showWebToolsItem, nil];
	}
    else {
		if (color)
			ret = [NSArray arrayWithObjects:removeItem, addNoteItem, showWebToolsItem, colorItem, nil];
		else
			ret = [NSArray arrayWithObjects:removeItem, addNoteItem, showWebToolsItem, nil];
	}
    
    return ret;
}

- (NSArray *)rootMenuItemsIncludingTextCpyItem:(BOOL)copy {
    EucMenuItem *highlightItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Highlight", "\"Highlight\" option in popup menu")                                                              
                                                              action:@selector(highlight:)] autorelease];
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu")                                                    
                                                            action:@selector(addNote:)] autorelease];
    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu")
                                                         action:@selector(copy:)] autorelease];
    EucMenuItem *showWebToolsItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Reference", "\"Reference\" option in popup menu")
                                                                 action:@selector(showWebTools:)] autorelease];
    
    NSArray *ret;
    if (copy)
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, copyItem, showWebToolsItem, nil];
    else
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, showWebToolsItem, nil];
    
    return ret;
}

- (NSArray *)menuItemsForEucSelector:(EucSelector *)selector {
    if ([selector selectedRangeIsHighlight]) {
        // Disallowing copy because of DRM.
		return [self highlightMenuItemsIncludingTextCpyItem:NO];
    } else {
        // Disallowing copy because of DRM.
		return [self rootMenuItemsIncludingTextCpyItem:NO];
    }
}


#pragma mark -
#pragma mark Selector Menu Responder Actions 

- (UIColor *)lastHighlightColor {
    if (nil == lastHighlightColor) {
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastHighlightColorKey];
        if (nil != colorData) {
            lastHighlightColor = [[NSKeyedUnarchiver unarchiveObjectWithData:colorData] retain];
        }
        if (nil == lastHighlightColor) {
			// Default highlight color.
			lastHighlightColor = [[UIColor orangeColor] retain];
        }
    }
    return lastHighlightColor;
}

- (void)setLastHighlightColor:(UIColor *)color {
    if (![lastHighlightColor isEqual:color]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:color] forKey:kBlioLastHighlightColorKey];
        [lastHighlightColor release];
        lastHighlightColor = [color retain];
    }
}

- (void)addHighlightWithColor:(UIColor *)color {
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
        
        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:color];
        
        // Deselect, this will fire the endEditing highlight callback which refreshes
        [self.selector setSelectedRange:nil];
        
    } else {
        
        if ([self.delegate respondsToSelector:@selector(addHighlightWithColor:)])
            [self.delegate addHighlightWithColor:color];
        
        // Set this to nil now because the refresh depends on it
        [self.selector setSelectedRange:nil];
        [self refreshHighlights];
    }
    
    self.lastHighlightColor = color;
}

- (void)highlightColorYellow:(id)sender {
    [self addHighlightWithColor:[UIColor yellowColor]];
}

- (void)highlightColorOrange:(id)sender {
    [self addHighlightWithColor:[UIColor orangeColor]];
}

- (void)highlightColorRed:(id)sender {
    [self addHighlightWithColor:[UIColor redColor]];
}

- (void)highlightColorBlue:(id)sender {
    [self addHighlightWithColor:[UIColor blueColor]];
}

- (void)highlightColorGreen:(id)sender {
    [self addHighlightWithColor:[UIColor greenColor]];
}

- (void)highlight:(id)sender {
    [self addHighlightWithColor:self.lastHighlightColor];
}

- (void)showColorMenu:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self colorMenuItems]];
}

- (void)removeHighlight:(id)sender {
    BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
    
    if ([self.delegate respondsToSelector:@selector(removeHighlightAtRange:)])
        [self.delegate removeHighlightAtRange:highlightRange];
    
    // Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)addNote:(id)sender {
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        if ([self.delegate respondsToSelector:@selector(updateHighlightNoteAtRange:toRange:withColor:)])
            [self.delegate updateHighlightNoteAtRange:highlightRange toRange:self.selectedRange withColor:nil]; 
    } else {
        if ([self.delegate respondsToSelector:@selector(addHighlightNoteWithColor:)])
            // Yellow is for notes.
			[self.delegate addHighlightNoteWithColor:[UIColor yellowColor]]; 
    }
    
    // TODO - this probably doesn't want to deselect yet in case the note is cancelled
    // Or the selection could be saved and reinstated
    // Or we could just not bother but it might be annoying
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)copy:(id)sender {    
    BlioBookmarkRange *copyRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(copyWithRange:)]) {
        [self.delegate copyWithRange:copyRange];
        
        if ([self.selector selectedRangeIsHighlight])
            [self.selector changeActiveMenuItemsTo:[self highlightMenuItemsIncludingTextCpyItem:NO]];
        else
            [self.selector changeActiveMenuItemsTo:[self rootMenuItemsIncludingTextCpyItem:NO]];
    }    
}

- (void)showWebTools:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self webToolsMenuItems]];
}


- (void)dictionary:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange  toolType:dictionaryTool];
        [self.selector setSelectedRange:nil];
    }
}

/*
 - (void)thesaurus:(id)sender {
 BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
 if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
 [self.delegate openWebToolWithRange:webToolRange toolType:thesaurusTool];
 
 [self.selector setSelectedRange:nil];
 }
 }
 */

- (void)encyclopedia:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange toolType:encyclopediaTool];
        [self.selector setSelectedRange:nil];
    }
}

- (void)search:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange toolType:searchTool];
        [self.selector setSelectedRange:nil];
    }
}

#pragma mark -
#pragma mark Override Points.

- (EucSelector *)selector { return nil; }

- (void)refreshHighlights {}
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range { return nil; }
- (BlioBookmarkRange *)selectedRange { return nil; }

@end
