//
//  BlioBUpeBook.h
//  BlioApp
//
//  Created by James Montgomerie on 20/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <libEucalyptus/EucBookPageIndexPoint.h>
#import "BlioBookmark.h"

@protocol BlioBUpeBook <NSObject>

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@end
