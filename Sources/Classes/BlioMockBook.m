//
//  MockBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioMockBook.h"

@implementation BlioMockBook

@dynamic title;
@dynamic author;
@dynamic coverFilename;
@dynamic epubFilename;
@dynamic pdfFilename;
@dynamic progress;
@dynamic proportionateSize;
@dynamic position;
@dynamic layoutPageNumber;
@dynamic hasAudioRights;
@dynamic audiobookFilename;
@dynamic timingIndicesFilename;
@dynamic textflowFilename;

- (void)dealloc {
    if (coverThumb) [coverThumb release];
    if (textFlow) [textFlow release];
    [super dealloc];
}

- (NSString *)coverPath {
    NSString *filename = [self valueForKey:@"coverFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)thumbForGridPath {
    NSString *filename = [self valueForKey:@"gridThumbFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)thumbForListPath {
    NSString *filename = [self valueForKey:@"listThumbFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)ePubPath {
    NSString *filename = [self valueForKey:@"epubFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)pdfPath {
    NSString *filename = [self valueForKey:@"pdfFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
        
    return nil;
}

- (NSString *)audiobookPath {
    NSString *filename = [self valueForKey:@"audiobookFilename"];
    if (filename) {
        NSString *path = [[self.bookCacheDirectory stringByAppendingPathComponent:@"Audiobook"] stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)timingIndicesPath {
    NSString *filename = [self valueForKey:@"timingIndicesFilename"];
    if (filename) {
        NSString *path = [[self.bookCacheDirectory stringByAppendingPathComponent:@"Audiobook"] stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (BOOL)audioRights {
    return [[self valueForKey:@"hasAudioRights"] boolValue];
}

- (NSString *)textflowPath {
    NSString *filename = [self valueForKey:@"textflowFilename"];
    if (filename) {
        NSString *path = [[self.bookCacheDirectory stringByAppendingPathComponent:@"TextFlow"] stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (UIImage *)coverImage {
    NSString *path = [self coverPath];
    NSData *imageData = [NSData dataWithContentsOfMappedFile:path];
    return [UIImage imageWithData:imageData];
}

- (UIImage *)coverThumbForGrid {
    NSString *path = [self thumbForGridPath];
    NSData *imageData = [NSData dataWithContentsOfMappedFile:path];
    return [UIImage imageWithData:imageData];
}

- (UIImage *)coverThumbForList {
    NSString *path = [self thumbForListPath];
    NSData *imageData = [NSData dataWithContentsOfMappedFile:path];
    return [UIImage imageWithData:imageData];
}

- (BlioTextFlow *)textFlow {
    if (nil == textFlow) {
        textFlow = [[BlioTextFlow alloc] initWithPath:[self textflowPath]];
    }
    if (textFlow.ready)
        return textFlow;
    else
        return nil;
}

- (NSArray *)sortedBookmarks {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.paragraphOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.hyphenOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    return [[[self valueForKey:@"bookmarks"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedNotes {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.paragraphOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.hyphenOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    return [[[self valueForKey:@"notes"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedHighlights {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.paragraphOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.hyphenOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    
    return [[[self valueForKey:@"highlights"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage {
    NSManagedObjectContext *moc = [self managedObjectContext]; 
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioHighlight" inManagedObjectContext:moc]];
    
    NSNumber *minPageLayout = [NSNumber numberWithInteger:layoutPage];    
    NSNumber *maxPageLayout = [NSNumber numberWithInteger:layoutPage];
    
    NSPredicate *doesNotEndBeforeStartPage =      [NSPredicate predicateWithFormat:@"NOT  (range.endPoint.layoutPage < %@)", minPageLayout];                                 
    NSPredicate *doesNotStartAfterEndPage =       [NSPredicate predicateWithFormat:@"NOT  (range.startPoint.layoutPage > %@)", maxPageLayout];                                 
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                                                                                 doesNotEndBeforeStartPage, 
                                                                                 doesNotStartAfterEndPage,
                                                                                 nil]];
    
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.paragraphOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.hyphenOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil; 
    NSArray *results = [moc executeFetchRequest:request error:&error]; 
    [request release];
    
    if (error) {
        NSLog(@"Error whilst retrieving highlights for page. %@, %@", error, [error userInfo]); 
        return nil;
    }
    
    NSMutableArray *highlightRanges = [NSMutableArray array];
    
    for (NSManagedObject *highlight in results) {
        BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[highlight valueForKey:@"range"]];
        [highlightRanges addObject:range];
    }
    return highlightRanges;
    
}

- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range {
    NSManagedObjectContext *moc = [self managedObjectContext]; 
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioHighlight" inManagedObjectContext:moc]];
    
    NSNumber *minPageLayout = [NSNumber numberWithInteger:range.startPoint.layoutPage];
    NSNumber *minParagraphOffset = [NSNumber numberWithInteger:range.startPoint.paragraphOffset];
    NSNumber *minWordOffset = [NSNumber numberWithInteger:range.startPoint.wordOffset];

    NSNumber *maxPageLayout = [NSNumber numberWithInteger:range.endPoint.layoutPage];
    NSNumber *maxParagraphOffset = [NSNumber numberWithInteger:range.endPoint.paragraphOffset];
    NSNumber *maxWordOffset = [NSNumber numberWithInteger:range.endPoint.wordOffset];
    
    NSPredicate *doesNotEndBeforeStartPage =      [NSPredicate predicateWithFormat:@"NOT  (range.endPoint.layoutPage < %@)", minPageLayout];                                 
    NSPredicate *doesNotEndBeforeStartParagraph = [NSPredicate predicateWithFormat:@"NOT ((range.endPoint.layoutPage == %@) && (range.endPoint.paragraphOffset < %@))", minPageLayout, minParagraphOffset]; 
    NSPredicate *doesNotEndBeforeStartWord =      [NSPredicate predicateWithFormat:@"NOT ((range.endPoint.layoutPage == %@) && (range.endPoint.paragraphOffset == %@) && (range.endPoint.wordOffset < %@))", minPageLayout, minParagraphOffset, minWordOffset]; 
    NSPredicate *doesNotStartAfterEndPage =       [NSPredicate predicateWithFormat:@"NOT  (range.startPoint.layoutPage > %@)", maxPageLayout];                                 
    NSPredicate *doesNotStartAfterEndParagraph =  [NSPredicate predicateWithFormat:@"NOT ((range.startPoint.layoutPage == %@) && (range.startPoint.paragraphOffset > %@))", maxPageLayout, maxParagraphOffset]; 
    NSPredicate *doesNotStartAfterEndWord =       [NSPredicate predicateWithFormat:@"NOT ((range.startPoint.layoutPage == %@) && (range.startPoint.paragraphOffset == %@) && (range.startPoint.wordOffset > %@))", maxPageLayout, maxParagraphOffset, maxWordOffset]; 
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                               doesNotEndBeforeStartPage, 
                               doesNotEndBeforeStartParagraph,
                               doesNotEndBeforeStartWord,
                               doesNotStartAfterEndPage,
                               doesNotStartAfterEndParagraph,
                               doesNotStartAfterEndWord,
                               nil]];
    
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.paragraphOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.hyphenOffset" ascending:YES] autorelease];

    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil; 
    NSArray *results = [moc executeFetchRequest:request error:&error]; 
    [request release];
    
    if (error) {
        NSLog(@"Error whilst retrieving highlights for range. %@, %@", error, [error userInfo]); 
        return nil;
    }
    
    NSMutableArray *highlightRanges = [NSMutableArray array];
    
    for (NSManagedObject *highlight in results) {
        BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[highlight valueForKey:@"range"]];
        [highlightRanges addObject:range];
    }
    return highlightRanges;
}

- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range {
    NSManagedObjectContext *moc = [self managedObjectContext]; 
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioHighlight" inManagedObjectContext:moc]];
        
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(book == %@) AND (range.startPoint.layoutPage == %@) AND (range.startPoint.paragraphOffset == %@) AND (range.startPoint.wordOffset == %@) AND (range.startPoint.hyphenOffset == %@) AND (range.endPoint.layoutPage == %@) AND (range.endPoint.paragraphOffset == %@) AND (range.endPoint.wordOffset == %@) AND (range.endPoint.hyphenOffset == %@)",
                              self,
                              [NSNumber numberWithInteger:range.startPoint.layoutPage],
                              [NSNumber numberWithInteger:range.startPoint.paragraphOffset],
                              [NSNumber numberWithInteger:range.startPoint.wordOffset],
                              [NSNumber numberWithInteger:range.startPoint.hyphenOffset],
                              [NSNumber numberWithInteger:range.endPoint.layoutPage],
                              [NSNumber numberWithInteger:range.endPoint.paragraphOffset],
                              [NSNumber numberWithInteger:range.endPoint.wordOffset],
                              [NSNumber numberWithInteger:range.endPoint.hyphenOffset]
                              ];
        
    [request setPredicate:predicate];
    
    
    NSError *error = nil; 
    NSArray *results = [moc executeFetchRequest:request error:&error]; 
    [request release];
    
    if (error) {
        NSLog(@"Error whilst fetching highlight with range. %@, %@", error, [error userInfo]); 
        return nil;
    }
    
    if ([results count] == 1) {
        return [results objectAtIndex:0];
    } else if ([results count] > 1) {
        NSLog(@"Warning multiple highlights found with identical ranges. Only first returned.");
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSString *)bookCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *bookPath = [docsPath stringByAppendingPathComponent:[self valueForKey:@"uuid"]];
    return bookPath;
}
         
#pragma mark -
#pragma mark BlioBookText

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    if ((nil != self.textFlow) && ([self.textFlow isReady])) {
        return [self.textFlow wordStringsForBookmarkRange:range];
    }
    return nil;
}

@end


