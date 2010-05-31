//
//  BlioDrmManager.m
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioDrmManager.h"
#import "DrmGlobals.h"

@implementation BlioDrmManager

- (BOOL)initialize {
	DRM_RESULT dr = DRM_SUCCESS;
	
	DRM_CONST_STRING  dstrDataStoreFile = CREATE_DRM_STRING( HDS_STORE_FILE );
	//DRM_STRING dstrDataStoreFile;
	dstrDataStoreFile.pwszString = [DrmGlobals getDrmGlobals].dataStore.pwszString;
	dstrDataStoreFile.cchString = [DrmGlobals getDrmGlobals].dataStore.cchString;
	
	[DrmGlobals getDrmGlobals].drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	
    //DeleteFileW( HDS_STORE_FILE );
    
	ChkDR( Drm_Initialize( [DrmGlobals getDrmGlobals].drmAppContext, //g_pAppContext,
						  NULL,
						  &dstrDataStoreFile ) );
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM Error: %d",dr);
		return NO;
	}
	return YES;
	
}

@end
