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
    if (responseData) {
        NSError* err;
        id jsonObj = [NSJSONSerialization
                       JSONObjectWithData:responseData
                       options:kNilOptions
                       error:&err];
        if (!jsonObj) {
            NSString * responseStr;
            responseStr = [[[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding] autorelease];
            if (responseStr) {
                responseStr = [responseStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                return [NSURL URLWithString:responseStr];
            }
            else {
                NSLog(@"Download URL is corrupt.");
                return nil;
            }
        }
        // else if a song, not an album
        else if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            NSArray* discsArray = [jsonObj objectForKey:@"Discs"];
            if (!discsArray) {
                NSLog(@"Download URL is corrupt.");
                return nil;
            }
            NSDictionary* disc1Dict = [discsArray objectAtIndex:0];
            if (!disc1Dict) {
                NSLog(@"Download URL is corrupt.");
                return nil;
            }
            NSArray* tracksArray = [disc1Dict objectForKey:@"Tracks"];
            if (!tracksArray) {
                NSLog(@"Download URL is corrupt.");
                return nil;
            }
            for (NSDictionary* track in tracksArray) {
                NSDictionary* digitalAssetsDict = [track objectForKey:@"DigitalAsset"];
                if (!digitalAssetsDict) {
                    NSLog(@"Download URL is corrupt.");
                    return nil;
                }
                NSDictionary* fileInfoDict = [digitalAssetsDict objectForKey:@"FileInfo"];
                if (!fileInfoDict) {
                    NSLog(@"Download URL is corrupt.");
                    return nil;
                }
                id downloadURL = [fileInfoDict objectForKey:@"Location"];
                if (downloadURL != [NSNull null])
                    return [NSURL URLWithString:downloadURL];
            }
            return nil;
        }
        else {
            NSLog(@"Download URL is corrupt.");
            return nil;
        }
    }
    else {
        NSLog(@"No download URL available.");
        return nil;
    }
}

+ (void)reportDownloadCompleted:(NSString*)productID {
    NSString* requestURL = @"https://";
    requestURL = [[requestURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].productDownloadURLFormat];
    requestURL = [NSString stringWithFormat:requestURL,productID];
    NSMutableURLRequest *reportDownloadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [reportDownloadRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    [reportDownloadRequest setHTTPMethod:@"POST"];
    NSError* err;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:reportDownloadRequest returningResponse:nil error:&err];
    [reportDownloadRequest release];
    // TODO remove after testing
    if (responseData) {
        NSString * responseStr;
        responseStr = [[[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding] autorelease];
        if (responseStr)
            NSLog(@"ReportDownloadCompleted returned %@",responseStr);
        else
            NSLog(@"ReportDownloadCompleted did not return a string.");
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

+ (void)getSupportToken:(NSURLSession*)session {
    NSString* supportTokenURL = @"https://";
    supportTokenURL = [[supportTokenURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].supportTokenURL];
    NSMutableURLRequest *supportTokenRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:supportTokenURL]];
    [supportTokenRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:supportTokenRequest];
    [task resume];
    [supportTokenRequest release];
}

@end
