//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"
#import "BlioProcessing.h"

@interface BlioTextFlowPreParseOperation : BlioProcessingOperation
@end

@implementation BlioTextFlowPositionedWord

@synthesize string, rect, paragraphID, wordIndex, wordID;

- (void)dealloc {
    self.string = nil;
    self.paragraphID = nil;
    self.wordID = nil;
    [super dealloc];
}

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs {
    if ([[self paragraphID] compare:[rhs paragraphID]] == NSOrderedSame) {
        if ([self wordIndex] < [rhs wordIndex]) {
            return NSOrderedAscending;
        } else if ([self wordIndex] > [rhs wordIndex]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    } else {
        return [[self paragraphID] compare:[rhs paragraphID]];
    }
}

+ (NSInteger)wordIndexForWordID:(id)aWordID {
    NSNumber *wordIDNum = (NSNumber *)aWordID;
    return [wordIDNum integerValue];
}

+ (id)wordIDForWordIndex:(NSInteger)aWordIndex {
    return [NSNumber numberWithInteger:aWordIndex];
}

@end

@interface BlioTextFlowSection()
@property (nonatomic, assign) XML_Parser *currentParser;
@property (nonatomic) NSInteger currentPageIndex;
@end


@implementation BlioTextFlowSection

@synthesize pageIndex, name, path, anchor, pageMarkers;
@synthesize currentParser, currentPageIndex;

- (id)init {
    if ((self = [super init])) {
        self.pageMarkers = [NSMutableSet set];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        self.pageIndex = [coder decodeIntegerForKey:@"BlioTextFlowSectionPageIndex"];
        self.name = [coder decodeObjectForKey:@"BlioTextFlowSectionPageName"];
        self.path = [coder decodeObjectForKey:@"BlioTextFlowSectionPagePath"];
        self.anchor = [coder decodeObjectForKey:@"BlioTextFlowSectionPageAnchor"];
        self.pageMarkers = [NSMutableSet setWithSet:[coder decodeObjectForKey:@"BlioTextFlowSectionImmutablePageMarkers"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.pageIndex forKey:@"BlioTextFlowSectionPageIndex"];
    [coder encodeObject:self.name forKey:@"BlioTextFlowSectionPageName"];
    [coder encodeObject:self.path forKey:@"BlioTextFlowSectionPagePath"];
    [coder encodeObject:self.anchor forKey:@"BlioTextFlowSectionPageAnchor"];
    [coder encodeObject:[NSSet setWithSet:self.pageMarkers] forKey:@"BlioTextFlowSectionImmutablePageMarkers"];
}

- (void)dealloc {
    self.name = nil;
    self.path = nil;
    self.anchor = nil;
    self.pageMarkers = nil;
    self.currentParser = nil;
    [super dealloc];
}

- (NSArray *)sortedPageMarkers {
    NSSortDescriptor *sortByteDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"byteIndex" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortByteDescriptor, nil] autorelease];
    
    return [[self.pageMarkers allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

@end

@implementation BlioTextFlowPageMarker

@synthesize pageIndex, byteIndex;

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        self.pageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageMarkerPageIndex"];
        self.byteIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageMarkerByteIndex"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.pageIndex forKey:@"BlioTextFlowPageMarkerPageIndex"];
    [coder encodeInteger:self.byteIndex forKey:@"BlioTextFlowPageMarkerByteIndex"];
}

@end

@implementation BlioTextFlowParagraph

@synthesize pageIndex, paragraphIndex, paragraphID, words, folio;

- (void)dealloc {
    self.words = nil;
    self.paragraphID = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        self.words = [NSMutableArray array];
        self.folio = NO;
    }
    return self;
}

- (NSArray *)wordsArray {
    NSMutableArray *allWordStrings = [NSMutableArray arrayWithCapacity:[self.words count]];
    for (BlioTextFlowPositionedWord *word in self.words) {
        [allWordStrings addObject:word.string];
    }
    return allWordStrings;
}

- (NSString *)string {
    return [self.wordsArray componentsJoinedByString:@" "];
}

- (CGRect)rect {
    if (CGRectEqualToRect(rect, CGRectZero)) {
        for (BlioTextFlowPositionedWord *word in self.words) {
            if (CGRectEqualToRect(rect, CGRectZero))
                rect = word.rect;
            else
                rect = CGRectUnion(rect, word.rect);
        }
    }
    return rect;
}

- (NSComparisonResult)compare:(BlioTextFlowParagraph *)rhs {
    return [self.paragraphID compare:rhs.paragraphID];
}

+ (NSInteger)pageIndexForParagraphID:(id)aParagraphID {
    return [(NSIndexPath *)aParagraphID section];
}

+ (NSInteger)paragraphIndexForParagraphID:(id)aParagraphID {
    return [(NSIndexPath *)aParagraphID row];
}

+ (id)paragraphIDForPageIndex:(NSInteger)aPageIndex paragraphIndex:(NSInteger)aParagraphIndex {
    return [NSIndexPath indexPathForRow:aParagraphIndex inSection:aPageIndex];
}

@end

@interface BlioTextFlow()

@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic, retain) BlioTextFlowSection *currentSection;
@property (nonatomic, retain) BlioTextFlowParagraph *currentParagraph;
@property (nonatomic, retain) NSMutableArray *currentParagraphArray;
@property (nonatomic, readonly) XML_Parser currentParser;
@property (nonatomic) NSInteger cachedPageIndex;
@property (nonatomic, retain) NSArray *cachedPageParagraphs;
@property (nonatomic, retain) NSSet *sections;

- (NSArray *)paragraphsForPage:(NSInteger)pageIndex inSection:(BlioTextFlowSection *)section targetMarker:(BlioTextFlowPageMarker *)targetMarker firstMarker:(BlioTextFlowPageMarker *)firstMarker;


@end

@implementation BlioTextFlow

@synthesize sections;
@synthesize currentSection, currentParagraph;
@synthesize currentPageIndex, currentParagraphArray, currentParser;
@synthesize cachedPageIndex, cachedPageParagraphs;

- (void)dealloc {
    self.sections = nil;
    self.currentSection = nil;
    self.currentParagraph = nil;
    self.currentParagraphArray = nil;
    self.cachedPageParagraphs = nil;
    if (nil != self.currentParser) {
        enum XML_Status status = XML_StopParser(currentParser, false);
        if (status == XML_STATUS_OK) {
            XML_ParserFree(currentParser);
        } else {
            NSLog(@"Error whilst attempting to stop XML Parser in TextFlow dealloc.");
        }
    }
    [super dealloc];
}

- (id)initWithSections:(NSSet *)sectionsSet {
    if ((self = [super init])) {
        self.sections = sectionsSet;
    }
    return self;
} 

#pragma mark -
#pragma mark Fragment XML (paragraph) parsing

static void fragmentXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;

    if (strcmp("TextGroup", name) == 0) {    

        NSInteger targetIndex = [textFlow currentPageIndex];
        NSMutableArray *paragraphArray = [textFlow currentParagraphArray];
        BOOL newParagraph = NO;
        BOOL folio = NO;
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    NSInteger newIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                    if (newIndex == targetIndex) {
                        if (nil == paragraphArray) {
                            paragraphArray = [NSMutableArray array];
                            [textFlow setCurrentParagraphArray:paragraphArray];
                        }
                    } else if (newIndex > targetIndex) {
                        XML_StopParser([textFlow currentParser], false);
                        return;
                    } else {
                        return;
                    }
                }
            } else if (strcmp("NewParagraph", atts[i]) == 0) {
                NSString *newParagraphString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != newParagraphString) {
                    if ([newParagraphString isEqualToString:@"True"]) newParagraph = YES;
                    [newParagraphString release];
                }
            } else if (strcmp("Folio", atts[i]) == 0) {
                NSString *folioString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != folioString) {
                    if ([folioString isEqualToString:@"True"]) folio = YES;
                    [folioString release];
                }
            }
        }
        
        BlioTextFlowParagraph *paragraph = [textFlow currentParagraph];
        if (!folio && (nil == paragraph || newParagraph)) {
            paragraph = [[BlioTextFlowParagraph alloc] init];
            [paragraph setPageIndex:targetIndex];
            NSUInteger newParagraphIndex = [paragraphArray count];
            [paragraph setParagraphIndex:newParagraphIndex];
            NSIndexPath *paragraphID = [BlioTextFlowParagraph paragraphIDForPageIndex:targetIndex paragraphIndex:newParagraphIndex];
            [paragraph setParagraphID:paragraphID];
            [paragraphArray addObject:paragraph];
            [textFlow setCurrentParagraph:paragraph];
            [paragraph release];
        } else if (folio) {
            [textFlow setCurrentParagraph:nil];
        }

    } else if (strcmp("Word", name) == 0) {
        NSString *textString = nil;
        NSArray *rectArray = nil;
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("Text", atts[i]) == 0) {
                textString = [NSString stringWithUTF8String:atts[i+1]];
            } else if (strcmp("Rect", atts[i]) == 0) {
                NSString *rectString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != rectString) {
                    rectArray = [rectString componentsSeparatedByString:@","];
                    [rectString release];
                }
            }
        }
                
        if ((nil != textString) && ([rectArray count] == 4)) {
            BlioTextFlowParagraph *paragraph = [textFlow currentParagraph];
            BlioTextFlowPositionedWord *newWord = [[BlioTextFlowPositionedWord alloc] init];
            [newWord setString:textString];
            [newWord setRect:CGRectMake([[rectArray objectAtIndex:0] intValue], 
                                        [[rectArray objectAtIndex:1] intValue],
                                        [[rectArray objectAtIndex:2] intValue],
                                        [[rectArray objectAtIndex:3] intValue])];
            
            [newWord setParagraphID:[paragraph paragraphID]];
            NSInteger index = [[paragraph words] count];
            [newWord setWordIndex:index];
            [newWord setWordID:[NSNumber numberWithInteger:index]];
            [[paragraph words] addObject:newWord];
            [newWord release];
        }
    }
}

static void fragmentXMLParsingEndElementHandler(void *ctx, const XML_Char *name)  {
    if(strcmp("Flow", name) == 0) {
        BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
        XML_StopParser([textFlow currentParser], false);
    }
}

- (NSArray *)paragraphsForPage:(NSInteger)pageIndex inSection:(BlioTextFlowSection *)section targetMarker:(BlioTextFlowPageMarker *)targetMarker firstMarker:(BlioTextFlowPageMarker *)firstMarker {
    
    self.currentParagraphArray = nil;
    NSString *path = [section path];
    
    if (nil != path) {
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
        if (nil == data) return nil;
        
        NSUInteger dataLength = [data length];
        NSUInteger offset = (NSUInteger)[targetMarker byteIndex];
        if (offset >= dataLength) {
            [data release];
            return nil;
        }
        
        currentParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(currentParser, fragmentXMLParsingStartElementHandler);
        XML_SetEndElementHandler(currentParser, fragmentXMLParsingEndElementHandler);
        XML_SetUserData(currentParser, (void *)self);  
        
        // Parse anything before the first marker in the file
        NSUInteger firstFragmentLength = [firstMarker byteIndex] - 1;
        if (!XML_Parse(currentParser, [data bytes], firstFragmentLength - 1, XML_FALSE)) {
            enum XML_Error errorCode = XML_GetErrorCode(currentParser);
            if (errorCode != XML_ERROR_ABORTED) {
                char *error = (char *)XML_ErrorString(errorCode);
                NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, path);
            }
        }
        
        NSUInteger targetFragmentLength = dataLength - offset;
        const void* offsetBytes = [data bytes] + offset;
        
        [self setCurrentPageIndex:[targetMarker pageIndex]];
        [self setCurrentParagraph:nil];
          
        @try {
            if (!XML_Parse(currentParser, offsetBytes, targetFragmentLength, XML_FALSE)) {
                enum XML_Error errorCode = XML_GetErrorCode(currentParser);
                if (errorCode != XML_ERROR_ABORTED) {
                    char *error = (char *)XML_ErrorString(errorCode);
                    NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, path);
                }
            }
        }
        @catch (NSException * e) {
            NSLog(@"TextFlow parsing exception: '%@' in file: '%@'", e.userInfo, path);
        }
        
        @try {
            XML_ParserFree(currentParser);
        } @catch (NSException * e) {
            NSLog(@"TextFlow parser freeing exception: '%@'.", e.userInfo);
        }
        [data release];

    }
    
    return [NSArray arrayWithArray:self.currentParagraphArray];
}

#pragma mark -
#pragma mark Convenience methods

- (NSArray *)sortedSections {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortPageDescriptor, nil] autorelease];
    return [[self.sections allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex {
    if (self.cachedPageParagraphs && (self.cachedPageIndex == pageIndex))
        return self.cachedPageParagraphs;
    
    NSArray *pageParagraphs = [NSArray array];
    
    BlioTextFlowSection *targetSection = nil;
    for (BlioTextFlowSection *section in [self sortedSections]) {
        if ([section pageIndex] > pageIndex)
            break;
        else
            targetSection = section;
    }
    
    if (nil != targetSection) {
        BlioTextFlowPageMarker *targetMarker = nil;
        BlioTextFlowPageMarker *firstMarker = nil;
        
        NSArray *sortedPageMarkers = [targetSection sortedPageMarkers];
        NSUInteger i, count = [sortedPageMarkers count];
        for (i = 0; i < count; i++) {
            BlioTextFlowPageMarker *pageMarker = [sortedPageMarkers objectAtIndex:i];
            if (i == 0) firstMarker = pageMarker;
            if ([pageMarker pageIndex] == pageIndex) targetMarker = pageMarker;
            if ([pageMarker pageIndex] >= pageIndex) 
                break;
        }
        
        if ((nil != targetMarker) && (nil != firstMarker)) {
            NSArray *pageParagraphsFromDisk = [self paragraphsForPage:pageIndex inSection:targetSection targetMarker:targetMarker firstMarker:firstMarker];
            if (nil != pageParagraphsFromDisk) pageParagraphs = pageParagraphsFromDisk;
            
        }

    }
    
    //NSLog(@"Paragraphs retrieved from disk");
    self.cachedPageParagraphs = pageParagraphs;
    self.cachedPageIndex = pageIndex;
    
    return pageParagraphs;
}

- (NSArray *)wordsForPageAtIndex:(NSInteger)pageIndex {
    NSMutableArray *wordsArray = [NSMutableArray array];
    
    for (BlioTextFlowParagraph *paragraph in [self paragraphsForPageAtIndex:pageIndex]) {
        [wordsArray addObjectsFromArray:[paragraph wordsArray]];
    }
    
    return [NSArray arrayWithArray:wordsArray];
}

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    NSMutableArray *allWordStrings = [NSMutableArray array];
    
    for (NSInteger pageNumber = range.startPoint.layoutPage; pageNumber <= range.endPoint.layoutPage; pageNumber++) {
        NSInteger pageIndex = pageNumber - 1;

        for (BlioTextFlowParagraph *paragraph in [self paragraphsForPageAtIndex:pageIndex]) {
            for (BlioTextFlowPositionedWord *word in [paragraph words]) {
                if ((range.startPoint.layoutPage < pageNumber) &&
                    (paragraph.paragraphIndex <= range.endPoint.paragraphOffset) &&
                    (word.wordIndex <= range.endPoint.wordOffset)) {
                    
                    [allWordStrings addObject:[word string]];
                    
                } else if ((range.endPoint.layoutPage > pageNumber) &&
                           (paragraph.paragraphIndex >= range.startPoint.paragraphOffset) &&
                           (word.wordIndex >= range.startPoint.wordOffset)) {
                    
                    [allWordStrings addObject:[word string]];
                    
                } else if ((range.startPoint.layoutPage == pageNumber) &&
                           (paragraph.paragraphIndex == range.startPoint.paragraphOffset) &&
                           (word.wordIndex >= range.startPoint.wordOffset)) {
                    
                    if ((paragraph.paragraphIndex == range.endPoint.paragraphOffset) &&
                        (word.wordIndex <= range.endPoint.wordOffset)) {
                        [allWordStrings addObject:[word string]];
                    } else if (paragraph.paragraphIndex < range.endPoint.paragraphOffset) {
                        [allWordStrings addObject:[word string]];
                    }
                    
                } else if ((range.startPoint.layoutPage == pageNumber) &&
                           (paragraph.paragraphIndex > range.startPoint.paragraphOffset)) {
                    
                    if ((paragraph.paragraphIndex == range.endPoint.paragraphOffset) &&
                        (word.wordIndex <= range.endPoint.wordOffset)) {
                        [allWordStrings addObject:[word string]];
                    } else if (paragraph.paragraphIndex < range.endPoint.paragraphOffset) {
                        [allWordStrings addObject:[word string]];
                    }
                    
                }
            }
        }
        
    }

    return [NSArray arrayWithArray:allWordStrings];
}

- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex {
    NSMutableString *pageString = [NSMutableString string];
    NSArray *pageParagraphs = [self paragraphsForPageAtIndex:pageIndex];
    for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
        if ([pageString length])
            [pageString appendFormat:@"\n\n%@", paragraph.string];
        else 
            [pageString appendString:paragraph.string];
    }
    return pageString;
}

+ (NSArray *)preAvailabilityOperations {
    BlioTextFlowPreParseOperation *preParseOp = [[BlioTextFlowPreParseOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

@end

#pragma mark -
@implementation BlioTextFlowPreParseOperation

static void sectionFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    NSMutableArray *sectionsArray = (NSMutableArray *)ctx;
    
    if(strcmp("Section", name) == 0) {
        BlioTextFlowSection *aSection = [[BlioTextFlowSection alloc] init];
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    NSInteger newIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                    [aSection setPageIndex:newIndex];
                }
            } else if (strcmp("Name", atts[i]) == 0) {
                NSString *nameString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != nameString) {
                    [aSection setName:nameString];
                    [nameString release];
                }
            } else if (strcmp("Source", atts[i]) == 0) {
                NSString *sourceString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != sourceString) {
                    NSArray *sectionArray = [sourceString componentsSeparatedByString:@"#"];
                    [aSection setPath:[sectionArray objectAtIndex:0]];
                    if ([sectionArray count] > 1) [aSection setAnchor:[sectionArray objectAtIndex:1]];
                    [sourceString release];
                }
            }
        }
        
        if (nil != aSection) {
            [sectionsArray addObject:aSection];
            [aSection release];
        }
    }
    
}   

static void flowFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlowSection *section = (BlioTextFlowSection *)ctx;
    NSInteger newPageIndex = -1;
    
    if(strcmp("TextGroup", name) == 0) {
        
        NSUInteger currentByteIndex = (NSUInteger)(XML_GetCurrentByteIndex(*[section currentParser]));
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    newPageIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                }
            } 
        }
        
        if ((newPageIndex >= 0) && (newPageIndex != [section currentPageIndex])) {
            BlioTextFlowPageMarker *newPageMarker = [[BlioTextFlowPageMarker alloc] init];
            [newPageMarker setPageIndex:newPageIndex];
            [newPageMarker setByteIndex:currentByteIndex];
            [section.pageMarkers addObject:newPageMarker];
            [newPageMarker release];
            [section setCurrentPageIndex:newPageIndex];
        }
    }
    
} 

- (void)main {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *filename = [self getBookValueForKey:@"textflowFilename"];
    NSString *path = [[self.cacheDirectory stringByAppendingPathComponent:@"TextFlow"] stringByAppendingPathComponent:filename];
    
    if (!filename || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist at path: %@.", path);
        [pool drain];
        return;
    }
    
    NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
    
    if (nil == data) {
        NSLog(@"Could not create TextFlow data file.");
        [pool drain];
        return;
    }
    
    NSString *basePath = [path stringByDeletingLastPathComponent];
    NSMutableSet *sectionsSet = [NSMutableSet set];
    
    // Parse section file
    XML_Parser sectionFileParser = XML_ParserCreate(NULL);
    XML_SetStartElementHandler(sectionFileParser, sectionFileXMLParsingStartElementHandler);
    XML_SetUserData(sectionFileParser, (void *)sectionsSet);    
    if (!XML_Parse(sectionFileParser, [data bytes], [data length], XML_TRUE)) {
        char *anError = (char *)XML_ErrorString(XML_GetErrorCode(sectionFileParser));
        NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, path);
    }
    XML_ParserFree(sectionFileParser);
    [data release];
    
    for (BlioTextFlowSection *section in sectionsSet) {
        NSString *path = [basePath stringByAppendingPathComponent:[section path]];
        [section setPath:path];
        
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
            
        if (!data) {
            NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist at path: %@.", path);
            [pool drain];
            return;
        }
            
        XML_Parser flowParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(flowParser, flowFileXMLParsingStartElementHandler);
        section.currentPageIndex = -1;
        section.currentParser = &flowParser;
        XML_SetUserData(flowParser, (void *)section);    
        if (!XML_Parse(flowParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(flowParser));
            NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, path);
        }
        XML_ParserFree(flowParser);
        [data release];
        
    }
    
    [self setBookValue:[NSSet setWithSet:sectionsSet] forKey:@"textFlowSections"];
    
    [pool drain];
}


@end

