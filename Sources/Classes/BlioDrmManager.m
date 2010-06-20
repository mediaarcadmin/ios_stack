//
//  BlioDrmManager.m
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioDrmManager.h"
#import "BlioLicenseClient.h"
#import "BlioXpsClient.h"
#import "DrmGlobals.h"
#import "XpsSdk.h"

static BlioDrmManager* drmManager = nil; 

@implementation BlioDrmManager

@synthesize drmInitialized, xpsClient;

+ (BlioDrmManager*)getDrmManager {
	if ( drmManager == nil ) {
		drmManager = [[BlioDrmManager alloc] init];
		drmManager.xpsClient = [[BlioXpsClient alloc] init];
	}
	return drmManager;
}

-(void) dealloc {
	self.xpsClient = nil;
	[super dealloc];
}

- (void)initialize {
	DRM_RESULT dr = DRM_SUCCESS;
	
	// Data store.
	DRM_CONST_STRING  dstrDataStoreFile = CREATE_DRM_STRING( HDS_STORE_FILE );
	dstrDataStoreFile.pwszString = [DrmGlobals getDrmGlobals].dataStore.pwszString;
	dstrDataStoreFile.cchString = [DrmGlobals getDrmGlobals].dataStore.cchString;
	[DrmGlobals getDrmGlobals].drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	
	// For testing, delete store from previous run.
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	//NSString *documentsDirectory = [paths objectAtIndex:0];
	//NSString* strDataStore = [documentsDirectory stringByAppendingString:@"/playready.hds"];
	//int res = remove([strDataStore cStringUsingEncoding:NSASCIIStringEncoding]);
	
	// Copy certs to writeable directory.
	NSError* err;	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString* rsrcWmModelKey = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/priv.dat"]; 
	NSString* docsWmModelKey = [documentsDirectory stringByAppendingString:@"/priv.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcWmModelKey toPath:docsWmModelKey error:&err];
	NSString* rsrcWmModelCert = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/devcerttemplate.dat"]; 
	NSString* docsWmModelCert = [documentsDirectory stringByAppendingString:@"/devcerttemplate.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcWmModelCert toPath:docsWmModelCert error:&err];
	NSString* rsrcPRModelCert = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/iphonecert.dat"]; 
	NSString* docsPRModelCert = [documentsDirectory stringByAppendingString:@"/iphonecert.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcPRModelCert toPath:docsPRModelCert error:&err];
	NSString* rsrcPRModelKey = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/iphonezgpriv.dat"]; 
	NSString* docsPRModelKey = [documentsDirectory stringByAppendingString:@"/iphonezgpriv.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcPRModelKey toPath:docsPRModelKey error:&err];
    
	// Initialize the DRM runtime.
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

- (DRM_RESULT)getLicense {
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

	BlioLicenseClient* licenseClient = [[BlioLicenseClient alloc] initWithMessage:(const void*)pbChallenge 
																	  messageSize:cbChallenge];
	if ( ![licenseClient getResponse:(unsigned char**)&pbResponse responseSize:(unsigned int*)&cbResponse] ) {
		return DRM_S_FALSE;
	}
	
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


- (BOOL)getLicenseForBookPath:(NSString*)xpsPath {
	if ( !self.drmInitialized ) {
		NSLog(@"DRM error: license cannot be acquired because DRM is not initialized.");
		return NO;
	}
	DRM_RESULT dr = DRM_SUCCESS;	

	void* xpsHandle = [xpsClient openFile:xpsPath];
	void* compHandle = [xpsClient openComponent:xpsHandle componentPath:@"/Documents/1/Other/KNFB/DrmpHeader.bin"];
	NSMutableData* headerData = [[NSMutableData alloc] init];
	unsigned char buffer[4096];
	int bytesRead = [xpsClient readComponent:compHandle componentBuffer:buffer componentLen:sizeof(buffer)];
	while (1) {
		NSData* data = [[NSData alloc] initWithBytes:(const void*)buffer length:bytesRead];
		[headerData appendData:data];
		if ( bytesRead != sizeof(buffer) )
			break;
		bytesRead = [xpsClient readComponent:compHandle componentBuffer:buffer componentLen:sizeof(buffer)]; 
	}
	[xpsClient closeComponent:compHandle];
	[xpsClient closeFile:xpsHandle];
	unsigned char* headerBuff = Oem_MemAlloc( [headerData length] );
    [headerData getBytes:headerBuff length:[headerData length]];
	
    ChkDR( Drm_Content_SetProperty( [DrmGlobals getDrmGlobals].drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   headerBuff,   
								   [headerData length] ) );
	ChkDR( [self getLicense] );
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM license error: %d",dr);
		return NO;
	}
	return YES;
}

- (BOOL)decryptComponentInBook:(NSString*)component xpsFileHandle:(void*)fileHandle decryptedBuffer:(unsigned char**)decrBuff decryptedBufferSz:(NSInteger*)decrBuffSz {
	if ( !self.drmInitialized ) {
		NSLog(@"DRM error: content cannot be decrypted because DRM is not initialized.");
		return NO;
	}
	DRM_RESULT dr = DRM_SUCCESS;
	const DRM_CONST_STRING *rgpdstrRights[1] = {0};
    DRM_DECRYPT_CONTEXT     oDecryptContext  = {0};
    DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};

	// Get encrypted page from XPS file.
	void* compHandle = [xpsClient openComponent:fileHandle componentPath:component];
	NSMutableData* fpData = [[NSMutableData alloc] init];
	unsigned char buff[4096];
	int bytesRead = [xpsClient readComponent:compHandle componentBuffer:buff componentLen:sizeof(buff)];
	while (1) {
		NSData* data = [[NSData alloc] initWithBytes:(const void*)buff length:bytesRead];
		[fpData appendData:data];
		if ( bytesRead != sizeof(buff) )
			break;
		bytesRead = [xpsClient readComponent:compHandle componentBuffer:buff componentLen:sizeof(buff)]; 
	}
	[xpsClient closeComponent:compHandle];
	
 	unsigned char *buffer = (unsigned char*)[fpData bytes];
 	
	 // Roundabout assignment needed to get around compiler complaint.
	DRM_CONST_STRING readRight;
	readRight.pwszString = [DrmGlobals getDrmGlobals].readRight.pwszString;
	readRight.cchString = [DrmGlobals getDrmGlobals].readRight.cchString;
	rgpdstrRights[0] = &readRight; 

 	ChkDR( Drm_Reader_Bind( [DrmGlobals getDrmGlobals].drmAppContext,
				rgpdstrRights,
				NO_OF(rgpdstrRights),
				NULL, 
				NULL,
				&oDecryptContext ) );
 
	ChkDR(Drm_Reader_Decrypt (&oDecryptContext,
					&oCtrContext,
					buffer, 
					[fpData length]));
 
	// At this point, the buffer is PlayReady-decrypted.
	
	ChkDR( Drm_Reader_Commit( [DrmGlobals getDrmGlobals].drmAppContext,
					NULL, 
					NULL ) );   

	// This XOR step is to undo an additional encryption step that was needed for .NET environment.
	for (int i=0;i<[fpData length];++i)
		buffer[i] ^= 0xA0;
	
	// The buffer is fully decrypted now, but gzip compressed; so must decompress.
	[xpsClient decompress:buffer inBufferSz:[fpData length] outBuffer:decrBuff outBufferSz:decrBuffSz];
	
	[fpData release];

ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM decryption error: %d",dr);
		return NO;
	}
	return YES;
}

@end
