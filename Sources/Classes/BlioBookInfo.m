//
//  BlioBookInfo.m
//  StackApp
//
//  Created by Arnold Chien on 2/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioBookInfo.h"

@implementation BlioBookInfo

@synthesize authors, isbn, expiration;

-(id)initWithDictionary:(NSDictionary*)productDict isbn:(NSString*)anIsbn {
    if (self = [super initWithDictionary:productDict]) {
        /*
         NSMutableArray * authors = [NSMutableArray array];
         if (author) {
            NSArray * preTrimmedAuthors = [author componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
            for (NSString * preTrimmedAuthor in preTrimmedAuthors) {
                [authors addObject:[preTrimmedAuthor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
         }
         }
         */
        //For now.  Will need [productDict valueForKey:@"Contributor"], but that's always empty at the moment.
        self.authors = nil;
        self.isbn = anIsbn;
        self.expiration = nil;
    }
    return self;
}

@end
