//
//  BlioLoginManager.h
//  BlioApp
//
//  Created by Arnold Chien on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
	success = 0,
    invalidPassword,
    error,
} BlioLoginResult;

@interface BlioLoginManager : NSObject {
	BOOL isLoggedIn;
	NSString* username;
	NSString* token;
	NSDate* timeout;
	NSMutableArray* isbns; // array of ISBN numbers
	NSMutableArray* vaultBooks;  
}

@property (nonatomic, retain) NSDate* timeout;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *token;
@property (nonatomic) BOOL isLoggedIn;

- (BlioLoginResult)login:(NSString*)user password:(NSString*)passwd;
- (void)archiveBooks;
- (void)logout;

@end
