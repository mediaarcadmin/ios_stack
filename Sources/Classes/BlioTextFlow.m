//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"

@implementation BlioTextFlowPositionedWord

@synthesize string, rect, pageIndex, wordIndex, wordID;

- (void)dealloc {
    self.string = nil;
    self.wordID = nil;
    [super dealloc];
}

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs {
    if ([self pageIndex] == [rhs pageIndex]) {
        if ([self wordIndex] < [rhs wordIndex]) {
            return NSOrderedAscending;
        } else if ([self wordIndex] > [rhs wordIndex]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    } else if ([self pageIndex] < [rhs pageIndex]) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
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

@implementation BlioTextFlowSection

@synthesize pageIndex, name, path, anchor, pageMarkers;

- (id)init {
    if ((self = [super init])) {
        self.pageMarkers = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.path = nil;
    self.anchor = nil;
    self.pageMarkers = nil;
    [super dealloc];
}

- (void)addPageMarker:(BlioTextFlowPageMarker *)aPageMarker {
    [self.pageMarkers addObject:aPageMarker];
}

- (NSArray *)sortedPageMarkers {
    NSSortDescriptor *sortByteDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"byteIndex" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortByteDescriptor, nil] autorelease];
    
    return [[self.pageMarkers allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

@end

@implementation BlioTextFlowPageMarker

@synthesize pageIndex, byteIndex;

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
    if ([self pageIndex] == [rhs pageIndex]) {
        if ([self paragraphIndex] < [rhs paragraphIndex]) {
            return NSOrderedAscending;
        } else if ([self paragraphIndex] > [rhs paragraphIndex]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    } else if ([self pageIndex] < [rhs pageIndex]) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

+ (NSInteger)pageIndexForParagraphID:(id)aParagraphID {
    NSString *paraID = (NSString *)aParagraphID;
    
    if (nil != paraID) {
        NSArray *components = [paraID componentsSeparatedByString:@"-"];
        return [[components objectAtIndex:0] integerValue];
    } else {
        return -1;
    }
}

+ (NSInteger)paragraphIndexForParagraphID:(id)aParagraphID {
    NSString *paraID = (NSString *)aParagraphID;
    NSArray *components = [paraID componentsSeparatedByString:@"-"];

    if ([components count] > 1) {
        return [[components objectAtIndex:1] integerValue];
    } else {
        return -1;
    }
}

+ (id)paragraphIDForPageIndex:(NSInteger)aPageIndex paragraphIndex:(NSInteger)aParagraphIndex {
    return [NSString stringWithFormat:@"%d-%d", aPageIndex, aParagraphIndex];
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

- (void)parseSectionsFileAtPath:(NSString *)path;
- (void)parseSection:(BlioTextFlowSection *)section;
- (NSArray *)paragraphsForPage:(NSInteger)pageIndex inSection:(BlioTextFlowSection *)section targetMarker:(BlioTextFlowPageMarker *)targetMarker firstMarker:(BlioTextFlowPageMarker *)firstMarker;


@end

@implementation BlioTextFlow

@synthesize sections;
@synthesize currentSection, currentParagraph;
@synthesize currentPageIndex, currentParagraphArray, currentParser;
@synthesize cachedPageIndex, cachedPageParagraphs;
@synthesize ready;

- (void)dealloc {
    self.sections = nil;
    self.currentSection = nil;
    self.currentParagraph = nil;
    self.currentParagraphArray = nil;
    self.cachedPageParagraphs = nil;
    if (nil != self.currentParser) {
        XML_ParserFree(currentParser);
    }
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {    
    if ((self = [super init])) {
        self.sections = [NSMutableSet set];
        self.ready = NO;
        [self performSelectorInBackground:@selector(parseSectionsFileAtPath:) withObject:path];
    }
    return self;
}

- (void)addSection:(BlioTextFlowSection *)section {
    if (nil != section)
        [self.sections addObject:section];
}

- (void)parseSectionsFileComplete {
    [self performSelectorInBackground:@selector(parseSections:) withObject:self.sections];
}

- (void)parseSectionsComplete {
    //NSLog(@"TextFlow pageMarkers created");
    self.ready = YES;
}

#pragma mark -
#pragma mark Split XML (sections file) parsing

static void splitXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
    
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
                    [aSection setPath:[[sectionArray objectAtIndex:0] stringByDeletingPathExtension]];
                    if ([sectionArray count] > 1) [aSection setAnchor:[sectionArray objectAtIndex:1]];
                    [sourceString release];
                }
            }
        }
        
        if (nil != aSection) {
            [textFlow performSelectorOnMainThread:@selector(addSection:) withObject:aSection waitUntilDone:NO];
            [aSection release];
        }
    }
    
}   

- (void)parseSectionsFileAtPath:(NSString *)path {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
    currentParser = XML_ParserCreate(NULL);
    XML_SetStartElementHandler(currentParser, splitXMLParsingStartElementHandler);
    XML_SetUserData(currentParser, (void *)self);    
    if (!XML_Parse(currentParser, [data bytes], [data length], XML_TRUE)) {
        char *error = (char *)XML_ErrorString(XML_GetErrorCode(currentParser));
        NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, path);
    }
    XML_ParserFree(currentParser);
    [data release];
    
    [self performSelectorOnMainThread:@selector(parseSectionsFileComplete) withObject:nil waitUntilDone:NO];

    [pool drain];
}

- (void)parseSections:(NSArray *)sectionsArray {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    for (BlioTextFlowSection *section in sectionsArray) {
        [self parseSection:section];
    }
    
    [self performSelectorOnMainThread:@selector(parseSectionsComplete) withObject:nil waitUntilDone:NO];
    [pool drain];
} 

#pragma mark -
#pragma mark Flow XML (contents file) parsing

static void flowXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
    NSInteger newPageIndex = -1;
    
    if(strcmp("TextGroup", name) == 0) {
        
        NSUInteger currentByteIndex = (NSUInteger)(XML_GetCurrentByteIndex([textFlow currentParser]));
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    newPageIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                }
            } 
        }
        
        if ((newPageIndex >= 0) && (newPageIndex != [textFlow currentPageIndex])) {
            BlioTextFlowPageMarker *newPageMarker = [[BlioTextFlowPageMarker alloc] init];
            [newPageMarker setPageIndex:newPageIndex];
            [newPageMarker setByteIndex:currentByteIndex];
            [[textFlow currentSection] performSelectorOnMainThread:@selector(addPageMarker:) withObject:newPageMarker waitUntilDone:NO];
            [newPageMarker release];
            [textFlow setCurrentPageIndex:newPageIndex];
        }
    }
    
}   

- (void)parseSection:(BlioTextFlowSection *)section {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:[section path] ofType:@"xml" inDirectory:@"TextFlows"];
    NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
    
    if (!data) return;
    
    [self setCurrentPageIndex:-1];
    [self setCurrentSection:section];
    
    currentParser = XML_ParserCreate(NULL);
    XML_SetStartElementHandler(currentParser, flowXMLParsingStartElementHandler);
    XML_SetUserData(currentParser, (void *)self);    
    if (!XML_Parse(currentParser, [data bytes], [data length], XML_TRUE)) {
        char *error = (char *)XML_ErrorString(XML_GetErrorCode(currentParser));
        NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, path);
    }
    XML_ParserFree(currentParser);
    [data release];
        
    [pool drain];
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
            NSString *idString = [[NSString alloc] initWithFormat:@"%d-%d", targetIndex, newParagraphIndex];
            [paragraph setParagraphID:idString];
            [idString release];
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
            
            [newWord setPageIndex:[paragraph pageIndex]];
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
    
    if (nil != [section path]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:[section path] ofType:@"xml" inDirectory:@"TextFlows"];
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
        
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
        XML_ParserFree(currentParser);
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

@end
