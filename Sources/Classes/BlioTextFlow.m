//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"

@interface BlioTextFlow()

@property (nonatomic, retain) NSXMLParser *textFlowParser;
@property (nonatomic, retain) BlioTextFlowSection *currentSection;
@property (nonatomic, retain) NSMutableArray *currentPage;
@property (nonatomic, retain) BlioTextFlowParagraph *currentParagraph;
@property (nonatomic, retain) BlioTextFlowPositionedWord *currentWord;
@property (nonatomic, retain) NSString *currentWordString;
@property (nonatomic, retain) NSString *currentWordRect;

@end

@implementation BlioTextFlow

@synthesize textFlowParser, sections, pages, paragraphs;
@synthesize currentSection, currentPage, currentParagraph, currentWord, currentWordString, currentWordRect;

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

- (id)init {        
    if ((self = [super init])) {
        self.sections = [NSMutableArray array];
        self.pages = [NSMutableArray array];
        self.paragraphs = [NSMutableArray array];
    }
    
    return self;
}

- (void)addFlowViewFileAtPath:(NSString *)path {
    if (nil == path) {
        return;
    } else if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"Error: FlowView file does not exist at path: %@", path);
        return;
    }

    BOOL success;
    NSURL *xmlURL = [NSURL fileURLWithPath:path];

    NSXMLParser *aTextFlowParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [aTextFlowParser setDelegate:self];
    success = [aTextFlowParser parse];
    self.textFlowParser = aTextFlowParser;
    [aTextFlowParser release];
    
    if (success)
        NSLog(@"TextFlow parsed successfully");
    else
        NSLog(@"TextFlow file at path: %@ failed to parse", path);
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
    NSLog(@"TextFlow parsing error %i, Description: %@, Line: %i, Column: %i", [parseError code],
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
        if (sectionName) [self.currentSection setString:sectionName];
        
    } else if ([elementName isEqualToString:@"Paragraph"]) {
        BlioTextFlowParagraph *aParagraph = [[BlioTextFlowParagraph alloc] init];
        self.currentParagraph = aParagraph;
        [aParagraph release];
        
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
            }
        }
    } else if ([elementName isEqualToString:@"Word"]) {
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
            [newWord release];
        }
    }

    [pool drain];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Ignore <BookContents> and <Flow> elements currently
    if (([elementName isEqualToString:@"BookContents"]) ||
        ([elementName isEqualToString:@"Flow"])) {
        // Do nothing
    } else if ( [elementName isEqualToString:@"Section"] ) {
        [self.sections addObject:self.currentSection];
        self.currentSection = nil;
    } else if ( [elementName isEqualToString:@"Paragraph"] ) {
        [self.paragraphs addObject:self.currentParagraph];
        [self.currentPage addObject:self.currentParagraph];
        self.currentParagraph = nil;
    }
    
    [pool drain];
}
        
@end

@implementation BlioTextFlowPositionedWord

@synthesize string, rect;

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}

@end

@implementation BlioTextFlowSection

@synthesize pageIndex, string;

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}

@end

@implementation BlioTextFlowParagraph

@synthesize pageIndex, words;

- (void)dealloc {
    self.words = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        self.words = [NSMutableArray array];
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
            if (CGRectIsNull(rect))
                rect = word.rect;
            else
                rect = CGRectUnion(rect, word.rect);
        }
    }
    return rect;
}

@end