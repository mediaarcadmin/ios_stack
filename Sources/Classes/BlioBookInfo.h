//
//  BlioBookInfo.h
//  StackApp
//
//  Created by Arnold Chien on 2/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioMediaInfo.h"

// Supersedes the BookOwnershipInfo class.  This class has a mix of account specific and product specific info.
// These are created at archive population time, when there may or may not (yet) be a corresponding BlioBook managed object.

@interface BlioBookInfo : BlioMediaInfo

@property (nonatomic, retain) NSMutableArray* authors;
@property (nonatomic, retain) NSString* isbn;
// Not supported currently in the Windows app (or in the services).
@property (nonatomic, retain) NSDate* expiration;

-(id)initWithDictionary:(NSDictionary*)productDict isbn:(NSString*)anIsbn;

@end
