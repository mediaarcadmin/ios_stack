//
//  MediaArcPlatform.m
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "MediaArcPlatform.h"

@implementation MediaArcPlatform

@synthesize acsNamespace, acsHost, drmHost, servicesHost, realmURL, termsURL;

+(MediaArcPlatform*)sharedInstance
{
	static MediaArcPlatform * sharedPlatform = nil;
	if (sharedPlatform == nil) {
		sharedPlatform = [[MediaArcPlatform alloc] init];
	}
	
	return sharedPlatform;
}

- (id)init
{
	self = [super init];
	if (self)
		[self setDefaults];
	return self;
}

-(void)setDefaults {
    self.acsNamespace = @"mediaarc";
    self.acsHost = @"accesscontrol.windows.net";
    self.drmHost = @"drm.mediaarc.com";
    self.servicesHost = @"services.mediaarc.com";
    self.realmURL = @"http://mediaarc.com";
    self.termsURL = @"http://www.blio.com/1010/en/terms.htm";
}

@end
