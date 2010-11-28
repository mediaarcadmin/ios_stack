//
//  BlioBookSearchResult.h
//  BlioApp
//
//  Created by matt on 11/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioBookmark.h"

@interface BlioBookSearchResult : NSObject {
    NSString *prefix;
    NSString *match;
    NSString *suffix;
    BlioBookmarkRange *bookmarkRange;
}

@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *match;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) BlioBookmarkRange *bookmarkRange;
@end
