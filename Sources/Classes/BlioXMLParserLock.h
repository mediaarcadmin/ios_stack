//
//  BlioXMLParserLock.h
//  BlioApp
//
//  Created by Don Shin on 10/13/11.
//  Copyright (c) 2011 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioXMLParserLock : NSObject {
}

+(BlioXMLParserLock*)sharedLock;
@end
