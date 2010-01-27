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

- (BOOL)parseFileAtPath:(NSString *)path;

@end

@implementation BlioTextFlow

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
    NSLog(@"TextFlow parsing error %i, File: %@, Description: %@, Line: %i, Column: %i", [parseError code], [self.currentSection path],
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
                    if (![self.currentPage containsObject:self.currentParagraph])
                        [self.currentPage addObject:self.currentParagraph];
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

@synthesize string, rect;

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}

@end

@implementation BlioTextFlowSection

@synthesize pageIndex, name, path, anchor;

- (void)dealloc {
    self.name = nil;
    self.path = nil;
    self.anchor = nil;
    [super dealloc];
}

@end

@implementation BlioTextFlowParagraph

@synthesize pageIndex, words, folio;

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
            if (CGRectIsNull(rect))
                rect = word.rect;
            else
                rect = CGRectUnion(rect, word.rect);
        }
    }
    return rect;
}

@end