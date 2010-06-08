//
//  BlioLicenseClient.m
//  BlioApp
//
//  Created by Arnold Chien on 6/3/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioLicenseClient.h"


@implementation BlioLicenseClient

@synthesize connection, request, expectedContentLength;

-(id)initWithMessage:(const void*)msg 
		 messageSize:(NSUInteger)msgSize {
	if((self = [super init])) {
		NSURL* licenseURL = [[NSURL alloc] initWithString:@"http://prl.kreader.net/PlayReady/service/LicenseAcquisition.asmx"];
		self.request = [[NSMutableURLRequest alloc] initWithURL:licenseURL];
		[self.request setHTTPMethod:@"POST"];
		[self.request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
		[self.request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
		[self.request setValue:@"Microsoft-PlayReady-DRM/1.0" forHTTPHeaderField:@"User-Agent"];
		[self.request setValue:@"http://schemas.microsoft.com/DRM/2007/03/protocols/AcquireLicense" forHTTPHeaderField:@"SoapAction"];
		[self.request setValue:[NSString stringWithFormat:@"%d",msgSize] forHTTPHeaderField:@"Content-Length"];
		[self.request setHTTPBody:[[NSData alloc] initWithBytes:(const void*)msg length:(NSUInteger)msgSize]];		
	}
	return self;
}

-(BOOL)getResponse:(unsigned char**)resp responseSize:(unsigned int*)respSize {
	NSURLResponse* response = [[NSURLResponse alloc] init];;
	NSError* error = [[NSError alloc] init];
	// This is still asynchronous under the hood, but with default behavior for all the delegate methods.
	// Note in particular, redirects are always accepted, without URL change.
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if ( error != nil ) {
		NSLog(@"DRM error connecting to license server: %s",[error localizedDescription]);
		return NO;		
	}
	*respSize = [data length];
	*resp = (unsigned char*)malloc(*respSize);
	[data getBytes:(void*)*resp length:*respSize];
	return YES;
}

@end
