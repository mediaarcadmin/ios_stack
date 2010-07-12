//
//  BlioLicenseClient.m
//  BlioApp
//
//  Created by Arnold Chien on 6/3/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioLicenseClient.h"


@implementation BlioLicenseClient

@synthesize request;

- (void)dealloc {
    self.request = nil;
    [super dealloc];
}

- (id)initWithMessage:(const void*)msg messageSize:(NSUInteger)msgSize {
	if((self = [super init])) {
		NSURL* licenseURL = [NSURL URLWithString:@"http://prl.kreader.net/PlayReady/service/LicenseAcquisition.asmx"];
		NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] initWithURL:licenseURL];
        self.request = aRequest;
        [aRequest release];
        
		[self.request setHTTPMethod:@"POST"];
		[self.request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
		[self.request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
		[self.request setValue:@"Microsoft-PlayReady-DRM/1.0" forHTTPHeaderField:@"User-Agent"];
		[self.request setValue:@"http://schemas.microsoft.com/DRM/2007/03/protocols/AcquireLicense" forHTTPHeaderField:@"SoapAction"];
		[self.request setValue:[NSString stringWithFormat:@"%d",msgSize] forHTTPHeaderField:@"Content-Length"];
		[self.request setHTTPBody:[NSData dataWithBytes:(const void*)msg length:(NSUInteger)msgSize]];		
	}
	return self;
}

- (NSData *)getResponseSynchronously {
    NSURLResponse* response;
    NSError *error;
	
    // This is still asynchronous under the hood, but with default behavior for all the delegate methods.
	// Note in particular, redirects are always accepted, without URL change.
	NSData* data = [NSURLConnection sendSynchronousRequest:self.request returningResponse:&response error:&error];
	if ( data == nil ) {
		NSLog(@"DRM error connecting to license server: %@", [error localizedDescription]);
	}
    
    return data;
}

@end
