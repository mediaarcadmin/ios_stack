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

@interface BlioSelectableBookView ()
@property (nonatomic, readonly) BOOL shouldPutDictionaryInRootMenu;
@end

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

- (BOOL)shouldPutDictionaryInRootMenu {
    if(NSClassFromString(@"UIReferenceLibraryViewController")) {
        if(self.bounds.size.width > 320) {
            return YES;
        }
    }
    return NO;
}

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

    return [NSArray arrayWithObjects:orangeItem, blueItem, redItem, greenItem, nil];
}

- (NSArray *)wordToolsMenuItems {    
    NSMutableArray *ret = [NSMutableArray array];

    // Put this in here even if it's also in the root menu, for consistency 
    // (i.e. we won't confuse and annoy people who muscle-memory tap 
    // "Reference")
    //if(!self.shouldPutDictionaryInRootMenu) {
        [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Dictionary", "\"Dictionary\" option in popup menu")
                                                    action:@selector(dictionary:)] autorelease]];
    //}
    
    //[ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Thesaurus", "\"Thesaurus\" option in popup menu")
    //                                            action:@selector(thesaurus:)] autorelease]];
    
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Encyclopedia", "\"Encyclopedia\" option in popup menu")
                                                action:@selector(encyclopedia:)] autorelease]];
        
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Search", "\"Search\" option in popup menu")
                                                action:@selector(search:)] autorelease]];
    
    return ret;
}
	
- (NSArray *)highlightMenuItemsIncludingTextCpyItem:(BOOL)copy {
    NSMutableArray *ret = [NSMutableArray array];
        
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", "\"Remove Highlight\" option in popup menu")
                                                action:@selector(removeHighlight:)] autorelease]];

    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu")                                                    
                                                action:@selector(addNote:)] autorelease]];
    
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Color", "\"Color\" option in popup menu")
                                                action:@selector(showColorMenu:)] autorelease]];

    if(copy) {
        [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu")
                                                    action:@selector(copy:)] autorelease]];
    }
    
    if(self.shouldPutDictionaryInRootMenu) {
        [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Dictionary", "\"Dictionary\" option in popup menu")
                                                    action:@selector(dictionary:)] autorelease]];
    }

    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Reference", "\"Reference\" option in popup menu")
                                                action:@selector(showWordTools:)] autorelease]];
    
    return ret;
}

- (NSArray *)rootMenuItemsIncludingTextCpyItem:(BOOL)copy {
    NSMutableArray *ret = [NSMutableArray array];
    
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Highlight", "\"Highlight\" option in popup menu")                                                              
                                                action:@selector(highlight:)] autorelease]];
    
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu")                                                    
                                                action:@selector(addNote:)] autorelease]];
    
    if(copy) {
        [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu")
                                                    action:@selector(copy:)] autorelease]];
    }
    
    if(self.shouldPutDictionaryInRootMenu) {
        [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Dictionary", "\"Dictionary\" option in popup menu")
                                                                                action:@selector(dictionary:)] autorelease]];
    }
    
    [ret addObject:[[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Reference", "\"Reference\" option in popup menu")
                                                action:@selector(showWordTools:)] autorelease]];

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
    if (![lastHighlightColor isEqual:color] && ![color isEqual:[UIColor yellowColor]]) {
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
            [self.delegate updateHighlightNoteAtRange:highlightRange toRange:self.selectedRange withColor:[UIColor yellowColor]]; 
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

- (void)showWordTools:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self wordToolsMenuItems]];
}


- (void)dictionary:(id)sender {
    BlioBookmarkRange *wordToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    [self.delegate openWordToolWithRange:wordToolRange atRect:self.selector.selectedRangeRect toolType:dictionaryTool];
    [self.selector setSelectedRange:nil];
}

/*
 - (void)thesaurus:(id)sender {
 BlioBookmarkRange *wordToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
 [self.delegate openWordToolWithRange:wordToolRange atRect:self.selector.selectedRangeRect toolType:thesaurusTool];
 [self.selector setSelectedRange:nil];
 }
 */

- (void)encyclopedia:(id)sender {
    BlioBookmarkRange *wordToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    [self.delegate openWordToolWithRange:wordToolRange atRect:self.selector.selectedRangeRect toolType:encyclopediaTool];
    [self.selector setSelectedRange:nil];
}

- (void)search:(id)sender {
    BlioBookmarkRange *wordToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    [self.delegate openWordToolWithRange:wordToolRange atRect:self.selector.selectedRangeRect toolType:searchTool];
    [self.selector setSelectedRange:nil];
}

#pragma mark -
#pragma mark Override Points.

- (EucSelector *)selector { return nil; }

- (void)refreshHighlights {}
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range { return nil; }
- (BlioBookmarkRange *)selectedRange { return nil; }

@end
