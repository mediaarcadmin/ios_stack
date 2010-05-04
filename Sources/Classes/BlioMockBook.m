//
//  MockBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioMockBook.h"
#import "BlioTextFlowParagraphSource.h"
#import "BlioEPubParagraphSource.h"
#import <libEucalyptus/EucBUpeBook.h>

@interface BlioMockBook ()
@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, retain) EucBUpeBook *ePubBook;
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@end

@implementation BlioMockBook

@dynamic title;
@dynamic author;
@dynamic coverFilename;
@dynamic epubFilename;
@dynamic pdfFilename;
@dynamic progress;
@dynamic processingState;
@dynamic libraryPosition;
@dynamic hasAudioRights;
@dynamic audiobookFilename;
@dynamic timingIndicesFilename;
@dynamic textFlowFilename;
@dynamic sourceID;
@dynamic sourceSpecificID;
@dynamic placeInBook;
@dynamic xpsFilename;


// Lazily instantiated - see getters below.
@synthesize textFlow;
@synthesize ePubBook;
@synthesize paragraphSource;

- (void)dealloc {

    [textFlow release];
	[ePubBook release];
    [paragraphSource release];
    
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

- (NSString *)textFlowPath {
    NSString *filename = [self valueForKey:@"textFlowFilename"];
    if (filename) {
        NSString *path = [[self.bookCacheDirectory stringByAppendingPathComponent:@"TextFlow"] stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    return nil;
}

- (NSString *)xpsPath {
    NSString *filename = [self valueForKey:@"xpsFilename"];
    if (filename) {
        NSString *path = [self.bookCacheDirectory stringByAppendingPathComponent:filename];
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
        NSSet *pageRanges = [self valueForKey:@"textFlowPageRanges"];
        if (pageRanges) { 
            BlioTextFlow *myTextFlow = [[BlioTextFlow alloc] initWithPageRanges:pageRanges basePath:[[self bookCacheDirectory] stringByAppendingPathComponent:@"TextFlow"]];
            self.textFlow = myTextFlow;
            [myTextFlow release];
        }
    }
    
    return textFlow;
}

- (EucBUpeBook *)ePubBook {
    if (nil == ePubBook) {
        NSString *ePubPath = self.ePubPath;
        if (ePubPath) {
            EucBUpeBook *myEPubBook = [[EucBUpeBook alloc] initWithPath:[self ePubPath]];
            [myEPubBook setPersistsPositionAutomatically:NO];
            [myEPubBook setCacheDirectoryPath:[self.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusCache"]];
            self.ePubBook = myEPubBook;
            [myEPubBook release];
        }
    }
    return ePubBook;    
}

- (id<BlioParagraphSource>)paragraphSource {
    if (nil == paragraphSource) {
        BlioTextFlow *myTextFlow = self.textFlow;
        id<BlioParagraphSource> myParagraphSource = nil;
        if (myTextFlow) {
            myParagraphSource = [[BlioTextFlowParagraphSource alloc] initWithTextFlow:myTextFlow];
        } else {
            EucBUpeBook *myEPubBook = self.ePubBook;
            if(myEPubBook) {
                myParagraphSource = [[BlioEPubParagraphSource alloc] initWitBUpeBook:myEPubBook];
            }
        }
        if(myParagraphSource) {
            self.paragraphSource = myParagraphSource;
            [myParagraphSource release];
        }
    }
    return paragraphSource;
}

- (void)flushCaches
{
    self.textFlow = nil;
    self.ePubBook = nil;
    self.paragraphSource = nil;
}

- (NSArray *)sortedBookmarks {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.blockOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.elementOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    return [[[self valueForKey:@"bookmarks"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedNotes {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.blockOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.elementOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    return [[[self valueForKey:@"notes"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedHighlights {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.blockOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.elementOffset" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, sortWordDescriptor, sortHyphenDescriptor, nil];
    
    return [[[self valueForKey:@"highlights"] allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage {
    NSManagedObjectContext *moc = nil;
    
    if ([NSThread isMainThread]) {
        moc = [self managedObjectContext]; 
    } else {
        moc = [[[NSManagedObjectContext alloc] init] autorelease]; 
        [moc setPersistentStoreCoordinator:[[self managedObjectContext] persistentStoreCoordinator]];
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioHighlight" inManagedObjectContext:moc]];
    
    NSNumber *minPageLayout = [NSNumber numberWithInteger:layoutPage];    
    NSNumber *maxPageLayout = [NSNumber numberWithInteger:layoutPage];
        
    NSPredicate *belongsToBook =                  [NSPredicate predicateWithFormat:@"(book == %@)", self]; 
    NSPredicate *doesNotEndBeforeStartPage =      [NSPredicate predicateWithFormat:@"NOT  (range.endPoint.layoutPage < %@)", minPageLayout];                                 
    NSPredicate *doesNotStartAfterEndPage =       [NSPredicate predicateWithFormat:@"NOT  (range.startPoint.layoutPage > %@)", maxPageLayout];                                 
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                                                                                 belongsToBook,
                                                                                 doesNotEndBeforeStartPage, 
                                                                                 doesNotStartAfterEndPage,
                                                                                 nil]];
    
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.blockOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.elementOffset" ascending:YES] autorelease];
    
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
    NSManagedObjectContext *moc = nil;
    
    if ([NSThread isMainThread]) {
        moc = [self managedObjectContext]; 
    } else {
        moc = [[[NSManagedObjectContext alloc] init] autorelease]; 
        [moc setPersistentStoreCoordinator:[[self managedObjectContext] persistentStoreCoordinator]];
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioHighlight" inManagedObjectContext:moc]];
    
    NSNumber *minPageLayout = [NSNumber numberWithInteger:range.startPoint.layoutPage];
    NSNumber *minBlockOffset = [NSNumber numberWithInteger:range.startPoint.blockOffset];
    NSNumber *minWordOffset = [NSNumber numberWithInteger:range.startPoint.wordOffset];

    NSNumber *maxPageLayout = [NSNumber numberWithInteger:range.endPoint.layoutPage];
    NSNumber *maxBlockOffset = [NSNumber numberWithInteger:range.endPoint.blockOffset];
    NSNumber *maxWordOffset = [NSNumber numberWithInteger:range.endPoint.wordOffset];
    
    NSPredicate *belongsToBook =                  [NSPredicate predicateWithFormat:@"(book == %@)", self]; 
    NSPredicate *doesNotEndBeforeStartPage =      [NSPredicate predicateWithFormat:@"NOT  (range.endPoint.layoutPage < %@)", minPageLayout];                                 
    NSPredicate *doesNotEndBeforeStartBlock = [NSPredicate predicateWithFormat:@"NOT ((range.endPoint.layoutPage == %@) && (range.endPoint.blockOffset < %@))", minPageLayout, minBlockOffset]; 
    NSPredicate *doesNotEndBeforeStartWord =      [NSPredicate predicateWithFormat:@"NOT ((range.endPoint.layoutPage == %@) && (range.endPoint.blockOffset == %@) && (range.endPoint.wordOffset < %@))", minPageLayout, minBlockOffset, minWordOffset]; 
    NSPredicate *doesNotStartAfterEndPage =       [NSPredicate predicateWithFormat:@"NOT  (range.startPoint.layoutPage > %@)", maxPageLayout];                                 
    NSPredicate *doesNotStartAfterEndBlock =  [NSPredicate predicateWithFormat:@"NOT ((range.startPoint.layoutPage == %@) && (range.startPoint.blockOffset > %@))", maxPageLayout, maxBlockOffset]; 
    NSPredicate *doesNotStartAfterEndWord =       [NSPredicate predicateWithFormat:@"NOT ((range.startPoint.layoutPage == %@) && (range.startPoint.blockOffset == %@) && (range.startPoint.wordOffset > %@))", maxPageLayout, maxBlockOffset, maxWordOffset]; 
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                               belongsToBook,
                               doesNotEndBeforeStartPage, 
                               doesNotEndBeforeStartBlock,
                               doesNotEndBeforeStartWord,
                               doesNotStartAfterEndPage,
                               doesNotStartAfterEndBlock,
                               doesNotStartAfterEndWord,
                               nil]];
    
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.blockOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortWordDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.wordOffset" ascending:YES] autorelease];
    NSSortDescriptor *sortHyphenDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"range.startPoint.elementOffset" ascending:YES] autorelease];

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
        
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(book == %@) AND (range.startPoint.layoutPage == %@) AND (range.startPoint.blockOffset == %@) AND (range.startPoint.wordOffset == %@) AND (range.startPoint.elementOffset == %@) AND (range.endPoint.layoutPage == %@) AND (range.endPoint.blockOffset == %@) AND (range.endPoint.wordOffset == %@) AND (range.endPoint.elementOffset == %@)",
                              self,
                              [NSNumber numberWithInteger:range.startPoint.layoutPage],
                              [NSNumber numberWithInteger:range.startPoint.blockOffset],
                              [NSNumber numberWithInteger:range.startPoint.wordOffset],
                              [NSNumber numberWithInteger:range.startPoint.elementOffset],
                              [NSNumber numberWithInteger:range.endPoint.layoutPage],
                              [NSNumber numberWithInteger:range.endPoint.blockOffset],
                              [NSNumber numberWithInteger:range.endPoint.wordOffset],
                              [NSNumber numberWithInteger:range.endPoint.elementOffset]
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
- (NSString *)bookTempDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *bookPath = [docsPath stringByAppendingPathComponent:[self valueForKey:@"uuid"]];
    return bookPath;
}

- (BlioBookmarkPoint *)implicitBookmarkPoint
{
    BlioBookmarkPoint *ret;
    
    NSManagedObject *placeInBook = [self valueForKey:@"placeInBook"];
    if(placeInBook) {
        ret = [BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[[placeInBook valueForKey:@"range"] valueForKey:@"startPoint"]];
    } else {
        ret = [[[BlioBookmarkPoint alloc] init] autorelease];
        ret.layoutPage = 1;
    }
    return ret;
}

- (void)setImplicitBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    NSManagedObject *placeInBook = [self valueForKey:@"placeInBook"];
    if(placeInBook) {
        NSManagedObject *persistentBookmarkRange = [placeInBook valueForKey:@"range"];
        
        NSNumber *layoutPageNumber = [NSNumber numberWithInteger:bookmarkPoint.layoutPage];
        NSNumber *layoutBlockOffset = [NSNumber numberWithInteger:bookmarkPoint.blockOffset];
        NSNumber *layoutWordOffset = [NSNumber numberWithInteger:bookmarkPoint.wordOffset];
        NSNumber *layoutElementOffset = [NSNumber numberWithInteger:bookmarkPoint.elementOffset];   
        
        NSManagedObject *bookmarkStartPoint = [persistentBookmarkRange valueForKey:@"startPoint"];
        [bookmarkStartPoint setValue:layoutPageNumber forKey:@"layoutPage"];
        [bookmarkStartPoint setValue:layoutBlockOffset forKey:@"blockOffset"];
        [bookmarkStartPoint setValue:layoutWordOffset forKey:@"wordOffset"];
        [bookmarkStartPoint setValue:layoutElementOffset forKey:@"elementOffset"];
        
        NSManagedObject *bookmarkEndPoint = [persistentBookmarkRange valueForKey:@"endPoint"];
        [bookmarkEndPoint setValue:layoutPageNumber forKey:@"layoutPage"];
        [bookmarkEndPoint setValue:layoutBlockOffset forKey:@"blockOffset"];
        [bookmarkEndPoint setValue:layoutWordOffset forKey:@"wordOffset"];
        [bookmarkEndPoint setValue:layoutElementOffset forKey:@"elementOffset"];
    } else {
        placeInBook = [NSEntityDescription
                       insertNewObjectForEntityForName:@"BlioPlaceInBook"
                       inManagedObjectContext:[self managedObjectContext]];
        [self setValue:placeInBook forKey:@"placeInBook"];
        
        BlioBookmarkRange *bookmarkRange = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:bookmarkPoint];
        
        NSManagedObject *persistentBookmarkRange = [bookmarkRange persistentBookmarkRangeInContext:[self managedObjectContext]];
        [placeInBook setValue:persistentBookmarkRange forKey:@"range"];
    }     
}

#pragma mark -
#pragma mark BlioBookText

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    if (nil != self.textFlow) {
        return [self.textFlow wordStringsForBookmarkRange:range];
    }
    return nil;
}

@end


