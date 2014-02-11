//
//  MediaArcPlatform.m
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "MediaArcPlatform.h"

// Move to build settings when we have more targets
#define TEST

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
#ifdef PROD
    self.acsNamespace = @"mediaarc";
    self.realmURL = @"http://mediaarc.com/";
    self.servicesHost = @"services.mediaarc.com";
    self.drmHost = @"drm.mediaarc.com";
#elif defined(DEV)
    self.acsNamespace = @"dev-mediaarc";
    self.realmURL = @"http://localhost:8000/Service/";
    self.servicesHost = @"dev-services.mediaarc.com";
    self.drmHost = @"dev-drm.mediaarc.com";
#elif defined(TEST)
    self.acsNamespace = @"test-mediaarc";
    self.realmURL = @"http://mediaarc.com/";
    self.servicesHost = @"test-services.mediaarc.com";
    self.drmHost = @"test-drm.mediaarc.com";
#endif
    self.acsHost = @"accesscontrol.windows.net";
    self.termsURL = @"http://www.blio.com/1010/en/terms.htm";
}

@end
