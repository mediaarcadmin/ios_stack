//
//  MediaArcPlatform.h
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaArcPlatform : NSObject {
    
}

@property (nonatomic, assign) NSString *acsNamespace;
@property (nonatomic, assign) NSString *acsHost;
@property (nonatomic, assign) NSString *drmHost;
@property (nonatomic, assign) NSString *servicesHost;
@property (nonatomic, assign) NSString *termsURL;
@property (nonatomic, assign) NSString *realmURL;
@property (nonatomic, assign) NSString *checkinURL;
@property (nonatomic, assign) NSString *supportTokenURL;
@property (nonatomic, assign) NSString *vaultURL;

+(MediaArcPlatform*)sharedInstance;

-(void)setDefaults;

@end
