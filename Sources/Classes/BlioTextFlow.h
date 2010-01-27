//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioTextFlowPositionedWord : NSObject {
    NSString *string;
    CGRect rect;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;

@end

@interface BlioTextFlowSection : NSObject {
    NSInteger pageIndex;
    NSString *name;
    NSString *path;
    NSString *anchor;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *anchor;

@end

@interface BlioTextFlowParagraph : NSObject {
    NSInteger pageIndex;
    NSMutableArray *words;
    CGRect rect;
    BOOL folio;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, retain) NSMutableArray *words;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic) BOOL folio;

- (NSString *)string;
- (NSArray *)wordsArray;

@end

@interface BlioTextFlow : NSObject {
    NSXMLParser *textFlowParser;
    NSMutableArray *sections;
    NSMutableArray *pages;
    NSMutableArray *paragraphs;
    
    BlioTextFlowSection *currentSection;
    NSMutableArray *currentPage;
    BlioTextFlowParagraph *currentParagraph;
    BlioTextFlowPositionedWord *currentWord;
    NSString *currentWordString;
    NSString *currentWordRect;
}

@property (nonatomic, retain) NSMutableArray *sections;
@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSMutableArray *paragraphs;

- (id)initWithPath:(NSString *)path;

// Convenience methods
- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end
