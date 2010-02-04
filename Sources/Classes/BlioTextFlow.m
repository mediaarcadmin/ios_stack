//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"

@interface BlioTextFlowSlow()

@property (nonatomic, retain) NSXMLParser *textFlowParser;
@property (nonatomic, retain) BlioTextFlowSection *currentSection;
@property (nonatomic, retain) NSMutableArray *currentPage;
@property (nonatomic, retain) BlioTextFlowParagraph *currentParagraph;
@property (nonatomic, retain) BlioTextFlowPositionedWord *currentWord;
@property (nonatomic, retain) NSString *currentWordString;
@property (nonatomic, retain) NSString *currentWordRect;

- (BOOL)parseFileAtPath:(NSString *)path;

@end

@implementation BlioTextFlowSlow

@synthesize sections, pages, paragraphs;
@synthesize textFlowParser, currentSection, currentPage, currentParagraph, currentWord, currentWordString, currentWordRect;

- (void)dealloc {
    self.textFlowParser = nil;
    self.sections = nil;
    self.pages = nil;
    self.paragraphs = nil;
    self.currentSection = nil;
    self.currentPage = nil;
    self.currentParagraph = nil;
    self.currentWord = nil;
    self.currentWordString = nil;
    self.currentWordRect = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {      
    if ((self = [super init])) {
        self.sections = [NSMutableArray array];
        
        BOOL success = [self parseFileAtPath:path];
        
        if (!success) {
            NSLog(@"TextFlow file at path: %@ failed to parse", path);
            self.sections = nil;
            return nil;
        }
        
        self.pages = [NSMutableArray array];
        self.paragraphs = [NSMutableArray array];
        
        for (BlioTextFlowSection *section in self.sections) {
            self.currentSection = section;
            [self parseFileAtPath:[[NSBundle mainBundle] pathForResource:[section path] ofType:@"xml" inDirectory:@"TextFlows"]];
        }
        
    }
    
    return self;
}

- (BOOL)parseFileAtPath:(NSString *)path {
    if (nil == path) {
        return NO;
    } else if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"Error: FlowView file does not exist at path: %@", path);
        return NO;
    }

    BOOL success;
    NSURL *xmlURL = [NSURL fileURLWithPath:path];

    NSXMLParser *aTextFlowParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [aTextFlowParser setDelegate:self];
    success = [aTextFlowParser parse];
    self.textFlowParser = aTextFlowParser;
    [aTextFlowParser release];
    
    return success;
}

#pragma mark -
#pragma mark Convenience methods

- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex {
    NSArray *pageParagraphs = [NSArray array];
    if (pageIndex < [pages count]) {
        pageParagraphs = [pages objectAtIndex:pageIndex];
    }
    return pageParagraphs;
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

#pragma mark -
#pragma mark Parsing methods

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.textFlowParser = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.textFlowParser = nil;
    NSLog(@"TextFlow parsing error %i, Domain: %@, File: %@, Description: %@, Line: %i, Column: %i", [parseError code], [parseError domain], [self.currentSection path],
          [[parser parserError] localizedDescription], [parser lineNumber], [parser columnNumber]);
}  

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([elementName isEqualToString:@"Section"]) {
        BlioTextFlowSection *aSection = [[BlioTextFlowSection alloc] init];
        self.currentSection = aSection;
        [aSection release];
        
        NSString *pageNumber = [attributeDict objectForKey:@"PageIndex"];
        if (pageNumber) [self.currentSection setPageIndex:[pageNumber intValue]];
        NSString *sectionName = [attributeDict objectForKey:@"Name"];
        if (sectionName) [self.currentSection setName:sectionName];
        NSString *sectionPath = [attributeDict objectForKey:@"Source"];
        if (sectionPath) {
            NSArray *sectionArray = [sectionPath componentsSeparatedByString:@"#"];
            [self.currentSection setPath:[[sectionArray objectAtIndex:0] stringByDeletingPathExtension]];
            if ([sectionArray count] > 1) [self.currentSection setAnchor:[sectionArray objectAtIndex:1]];
        }
        
    } else if ([elementName isEqualToString:@"TextGroup"]) {
        NSInteger currentPageIndex;
        if (nil != self.currentParagraph)
            currentPageIndex = [self.currentParagraph pageIndex];
        else
            currentPageIndex = -1;
            
        NSString *pageNumber = [attributeDict objectForKey:@"PageIndex"];
        if (!pageNumber) {
            self.currentPage = nil;
            return;
        }
        NSInteger newPageIndex = [pageNumber intValue];
        if (newPageIndex < 0) {
            self.currentPage = nil;
            return;
        }
        
        NSString *newParagraph = [attributeDict objectForKey:@"NewParagraph"];
        if ([newParagraph isEqualToString:@"True"] || (newPageIndex > currentPageIndex)) {
            BlioTextFlowParagraph *aParagraph = [[BlioTextFlowParagraph alloc] init];
            self.currentParagraph = aParagraph;
            [aParagraph release];
            
            NSString *folio = [attributeDict objectForKey:@"Folio"];
            if ([folio isEqualToString:@"True"]) {
                [self.currentParagraph setFolio:YES];
            } else {
                [self.currentParagraph setFolio:NO];
                [self.paragraphs addObject:self.currentParagraph];
            }
        }
        
        if (![self.currentParagraph folio]) {           
            NSString *pageNumber = [attributeDict objectForKey:@"PageIndex"];
            if (pageNumber) {
                NSInteger pageIndex = [pageNumber intValue];
                if (pageIndex < 0) {
                    self.currentPage = nil;
                } else {
                    while ([self.pages count] <= pageIndex) {
                        NSMutableArray *aPage = [[NSMutableArray alloc] init];
                        [self.pages addObject:aPage];
                        [aPage release];
                    }
                    self.currentPage = [self.pages objectAtIndex:pageIndex];
                    [self.currentParagraph setPageIndex:pageIndex];
                    if (![self.currentPage containsObject:self.currentParagraph]) {
                        [self.currentPage addObject:self.currentParagraph];
                        [self.currentParagraph setParagraphIndex:[self.currentPage count] - 1];
                    }
                }
            }            
        }
        
    } else if ([elementName isEqualToString:@"Word"] && ![self.currentParagraph folio]) {
        NSString *wordString = [attributeDict objectForKey:@"Text"];
        NSString *wordRect = [attributeDict objectForKey:@"Rect"];
        NSArray *wordRectArray = [wordRect componentsSeparatedByString:@","];
        
        if (wordString && ([wordRectArray count] == 4)) {
            BlioTextFlowPositionedWord *newWord = [[BlioTextFlowPositionedWord alloc] init];
            [newWord setString:wordString];
            [newWord setRect:CGRectMake([[wordRectArray objectAtIndex:0] intValue], 
                                        [[wordRectArray objectAtIndex:1] intValue],
                                        [[wordRectArray objectAtIndex:2] intValue],
                                        [[wordRectArray objectAtIndex:3] intValue])];
            [[self.currentParagraph words] addObject:newWord];
            [newWord setPageIndex:[self.currentParagraph pageIndex]];
            [newWord setWordIndex:[[self.currentParagraph words] count] - 1];
            [newWord release];
        }
    }

    [pool drain];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([elementName isEqualToString:@"Section"]) {
        [self.sections addObject:self.currentSection];
        self.currentSection = nil;
    }
    
    [pool drain];
}
        
@end

@implementation BlioTextFlowPositionedWord

@synthesize string, rect, pageIndex, wordIndex;

- (void)dealloc {
    self.string = nil;
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
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSSortDescriptor *sortLineDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"lineNumber" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortPageDescriptor, sortLineDescriptor, nil] autorelease];
    
    return [[self.pageMarkers allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

@end

@implementation BlioTextFlowPageMarker

@synthesize pageIndex, lineNumber;

@end


@implementation BlioTextFlowParagraph

@synthesize pageIndex, paragraphIndex, words, folio;

- (void)dealloc {
    self.words = nil;
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

@end

#if 0
// Function prototypes for SAX callbacks.
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

// Forward reference. The structure is defined in full at the end of the file.
static xmlSAXHandler simpleSAXHandlerStruct;

#endif
@interface BlioTextFlow()

@property (nonatomic, retain) BlioTextFlowSection *currentSection;
@property (nonatomic, retain) NSMutableArray *currentPage;
@property (nonatomic, retain) BlioTextFlowParagraph *currentParagraph;
@property (nonatomic, retain) BlioTextFlowPositionedWord *currentWord;
@property (nonatomic, retain) NSString *currentWordString;
@property (nonatomic, retain) NSString *currentWordRect;

- (void)parseSectionsFileAtPath:(NSString *)path;
- (void)parseSection:(BlioTextFlowSection *)section;

@end

@implementation BlioTextFlow

@synthesize sections, pages, paragraphs;
@synthesize currentSection, currentPage, currentParagraph, currentWord, currentWordString, currentWordRect;
@synthesize done, parsingAnElement, storingCharacters, countOfParsedElements, characterBuffer, parsePool;

- (void)dealloc {
    self.sections = nil;
    self.pages = nil;
    self.paragraphs = nil;
    self.currentSection = nil;
    self.currentPage = nil;
    self.currentParagraph = nil;
    self.currentWord = nil;
    self.currentWordString = nil;
    self.currentWordRect = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {    
    if ((self = [super init])) {
        self.sections = [NSMutableSet set];
        self.pages = [NSMutableArray array];
        self.paragraphs = [NSMutableArray array];
        
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
    NSLog(@"TextFlow pageMarkers created");
//    for (BlioTextFlowSection *section in self.sections) {
//        for (BlioTextFlowPageMarker *pageMarker in [section sortedPageMarkers]) {
//            NSLog(@"%@ (%d): %d-%d", [section name], [section pageIndex], [pageMarker pageIndex], [pageMarker lineNumber]);
//        }
//    }
}

- (void)parseSectionsFileAtPath:(NSString *)path {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSData *xmlData = [NSData dataWithContentsOfMappedFile:path];
    xmlTextReaderPtr reader = xmlReaderForMemory([xmlData bytes], 
                                                 [xmlData length], 
                                                 [path UTF8String], nil, 
                                                 (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
    if (!reader) {
        NSLog(@"Failed to load xmlreader");
        return;
    }
    
    NSString *currentTagName = nil;
    NSString *currentAttributeValue = nil;
    
    char* temp;
    while (true) {
        if (!xmlTextReaderRead(reader)) break;
        switch (xmlTextReaderNodeType(reader)) {
            case XML_READER_TYPE_ELEMENT:
                //We are starting an element
                temp =  (char *)xmlTextReaderConstName(reader);
                currentTagName = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
                
                if ([currentTagName isEqualToString:@"Section"]) {
                    BlioTextFlowSection *aSection = [[BlioTextFlowSection alloc] init];
                    
                    temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"PageIndex");
                    currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
                    
                    if (nil != currentAttributeValue) {
                        [aSection setPageIndex:[currentAttributeValue intValue]];
                    }
                    
                    temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"Name");
                    currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
                    
                    if (nil != currentAttributeValue) {
                        [aSection setName:currentAttributeValue];
                    } 
                    
                    temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"Source");
                    currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
                    
                    if (nil != currentAttributeValue) {
                        NSArray *sectionArray = [currentAttributeValue componentsSeparatedByString:@"#"];
                        [aSection setPath:[[sectionArray objectAtIndex:0] stringByDeletingPathExtension]];
                        if ([sectionArray count] > 1) [aSection setAnchor:[sectionArray objectAtIndex:1]];
                        
                    }
                    
                    if (nil != aSection) {
                        [self performSelectorOnMainThread:@selector(addSection:) withObject:aSection waitUntilDone:NO];
                        [aSection release];
                    }
                }
                    
                break;
            default: continue;
        }
	}
            
    xmlFreeTextReader(reader);
    
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

- (void)parseSection:(BlioTextFlowSection *)section {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:[section path] ofType:@"xml" inDirectory:@"TextFlows"];
    //NSFileHandle *sectionFile = [NSFileHandle fileHandleForReadingAtPath:path];
    
    
    NSData *xmlData = [NSData dataWithContentsOfMappedFile:path];
    xmlTextReaderPtr reader = xmlReaderForMemory([xmlData bytes], 
                                                 [xmlData length], 
                                                 [path UTF8String], nil, 
                                                 (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
    //xmlTextReaderPtr reader = xmlReaderForFd([sectionFile fileDescriptor], [path UTF8String], nil, 
//                                             (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
    
    if (!reader) {
        NSLog(@"Failed to load xmlreader");
        return;
    }
    
    NSString *currentTagName = nil;
    NSString *currentAttributeValue = nil;
    //BlioTextFlowParagraph *currentPara;
    NSInteger currentPageIndex = -1;
    
    char* temp;
    while (true) {
        if (!xmlTextReaderRead(reader)) break;
        switch (xmlTextReaderNodeType(reader)) {
            case XML_READER_TYPE_ELEMENT:
                //We are starting an element
                temp =  (char *)xmlTextReaderConstName(reader);
                currentTagName = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
                
                if ([currentTagName isEqualToString:@"TextGroup"]) {
                    
                    temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"PageIndex");
                    currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
                    
                    if (nil == currentAttributeValue) break;        
                    NSInteger newPageIndex = [currentAttributeValue intValue];
                    if (newPageIndex < 0) break;
                    
//                    NSLog(@"TextGroup at %f with index: %d, parser line: %d, node line: %d", (float)xmlTextReaderByteConsumed(reader), newPageIndex,
//                          (int)xmlTextReaderGetParserLineNumber(reader), (int)(xmlTextReaderCurrentNode(reader)->line));
                    
                    if (newPageIndex != currentPageIndex) {
                        BlioTextFlowPageMarker *newPageMarker = [[BlioTextFlowPageMarker alloc] init];
                        [newPageMarker setPageIndex:newPageIndex];
                        [newPageMarker setLineNumber:(NSInteger)(xmlTextReaderCurrentNode(reader)->line)];
                        [section performSelectorOnMainThread:@selector(addPageMarker:) withObject:newPageMarker waitUntilDone:NO];
                        [newPageMarker release];
                        currentPageIndex = newPageIndex;
                    }
                }
                break;
            default: continue;
        }
    }
                    
    xmlFreeTextReader(reader);
    
    [pool drain];
}


- (NSArray *)paragraphsForPage:(NSInteger)pageIndex inSection:(BlioTextFlowSection *)section atMarker:(BlioTextFlowPageMarker *)pageMarker {
    NSArray *paragraphArray = nil;
    
    if (nil != [section path]) {
        NSString *sectionPath = [[NSBundle mainBundle] pathForResource:[section path] ofType:@"xml" inDirectory:@"TextFlows"];
        NSData *xmlData = [NSData dataWithContentsOfMappedFile:sectionPath];
        xmlTextReaderPtr reader = xmlReaderForMemory([xmlData bytes], 
                                                     [xmlData length], 
                                                     [sectionPath UTF8String], nil, 
                                                     (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
        if (!reader) {
            NSLog(@"Failed to load xmlreader");
            return nil;
        }
        
        NSString *currentTagName = nil;
        NSString *currentAttributeValue = nil;
        
        char* temp;
        BOOL pageProcessed = NO;
        
        while (!pageProcessed) {
            if (!xmlTextReaderRead(reader)) break;
            switch (xmlTextReaderNodeType(reader)) {
                case XML_READER_TYPE_ELEMENT:
                    //We are starting an element
                    temp =  (char *)xmlTextReaderConstName(reader);
                    currentTagName = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
                    
                    if ([currentTagName isEqualToString:@"TextGroup"]) {
                        temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"PageIndex");
                        currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
//                        NSLog(@"TextGroup with page index %@", currentAttributeValue);
                        if ([currentAttributeValue integerValue] == pageIndex) {
                            paragraphArray = [NSArray array];
                        }
                    }
                    break;
                case XML_READER_TYPE_END_ELEMENT:
                    //We are ending an element
                    if (nil != paragraphArray) {
                        temp =  (char *)xmlTextReaderConstName(reader);
                        currentTagName = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
                    
                        if ([currentTagName isEqualToString:@"TextGroup"]) {
                            temp = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar *)"PageIndex");
                            currentAttributeValue = temp ? [NSString stringWithCString:temp encoding:NSUTF8StringEncoding] : nil;
                            NSLog(@"TextGroup ended with page index %@", currentAttributeValue);
                            if ([currentAttributeValue integerValue] == pageIndex) pageProcessed = YES;
                        }
                    }
                    break;
                default: continue;
            }
        }
    }
        
    return paragraphArray;
}

#pragma mark -
#pragma mark Convenience methods

- (NSArray *)sortedSections {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortPageDescriptor, nil] autorelease];
    return [[self.sections allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex {
    NSLog(@"Request for paragraph %d", pageIndex);
    NSArray *pageParagraphs = [NSArray array];
    
    BlioTextFlowSection *targetSection = nil;
    for (BlioTextFlowSection *section in [self sortedSections]) {
        if ([section pageIndex] > pageIndex)
            break;
        else
            targetSection = section;
    }
    
    if (nil != targetSection) {
        BlioTextFlowPageMarker *targetPageMarker = nil;
        for (BlioTextFlowPageMarker *pageMarker in [targetSection sortedPageMarkers]) {
            if ([pageMarker pageIndex] == pageIndex) targetPageMarker = pageMarker;
            if ([pageMarker pageIndex] >= pageIndex) 
                break;
        }
        
        if (nil != targetPageMarker) {
            NSLog(@"Page %d is at line %d in file %@", pageIndex, [targetPageMarker lineNumber], [targetSection path]);
                            
            NSArray *pageParagraphsFromDisk = [self paragraphsForPage:pageIndex inSection:targetSection atMarker:targetPageMarker];
            if (nil != pageParagraphsFromDisk) pageParagraphs = pageParagraphsFromDisk;
            
        }

    }
    NSLog(@"Page paragraphs: %@", [pageParagraphs description]);
    
    return pageParagraphs;
    
    
    //NSArray *pageParagraphs = [NSArray array];
//    if (pageIndex < [pages count]) {
//        pageParagraphs = [pages objectAtIndex:pageIndex];
//    }
//    return pageParagraphs;
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

static const NSUInteger kAutoreleasePoolPurgeFrequency = 20;

- (void)finishedCurrentElement {
    countOfParsedElements++;
    // Periodically purge the autorelease pool. The frequency of this action may need to be tuned according to the 
    // size of the objects being parsed. The goal is to keep the autorelease pool from growing too large, but 
    // taking this action too frequently would be wasteful and reduce performance.
    if (countOfParsedElements == kAutoreleasePoolPurgeFrequency) {
        [parsePool release];
        self.parsePool = [[NSAutoreleasePool alloc] init];
        countOfParsedElements = 0;
    }
}

/*
 Character data is appended to a buffer until the current element ends.
 */
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
    [characterBuffer appendBytes:charactersFound length:length];
}

- (NSString *)currentString {
    // Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
    NSString *currentString = [[[NSString alloc] initWithData:characterBuffer encoding:NSUTF8StringEncoding] autorelease];
    [characterBuffer setLength:0];
    return currentString;
}

@end

#pragma mark SAX Parsing Callbacks

#if 0
// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.
static const char *kName_Section = "Section";
static const NSUInteger kLength_Section = 8;
static const char *kName_PageIndex = "PageIndex";
static const NSUInteger kLength_PageIndex = 10;
static const char *kName_Name = "Name";
static const NSUInteger kLength_Name = 5;
//static const char *kName_Source = "Source";
//static const NSUInteger kLength_Source = 7;
static const char *kName_TextGroup = "TextGroup";
static const NSUInteger kLength_TextGroup = 10;
static const char *kName_Text = "Text";
static const NSUInteger kLength_Text = 5;
static const char *kName_Rect = "Rect";
static const NSUInteger kLength_Rect = 5;
#endif
/*
 This callback is invoked when the parser finds the beginning of a node in the XML.
 */
#if 0
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
    // The second parameter to strncmp is the name of the element, which we known from the XML schema of the feed.
    // The third parameter to strncmp is the number of characters in the element name, plus 1 for the null terminator.
    if (prefix == NULL && !strncmp((const char *)localname, kName_Section, kLength_Section)) {
        //Song *newSong = [[Song alloc] init];
//        parser.currentSong = newSong;
//        [newSong release];
        textFlow.parsingAnElement = YES;
    } else  if (prefix == NULL && !strncmp((const char *)localname, kName_PageIndex, kLength_PageIndex)) {
        
        textFlow.parsingAnElement = YES;
    } else  if (prefix == NULL && !strncmp((const char *)localname, kName_Name, kLength_Name)) {
        
        textFlow.parsingAnElement = YES;
    } else  if (prefix != NULL && !strncmp((const char *)localname, kName_Text, kLength_Text)) {
        
        textFlow.parsingAnElement = YES;
    } else  if (prefix != NULL && !strncmp((const char *)localname, kName_Rect, kLength_Rect)) {
        
        textFlow.parsingAnElement = YES;
    } else if (textFlow.parsingAnElement) {
        textFlow.storingCharacters = YES;
    }
}

/*
 This callback is invoked when the parse reaches the end of a node. For the nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that..
 */
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
    if (textFlow.parsingAnElement == NO) return;
    
    // Prefix denotes...?
    if (prefix == NULL) {
        if (!strncmp((const char *)localname, kName_Section, kLength_Section)) {
            //[parser finishedCurrentSong];
            textFlow.parsingAnElement = NO;
        } else if (!strncmp((const char *)localname, kName_PageIndex, kLength_PageIndex)) {
            //parser.currentSong.title = [parser currentString];
        } else if (!strncmp((const char *)localname, kName_Name, kLength_Name)) {
            //parser.currentSong.category = [parser currentString];
        }
    } else if (!strncmp((const char *)prefix, kName_TextGroup, kLength_TextGroup)) {
        if (!strncmp((const char *)localname, kName_Text, kLength_Text)) {
            //parser.currentSong.artist = [parser currentString];
        } else if (!strncmp((const char *)localname, kName_Rect, kLength_Rect)) {
            //parser.currentSong.album = [parser currentString];
        }
    }
    textFlow.storingCharacters = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The parser class determines how to use the character data.
 */
static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    BlioTextFlow *textFlow = (BlioTextFlow *)ctx;
    // A state variable, "storingCharacters", is set when nodes of interest begin and end. 
    // This determines whether character data is handled or ignored. 
    if (textFlow.storingCharacters == NO) return;
    [textFlow appendCharacters:(const char *)ch length:len];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
    // Handle errors as appropriate for your application.
    NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}

// The handler struct has positions for a large number of callback functions. If NULL is supplied at a given position,
// that callback functionality won't be used. Refer to libxml documentation at http://www.xmlsoft.org for more information
// about the SAX callbacks.
static xmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};
#endif
