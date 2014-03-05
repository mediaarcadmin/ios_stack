//
//  BlioBookInfo.h
//  StackApp
//
//  Created by Arnold Chien on 2/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioMedia.h"

// Supersedes the BookOwnershipInfo class.  This class has a mix of account specific and product specific info.
// These are created at archive population time, when there may or may not (yet) be a corresponding BlioBook managed object.

@interface BlioBookInfo : BlioMedia

@property (nonatomic, retain) NSMutableArray* authors;
@property (nonatomic, retain) NSString* isbn;

-(id)initWithDictionary:(NSDictionary*)productDict isbn:(NSString*)anIsbn;

@end
