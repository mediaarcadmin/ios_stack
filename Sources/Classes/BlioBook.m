//
//  BlioBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioParagraphSource.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/THStringRenderer.h>
#import <pthread.h>

@interface BlioBook (PRIVATE_DO_NOT_MAKE_PUBLIC)
- (NSString *)fullPathOfFileSystemItemAtPath:(NSString *)path;
- (NSString *)fullPathOfTextFlowItemAtPath:(NSString *)path;
- (NSData *)dataFromFileSystemAtPath:(NSString *)path;
- (NSData *)dataFromXPSAtPath:(NSString *)path;
- (NSData *)dataFromTextFlowAtPath:(NSString *)path;
- (BOOL)componentExistsInXPSAtPath:(NSString *)path;
- (BlioXPSProvider *)xpsProvider;

@end

@implementation BlioBook

// Dynamic properties (map to core data attributes)
@dynamic audiobook;
@dynamic author;
@dynamic expirationDate;
@dynamic layoutPageEquivalentCount;
@dynamic libraryPosition;
@dynamic progress;
@dynamic processingState;
@dynamic reflowRight;
@dynamic sourceID;
@dynamic sourceSpecificID;
@dynamic title;
@dynamic titleSortable;
@dynamic transactionType;
@dynamic ttsRight;
@dynamic ttsCapable;
@dynamic twoPageSpread;

- (void)dealloc {    
    [self flushCaches];

    [super dealloc];
}

#pragma mark -
#pragma mark Convenience accessors

- (BlioBookmarkPoint *)implicitBookmarkPoint
{
    BlioBookmarkPoint *ret = nil;
    
    NSManagedObject *placeInBook = [self valueForKey:@"placeInBook"];
    if(placeInBook) {
        ret = [BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[[placeInBook valueForKey:@"range"] valueForKey:@"startPoint"]];
    } 
    
    if(!ret || 
       ret.layoutPage == 0) {  // layoutPage should never be zero, but some old versions of the app did save it that way.
        ret = [[[BlioBookmarkPoint alloc] init] autorelease];
        ret.layoutPage = 1;
    }
    return ret;
}

- (void)setImplicitBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(bookmarkPoint.layoutPage == 0) {
        NSParameterAssert(bookmarkPoint.blockOffset == 0 && bookmarkPoint.wordOffset == 0 && bookmarkPoint.elementOffset == 0);
        // This is a result of saving a nil bookmark point.  Shouldn't really 
        // happen, but it's easy to guard against here anyway.
        bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
        bookmarkPoint.layoutPage = 1;
    }
    
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

- (void)flushCaches
{
    BlioBookManager *manager = [BlioBookManager sharedBookManager];
    if(textFlow) {
        [textFlow release];
        textFlow = nil;
        [manager checkInTextFlowForBookWithID:self.objectID];
    }
    if(xpsProvider) {
        [xpsProvider release];
        xpsProvider = nil;
        [manager checkInXPSProviderForBookWithID:self.objectID];
    }
}

- (void)reportReadingIfRequired {
    [[self xpsProvider] reportReadingIfRequired];
}

- (NSString *)bookCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
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

- (BOOL)hasAudiobook {
	return [[self valueForKey:@"audiobook"] boolValue];
//	return [self hasManifestValueForKey:BlioManifestAudiobookMetadataKey];
}
- (BOOL)hasTTSRights {
	//    return NO;//[[self valueForKey:@"hasTTSRightsNum"] boolValue];
    return [[self valueForKey:@"ttsRight"] boolValue];
}
- (BOOL)isTTSCapable {
    return [[self valueForKey:@"ttsCapable"] boolValue];
}
- (BOOL)reflowEnabled {
    return ([[self valueForKey:@"reflowRight"] boolValue] && 
            ([self hasEPub] || 
             ([self hasTextFlow] && 
              ([[self textFlow] flowTreeKind] == KNFBTextFlowFlowTreeKindXaml ||
               [[self textFlow] conversionQuality] == KNFBTextFlowConversionQualityHigh))));
}
- (BOOL)fixedViewEnabled {
	return ([self hasPdf] || ([self hasXps] && ![self hasEmbeddedEPub]));
}

- (BOOL)enforceTwoPageSpread {
    return [[self valueForKey:@"twoPageSpread"] boolValue];
}

- (NSString *)ePubPath {
    return [self manifestPathForKey:BlioManifestEPubKey];
}

- (NSString *)pdfPath {        
    return [self manifestPathForKey:BlioManifestPDFKey];
}

- (NSString *)xpsPath {
    return [self manifestPathForKey:BlioManifestXPSKey];
}

- (BOOL)hasEPub {
    return [self hasManifestValueForKey:BlioManifestEPubKey];
}
- (BOOL)hasEmbeddedEPub {
    return [self manifestPath:BlioXPSEPubMetaInfContainerFile existsForLocation:BlioManifestEntryLocationXPS];
}
- (BOOL)hasPdf {
    return [self hasManifestValueForKey:BlioManifestPDFKey];
}

- (BOOL)hasXps {
    return [self hasManifestValueForKey:BlioManifestXPSKey];
}
- (BOOL)hasCoverImage {
    // PDFs should always have a cover, if it's not currently set it should be re-generated
    return [self hasManifestValueForKey:BlioManifestCoverKey] || [self hasPdf];
}

- (BOOL)hasTextFlow {
    return [self hasManifestValueForKey:BlioManifestTextFlowKey];
}
- (BOOL)hasSearch {
    return ([self hasEPub] || ([self hasXps] && [self manifestPath:BlioXPSKNFBMetadataFile existsForLocation:BlioManifestEntryLocationXPS]));
}
- (BOOL)hasTOC {
    return ([self hasEPub] || [self hasPdf] || ([self hasXps] && [self manifestPath:BlioXPSKNFBMetadataFile existsForLocation:BlioManifestEntryLocationXPS]));
}

- (BOOL)isEncrypted {
    return [self hasManifestValueForKey:BlioManifestDrmHeaderKey];
}

- (BOOL)decryptionIsAvailable {
    return [[self xpsProvider] decryptionIsAvailable];
}

- (BOOL)checkBindToLicense {
    return [[self xpsProvider] checkBindToLicense];    
}

- (BOOL)firstLayoutPageOnLeft {
    return [self hasManifestValueForKey:BlioManifestFirstLayoutPageOnLeftKey];
}

- (UIImage *)missingCoverImageOfSize:(CGSize)size {
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
        titleString = [NSString stringWithFormat:@"%@\u2026", [titleString substringToIndex:maxTitleLength]];
    }
    
    THStringRenderer *renderer = [THStringRenderer stringRendererWithFontName:@"Linux Libertine O"];

    CGSize fullSize = [[UIScreen mainScreen] bounds].size;
    CGFloat pointSize = roundf(fullSize.height / 8.0f);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(size.width / fullSize.width, size.height / fullSize.height);
    
    UIEdgeInsets titleInsets = UIEdgeInsetsMake(fullSize.height * 0.2f, fullSize.width * 0.2f, fullSize.height * 0.2f, fullSize.width * 0.1f);
    CGRect titleRect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, fullSize.width, fullSize.height), titleInsets);
    
    BOOL fits = NO;
    
    NSUInteger flags = THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter;
    
    while (!fits && pointSize >= 2) {
        CGSize size = [renderer sizeForString:titleString pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
        if ((size.height <= titleRect.size.height) && (size.width <= titleRect.size.width)) {
            fits = YES;
        } else {
            pointSize -= 1.0f;
        }
    }
    
    CGContextConcatCTM(ctx, scaleTransform);
    CGContextClipToRect(ctx, titleRect); // if title won't fit at 2 points it gets clipped
    
    CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.919 green:0.888 blue:0.862 alpha:0.8f].CGColor);
    CGContextBeginTransparencyLayer(ctx, NULL);
    CGContextSetShadow(ctx, CGSizeMake(0, -1*scaleTransform.d), 0);
    [renderer drawString:titleString inContext:ctx atPoint:titleRect.origin pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
    CGContextEndTransparencyLayer(ctx);
    
    CGContextSetRGBFillColor(ctx, 0.9f, 0.9f, 1, 0.8f);
    [renderer drawString:titleString inContext:ctx atPoint:titleRect.origin pointSize:pointSize maxWidth:titleRect.size.width flags:flags];
    
    UIImage *aCoverImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    return aCoverImage;
}

- (UIImage *)coverImage {
    NSData *imageData = [self manifestDataForKey:BlioManifestCoverKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        return aCoverImage;
    } else {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        return [self missingCoverImageOfSize:CGSizeMake(screenSize.width, screenSize.height)];
    }
}
- (BOOL)hasAppropriateCoverThumbForGrid {
    CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
	
    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
	if (aCoverImage) return YES;
	return NO;
}
- (UIImage *)coverThumbForGrid {
	
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }

	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];

    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        if(scaleFactor != 1.0f) {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
        } else {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage];
        }
        return aCoverImage;
    } else {
        return [self missingCoverImageOfSize:CGSizeMake(targetThumbWidth, targetThumbHeight)];
    }
    return [UIImage imageWithData:imageData];
}
- (BOOL)hasAppropriateCoverThumbForList {
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }
	
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;
	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];
    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
	if (aCoverImage) return YES;
	return NO;
}
- (UIImage *)coverThumbForList {
	
	CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }

	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;
		
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	NSString * pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledTargetThumbWidth,scaledTargetThumbHeight];

    NSData *imageData = [self manifestDataForKey:pixelSpecificKey];
    UIImage *aCoverImage = [UIImage imageWithData:imageData];
    if (aCoverImage) {
        if(scaleFactor != 1.0f) {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
        } else {
            aCoverImage = [UIImage imageWithCGImage:aCoverImage.CGImage];
        }
        return aCoverImage;
    } else {
        return [self missingCoverImageOfSize:CGSizeMake(targetThumbWidth, targetThumbHeight)];
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

// FIXME: Although this predicate is identical to the sortedHighlightRanges predicate (which should probably be removed) they are being left in
// so near to a release until we have a longer QA cycle to test there aren't any issues with changing it
static NSPredicate *sSortedBookmarkRangePredicate = nil;
pthread_once_t sSortedBookmarkRangePredicateOnceControl = PTHREAD_ONCE_INIT;
static void sortedBookmarkRangePredicateInit() {
    sSortedBookmarkRangePredicate = [[NSPredicate predicateWithFormat:
                                       @"book == $BOOK AND "
                                       @"NOT ( range.startPoint.layoutPage > $MAX_LAYOUT_PAGE ) && "
                                       @"NOT ( range.endPoint.layoutPage < $MIN_LAYOUT_PAGE ) && "
                                       @"NOT ( range.startPoint.layoutPage == $MAX_LAYOUT_PAGE && range.startPoint.blockOffset > $MAX_BLOCK_OFFSET ) && "
                                       @"NOT ( range.endPoint.layoutPage == $MIN_LAYOUT_PAGE && range.endPoint.blockOffset < $MIN_BLOCK_OFFSET) && "
                                       @"NOT ( range.startPoint.layoutPage == $MAX_LAYOUT_PAGE && range.startPoint.blockOffset == $MAX_BLOCK_OFFSET && range.startPoint.wordOffset > $MAX_WORD_OFFSET ) && "
                                       @"NOT ( range.endPoint.layoutPage == $MIN_LAYOUT_PAGE && range.endPoint.blockOffset == $MIN_BLOCK_OFFSET && range.endPoint.wordOffset < $MIN_WORD_OFFSET )"
                                       ] retain];
}

- (NSPredicate *)sortedBookmarkRangePredicate {
    pthread_once(&sSortedBookmarkRangePredicateOnceControl, sortedBookmarkRangePredicateInit);
    return sSortedBookmarkRangePredicate;
}

- (NSArray *)sortedBookmarksForRange:(BlioBookmarkRange *)range {
    NSManagedObjectContext *moc = nil;
    
    if ([NSThread isMainThread]) {
        moc = [self managedObjectContext]; 
    } else {
        moc = [[[NSManagedObjectContext alloc] init] autorelease]; 
        [moc setPersistentStoreCoordinator:[[self managedObjectContext] persistentStoreCoordinator]];
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    [request setEntity:[NSEntityDescription entityForName:@"BlioBookmark" inManagedObjectContext:moc]];
    
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
    
    NSPredicate *predicate = [[self sortedBookmarkRangePredicate] predicateWithSubstitutionVariables:substitutionVariables];
    
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
        NSLog(@"Error whilst retrieving bookmarks for range. %@, %@", error, [error userInfo]); 
        return nil;
    }
    
    return results;
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
            NSString *textFlowLocation = [self manifestLocationForKey:BlioManifestTextFlowKey];
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
			if ([path isEqualToString:BlioXPSMetaDataDir]) {
				// Workaround for the fact that this mechanism doesn't work for directories
				// Just check if the first page thumbnail is at that location
				exists = [self componentExistsInXPSAtPath:[path stringByAppendingPathComponent:@"1.jpg"]];
			} else {
				exists = [self componentExistsInXPSAtPath:path];
			}
        }
    }
    
    return exists;
}

- (void)setManifestValue:(id)value forKey:(NSString *)key {
//	NSLog(@"setManifestValue:forKey:%@ \n value: %@ for book with ID %@",key,value,self.objectID);
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
    NSString *textFlowLocation = [self manifestLocationForKey:BlioManifestTextFlowKey];
    
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

- (NSData *)textFlowDataWithPath:(NSString *)path {
    return [self dataFromTextFlowAtPath:path];
}

- (BOOL)hasManifestValueForKey:(NSString *)key
{
    return [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]] != nil;
}

- (NSString *)manifestPathForKey:(NSString *)key {
    NSString *filePath = nil;
    
    NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        NSString *location = [manifestEntry objectForKey:BlioManifestEntryLocationKey];
        NSString *path = [manifestEntry objectForKey:BlioManifestEntryPathKey];
        if (location && path) {
            // TODO: what if the textflow is in the XPS - this won't work? manifestPathForKey perhaps should have stayed private
            if ([location isEqualToString:BlioManifestEntryLocationTextflow]) {
                filePath = [self fullPathOfTextFlowItemAtPath:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationBundle]) {
				filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:path];
            } else if ([location isEqualToString:BlioManifestEntryLocationFileSystem]) {
				filePath = [self fullPathOfFileSystemItemAtPath:path];
			} else if ([location isEqualToString:BlioManifestEntryLocationXPS]) {
                // There is no such thing as a full-path to an XPS item - must be accessed via a data accessor
				NSLog(@"ERROR: manifest path tried to be obtained for an in-XPS item! key: %@, returning nil...",key);
                filePath = nil;
            } else {
                filePath = path;
            }
        }
    }
    
    return filePath;
}

- (NSString *)manifestRelativePathForKey:(NSString *)key {
	NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        NSString *path = [manifestEntry objectForKey:BlioManifestEntryPathKey];
        if (path) return path;
    }
    return nil;
}

- (NSString *)manifestLocationForKey:(NSString *)key {
    NSString *fileLocation = nil;
    
    NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        fileLocation = [manifestEntry objectForKey:BlioManifestEntryLocationKey];
    }
    return fileLocation;
}

- (BOOL)manifestPreAvailabilityCompleteForKey:(NSString *)key {
    BOOL fileStatus = false;
    
    NSDictionary *manifestEntry = [self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]];
    if (manifestEntry) {
        fileStatus = [[manifestEntry objectForKey:BlioManifestPreAvailabilityCompleteKey] boolValue];
    }
    return fileStatus;
}

- (NSData *)manifestDataForKey:(NSString *)key {
    NSData *data = nil;
    NSDictionary *manifestEntry = [[self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]] retain];
    if(manifestEntry) {
        NSString *location = [manifestEntry objectForKey:BlioManifestEntryLocationKey];
        NSString *path = [manifestEntry objectForKey:BlioManifestEntryPathKey];
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
- (NSData *)manifestDataForKey:(NSString *)key pathIndex:(NSInteger)index {
    NSData *data = nil;
    NSDictionary *manifestEntry = [[self valueForKeyPath:[NSString stringWithFormat:@"manifest.%@", key]] retain];
    if(manifestEntry) {
        NSString *location = [manifestEntry objectForKey:BlioManifestEntryLocationKey];
		if ([[manifestEntry objectForKey:BlioManifestEntryPathKey] isKindOfClass:[NSArray class]]) {
			NSArray *pathArray = [manifestEntry objectForKey:BlioManifestEntryPathKey];
			NSString * path = nil;
			if (index < [pathArray count]) path = [pathArray objectAtIndex:index];
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
		else NSLog(@"WARNING: manifestDataForKey:pathIndex: called, but path value is not an array!");
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
    } else if (![self hasPdf]) {
        id<BlioParagraphSource> paragraphSource = [[BlioBookManager sharedBookManager] checkOutParagraphSourceForBookWithID:self.objectID];
    
        id startParagraphID;
        uint32_t startWordOffset;
        [paragraphSource bookmarkPoint:range.startPoint
                         toParagraphID:&startParagraphID
                            wordOffset:&startWordOffset];
        
        id endParagraphID;
        uint32_t endWordOffset;
        [paragraphSource bookmarkPoint:range.endPoint
                         toParagraphID:&endParagraphID
                            wordOffset:&endWordOffset];        
        
        NSMutableArray *buildWords = [[NSMutableArray alloc] init];
        id paragraphID = startParagraphID;
        for(;;) {
            NSArray *words = [paragraphSource wordsForParagraphWithID:paragraphID];
            if([paragraphID isEqual:startParagraphID] && [paragraphID isEqual:endParagraphID]) {
                words = [words subarrayWithRange:NSMakeRange(startWordOffset, endWordOffset - startWordOffset + 1)];
            } else if([paragraphID isEqual:startParagraphID]) {
                words = [words subarrayWithRange:NSMakeRange(startWordOffset, words.count - startWordOffset)];
            } else if([paragraphID isEqual:endParagraphID]) {
                words = [words subarrayWithRange:NSMakeRange(0, endWordOffset + 1)];
            }
            [buildWords addObjectsFromArray:words];
            
            if([paragraphID isEqual:endParagraphID]) {
                break;
            } else {
                paragraphID = [paragraphSource nextParagraphIdForParagraphWithID:paragraphID];
            }
        }
        
        [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.objectID];
        
        return [buildWords autorelease];
    }
    return nil;
}

#pragma mark -
#pragma mark Author name conversion functions

- (NSString *)authorsWithStandardFormat {
	if (self.author) {
		NSArray * authorsArray = [self.author componentsSeparatedByString:@"|"];
		return [BlioBook standardNamesFromCanonicalNameArray:authorsArray];
	}
	return nil;
}

+(NSString*)standardNamesFromCanonicalNameArray:(NSArray*)aNameArray {
	if (aNameArray) {
		NSString * authorsString = @"";
		for (int i = 0; i < [aNameArray count]; i++) {
			if (i != 0) {
				if (i == ([aNameArray count] - 1)) {
					authorsString = [authorsString stringByAppendingString:@" & "];
				}
				else authorsString = [authorsString stringByAppendingString:@", "];
			}
			authorsString = [authorsString stringByAppendingString:[BlioBook standardNameFromCanonicalName:[aNameArray objectAtIndex:i]]];
		}		
		return authorsString;
	}
	return nil;
}
+(NSArray*) suffixes{
	return [NSArray arrayWithObjects:@"Ph.D.",@"PhD",@"M.D.",@"M.d.",@"MD",nil];
}

+(NSArray*) suffixesWithoutCommas{
	return [NSArray arrayWithObjects:@"Jr.",@"Sr.",@"Jr",@"Sr",@"Esq.",@"II",@"III",@"IV",@"V",nil];
}

+(NSArray*) prefixes{
	return [NSArray arrayWithObjects:@"Saint",@"Sir",@"Viscount",@"Baron",@"Brother",nil];
}

+(NSArray*) specialSuffixes{
	return [NSArray arrayWithObjects:@"(CON)",@"(ILT)",nil];
}

+(NSString*)standardNameFromCanonicalName:(NSString*)name {
	//get a mutable copy so we can delete unneeded parts of the string
	NSMutableString* aName = [[name mutableCopy] autorelease];
	
	//This is to check and handle the case where there are special suffixes to the author. This is resolved at the end of this function with adding back the special suffix
	NSString* specialEnding = @"";
	for (NSString* endingType in [BlioBook specialSuffixes]){
		NSRange endingRange = [aName rangeOfString:[NSString stringWithFormat:@" %@",endingType]];
		if (endingRange.location != NSNotFound){
			[aName deleteCharactersInRange:endingRange];
			specialEnding = [NSString stringWithFormat:@" %@",endingType];
		}
	}
	
	//Split by commas
	NSMutableArray* namePieces = [[[aName componentsSeparatedByString:@", "]mutableCopy] autorelease];
	
	//If 1 Piece, Plato Case (only one name) return piece
	if ([namePieces count] == 1)
		return aName;
	
	//If 2 Pieces, no suffix, so return 2nd piece first Piece
	if ([namePieces count] == 2){
		NSString* result = [NSString stringWithFormat:@"%@ %@",[namePieces objectAtIndex:1],[namePieces objectAtIndex:0]];
		if ([specialEnding length]>0){
			result = [result stringByAppendingString:specialEnding];
		}
		return result;
	}
	
	//if 3 pieces, there are suffixes/prefixes, so return 2nd Piece 1st Piece, 3rd Piece
	//determine the suffixes, prefixes and suffixes that don't require commas
	NSArray* suffixPrefixPieces = [[namePieces objectAtIndex:2]componentsSeparatedByString:@" "];
	NSMutableArray* suffixes = [NSMutableArray array];
	NSMutableArray* suffixesWithoutCommas = [NSMutableArray array];
	NSMutableArray* prefixes = [NSMutableArray array];
	
	//for each suffix/prefix piece, see if it is in one of the predefined subsets and add to arrays of objects for reinsertion to main string later
	for (NSString* suffixPrefixPiece in suffixPrefixPieces){
		if ([[BlioBook suffixes]containsObject:suffixPrefixPiece]){
			[suffixes addObject:suffixPrefixPiece];
		} else if ([[BlioBook suffixesWithoutCommas]containsObject:suffixPrefixPiece]){
			[suffixesWithoutCommas addObject:suffixPrefixPiece];
		} else if ([[BlioBook prefixes]containsObject:suffixPrefixPiece]){
			[prefixes addObject:suffixPrefixPiece];
		} else NSLog(@"potential suffix of %@ found, not recognized and ignoring",suffixPrefixPiece);
	}
	
	//Build string by handling prefixes first, then add in the main pieces of the name, then tacking on suffixes
	NSString* standardName = @"";
	if ([prefixes count]>0){
		standardName = [NSString stringWithFormat:@"%@ %@",[prefixes componentsJoinedByString:@" "],[namePieces objectAtIndex:1]];
	} else {
		standardName = [namePieces objectAtIndex:1];
	}
	
	standardName = [standardName stringByAppendingFormat:@" %@",[namePieces objectAtIndex:0]];
	
	if ([suffixesWithoutCommas count]>0)
		standardName = [standardName stringByAppendingFormat:@" %@",[suffixesWithoutCommas componentsJoinedByString:@" "]];
	
	if ([suffixes count]>0)
		standardName = [standardName stringByAppendingFormat:@", %@",[suffixes componentsJoinedByString:@" "]];
	
	if ([specialEnding length]>0){
		standardName = [standardName stringByAppendingString:specialEnding];
	}
	
	return standardName;
}

+(NSString*)canonicalNameFromStandardName:(NSString*)name {
	//get a mutable copy so we can delete unneeded parts of the string
	NSMutableString* aName = [[name mutableCopy] autorelease];
	
	//This is to check and handle the case where there are special suffixes to the author. This is resolved at the end of this function with adding back the special suffix
	NSString* specialEnding = @"";
	for (NSString* endingType in [BlioBook specialSuffixes]){
		NSRange endingRange = [aName rangeOfString:[NSString stringWithFormat:@" %@",endingType]];
		if (endingRange.location != NSNotFound){
			[aName deleteCharactersInRange:endingRange];
			specialEnding = [NSString stringWithFormat:@" %@",endingType];
		}
	}
	
	//split name string into pieces by spaces.  Array is mutable so it can be changed later in function
	NSMutableArray* namePieces = [[[aName componentsSeparatedByString:@" "]mutableCopy] autorelease];
	
	//Check Plato case: if single name, return single name unchanged
	if ([namePieces count] == 1)
		return aName;
	
	//lastNamePieces holds all the pieces in the last name (including suffixes)
	NSMutableArray* suffixesPrefixes = [NSMutableArray array];
	NSString* piece;
	BOOL finished = NO;
	
	//find all the prefixes and add in to array
	do {
		piece = [namePieces objectAtIndex:0];
		if ([[BlioBook prefixes]containsObject:piece]){
			[suffixesPrefixes addObject:piece];
			[namePieces removeObjectAtIndex:0];
		} else finished = YES;
	} while (!finished);
	
	finished = NO;
	
	//remove the last object in the namePieces array and add to the suffixesPrefixes array while we have a suffix
	do {
		//get last piece and then remove it from the namePieces array
		piece = [namePieces lastObject];
		[namePieces removeLastObject];
		if ([[BlioBook suffixes]containsObject:piece] || [[BlioBook suffixesWithoutCommas]containsObject:piece]){
			[suffixesPrefixes addObject:piece];
		} else finished = YES;
		//NOTE: if this comparison becomes more complicated than simply looking at a list of suffixes, you could use a regular expression to check each piece
	} while (!finished);
	
	if ([piece hasSuffix:@","])
		piece = [piece stringByReplacingOccurrencesOfString:@"," withString:@""];
	
	//the last name is now stored in the piece value as the first piece before the suffixes
	NSString* finalString;
	if ([suffixesPrefixes count] == 0)
		finalString = [NSString stringWithFormat:@"%@, %@",piece,[namePieces componentsJoinedByString:@" "]];
	else finalString = [NSString stringWithFormat:@"%@, %@, %@",piece,[namePieces componentsJoinedByString:@" "],[suffixesPrefixes componentsJoinedByString:@" "]];
	if ([specialEnding length]>0){
		finalString = [finalString stringByAppendingString:specialEnding];
	}
	
	//flatten arrays into strings separated by original spaces and add in comma
	return finalString;
}

@end


