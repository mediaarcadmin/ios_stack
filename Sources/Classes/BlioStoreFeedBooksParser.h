//
//  BlioStoreFeedBooksParser.h
//  BlioApp
//
//  Created by matt on 09/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BlioStoreParsedCategory;
@class BlioStoreParsedEntity;

@interface BlioStoreFeedBooksParser : NSObject {
    NSMutableArray *parsedCategories;
    NSMutableArray *parsedEntities;
}

@property (nonatomic, retain) NSMutableArray *parsedCategories;
@property (nonatomic, retain) NSMutableArray *parsedEntities;

- (void)start;
//- (void)downloadAndParse:(NSURL *)url;
//- (void)downloadStarted;
//- (void)downloadEnded;
//- (void)parseEnded;
//- (void)parsedCategory:(BlioStoreParsedCategory *)category;
//- (void)parsedEntity:(BlioStoreParsedEntity *)entity;
//- (void)parseError:(NSError *)error;

@end
