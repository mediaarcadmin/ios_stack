//
//  BlioXPSProtocol.h
//  BlioApp
//
//  Created by Matt Farrugia on 07/04/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioXPSProtocol : NSURLProtocol {}

+ (NSString *)xpsProtocolScheme;
+ (void)registerXPSProtocol;

@end