//
//  BlioDrmManager.m
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioDrmManager.h"
#import "BlioLicenseClient.h"
#import "DrmGlobals.h"

@implementation BlioDrmManager

@synthesize drmInitialized, xpsHeaderSize, xpsHeaderData;

+ (BlioDrmManager*)getDrmManager {
	static BlioDrmManager* drmManager = nil; 
	if ( drmManager == nil )
		drmManager = [[BlioDrmManager alloc] init];
	return drmManager;
}

- (void)initialize {
	DRM_RESULT dr = DRM_SUCCESS;
	DRM_CONST_STRING  dstrDataStoreFile = CREATE_DRM_STRING( HDS_STORE_FILE );
	dstrDataStoreFile.pwszString = [DrmGlobals getDrmGlobals].dataStore.pwszString;
	dstrDataStoreFile.cchString = [DrmGlobals getDrmGlobals].dataStore.cchString;
	[DrmGlobals getDrmGlobals].drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	
    //DeleteFileW( HDS_STORE_FILE );
    
	ChkDR( Drm_Initialize( [DrmGlobals getDrmGlobals].drmAppContext,
						  NULL,
						  &dstrDataStoreFile ) );
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM initialization error: %d",dr);
		self.drmInitialized = NO;
		return;
	}
	self.drmInitialized = YES;
}

DRM_RESULT DRM_CALL NetClient(
							  IN DRM_BYTE *f_pbChallenge,
							  IN DRM_DWORD f_cbChallenge,
							  OUT DRM_BYTE **f_ppbResponse,  
							  OUT DRM_DWORD *f_pcbResponse )
{
	DRM_RESULT dr = DRM_SUCCESS;
	
	BlioLicenseClient* licenseClient = [[BlioLicenseClient alloc] initWithMessage:(const void*)f_pbChallenge 
										messageSize:f_cbChallenge];
	if ( ![licenseClient getResponse:(unsigned char**)f_ppbResponse responseSize:(unsigned int*)f_pcbResponse] ) {
		dr = DRM_S_FALSE;
	}
	
ErrorExit:
	return dr;
}

- (DRM_RESULT)_getLicense {
    DRM_RESULT dr = DRM_SUCCESS;
    DRM_CHAR rgchURL[MAX_URL_SIZE];
    DRM_DWORD cchUrl = MAX_URL_SIZE;
    DRM_BYTE *pbChallenge = NULL;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
    DRM_LICENSE_RESPONSE oLicenseResponse = {0};
	
    dr = Drm_LicenseAcq_GenerateChallenge( [DrmGlobals getDrmGlobals].drmAppContext,
										  NULL,
										  0,
										  NULL,
										  NULL,
										  0,
										  rgchURL,
										  &cchUrl,
										  NULL,
										  0,
										  pbChallenge,
										  &cbChallenge );
	
    if( dr == DRM_E_BUFFERTOOSMALL )
    {
        pbChallenge = Oem_MemAlloc( cbChallenge );
        ChkDR( Drm_LicenseAcq_GenerateChallenge( [DrmGlobals getDrmGlobals].drmAppContext,
												NULL,
												0,
												NULL,
												NULL,
												0,
												rgchURL,
												&cchUrl,
												NULL,
												0,
												pbChallenge,
												&cbChallenge ) );
    }
    else
    {
        ChkDR( dr );
    }
	
	NSLog(@"DRM license challenge: %s",(unsigned char*)pbChallenge);
		
    ChkDR( NetClient( pbChallenge,
					 cbChallenge,
					 &pbResponse,
					 &cbResponse) );
	
	NSLog(@"DRM license response: %s",(unsigned char*)pbResponse);
	
    ChkDR( Drm_LicenseAcq_ProcessResponse( [DrmGlobals getDrmGlobals].drmAppContext,
										  NULL,
										  NULL,
										  pbResponse,
										  cbResponse,
										  &oLicenseResponse ) );
	
    ChkDR( oLicenseResponse.m_dwResult );
	
    for( int idx = 0; idx < oLicenseResponse.m_cAcks; idx++ )
    {
        //TODO (maybe): call Drm_Reinitialize and Drm_Content_GetProperty
        //for each content that licenses were sent for
        if( DRM_SUCCEEDED( oLicenseResponse.m_rgoAcks[idx].m_dwResult )
		   && (oLicenseResponse.m_rgoAcks[idx].m_dwFlags & DRM_LICENSE_ACK_FLAGS_EMBED ) )
        {
            ChkDR( Drm_Content_UpdateEmbeddedStore( [DrmGlobals getDrmGlobals].drmAppContext ) );
        }
        ChkDR( Drm_Content_UpdateEmbeddedStore_Commit( [DrmGlobals getDrmGlobals].drmAppContext ) );
    }
	
	
ErrorExit:
	return dr;
}


- (void)getLicense {
	DRM_RESULT dr = DRM_SUCCESS;
    ChkDR( Drm_Content_SetProperty( [DrmGlobals getDrmGlobals].drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   self.xpsHeaderData,
								   self.xpsHeaderSize ) );
    dr = [self _getLicense];
	ChkDR( dr );
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM license error: %d",dr);
	}
}

@end
