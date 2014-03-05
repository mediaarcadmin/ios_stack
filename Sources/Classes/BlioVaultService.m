//
//  BlioVaultService.m
//  StackApp
//
//  Created by Arnold Chien on 2/12/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioVaultService.h"
#import "BlioAccountService.h"
#import "MediaArcPlatform.h"

@implementation BlioVaultService

+ (NSURL*)getDownloadURL:(NSString*)productID {
    NSString* requestURL = @"https://";
    requestURL = [[requestURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].productDownloadURLFormat];
    requestURL = [NSString stringWithFormat:requestURL,productID];
    NSMutableURLRequest *downloadUrlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [downloadUrlRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    NSError* err;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:downloadUrlRequest returningResponse:nil error:&err];
    [downloadUrlRequest release];
    NSString * responseStr;
    if (responseData) {
        responseStr = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
        responseStr = [responseStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
        //responseStr = [responseStr stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
        return [NSURL URLWithString:responseStr];
    }
    else {
        NSLog(@"Error getting download url.");
        return nil;
    }
}

+ (void)getProductIdentifiers:(NSURLSession*)session product:(NSString*)productID handler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler {
    NSString* productIdentifiersURL = @"http://";
    productIdentifiersURL = [[productIdentifiersURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].productIdentifiersURLFormat];
    productIdentifiersURL = [NSString stringWithFormat:productIdentifiersURL,productID];
    NSMutableURLRequest *productIdentifiersRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:productIdentifiersURL]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:productIdentifiersRequest completionHandler:handler];
    [task resume];
    [productIdentifiersRequest release];
    
}

+ (void)getProductDetails:(NSURLSession*)session product:(NSString*)productID handler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler {
    // TODO? check for locally saved details?
    NSString* productDetailsURL = @"http://";
    // TODO: Strip port from servicesHost if necessary, so default port is used.  (not currently necessary)
    productDetailsURL = [[productDetailsURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].productDetailURLFormat];
    productDetailsURL = [NSString stringWithFormat:productDetailsURL,productID];
    NSMutableURLRequest *productDetailsRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:productDetailsURL]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:productDetailsRequest completionHandler:handler];
    [task resume];
    [productDetailsRequest release];
}


+ (void)getProductsPlusDetails:(NSURLSession*)session {
    NSString* productplusdetailsListURL = @"https://";
    productplusdetailsListURL = [[productplusdetailsListURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].vaultDetailsURL];
    NSMutableURLRequest *productplusdetailsRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:productplusdetailsListURL]];
    [productplusdetailsRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:productplusdetailsRequest];
    [task resume];
    [productplusdetailsRequest release];
    
}

+ (void)getProducts:(NSURLSession*)session {
    NSString* productListURL = @"https://";
    productListURL = [[productListURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].vaultURL];
    NSMutableURLRequest *productListRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:productListURL]];
    [productListRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:productListRequest];
    [task resume];
    [productListRequest release];
}


@end
