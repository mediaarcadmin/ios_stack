//
//  BlioVaultService.h
//  StackApp
//
//  Created by Arnold Chien on 2/12/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Book = 0,
    Album,
    Song,
    Video,
    App
} BlioMediaType;

@interface BlioVaultService : NSObject {
    
}

+ (void)getProductIdentifiers:(NSURLSession*)session product:(NSString*)productID handler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler;
+ (void)getProductDetails:(NSURLSession*)session  product:(NSString*)productID handler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler;
+ (void)getProducts:(NSURLSession*)session;
+ (void)getProductsPlusDetails:(NSURLSession*)session;
+ (void)getSupportToken:(NSURLSession*)session;
+ (NSURL*)getDownloadURL:(NSString*)productID;
+ (void)reportDownloadCompleted:(NSString*)productID;

@end
