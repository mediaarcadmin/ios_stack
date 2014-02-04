/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WACloudAccessToken;

/** 
 A class that represents a client used to authenticate against the Windows Azure Access Control Service (ACS). 
 */
@interface WACloudAccessControlClient : NSObject 
{
@private
    NSURL *_serviceURL;
    NSString *_realm;
    NSString *_serviceNamespace;
}

/** 
 The ACS realm for the client. 
 */
@property (readonly) NSString *realm;

/** 
 The service namespace for the client. 
 */
@property (readonly) NSString *serviceNamespace;

/**
 Create an access control client initialized with the given service namespace and realm.
 
 @param serviceNamespace The ACS service namespace.
 @param realm The ACS realm.
	
 @returns The newly initialized WACloudAccessControlClient object.
 */
+ (WACloudAccessControlClient *)accessControlClientForNamespace:(NSString *)serviceNamespace realm:(NSString *)realm;


/**
 Creates a new view controller that contains the authentication user interface.
 
 @param allowsClose Determines if the user interface can be closed.
 @param block The completion handler is called when the process is completed and contains if the user is authenticated or not.
 
 @returns A UIViewController to display the authentication view.
 */
- (UIViewController *)createViewControllerAllowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block;


/*! Present the authentication user interface. The completion handler is called when the process is completed. */
/**
 Present the authentication user interface in a given controler.
 
 @param controller The controller to display the view.
 @param allowsClose Determines if the user interface can be closed.
 @param block The completion handler is called when the process is completed and contains if the user is authenticated or not.
 */
- (void)showInViewController:(UIViewController*)controller allowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block
;

/**
 The security token that was set when the user authenticated through a call to requestAccessInViewController:withCompletionHandler:.
 */
+ (WACloudAccessToken*)sharedToken;

/**
 Instructs the client to release the shared token.
 */
+ (void)logOut;


@end
