//
//  BlioXMLParserLock.m
//  BlioApp
//
//  Created by Don Shin on 10/13/11.
//  Copyright (c) 2011 CrossComm, Inc. All rights reserved.
//

#import "BlioXMLParserLock.h"

@implementation BlioXMLParserLock

+(BlioXMLParserLock*)sharedLock
{
	static BlioXMLParserLock * _sharedLock = nil;
	if (_sharedLock == nil) {
		_sharedLock = [[BlioXMLParserLock alloc] init];
	}
	
	return _sharedLock;
}

@end
