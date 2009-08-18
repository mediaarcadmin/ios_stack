//
//  EucEPubPageLayoutController.m
//  Eucalyptus
//
//  Created by James Montgomerie on 29/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "EucEPubPageLayoutController.h"
#import "THLog.h"
#import "EucEPubBook.h"
#import "EucBookSection.h"
#import "EucEPubBookParagraph.h"
#import "EucBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookTextView.h"
#import "EucEPubBookReader.h"
#import "EucBookTextStyle.h"
#import "THPair.h"
#import "EucPageView.h"
#import <pthread.h>


@implementation EucEPubPageLayoutController

static NSString * const kRightRaggedJustificationDefaultsKey = @"rightRaggedJustification";
static BOOL sRightRaggedJustificationDefault;
static pthread_once_t sRightRaggedJustificationDefaultOnceControl = PTHREAD_ONCE_INIT;

@synthesize book = _book;
@synthesize fontPointSize = _fontPointSize;
@synthesize globalPageCount = _globalPageCount;
@synthesize availablePointSizes = _availablePointSizes;

static void readRightRaggedJustificationDefault()
{
    sRightRaggedJustificationDefault = [[NSUserDefaults standardUserDefaults] boolForKey:kRightRaggedJustificationDefaultsKey];
}

- (id)initWithBook:(EucEPubBook *)book fontPointSize:(CGFloat)pointSize
{
    if((self = [super init])) {
        pthread_once(&sRightRaggedJustificationDefaultOnceControl, readRightRaggedJustificationDefault);
        
        NSString *familyName = [EucBookTextStyle defaultFontFamilyName];
        
        _book = [book retain];   
        _bookIndexes = [[EucBookPageIndex bookPageIndexesForBook:_book forFontFamily:familyName] retain];
        
        NSMutableArray *buildAvailablePointSizes = [[NSMutableArray alloc] initWithCapacity:_bookIndexes.count];
        for(EucBookPageIndex *index in _bookIndexes) {
            [buildAvailablePointSizes addObject:[NSNumber numberWithFloat:index.pointSize]];
        }
        [buildAvailablePointSizes sortUsingSelector:@selector(compare:)];
        _availablePointSizes = buildAvailablePointSizes; 
        
        [self setFontPointSize:pointSize];
        _bookReader = [[_book reader] retain];
        
        _paperImage = [[UIImage imageNamed:@"BookPaperWhite.png"] retain];
    }
    return self;
}

- (void)dealloc
{
    [_book release];
    [_bookIndex release];
    [_bookReader release];

    [_bookIndexes release];
    [_availablePointSizes release];
    
    [_paperImage release];
    [super dealloc];
}

- (void)setFontPointSize:(CGFloat)pointSize
{
    CGFloat difference = CGFLOAT_MAX;
    EucBookPageIndex *foundIndex = nil;
    for(EucBookPageIndex *index in _bookIndexes) {
        CGFloat thisDifference = fabsf(index.pointSize - pointSize);
        if(thisDifference < difference) {
            difference = thisDifference;
            foundIndex = index;
        }
    }
    if(foundIndex != _bookIndex) {
        [_bookIndex release];
        _bookIndex = [foundIndex retain];
        _fontPointSize = _bookIndex.pointSize;  
        _globalPageCount = _bookIndex.lastPageNumber;
    }
}


- (NSString *)pageDescriptionForPageNumber:(NSUInteger)pageNumber
{
    NSString *text = nil;
    if(pageNumber == 1) {
        text = NSLocalizedString(@"Cover", @"Page number display below page slider");
    } else {
        text = [NSString stringWithFormat:NSLocalizedString(@"%ld of %ld", @"Page number display below page slider"), (long)pageNumber-1, (long)_globalPageCount-1];
    }
    return text;
}


- (NSString *)displayPageNumberForPageNumber:(NSUInteger)pageNumber
{
    NSString *text = nil;
    if(pageNumber == 1) {
        return nil;
    } else {
        text = [NSString stringWithFormat:@"%ld", (long)pageNumber-1];
    }
    return text;
}

- (NSString *)contentsPageNumberForPageNumber:(NSUInteger)pageNumber
{
    NSString *text = nil;
    text = [NSString stringWithFormat:@"%ld", pageNumber];
    return text;
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)pageNumber
{
    // In ePub, sections can start anywhere on a page, so we fake out that we're
    EucBookSection *section = [_book topLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber+1].startOfParagraphByteOffset-1];
    return section.uuid;
}


- (NSString *)sectionNameForPageNumber:(NSUInteger)pageNumber
{
    // In ePub, sections can start anywhere on a page, so we fake out that we're
    EucBookSection *section = [_book topLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber+1].startOfParagraphByteOffset-1];
    NSString *name = [[section properties] objectForKey:kBookSectionPropertyTitle];
    return name;
}

- (NSUInteger)nextSectionPageNumberForPageNumber:(NSUInteger)pageNumber
{
    EucBookSection *section = [_book nextTopLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber].startOfParagraphByteOffset];
    NSUInteger nextPageNumber = [_bookIndex pageForByteOffset:section.startOffset];
    if(nextPageNumber == pageNumber && pageNumber < _globalPageCount) {
        section = [_book nextTopLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber+1].startOfParagraphByteOffset];
        nextPageNumber = [_bookIndex pageForByteOffset:section.startOffset];
    }
    return nextPageNumber;
}

- (NSUInteger)previousSectionPageNumberForPageNumber:(NSUInteger)pageNumber
{
    EucBookSection *section = [_book previousTopLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber].startOfParagraphByteOffset];
    NSUInteger nextPageNumber = [_bookIndex pageForByteOffset:section.startOffset];
    if(nextPageNumber == pageNumber && pageNumber > 1) {
        section = [_book previousTopLevelSectionForByteOffset:[_bookIndex indexPointForPage:pageNumber-1].startOfParagraphByteOffset];
        nextPageNumber = [_bookIndex pageForByteOffset:section.startOffset];
    }
    return nextPageNumber;
}

- (NSUInteger)pageNumberForUuid:(NSString *)uuid
{
    return [_bookIndex pageForByteOffset:[_book byteOffsetForUuid:uuid]];
}

- (NSArray *)sections
{
    return nil; 
}

- (THPair *)viewAndIndexPointForPageNumber:(NSUInteger)pageNumber
{
    if(pageNumber >= 1 && pageNumber <= _globalPageCount) {
        UIView *view = nil;
        EucBookPageIndexPoint *indexPoint = [_bookIndex indexPointForPage:pageNumber];
        EucPageView *pageView = [[EucPageView alloc] initWithPointSize:_bookIndex.pointSize 
                                                       titleFont:@"Helvetica-Oblique" 
                                                  pageNumberFont:@"Helvetica"
                                                  titlePointSize:_bookIndex.pointSize * 0.75
                                                      paperImage:_paperImage];
        pageView.titleLinePosition = EucPageViewTitleLinePositionBottom;
        pageView.titleLineContents = EucPageViewTitleLineContentsCenteredPageNumber;
        [[self class] layoutPageFromBookReader:_bookReader 
                               startingAtPoint:indexPoint 
                                      intoView:pageView.bookTextView];
        pageView.pageNumber = [self displayPageNumberForPageNumber:pageNumber];
        pageView.title = _book.title;
        if(pageNumber == 1) {
            pageView.fullBleed = YES;
            pageView.bookTextView.allowScaledImageDistortion = YES;
        }        
        view = [pageView autorelease];            
        return  [THPair pairWithFirst:view second:indexPoint];
    } else {
        return nil;
    }
}

- (NSUInteger)pageNumberForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    NSUInteger ret = [_bookIndex pageForIndexPoint:indexPoint];
    if(ret == 0) {
        return 1;
    }
    return ret;
}


+ (EucBookPageIndexPoint *)layoutPageFromBookReader:(id <EucBookReader>)reader
                                    startingAtPoint:(EucBookPageIndexPoint *)indexPoint
                                           intoView:(EucBookTextView *)bookTextView
{
    NSParameterAssert([reader isKindOfClass:[EucEPubBookReader class]]);
    EucEPubBookReader *bookReader = (EucEPubBookReader *)reader;
    
    EucBookPageIndexPoint *ret = nil;
    
    size_t nextParagraphOffset = indexPoint.startOfParagraphByteOffset;
    NSUInteger wordOffset = indexPoint.startOfPageParagraphWordOffset;
    NSUInteger hyphenOffset = indexPoint.startOfPageWordHyphenOffset;
    NSUInteger paragraphCount = 0;
    NSUInteger paragraphsWithContentCount = 0;
    CGFloat lastBottomMargin = 0;
    
    while(!ret) {
        size_t thisParagraphOffset = nextParagraphOffset;
        EucEPubBookParagraph *paragraph = [bookReader paragraphAtOffset:thisParagraphOffset
                                                              maxOffset:-1];
        if(paragraph) {            
            EucBookTextStyle *globalStyle = paragraph.globalStyle;
            if(paragraphCount != 0 && globalStyle.shouldPageBreakBefore && !wordOffset && !hyphenOffset) {
                ret = [[EucBookPageIndexPoint alloc] init];
                ret.startOfParagraphByteOffset = thisParagraphOffset; 
                ret.startOfPageParagraphWordOffset = 0;
                ret.startOfPageWordHyphenOffset = 0; 
                break;
            }
            
            CGFloat containingWidth = bookTextView.outerWidth;
            
            bookTextView.textIndent = [globalStyle textIndentForPointSize:bookTextView.pointSize inWidth:containingWidth];
            
            bookTextView.leftMargin = [globalStyle marginLeftForPointSize:bookTextView.pointSize inWidth:containingWidth];
            bookTextView.rightMargin = [globalStyle marginRightForPointSize:bookTextView.pointSize inWidth:containingWidth];
            
            if(paragraphCount != 0) {
                // This is correct - HTML calculates percentage top and bottom
                // margins as percentages of the containing block's /width/, 
                // not height.
                CGFloat topMargin = [globalStyle marginTopForPointSize:bookTextView.pointSize inWidth:containingWidth];
                topMargin = MAX(lastBottomMargin, topMargin);
                [bookTextView addVerticalSpace:topMargin];
                lastBottomMargin = [globalStyle marginBottomForPointSize:bookTextView.pointSize inWidth:containingWidth];
            }
            
            nextParagraphOffset = paragraph.nextParagraphByteOffset;
            NSArray *words = paragraph.words;
            NSUInteger wordCount = words.count;
            if(wordCount) {
                NSArray *wordFormattingAttributes = paragraph.wordFormattingAttributes;
                
                if(wordOffset && wordOffset <= wordCount) {
                    wordCount -= wordOffset;
                    NSRange rangeOnPage = NSMakeRange(wordOffset, wordCount);
                    words = [words subarrayWithRange:rangeOnPage];
                    wordFormattingAttributes = [wordFormattingAttributes subarrayWithRange:rangeOnPage];
                    bookTextView.textIndent = 0;
                }            
                
                EucBookTextStyleTextAlign alignment = globalStyle.textAlign;
                BOOL shouldCenter = alignment == EucBookTextStyleTextAlignCenter;
                BOOL shouldJustify = !sRightRaggedJustificationDefault;
                BOOL shouldFairlyJustifyLastLine = shouldCenter;
                BOOL shouldHyphenate = !shouldCenter;
                
                EucBookTextViewEndPosition endPosition;
                endPosition = [bookTextView addParagraphWithWords:words 
                                                       attributes:wordFormattingAttributes 
                               hyphenationPointsPassedInFirstWord:hyphenOffset
                                              indentBrokenLinesBy:0
                                                           center:shouldCenter
                                                          justify:shouldJustify
                                                  justifyLastLine:shouldFairlyJustifyLastLine
                                                        hyphenate:shouldHyphenate];   
                
                // Don't allow orphans.
                if(endPosition.completeLineCount == 1 && endPosition.completeWordCount != wordCount && paragraphsWithContentCount > 0) {
                    // Remove the paragraph, and fake out that adding it was
                    // unsuccessful.
                    if(endPosition.completeWordCount > 0) {
                        [bookTextView removeFromCookie:endPosition.removalCookie];
                    }
                    endPosition.completeLineCount = 0;
                    endPosition.completeWordCount = 0;
                    endPosition.hyphenationPointsPassedInNextWord = 0;
                    endPosition.removalCookie = 0;
                }     
                
                if(endPosition.completeWordCount == wordCount) {
                    /*if(nextParagraphOffset >= maxFileOffset) {
                     // This paragraph ended at the end of the section.
                     ret = [[BookPageIndexPoint alloc] init];
                     ret.startOfParagraphByteOffset = maxFileOffset;
                     }*/
                } else {
                    // If we didn't get to the end of the words
                    // Return the next-word position.
                    ret = [[EucBookPageIndexPoint alloc] init];
                    ret.startOfParagraphByteOffset = thisParagraphOffset; 
                    ret.startOfPageParagraphWordOffset = wordOffset + endPosition.completeWordCount;
                    ret.startOfPageWordHyphenOffset = endPosition.hyphenationPointsPassedInNextWord;                    
                }        
                
                if(hyphenOffset) {
                    hyphenOffset = 0;
                }
                if(wordOffset) {
                    wordOffset = 0;
                }
                ++paragraphsWithContentCount;
            }
            ++paragraphCount;
        } else {
            break;
        }
    }
    return [ret autorelease];
}

- (BOOL)viewShouldBeRigid:(UIView *)view
{
    return ((EucPageView *)view).fullBleed;
}

@end
