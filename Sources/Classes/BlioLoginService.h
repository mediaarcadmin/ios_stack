//
//  BlioLoginService.h
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
@interface BlioIdentityProvider : NSObject {
}

@property (nonatomic, assign) NSString *name;
@property (nonatomic, assign) NSString *loginURL;
@property (nonatomic, assign) NSString *logoutURL;
@property (nonatomic, assign) NSString *imageURL;

@end
*/

@interface BlioLoginService : NSObject {
}

+(BlioLoginService*)sharedInstance;

-(void)checkin:(NSDictionary*)provider;
-(NSMutableArray*)getIdentityProviders;

@end
