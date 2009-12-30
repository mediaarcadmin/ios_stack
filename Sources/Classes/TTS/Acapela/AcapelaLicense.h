//
//  AcapelaLicense.h
//  HelloWorld
//
//  Created by Jo De Lafonteyne on 16/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AcapelaLicense : NSObject {
	NSString *license;
	unsigned int user;
	unsigned int passwd;
}
@property(copy,readwrite) NSString* license;
@property(nonatomic, readwrite) unsigned int user;
@property(nonatomic, readwrite) unsigned int passwd;

- (id)initLicense:(NSString *)license user:(unsigned int)user passwd:(unsigned int)passwd;
@end
