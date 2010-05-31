//
//  DrmPath.h
//  libPlayReadyPK
//
//  Created by Arnold Chien on 4/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

//#ifndef __DRMGLOBALS_H__
//#define __DRMGLOBALS_H__

#import <Foundation/Foundation.h>
#import "drmmanager.h"

@interface DrmGlobals : NSObject {
	// The path to the device cert and other assets.
	// For now, just the resource path.
	DRM_WCHAR* _rawDrmPath; 
	DRM_STRING drmPath;
	
	// Data store.
	DRM_WCHAR* _dataStore;
	DRM_STRING dataStore;
	
	// App context.
	DRM_APP_CONTEXT* drmAppContext;
	
}

@property (nonatomic, assign) DRM_STRING drmPath;
@property (nonatomic, assign) DRM_STRING dataStore;
@property (nonatomic, assign) DRM_APP_CONTEXT* drmAppContext;


+ (DrmGlobals*)getDrmGlobals;


@end

//#endif
