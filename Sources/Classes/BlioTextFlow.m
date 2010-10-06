//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"
#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowXAMLTree.h"
#import "BlioProcessing.h"
#import "BlioBookManager.h"
#import "NSArray+BlioAdditions.h"
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/EucChapterNameFormatting.h>

#import <sys/stat.h>

@interface BlioTextFlowPreParseOperation : BlioProcessingOperation
@end

@implementation BlioTextFlowPositionedWord

@synthesize string, rect, blockID, wordIndex, wordID;

- (void)dealloc {
    self.string = nil;
    self.blockID = nil;
    self.wordID = nil;
    [super dealloc];
}

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs {
    if ([[self blockID] compare:[rhs blockID]] == NSOrderedSame) {
        if ([self wordIndex] < [rhs wordIndex]) {
            return NSOrderedAscending;
        } else if ([self wordIndex] > [rhs wordIndex]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    } else {
        return [[self blockID] compare:[rhs blockID]];
    }
}

+ (NSUInteger)wordIndexForWordID:(id)aWordID {
    NSNumber *wordIDNum = (NSNumber *)aWordID;
    return [wordIDNum unsignedIntegerValue];
}

+ (id)wordIDForWordIndex:(NSUInteger)aWordIndex {
    return [NSNumber numberWithUnsignedInteger:aWordIndex];
}

@end

@interface BlioTextFlowPageRange()
@property (nonatomic, assign) XML_Parser *currentParser;
@property (nonatomic) NSInteger currentPageIndex;
@end


@implementation BlioTextFlowPageRange

@synthesize startPageIndex, endPageIndex, pageMarkers;
@synthesize currentParser, currentPageIndex;
//@synthesize path;
@synthesize fileName;

- (id)init {
    if ((self = [super init])) {
        self.pageMarkers = [NSMutableSet set];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        self.startPageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageRangePageIndex"];
        self.endPageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageRangeEndPageIndex"];
        //self.path = [coder decodeObjectForKey:@"BlioTextFlowPageRangePagePath"];
        self.fileName = [coder decodeObjectForKey:@"BlioTextFlowPageRangePageFileName"];
        self.pageMarkers = [NSMutableSet setWithSet:[coder decodeObjectForKey:@"BlioTextFlowPageRangeImmutablePageMarkers"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.startPageIndex forKey:@"BlioTextFlowPageRangePageIndex"];
    [coder encodeInteger:self.endPageIndex forKey:@"BlioTextFlowPageRangeEndPageIndex"];
    //[coder encodeObject:self.path forKey:@"BlioTextFlowPageRangePagePath"];
    [coder encodeObject:self.fileName forKey:@"BlioTextFlowPageRangePageFileName"];
    [coder encodeObject:[NSSet setWithSet:self.pageMarkers] forKey:@"BlioTextFlowPageRangeImmutablePageMarkers"];
}

- (void)dealloc {
    //self.path = nil;
    self.fileName = nil;
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

@implementation BlioTextFlowBlock

@synthesize pageIndex, blockIndex, blockID, words, folio;

- (void)dealloc {
    self.words = nil;
    self.blockID = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        self.words = [NSMutableArray array];
        self.folio = NO;
    }
    return self;
}

- (NSArray *)wordStrings {
    NSMutableArray *allWordStrings = [NSMutableArray arrayWithCapacity:[self.words count]];
    for (BlioTextFlowPositionedWord *word in self.words) {
        [allWordStrings addObject:word.string];
    }
    return allWordStrings;
}

- (NSString *)string {
    return [[self wordStrings] componentsJoinedByString:@" "];
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

- (NSComparisonResult)compare:(BlioTextFlowBlock *)rhs {
    return [self.blockID compare:rhs.blockID];
}

+ (NSInteger)pageIndexForBlockID:(id)aBlockID {
    return [(NSIndexPath *)aBlockID section];
}

+ (NSInteger)blockIndexForBlockID:(id)aBlockID {
    return [(NSIndexPath *)aBlockID row];
}

+ (id)blockIDForPageIndex:(NSInteger)aPageIndex blockIndex:(NSInteger)aBlockIndex {
    return [NSIndexPath indexPathForRow:aBlockIndex inSection:aPageIndex];
}

@end


@interface BlioTextFlowFlowReference ()

@property (nonatomic, assign) NSUInteger startPage;
@property (nonatomic, retain) NSString *flowSourceFileName;

@end

@implementation BlioTextFlowFlowReference

@synthesize flowSourceFileName, startPage;

- (void)dealloc {
    self.flowSourceFileName = nil;
    [super dealloc];
}

@end


@interface BlioTextFlowTOCEntry ()

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) NSUInteger startPage;
@property (nonatomic, assign) NSUInteger level;

@end

@implementation BlioTextFlowTOCEntry

@synthesize name, startPage, level;

- (void)dealloc {
    self.name = nil;
    [super dealloc];
}

@end


@interface BlioTextFlow()

@property (nonatomic, assign, readonly) BlioBook *book;
@property (nonatomic, retain) NSSet *pageRanges;
@property (nonatomic, retain) NSArray *flowReferences;
@property (nonatomic, retain) NSArray *tableOfContents;

@property (nonatomic, assign) BlioTextFlowFlowTreeKind flowTreeKind;

- (NSArray *)blocksForPage:(NSInteger)pageIndex inPageRange:(BlioTextFlowPageRange *)pageRange targetMarker:(BlioTextFlowPageMarker *)targetMarker firstMarker:(BlioTextFlowPageMarker *)firstMarker;

@end

@implementation BlioTextFlow

@synthesize pageRanges;
@synthesize flowReferences; // Lazily loaded - see -(NSArray *)flowReferences
@synthesize tableOfContents; // Lazily loaded - see -(NSArray *)tableOfContents
@synthesize bookID;

- (void)dealloc {
    self.pageRanges = nil;
    self.flowReferences = nil;
    [pageBlocksCacheLock release];
    
    for(NSUInteger i = 0; i < kTextFlowPageBlocksCacheCapacity; ++i) {
        [pageBlocksCache[i] release];
    }
    
    self.bookID = nil;
    
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    if ((self = [super init])) {
        self.bookID = aBookID;
        self.pageRanges = [self.book valueForKey:@"textFlowPageRanges"] ;
        pageBlocksCacheLock = [[NSLock alloc] init];
    }
    return self;
} 

#pragma mark -
#pragma mark Fragment XML (block) parsing

typedef struct FragmentParsingContext {
    XML_Parser parser;
    NSInteger pageIndex;
    BlioTextFlowBlock *block;
    NSMutableArray *blockArray;
} FragmentParsingContext;

static void fragmentXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    FragmentParsingContext *context = (FragmentParsingContext *)ctx;

    if (strcmp("Page", name) == 0) {
        NSInteger targetIndex = context->pageIndex;
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    NSInteger newIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                    if (newIndex == targetIndex) {
                        if (!context->blockArray) {
                            context->blockArray = [[NSMutableArray alloc] init];
                        }
                    } else if (newIndex > targetIndex) {
                        XML_StopParser(context->parser, false);
                        return;
                    } else {
                        return;
                    }
                }
            }
        }
                
    } else if (strcmp("Block", name) == 0) {
        BOOL folio = NO;
        NSString *newBlockIDString = nil;
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("ID", atts[i]) == 0) {
                if (newBlockIDString) {
                    [newBlockIDString release];
                }
                newBlockIDString = [[NSString alloc] initWithUTF8String:atts[i+1]];
            } else if (strcmp("Folio", atts[i]) == 0) {
                folio = (strcmp("True", atts[i+1]) == 0);
            } else if (strcmp("Surround", atts[i]) == 0) {
                folio = (strcmp("True", atts[i+1]) == 0);
            }
            
        }
        
        NSInteger targetIndex = context->pageIndex;
        NSMutableArray *blockArray = context->blockArray;
        
        NSUInteger newBlockIndex = [blockArray count];
        if (newBlockIndex != [newBlockIDString integerValue]) {
            NSLog(@"Warning: block read with unexpected index - \"%@\" expected \"%ld\", will cause incorrect flow conversion.", newBlockIDString, newBlockIndex);
        }
            
        BlioTextFlowBlock *block = [[BlioTextFlowBlock alloc] init];
        [block setPageIndex:targetIndex];
        [block setBlockIndex:newBlockIndex];
        NSIndexPath *blockID = [BlioTextFlowBlock blockIDForPageIndex:targetIndex blockIndex:newBlockIndex];
        [block setBlockID:blockID];
        [block setFolio:folio];
        [blockArray addObject:block];
        [context->block release];
        context->block = block;
        
        [newBlockIDString release];
    } else if (strcmp("Word", name) == 0) {
        NSString *textString = nil;
        long rect[4];
        BOOL rectFound = NO;
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("Text", atts[i]) == 0) {
                if (textString) {
                    [textString release];
                }
                textString = [[NSString alloc] initWithUTF8String:atts[i+1]];
            } else if (strcmp("Rect", atts[i]) == 0) {
                if (4 == sscanf(atts[i+1], " %ld , %ld , %ld , %ld ", &rect[0], &rect[1], &rect[2], &rect[3])) {
                    rectFound = YES; 
                }
            }
        }
                
        if (textString) {
            if(rectFound) {
                BlioTextFlowBlock *block = context->block;
                BlioTextFlowPositionedWord *newWord = [[BlioTextFlowPositionedWord alloc] init];
                [newWord setString:textString];
                [newWord setRect:CGRectMake(rect[0], rect[1], rect[2], rect[3])];
                
                [newWord setBlockID:[block blockID]];
                NSInteger index = [[block words] count];
                [newWord setWordIndex:index];
                [newWord setWordID:[NSNumber numberWithInteger:index]];
                [[block words] addObject:newWord];
                [newWord release];
            }                
            [textString release];
        }
    }
}

static void fragmentXMLParsingEndElementHandler(void *ctx, const XML_Char *name)  {
    if(strcmp("Flow", name) == 0) {
        XML_StopParser(((FragmentParsingContext *)ctx)->parser, false);
    }
}

- (NSArray *)blocksForPage:(NSInteger)pageIndex inPageRange:(BlioTextFlowPageRange *)pageRange targetMarker:(BlioTextFlowPageMarker *)targetMarker firstMarker:(BlioTextFlowPageMarker *)firstMarker {
    
    //NSData *data = [self.book manifestDataForKey:[pageRange fileName]];
    NSData *data = [self.book textFlowDataWithPath:[pageRange fileName]];
    
        if (nil == data) return nil;
        
        NSUInteger dataLength = [data length];
        NSUInteger offset = (NSUInteger)[targetMarker byteIndex];
        if (offset >= dataLength) {
            [data release];
            return nil;
        }
        
        FragmentParsingContext context = {0};
        context.parser = XML_ParserCreate(NULL);
        context.pageIndex = [targetMarker pageIndex];

        XML_SetStartElementHandler(context.parser, fragmentXMLParsingStartElementHandler);
        XML_SetEndElementHandler(context.parser, fragmentXMLParsingEndElementHandler);
        XML_SetUserData(context.parser, &context);  
        
        // Parse anything before the first marker in the file
        NSUInteger firstFragmentLength = [firstMarker byteIndex] - 1;
        if (!XML_Parse(context.parser, [data bytes], firstFragmentLength - 1, XML_FALSE)) {
            enum XML_Error errorCode = XML_GetErrorCode(context.parser);
            if (errorCode != XML_ERROR_ABORTED) {
                char *error = (char *)XML_ErrorString(errorCode);
                NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, [pageRange fileName]);
            }
        }
        
        if ((dataLength - offset) < 0) {
            NSLog(@"offset is too large");
            return nil;
        }
        
        NSUInteger targetFragmentLength = dataLength - offset;
        const void* offsetBytes = [data bytes] + offset;
          
        @try {
            if (!XML_Parse(context.parser, offsetBytes, targetFragmentLength, XML_FALSE)) {
                enum XML_Error errorCode = XML_GetErrorCode(context.parser);
                if (errorCode != XML_ERROR_ABORTED) {
                    char *error = (char *)XML_ErrorString(errorCode);
                    NSLog(@"TextFlow parsing error: '%s' in file: '%@'", error, [pageRange fileName]);
                }
            }
        }
        @catch (NSException * e) {
            NSLog(@"TextFlow parsing exception: '%@' in file: '%@'", e.userInfo, [pageRange fileName]);
        }
        
        @try {
            XML_ParserFree(context.parser);
        } @catch (NSException * e) {
            NSLog(@"TextFlow parser freeing exception: '%@'.", e.userInfo);
        }

        [context.block release];
        
        return [context.blockArray autorelease];

    
    return nil;
}


#pragma mark -
#pragma mark Sections XML parsing

typedef struct BlioTextFlowSectionsXMLParsingContext
{
    NSMutableArray *buildTableOfContents;
    NSMutableArray *buildFlowReferences;
} BlioTextFlowSectionsXMLParsingContext;

static void sectionsXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) {
    BlioTextFlowSectionsXMLParsingContext *context = (BlioTextFlowSectionsXMLParsingContext *)ctx;
    
    if (strcmp("Section", name) == 0) {
        BlioTextFlowTOCEntry *tocEntry = [[BlioTextFlowTOCEntry alloc] init];
        
        BOOL pageIndexFound = NO;
        BOOL nameFound = NO;
                
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                tocEntry.startPage = atoi(atts[i+1]);
                pageIndexFound = YES;
            } else if (strcmp("Name", atts[i]) == 0) {
                NSString *nameString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != nameString) {
                    if(nameString.length) {
                        tocEntry.name = nameString;
                        nameFound = YES;
                    }
                    [nameString release];
                }
            } else if (strcmp("Level", atts[i]) == 0) {
                tocEntry.level = atoi(atts[i+1]);
            }
        }
        
        if(pageIndexFound && nameFound) {
            [context->buildTableOfContents addObject:tocEntry];
        } else {
            if(!pageIndexFound) {
                NSLog(@"Warning - Section with no page index - ignoring");
            }
            if(!nameFound) {
                NSLog(@"Warning - Section with no name - ignoring.");
            }
        }
        [tocEntry release];
    } else if (strcmp("FlowReference", name) == 0) {
        BlioTextFlowFlowReference *newSection = [[BlioTextFlowFlowReference alloc] init];

        BOOL pageIndexFound = NO;
        BOOL flowSourceFound = NO;
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndices", atts[i]) == 0) {
                newSection.startPage = atoi(atts[i+1]);
                pageIndexFound = YES;
            } else if (strcmp("Source", atts[i]) == 0) {
                NSString *sourceString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != sourceString) {
                    newSection.flowSourceFileName = sourceString;
                    [sourceString release];
                    flowSourceFound = YES;
                }                
            }
        }
        
        if(pageIndexFound && flowSourceFound) {
            [context->buildFlowReferences addObject:newSection];
        } else {
            if(!pageIndexFound) {
                NSLog(@"Warning - FlowReference with no page index - ignoring");
            }
            if(!flowSourceFound) {
                NSLog(@"Warning - FlowReference with no source - ignoring");
            }
        }
        [newSection release];
    }
}

static int tocEntryCompare(BlioTextFlowTOCEntry **rhs, BlioTextFlowTOCEntry **lhs) 
{
    return (int)(*rhs).startPage - (int)(*lhs).startPage;
}

- (void)parseSectionsXML
{
    BlioTextFlowSectionsXMLParsingContext context = { [NSMutableArray array], [NSMutableArray array] };

    BlioBook *aBook = self.book;
    NSData *data = [aBook manifestDataForKey:BlioManifestTextFlowKey];
    
    if(data) {
        XML_Parser flowParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(flowParser, sectionsXMLParsingStartElementHandler);
        
        XML_SetUserData(flowParser,&context);    
        if (!XML_Parse(flowParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(flowParser));
            NSLog(@"TextFlow sections parsing error: '%s'", anError);
        }
        XML_ParserFree(flowParser);
    }
    
    self.flowReferences = context.buildFlowReferences;
    
    // If there are no TOC entries for page index 0, add an artificial one.
    BOOL makeArtificialFrontEnrty = YES;
    for(BlioTextFlowTOCEntry *entry in context.buildTableOfContents) {
        if(entry.startPage == 0) {
            makeArtificialFrontEnrty = NO;
        }
    }
    if(makeArtificialFrontEnrty) {
        BlioTextFlowTOCEntry *tocEntry = [[BlioTextFlowTOCEntry alloc] init];
        tocEntry.name = NSLocalizedString(@"Front of book", @"Name for the single table-of-contents entry for the front page of a book that does not specify a TOC entry for the front page");
        [context.buildTableOfContents addObject:tocEntry];
        [tocEntry release];
    }

    self.tableOfContents = [context.buildTableOfContents blioStableSortedArrayUsingFunction:(int (*)(id *arg1, id *arg2))tocEntryCompare];
}

- (NSArray *)flowReferences
{
    if(!flowReferences) {
        [self parseSectionsXML];
    }
    return flowReferences;
}

- (NSArray *)tableOfContents
{
    if(!tableOfContents) {
        [self parseSectionsXML];
    }
    return tableOfContents;
}

- (BlioBook *)book {
    return [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
}

#pragma mark -
#pragma mark Flow Tree

@synthesize flowTreeKind;

struct FlowDetectionParsingContext
{
    XML_Parser parser;
    BlioTextFlowFlowTreeKind flowTreeKind;
};

static void flowDetectionXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) {
    if(strcmp("Flow", name) == 0) {
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("xmlns", atts[i]) == 0) {
                if(strcasestr(atts[i+1], "xaml") != NULL) {
                    ((struct FlowDetectionParsingContext *)ctx)->flowTreeKind =  BlioTextFlowFlowTreeKindXaml;
                }
            }
        }
        XML_StopParser(((struct FlowDetectionParsingContext *)ctx)->parser, XML_FALSE);
    }
}

- (BlioTextFlowFlowTreeKind)flowTreeKind {
    if(flowTreeKind == BlioTextFlowFlowTreeKindUnknown) {
        NSArray *allSections = self.flowReferences;
        if(allSections.count) {
            BlioTextFlowFlowReference *firstSection = [allSections objectAtIndex:0];
            NSData *data = [self.book textFlowDataWithPath:firstSection.flowSourceFileName];
            if(data) {
                XML_Parser flowDetectionParser = XML_ParserCreate(NULL);
                XML_SetStartElementHandler(flowDetectionParser, flowDetectionXMLParsingStartElementHandler);
                struct FlowDetectionParsingContext context = { flowDetectionParser, BlioTextFlowFlowTreeKindUnknown };
                XML_SetUserData(flowDetectionParser, &context); 
                enum XML_Error error = XML_ERROR_NONE;
                if(!XML_Parse(flowDetectionParser, [data bytes], [data length], XML_TRUE) &&
                   (error = XML_GetErrorCode(flowDetectionParser)) != XML_ERROR_ABORTED) {
                    char *anError = (char *)XML_ErrorString(error);
                    NSLog(@"TextFlow parsing error: '%s' in metadata file", anError);
                } else {
                    self.flowTreeKind = context.flowTreeKind;
                }
                XML_ParserFree(flowDetectionParser);
            }             
        }
    }
    if(flowTreeKind == BlioTextFlowFlowTreeKindUnknown) {
        flowTreeKind = BlioTextFlowFlowTreeKindFlow;
    }
    return flowTreeKind;
}

- (BlioTextFlowFlowTree *)flowTreeForFlowIndex:(NSUInteger)index {
    BlioTextFlowFlowTree *tree = nil;
 
    if(self.flowTreeKind == BlioTextFlowFlowTreeKindFlow) {
        NSArray *allFlowReferences = self.flowReferences;
        if(index < allFlowReferences.count) {
            BlioTextFlowFlowReference *flowReference = [allFlowReferences objectAtIndex:index];

            NSData *data = [self.book textFlowDataWithPath:flowReference.flowSourceFileName];
                        
            if(data) {
                tree = [[BlioTextFlowFlowTree alloc] initWithTextFlow:self
                                                                 data:data];
            }
        }
        [tree autorelease];
    }
    
    return tree;
}

- (BlioTextFlowXAMLTree *)xamlTreeForFlowIndex:(NSUInteger)index {
    BlioTextFlowXAMLTree *tree = nil;
    
    if(self.flowTreeKind == BlioTextFlowFlowTreeKindXaml) {
        NSArray *allFlowReferences = self.flowReferences;
        if(index < allFlowReferences.count) {
            BlioTextFlowFlowReference *flowReference = [allFlowReferences objectAtIndex:index];
            
            NSData *data = [self.book textFlowDataWithPath:flowReference.flowSourceFileName];
            
            if(data) {
                tree = [[BlioTextFlowXAMLTree alloc] initWithData:data];
            }
        }
        [tree autorelease];
    }
    
    return tree;    
}

#pragma mark -
#pragma mark Convenience methods

- (NSArray *)sortedPageRanges {
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"startPageIndex" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortPageDescriptor, nil] autorelease];
    return [[self.pageRanges allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)calculateBlocksForPageAtIndex:(NSInteger)pageIndex {
    
    NSArray *pageBlocks = nil;
    
    BlioTextFlowPageRange *targetPageRange = nil;
    NSArray *sortedPageRanges = [self sortedPageRanges];
    NSUInteger pageRangeCount = sortedPageRanges.count;
    NSUInteger i = 0;
    for (; i < pageRangeCount; ++i) {
        BlioTextFlowPageRange *pageRange = [sortedPageRanges objectAtIndex:i];
        if ([pageRange startPageIndex] > pageIndex)
            break;
        else
            targetPageRange = pageRange;
    }
    
    BOOL inLastPageRange = (i == pageRangeCount);
    BOOL afterLastPageMarker = NO;
    
    if (nil != targetPageRange) {
        BlioTextFlowPageMarker *targetMarker = nil;
        BlioTextFlowPageMarker *firstMarker = nil;
        
        NSArray *sortedPageMarkers = [targetPageRange sortedPageMarkers];
        NSUInteger i = 0;
        NSUInteger sortedPageMarkersCount = [sortedPageMarkers count];
        for (; i < sortedPageMarkersCount; i++) {
            BlioTextFlowPageMarker *pageMarker = [sortedPageMarkers objectAtIndex:i];
            if (i == 0) firstMarker = pageMarker;
            if ([pageMarker pageIndex] == pageIndex) targetMarker = pageMarker;
            if ([pageMarker pageIndex] >= pageIndex) 
                break;
        }
        
        if (!targetMarker && i == sortedPageMarkersCount) {
            afterLastPageMarker = YES;
        }
        
        if ((nil != targetMarker) && (nil != firstMarker)) {
            NSArray *pageBlocksFromDisk = [self blocksForPage:pageIndex inPageRange:targetPageRange targetMarker:targetMarker firstMarker:firstMarker];
            if (nil != pageBlocksFromDisk) pageBlocks = pageBlocksFromDisk;
        }
    }
    
    if (!pageBlocks && (!inLastPageRange || !afterLastPageMarker)) {
        // We haven't found blocks for this page, but we're also
        // not past the end of the book, so return an empty array.
        pageBlocks = [NSArray array];
    }
    
    return pageBlocks;
}

- (NSArray *)blocksForPageAtIndex:(NSInteger)pageIndex includingFolioBlocks:(BOOL)includingFolioBlocks {
    NSArray *ret = nil;
    
    [pageBlocksCacheLock lock];
    {
        NSUInteger cacheIndex = NSUIntegerMax;
        for(NSUInteger i = 0; i < kTextFlowPageBlocksCacheCapacity; ++i) {
            if(pageIndexCache[i] == pageIndex) {
                cacheIndex = i;
                break;
            }
        }
        
        if(cacheIndex != NSUIntegerMax) {
            ret = [pageBlocksCache[cacheIndex] autorelease];
            if(ret) {
                size_t toMove = kTextFlowPageBlocksCacheCapacity - cacheIndex - 1;
                if(toMove) {
                    memmove(pageIndexCache + cacheIndex, pageIndexCache + cacheIndex + 1, toMove * sizeof(NSInteger));
                    memmove(pageBlocksCache + cacheIndex, pageBlocksCache + cacheIndex + 1, toMove * sizeof(NSArray *));
                } 
            }
        } 
        
        if(!ret) {
            //if(pageBlocksCache[0]) {
            //    NSLog(@"Discarding cached blocks for layout page %ld", (long)pageIndexCache[0]);
            //}
            [pageBlocksCache[0] release];
            memmove(pageIndexCache, pageIndexCache + 1, sizeof(NSInteger) * (kTextFlowPageBlocksCacheCapacity - 1));
            memmove(pageBlocksCache, pageBlocksCache + 1, sizeof(NSArray *) * (kTextFlowPageBlocksCacheCapacity - 1));
            
            ret = [self calculateBlocksForPageAtIndex:pageIndex];
            //NSLog(@"Generating blocks for layout page %ld", (long)pageIndex);
        } //else {
            //NSLog(@"Using cached blocks for layout page %ld", (long)pageIndex);
        //}
        
        pageBlocksCache[kTextFlowPageBlocksCacheCapacity - 1] = [ret retain];
        pageIndexCache[kTextFlowPageBlocksCacheCapacity - 1] = pageIndex;
        
    }
    [pageBlocksCacheLock unlock];

    if(!includingFolioBlocks) {
        return [ret filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isFolio == NO"]];
    } else {
        return ret;
    }
}

- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage {
    NSUInteger currentBlockIndex = block.blockIndex;
    NSUInteger pageIndex = block.pageIndex;

    BlioTextFlowBlock *newBlock;
    if(onSamePage) {
        NSArray *blocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
        do {
            newBlock = nil;
            ++currentBlockIndex;
            if(blocks.count > currentBlockIndex) {
                newBlock = [blocks objectAtIndex:currentBlockIndex];
            }
        } while(newBlock && (!includingFolioBlocks && newBlock.isFolio));
    } else {
        do {
            newBlock = nil;
            ++currentBlockIndex;
            NSArray *blocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
            while(blocks && blocks.count < currentBlockIndex) {
                currentBlockIndex = 0;
                ++pageIndex;
                blocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
            }
            if(blocks) {
                newBlock = [blocks objectAtIndex:currentBlockIndex];
            }
        } while(newBlock && (!includingFolioBlocks && newBlock.isFolio));
    }
    
    return newBlock;
}


- (BlioTextFlowBlock *)previousBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage {
    NSUInteger currentBlockIndex = block.blockIndex;
    NSUInteger pageIndex = block.pageIndex;
    
    BlioTextFlowBlock *newBlock = nil;
    if(onSamePage) {
        NSArray *blocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
        while(currentBlockIndex > 0 && !newBlock) {
            --currentBlockIndex;
            newBlock = [blocks objectAtIndex:currentBlockIndex];
            if(!includingFolioBlocks && newBlock.isFolio) {
                newBlock = nil; 
            }                
        }
    } else {  
        ++pageIndex;
        do {
            --pageIndex;
            NSArray *blocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
            while(currentBlockIndex > 0 && !newBlock) {
                --currentBlockIndex;
                newBlock = [blocks objectAtIndex:currentBlockIndex];
                if(!includingFolioBlocks && newBlock.isFolio) {
                    newBlock = nil; 
                }                
            }
        } while(!newBlock && pageIndex != 0);
    }
    
    return newBlock;
}


- (NSArray *)wordStringsForPageAtIndex:(NSInteger)pageIndex {
    NSMutableArray *wordsArray = [NSMutableArray array];
    
    for (BlioTextFlowBlock *block in [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
        [wordsArray addObjectsFromArray:[block wordStrings]];
    }
    
    return [NSArray arrayWithArray:wordsArray];
}

- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range {
    NSMutableArray *allWords = [NSMutableArray array];
    
    for (NSInteger pageNumber = range.startPoint.layoutPage; pageNumber <= range.endPoint.layoutPage; pageNumber++) {
        NSInteger pageIndex = pageNumber - 1;
        
        for (BlioTextFlowBlock *block in [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
            if (![block isFolio]) {
                for (BlioTextFlowPositionedWord *word in [block words]) {
                    if ((range.startPoint.layoutPage < pageNumber) &&
                        (block.blockIndex <= range.endPoint.blockOffset) &&
                        (word.wordIndex <= range.endPoint.wordOffset)) {
                        
                        [allWords addObject:word];
                        
                    } else if ((range.endPoint.layoutPage > pageNumber) &&
                               (block.blockIndex >= range.startPoint.blockOffset) &&
                               (word.wordIndex >= range.startPoint.wordOffset)) {
                        
                        [allWords addObject:word];
                        
                    } else if ((range.startPoint.layoutPage == pageNumber) &&
                               (block.blockIndex == range.startPoint.blockOffset) &&
                               (word.wordIndex >= range.startPoint.wordOffset)) {
                        
                        if ((block.blockIndex == range.endPoint.blockOffset) &&
                            (word.wordIndex <= range.endPoint.wordOffset)) {
                            [allWords addObject:word];
                        } else if (block.blockIndex < range.endPoint.blockOffset) {
                            [allWords addObject:word];
                        }
                        
                    } else if ((range.startPoint.layoutPage == pageNumber) &&
                               (block.blockIndex > range.startPoint.blockOffset)) {
                        
                        if ((block.blockIndex == range.endPoint.blockOffset) &&
                            (word.wordIndex <= range.endPoint.wordOffset)) {
                            [allWords addObject:word];
                        } else if (block.blockIndex < range.endPoint.blockOffset) {
                            [allWords addObject:word];
                        }
                        
                    }
                }
            }
        }
    }
    
    return allWords;
}

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    return [[self wordsForBookmarkRange:range] valueForKey:@"string"];
}

- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex {
    NSMutableString *pageString = [NSMutableString string];
    NSArray *pageBlocks = [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
    for (BlioTextFlowBlock *block in pageBlocks) {
        if ([pageString length])
            [pageString appendFormat:@"\n\n%@", block.string];
        else 
            [pageString appendString:block.string];
    }
    return pageString;
}

- (NSUInteger)lastPageIndex
{
    return [[[self sortedPageRanges] lastObject] endPageIndex];
}

+ (NSArray *)preAvailabilityOperations {
    BlioTextFlowPreParseOperation *preParseOp = [[BlioTextFlowPreParseOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}


#pragma mark -
#pragma mark Contents Data Source protocol methods

- (NSArray *)sectionUuids
{
    NSUInteger sectionCount = self.tableOfContents.count;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:sectionCount];
    for(NSUInteger i = 0; i < sectionCount; ++i) {
        [array addObject:[[NSNumber numberWithUnsignedInteger:i] stringValue]];
    }
    return [array autorelease];
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page
{
    NSUInteger pageIndex = page - 1;
    NSUInteger sectionIndex = 0;
    NSUInteger nextSectionIndex = 0;
    for(BlioTextFlowTOCEntry *section in self.tableOfContents) {
        if(section.startPage <= pageIndex) {
            sectionIndex = nextSectionIndex;
            ++nextSectionIndex;
        } else {
            break;
        }
    }
    return [[NSNumber numberWithUnsignedInteger:sectionIndex] stringValue];
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid
{
    NSUInteger sectionIndex = [sectionUuid integerValue];
    NSString *sectionName = [[self.tableOfContents objectAtIndex:sectionIndex] name];
    if (sectionName) {
        return [sectionName splitAndFormattedChapterName];
    } else {
        NSString *sectionString;
        NSUInteger startPage = [[self.tableOfContents objectAtIndex:sectionIndex] startPage];
        if (startPage < 1) {
            sectionString = NSLocalizedString(@"Front of Book", @"TOC section string for missing section name without page");
        } else {
            sectionString = [NSString stringWithFormat:NSLocalizedString(@"Page %@", @"TOC section string for missing section name with page number"), [self displayPageNumberForPageNumber:startPage]];
        }
        return [sectionString splitAndFormattedChapterName];
    }
}

- (NSUInteger)pageNumberForSectionUuid:(NSString *)sectionUuid
{
    NSUInteger sectionIndex = [sectionUuid integerValue];
    return [[self.tableOfContents objectAtIndex:sectionIndex] startPage] + 1;
}

- (NSString *)displayPageNumberForPageNumber:(NSUInteger)aPageNumber
{
    return [NSString stringWithFormat:@"%ld", (long)aPageNumber];
}

@end

#pragma mark -
@implementation BlioTextFlowPreParseOperation

static void pageRangeFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    NSMutableArray *pageRangesArray = (NSMutableArray *)ctx;
    
    if(strcmp("PageRange", name) == 0) {
        BlioTextFlowPageRange *aPageRange = [[BlioTextFlowPageRange alloc] init];
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("Start", atts[i]) == 0) {
                [aPageRange setStartPageIndex:atoi(atts[i+1])];
            } else if (strcmp("End", atts[i]) == 0) {
                [aPageRange setEndPageIndex:atoi(atts[i+1])];
            } else if (strcmp("Source", atts[i]) == 0) {
                NSString *sourceString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != sourceString) {
                    // Write the filename directly but set up the manifest entries once we have completed parsing
                    [aPageRange setFileName:sourceString];
                    [sourceString release];
                }
            }
        }
        
        if (nil != aPageRange) {
            [pageRangesArray addObject:aPageRange];
            [aPageRange release];
        }
    }
    
}

static void pageFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlowPageRange *pageRange = (BlioTextFlowPageRange *)ctx;
    NSInteger newPageIndex = -1;
    
    if(strcmp("Page", name) == 0) {
        
        NSUInteger currentByteIndex = (NSUInteger)(XML_GetCurrentByteIndex(*[pageRange currentParser]));
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    newPageIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                }
            } 
        }
        
        if ((newPageIndex >= 0) && (newPageIndex != [pageRange currentPageIndex])) {
            BlioTextFlowPageMarker *newPageMarker = [[BlioTextFlowPageMarker alloc] init];
            [newPageMarker setPageIndex:newPageIndex];
            [newPageMarker setByteIndex:currentByteIndex];
            [pageRange.pageMarkers addObject:newPageMarker];
            [newPageMarker release];
            [pageRange setCurrentPageIndex:newPageIndex];
        }
    }
    
}

- (void)main {
    // NSLog(@"BlioTextFlowPreParseOperation main entered");
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioTextFlowPreParseOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}	
    if ([self isCancelled]) {
		NSLog(@"Operation cancelled, will prematurely abort start");	
		return;
	}
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSData *data = [self getBookManifestDataForKey:BlioManifestTextFlowKey];
    
    if (nil == data) {
        //NSLog(@"Could not create TextFlow data file.");
        NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist at path: %@.", [self getBookManifestPathForKey:BlioManifestTextFlowKey]);
        [pool drain];
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}		
#endif
	
    NSMutableSet *pageRangesSet = [NSMutableSet set];
    
    // Parse pageRange file
    XML_Parser pageRangeFileParser = XML_ParserCreate(NULL);
    
    XML_SetStartElementHandler(pageRangeFileParser, pageRangeFileXMLParsingStartElementHandler);

    XML_SetUserData(pageRangeFileParser, (void *)pageRangesSet);    
    if (!XML_Parse(pageRangeFileParser, [data bytes], [data length], XML_TRUE)) {
        char *anError = (char *)XML_ErrorString(XML_GetErrorCode(pageRangeFileParser));
        NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, [self getBookManifestPathForKey:BlioManifestTextFlowKey]);
    }
    XML_ParserFree(pageRangeFileParser);
    //[data release];
//    [pool drain];
//    pool = [[NSAutoreleasePool alloc] init];
    
    for (BlioTextFlowPageRange *pageRange in pageRangesSet) {
//        NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
//        [manifestEntry setValue:@"textflow" forKey:BlioManifestEntryLocationKey];
//        [manifestEntry setValue:[pageRange fileName] forKey:BlioManifestEntryPathKey];
//        [self setBookManifestValue:manifestEntry forKey:[pageRange fileName]];
        
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        //NSData *data = [self getBookManifestDataForKey:[pageRange fileName]];
        NSData *data = [self getBookTextFlowDataWithPath:[pageRange fileName]];
        
        if (!data) {
            NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist with name: %@.", [pageRange fileName]);
            [pool drain];
            return;
        }
            
        XML_Parser flowParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(flowParser, pageFileXMLParsingStartElementHandler);
        
        pageRange.currentPageIndex = -1;
        pageRange.currentParser = &flowParser;
        XML_SetUserData(flowParser, (void *)pageRange);    
        if (!XML_Parse(flowParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(flowParser));
            NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, [pageRange fileName]);
        }
        XML_ParserFree(flowParser);   
        
        [innerPool drain];
    }
    
    [self setBookValue:[NSSet setWithSet:pageRangesSet] forKey:@"textFlowPageRanges"];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"startPageIndex" ascending:YES] autorelease];
    NSArray *sortedRanges = [[pageRangesSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortPageDescriptor]];
    [self setBookValue:[NSNumber numberWithInteger:[[sortedRanges lastObject] endPageIndex]]
                forKey:@"layoutPageEquivalentCount"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
//		NSLog(@"ending background task...");
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}		
#endif	
    self.operationSuccess = YES;
	self.percentageComplete = 100;
    
    [pool drain];
}


@end

