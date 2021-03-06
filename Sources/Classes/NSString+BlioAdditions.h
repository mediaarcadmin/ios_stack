//
//  NSString+BlioAdditions.h
//  BlioApp
//
//  Created by James Montgomerie on 30/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BlioAdditions)

+ (NSString *)uniqueStringWithBaseString:(NSString *)baseString;
+ (NSString *)uniquePathWithBasePath:(NSString *)basePath;
- (NSString *)md5Hash;
-(NSString*)sansInitialArticle;
- (NSComparisonResult)titleSansArticleCompare:(NSString *)aString;
@end
