//
//  BlioBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioXPSProvider.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/THStringRenderer.h>
#import <pthread.h>

@interface BlioBook (PRIVATE_DO_NOT_MAKE_PUBLIC)
- (NSString *)fullPathOfFileSystemItemAtPath:(NSString *)path;
- (NSString *)fullPathOfTextFlowItemAtPath:(NSString *)path;
- (NSData *)dataFromFileSystemAtPath:(NSString *)path;
- (NSData *)dataFromXPSAtPath:(NSString *)path;
- (NSData *)dataFromTextFlowAtPath:(NSString *)path;
- (BOOL)componentExistsInXPSAtPath:(NSString *)path;

@end

@implementation BlioBook

// Dynamic properties (map to core data attributes)
@dynamic title;
@dynamic author;
@dynamic progress;
@dynamic processingState;
@dynamic sourceID;
@dynamic sourceSpecificID;
@dynamic layoutPageEquivalentCount;
@dynamic libraryPosition;
@dynamic hasAudiobookRights;
@dynamic reflowRight;
@dynamic audiobookFilename;
@dynamic timingIndicesFilename;

- (void)dealloc {    
    [self flushCaches];

    [super dealloc];
}

#pragma mark -
#pragma mark Convenience accessors

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

- (BlioTextFlow *)textFlow {
    if(!textFlow) {
        textFlow = [[[BlioBookManager sharedBookManager] checkOutTextFlowForBookWithID:self.objectID] retain];
    }
    return textFlow;
}

- (BlioXPSProvider *)xpsProvider {
    if(!xpsProvider) {
        xpsProvider = [[[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:self.objectID] retain];
    }
    return xpsProvider;
}

- (id<BlioParagraphSource>)paragraphSource {
    if(!paragraphSource) {
        paragraphSource = [[[BlioBookManager sharedBookManager] checkOutParagraphSourceForBookWithID:self.objectID] retain];
    }
    return paragraphSource;
}

- (void)flushCaches
{
    BlioBookManager *manager = [BlioBookManager sharedBookManager];
    if(textFlow) {
        [textFlow release];
        textFlow = nil;
        [manager checkInTextFlowForBookWithID:self.objectID];
    }
    if(paragraphSource) {
        [paragraphSource release];
        paragraphSource = nil;
        [manager checkInParagraphSourceForBookWithID:self.objectID];
    }
    if(xpsProvider) {
        [xpsProvider release];
        xpsProvider = nil;
        [manager checkInXPSProviderForBookWithID:self.objectID];
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
    return [[self valueForKey:@"hasAudiobookRights"] boolValue];
}
- (BOOL)reflowEnabled {
    return [[self valueForKey:@"reflowRight"] boolValue];
}

- (NSString *)ePubPath {
    return [self manifestPathForKey:@"epubFilename"];
}

- (NSString *)pdfPath {        
    return [self manifestPathForKey:@"pdfFilename"];
}

- (NSString *)xpsPath {
    return [self manifestPathForKey:@"xpsFilename"];
}

- (BOOL)hasEPub {
    return [self hasManifestValueForKey:@"epubFilename"];
}

- (BOOL)hasPdf {
    return [self hasManifestValueForKey:@"pdfFilename"];
}

- (BOOL)hasXps {
    return [self hasManifestValueForKey:@"xpsFilename"];
}

- (BOOL)hasTextFlow {
    return [self hasManifestValueForKey:@"textFlowFilename"];
}

- (BOOL)isEncrypted {
    return [self hasManifestValueForKey:@"drmHeaderFilename"];
}

- (UIImage *)missingCoverImageOfSize:(CGSize)size withPointSize:(CGFloat)pointSize {
    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIImage *missingCover = [UIImage imageNamed:@"booktexture-nocover.png"];
    [missingCover drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    NSString *titleString = [self title];
    NSUInteger maxTitleLength = 100;
    if ([titleString length] > maxTitleLength) {
        titleString = [NSString stringWithFormat:@"%@...", [titleString substringToIndex:maxTitleLength]];
    }
    
    THStringRenderer *renderer = [[THStringRenderer alloc] initWithFontName:@"Georgia"];

    UIEdgeInsets titleInsets = UIEdgeInsetsMake(size.height * 0.2f, size.width * 0.2f, size.height * 0.2f, size.width * 0.1f);
    CGRect titleRect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height), titleInsets);
    
    BOOL fits = NO;
    
    NSUInteger flags = THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter | THStringRendererFlagNoHinting;
    
    while (!fits && pointSize >= 2) {
        CGSize size = [renderer sizeForString:titleString pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
        if ((size.height <= titleRect.size.height) && (size.width <= titleRect.size.width)) {
            fits = YES;
        } else {
            pointSize -= 0.1f;
        }
    }
    
    CGContextClipToRect(ctx, titleRect); // if title won't fit at 2 points it gets clipped
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -MAX(size.height * 0.0005f, 0.5f)), MAX(size.height * 0.0005f, 0.5f), [UIColor blackColor].CGColor);
    CGContextSetRGBFillColor(ctx, 0.9f, 0.9f, 0.9f, 1);
    //[titleString drawInRect:titleRect withFont:[UIFont fontWithName:@"Georgia" size:titleRect.size.height * 0.15f] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
    [renderer drawString:titleString inContext:ctx atPoint:titleRect.origin pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
    [renderer release];
    
    UIImage *aCoverImage = UIGraphicsGetImageFromCurrentImageContext();
    
    return aCoverImage;
}

- (UIImage *)coverImage {
    NSData *imageData = [self manifestDataForKey:@"coverFilename"];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        return aCoverImage;
    } else {
        return [self missingCoverImageOfSize:CGSizeMake(kBlioMissingCoverWidth, kBlioMissingCoverHeight) withPointSize:kBlioMissingCoverFullPointSize];
    }
}

- (UIImage *)coverThumbForGrid {
    NSData *imageData = [self manifestDataForKey:@"gridThumbFilename"];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        return aCoverImage;
    } else {
        return [self missingCoverImageOfSize:CGSizeMake(kBlioCoverGridThumbWidth, kBlioCoverGridThumbHeight) withPointSize:kBlioMissingCoverGridPointSize];
    }
    return [UIImage imageWithData:imageData];
}

- (UIImage *)coverThumbForList {
    NSData *imageData = [self manifestDataForKey:@"listThumbFilename"];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        return aCoverImage;
    } else {
        return [self missingCoverImageOfSize:CGSizeMake(kBlioCoverListThumbWidth, kBlioCoverListThumbHeight) withPointSize:kBlioMissingCoverListPointSize];
    }
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

static NSPredicate *sSortedHighlightRangePredicate = nil;
pthread_once_t sSortedHighlightRangePredicateOnceControl = PTHREAD_ONCE_INIT;
static void sortedHighlightRangePredicateInit() {
    sSortedHighlightRangePredicate = [[NSPredicate predicateWithFormat:
          @"book == $BOOK AND "
          @"NOT ( range.startPoint.layoutPage > $MAX_LAYOUT_PAGE ) && "
          @"NOT ( range.endPoint.layoutPage < $MIN_LAYOUT_PAGE ) && "
          @"NOT ( range.startPoint.layoutPage == $MAX_LAYOUT_PAGE && range.startPoint.blockOffset > $MAX_BLOCK_OFFSET ) && "
          @"NOT ( range.endPoint.layoutPage == $MIN_LAYOUT_PAGE && range.endPoint.blockOffset < $MIN_BLOCK_OFFSET) && "
          @"NOT ( range.startPoint.layoutPage == $MAX_LAYOUT_PAGE && range.startPoint.blockOffset == $MAX_BLOCK_OFFSET && range.startPoint.wordOffset > $MAX_WORD_OFFSET ) && "
          @"NOT ( range.endPoint.layoutPage == $MIN_LAYOUT_PAGE && range.endPoint.blockOffset == $MIN_BLOCK_OFFSET && range.endPoint.wordOffset < $MIN_WORD_OFFSET )"
    ] retain];
}

- (NSPredicate *)sortedHighlightRangePredicate {
    pthread_once(&sSortedHighlightRangePredicateOnceControl, sortedHighlightRangePredicateInit);
    return sSortedHighlightRangePredicate;
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
    
    NSNumber *minLayoutPage = [NSNumber numberWithInteger:range.startPoint.layoutPage];
    NSNumber *minBlockOffset = [NSNumber numberWithInteger:range.startPoint.blockOffset];
    NSNumber *minWordOffset = [NSNumber numberWithInteger:range.startPoint.wordOffset];

    NSNumber *maxLayoutPage = [NSNumber numberWithInteger:range.endPoint.layoutPage];
    NSNumber *maxBlockOffset = [NSNumber numberWithInteger:range.endPoint.blockOffset];
    NSNumber *maxWordOffset = [NSNumber numberWithInteger:range.endPoint.wordOffset];
    
    NSDictionary *substitutionVariables = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           self, @"BOOK",
                                           minLayoutPage, @"MIN_LAYOUT_PAGE",
                                           minBlockOffset, @"MIN_BLOCK_OFFSET",
                                           minWordOffset, @"MIN_WORD_OFFSET",
                                           maxLayoutPage, @"MAX_LAYOUT_PAGE",
                                           maxBlockOffset, @"MAX_BLOCK_OFFSET",
                                           maxWordOffset, @"MAX_WORD_OFFSET",
                                           nil];
                                           
    NSPredicate *predicate = [[self sortedHighlightRangePredicate] predicateWithSubstitutionVariables:substitutionVariables];
    
    [substitutionVariables release];
                              
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

- (BOOL)componentExistsInXPSAtPath:(NSString *)path {
    // If the path is the drm header then flush the caches to refresh the xpsProvider
    BOOL exists = [[self xpsProvider] componentExistsAtPath:path];
    if ([path isEqualToString:BlioXPSKNFBDRMHeaderFile]) {
        [self flushCaches];
    }
    return exists;
}

- (BOOL)manifestPath:(NSString *)path existsForLocation:(NSString *)location {
    BOOL exists = NO;
    NSString *filePath;
    
    if (location && path) {
        if ([location isEqualToString:BlioManifestEntryLocationTextflow]) {
            NSString *textFlowLocation = [self manifestLocationForKey:@"textFlowFilename"];
            if ([textFlowLocation isEqualToString:BlioManifestEntryLocationXPS]) {
                filePath = [BlioXPSEncryptedTextFlowDir stringByAppendingPathComponent:path];
                exists = [self componentExistsInXPSAtPath:filePath];
            } else if ([textFlowLocation isEqualToString:BlioManifestEntryLocationTextflow]) {
                filePath = [self fullPathOfTextFlowItemAtPath:path];
                exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            }
        } else if ([location isEqualToString:BlioManifestEntryLocationBundle]) {
            filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:path];
            exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        } else if ([location isEqualToString:BlioManifestEntryLocationFileSystem]) {
            filePath = [self fullPathOfFileSystemItemAtPath:path];
            exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        } else if ([location isEqualToString:BlioManifestEntryLocationXPS]) {
            exists = [self componentExistsInXPSAtPath:path];
        }
    }
    
    return exists;
}

- (void)setManifestValue:(id)value forKey:(NSString *)key {
    NSMutableDictionary *manifest = nil;
    NSDictionary *currentManifest = [self valueForKey:@"manifest"];
    if (currentManifest) {
        manifest = [NSMutableDictionary dictionaryWithDictionary:currentManifest];
    } else {
        manifest = [NSMutableDictionary dictionary];
    }
    
    [manifest setValue:value forKey:key];
    [self setValue:manifest forKeyPath:@"manifest"];
    
    NSError *anError;
    if (![self.managedObjectContext save:&anError]) {
        NSLog(@"setManifestValue:%@ forKey:%@] Save failed with error: %@, %@", value, key, anError, [anError userInfo]);
    }
}

- (NSString *)fullPathOfFileSystemItemAtPath:(NSString *)path {
    return [self.bookCacheDirectory stringByAppendingPathComponent:path];
}

- (NSString *)fullPathOfTextFlowItemAtPath:(NSString *)path {
    return [[self.bookCacheDirectory stringByAppendingPathComponent:@"TextFlow"] stringByAppendingPathComponent:path];
}

- (NSData *)dataFromFileSystemAtPath:(NSString *)path {
    NSData *data = nil;
    NSString *filePath = [self fullPathOfFileSystemItemAtPath:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) 
        NSLog(@"Error whilst retrieving data from the filesystem. No file exists at path %@", path);
    else
        data = [NSData dataWithContentsOfMappedFile:filePath];
    
    return data;
}

- (NSData *)dataFromXPSAtPath:(NSString *)path {
    return [[self xpsProvider] dataForComponentAtPath:path];
}

- (NSData *)dataFromTextFlowAtPath:(NSString *)path {
    NSData *data = nil;
    NSString *textFlowLocation = [self manifestLocationForKey:@"textFlowFilename"];
    
    if ([textFlowLocation isEqualToString:BlioManifestEntryLocationXPS]) {
        data = [[self xpsProvider] dataForComponentAtPath:[BlioXPSEncryptedTextFlowDir stringByAppendingPathComponent:path]];
    } else if ([textFlowLocation isEqualToString:BlioManifestEntryLocationTextflow]) {
        NSString *filePath = [self fullPathOfTextFlowItemAtPath:path];
        if (filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSLog(@"Error whilst retrieving data from the filesystem. No file exists at path %@", filePath);
        } else {
            data = [NSData dataWithContentsOfMappedFile:filePath];
        }
    }
    
    return data;
}

- (BOOL)hasManifestValueForKey:(NSString *)key
{
    return [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]] != nil;
}

- (NSString *)manifestPathForKey:(NSString *)key {
    NSString *filePath = nil;
    
    NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        NSString *location = [manifestEntry objectForKey:@"location"];
        NSString *path = [manifestEntry objectForKey:@"path"];
        if (location && path) {
            // TODO: what if the textflow is in the XPS - this won't work? manifestPathForKey should have remained private
            if ([location isEqualToString:BlioManifestEntryLocationTextflow]) {
                filePath = [self fullPathOfTextFlowItemAtPath:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationBundle]) {
				filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationFileSystem]) {
				filePath = [self fullPathOfFileSystemItemAtPath:path];
			} else if ([location isEqualToString:BlioManifestEntryLocationXPS]) {
                // There is no such thing as a full-path to an XPS item - must be accessed via a data accessor
                filePath = nil;
            } else {
                filePath = path;
            }
        }
    }
    
    return filePath;
}

- (NSString *)manifestLocationForKey:(NSString *)key {
    NSString *fileLocation = nil;
    
    NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        fileLocation = [manifestEntry objectForKey:@"location"];
    }
    return fileLocation;
}

- (NSData *)manifestDataForKey:(NSString *)key {
    NSData *data = nil;
    NSDictionary *manifestEntry = [[self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]] retain];
    if(manifestEntry) {
        NSString *location = [manifestEntry objectForKey:@"location"];
        NSString *path = [manifestEntry objectForKey:@"path"];
        if (location && path) {
            if ([location isEqualToString:BlioManifestEntryLocationFileSystem]) {
                data = [self dataFromFileSystemAtPath:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationXPS]) {
                data = [self dataFromXPSAtPath:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationTextflow]) {
                data = [self dataFromTextFlowAtPath:path];
            }
        }
    }
    [manifestEntry release];
    return data;
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

#pragma mark -
#pragma mark BlioBookText

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    if (nil != self.textFlow) {
        return [self.textFlow wordStringsForBookmarkRange:range];
    }
    return nil;
}

#pragma mark -
#pragma mark Author name conversion functions

- (NSString *)authorWithStandardFormat {
	return [BlioBook standardNameFromCanonicalName:self.author];
}

+(NSString*)standardNameFromCanonicalName:(NSString*)aName {
	if (!aName) return nil;
	//Find last comma in name string (assumes that there are no commas in correctly formatted first or middle names)
	NSRange lastCommaLocation = [aName rangeOfString:@", " options:NSBackwardsSearch];
	
	//Check to see if it is a single name like Plato
	if (lastCommaLocation.location == NSNotFound)
		return aName;
	
	//Get first and last Name strings and put them in the correct order
	return [NSString stringWithFormat:@"%@ %@",
			[aName substringFromIndex:lastCommaLocation.location+lastCommaLocation.length ],
			[aName substringToIndex:lastCommaLocation.location]];
	
}

+(NSString*)canonicalNameFromStandardName:(NSString*)aName {
	if (!aName) return nil;
	//list of common suffixes.  Add more here if special case arises.
	NSArray* suffixes = [NSArray arrayWithObjects:@"Jr.",@"Sr.",@"Jr",@"Sr",@"Esq.",@"Ph.D.",@"PhD",@"M.D.",@"MD",@"II",@"III",@"IV",@"V",nil];
	
	//split name string into pieces by spaces.  Array is mutable so it can be changed later in function
	NSMutableArray* namePieces = [[aName componentsSeparatedByString:@" "]mutableCopy];
	
	//Check Plato case: if single name, return single name unchanged
	if ([namePieces count] == 1)
		return aName;
	
	//lastNamePieces holds all the pieces in the last name (including suffixes)
	NSMutableArray* lastNamePieces = [NSMutableArray array];
	NSString* lastPiece;
	
	//remove the last object in the namePieces array and add to the lastNamePieces array while we have a suffix
	do {
		//get last piece and then remove it from the namePieces array
		lastPiece = [namePieces lastObject];
		[namePieces removeLastObject];
		
		//insert at beginning of lastNamePieces array to preserve order
		[lastNamePieces insertObject:lastPiece atIndex:0];
		//NOTE: if this comparison becomes more complicated than simply looking at a list of suffixes, you could use a regular expression to check each piece
	} while ([suffixes containsObject:lastPiece]);
	
	//flatten arrays into strings separated by original spaces and add in comma
	return [[lastNamePieces componentsJoinedByString:@" "] stringByAppendingFormat:@", %@",[namePieces componentsJoinedByString:@" "]];	
}


@end


