//
//  BlioDrmSessionManager.m
//  BlioApp
//
//  Created by Arnold Chien on 8/25/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioDrmSessionManager.h"
#import "BlioLicenseClient.h"
#import "DrmGlobals.h"
#import "XpsSdk.h"
#import "BlioBook.h"
#import "BlioXPSProvider.h"
#import "BlioAlertManager.h"
#import "BlioAppSettingsConstants.h"
#import "BlioStoreHelper.h"

DRM_DOMAIN_ID oDomainIdReturned; 

// Domain controller URL must be hard-coded instead of parsed from a book's header 
// because registration can be done proactively from the UI.
#ifdef TEST_MODE
NSString* testUrl = @"http://prl.kreader.net/PlayReady/service/LicenseAcquisition.asmx";
#else
NSString* productionUrl = @"http://prl.kreader.net/PlayReadyDomains/service/LicenseAcquisition.asmx";
#endif

@interface BlioDrmSessionManager()

DRM_APP_CONTEXT* drmAppContext;
DRM_DECRYPT_CONTEXT  oDecryptContext;

@property (nonatomic, assign) DRM_APP_CONTEXT* drmAppContext;
@property (nonatomic, assign) DRM_DECRYPT_CONTEXT oDecryptContext;
@property (nonatomic, retain) NSManagedObjectID *headerBookID;
@property (nonatomic, retain) NSManagedObjectID *boundBookID;

- (DRM_RESULT)setHeaderForBookWithID:(NSManagedObjectID *)aBookID;

@end

@implementation BlioDrmSessionManager

@synthesize drmAppContext, oDecryptContext;
@synthesize drmInitialized;
@synthesize headerBookID, boundBookID;


-(void) dealloc {
	Drm_Uninitialize(drmAppContext); 
	Oem_MemFree(drmAppContext);
    self.headerBookID = nil;
    self.boundBookID = nil;
	[super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID 
{
    if((self = [super init])) {
		self.headerBookID = aBookID;
		[self initialize];
    }
    return self;
}

- (void)initialize {

	// TODO: move dstrDataStoreFile to DrmGlobals.
	// Data store.
	DRM_CONST_STRING  dstrDataStoreFile = CREATE_DRM_STRING( HDS_STORE_FILE );
	dstrDataStoreFile.pwszString = [DrmGlobals getDrmGlobals].dataStore.pwszString;
	dstrDataStoreFile.cchString = [DrmGlobals getDrmGlobals].dataStore.cchString;
	
	// Initialize the session.
	drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	DRM_RESULT dr = DRM_SUCCESS;	
@synchronized (self) {
	ChkDR( Drm_Initialize( drmAppContext,
							NULL,
							&dstrDataStoreFile ) );
	if ( self.headerBookID != nil )
		// Device registration does not require a book. 
		ChkDR( [self setHeaderForBookWithID:self.headerBookID] );
}
	
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM initialization error: %08X",dr);
		self.drmInitialized = NO;
		return;
	}
	self.drmInitialized = YES;
}

- (void)reportReading {
    NSLog(@"Report reading for book with ID %@", self.headerBookID);
    
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot report reading because DRM is not initialized.");
        return;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;   
@synchronized (self) {		
	ChkDR( Drm_Reader_Commit( drmAppContext,
								NULL, 
								NULL ) ); 
	}
ErrorExit:
	if (dr != DRM_SUCCESS) {
		unsigned int drInt = (unsigned int)dr;
		NSLog(@"DRM commit error: %08X",drInt);
	}
}

- (DRM_RESULT)getServerResponse:(NSString*)url challengeBuf:(DRM_BYTE*)pbChallenge 
					challengeSz:(DRM_DWORD*)cbChallenge 
					responseBuf:(DRM_BYTE**)pbResponse 
					 responseSz:(DRM_DWORD*)cbResponse
					 soapAction:(BlioSoapActionType)action
{
	BlioLicenseClient* licenseClient = [[BlioLicenseClient alloc] initWithMessage:(const void*)pbChallenge 
																	  messageSize:*cbChallenge
																			  url:url
																	   soapAction:action];
	NSData *drmResponse = [licenseClient getResponseSynchronously];
	if (drmResponse == nil) {
		[licenseClient release];
		return DRM_E_FAIL;
	} 
	else {
		*pbResponse = (DRM_BYTE*)[drmResponse bytes];
		*cbResponse = [drmResponse length];
	}
	
	[licenseClient release];
	return DRM_SUCCESS;
}

// Instead of parsing...
- (NSString*)getTagValue:(NSString*)xmlStr xmlTag:(NSString*)tag {
	NSString* beginTag = @"&lt;";
	beginTag = [[beginTag stringByAppendingString:tag] stringByAppendingString:@"&gt;"];
	NSRange beginTagRange = [xmlStr rangeOfString:beginTag]; // @"&lt;serviceid&gt;"];
	if ( beginTagRange.location != NSNotFound ) {
		NSString* endTag = @"&lt;/";
		endTag = [[endTag stringByAppendingString:tag] stringByAppendingString:@"&gt;"];
		NSRange endTagRange = [xmlStr rangeOfString:endTag]; //@"&lt;/serviceid&gt;"];
		if ( endTagRange.location != NSNotFound ) {
			NSRange valRange;
			valRange.location = beginTagRange.location + beginTagRange.length;
			valRange.length = endTagRange.location - valRange.location;
			NSLog(@"Extracted id:  %@", [xmlStr substringWithRange:valRange]);
			return [xmlStr substringWithRange:valRange];
		}
	}
	return nil;
}

- (BOOL)leaveDomain:(NSString*)token {
	
	DRM_RESULT dr = DRM_SUCCESS;
    DRM_RESULT dr2 = DRM_SUCCESS;
    DRM_DOMAIN_ID oDomainID;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbChallenge = NULL;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
	
	if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot leave domain because DRM is not initialized.");
        return NO;
    }
	
	if ( token == nil ) {
		NSLog(@"DRM error attempting to leave domain outside login session.");
		return NO;
	}
	
	DRM_CHAR* customData = (DRM_CHAR*)[[[[NSString stringWithString:@"<CustomData><AuthToken>"] 
										 stringByAppendingString:token] 
										stringByAppendingString:@"</AuthToken></CustomData>"]
									   UTF8String];
	DRM_DWORD customDataSz = (DRM_DWORD)(48 + [token length]);
	
	NSString* accountidStr = [[NSUserDefaults standardUserDefaults] objectForKey:kBlioAccountIDDefaultsKey];
	NSString* serviceidStr = [[NSUserDefaults standardUserDefaults] objectForKey:kBlioServiceIDDefaultsKey];
	if ( accountidStr == nil || serviceidStr == nil ) {
		NSLog(@"DRM error attempting to leave domain with no account information.");
		return NO;
	}
	
	unichar* aidBuf = (unichar*)Oem_MemAlloc([accountidStr length]*2);
	[accountidStr getCharacters:aidBuf];
	DRM_CONST_STRING accountId; 
	accountId.pwszString = (DRM_WCHAR*)aidBuf;
	accountId.cchString = DRM_GUID_STRING_LEN;
	
	unichar* sidBuf = (unichar*)Oem_MemAlloc([serviceidStr length]*2);
	[serviceidStr getCharacters:sidBuf];
	DRM_CONST_STRING serviceId;
	serviceId.pwszString = (DRM_WCHAR*)sidBuf; 
	serviceId.cchString = DRM_GUID_STRING_LEN;
	
	DRM_UTL_StringToGuid(&accountId,&oDomainID.m_oAccountID);
	DRM_UTL_StringToGuid(&serviceId,&oDomainID.m_oServiceID);
	
	dr = Drm_LeaveDomain_GenerateChallenge( drmAppContext,
										   DRM_REGISTER_NULL_DATA,
										   &oDomainID,
										   customData,
										   customDataSz,
										   pbChallenge,
										   &cbChallenge );
	
    if( dr == DRM_E_BUFFERTOOSMALL )
    {
		ChkMem( pbChallenge = Oem_MemAlloc( cbChallenge ) );
		// This returns 8004C509, DRM_E_DOMAIN_NOT_FOUND, if you're not joined to a domain
		// or if the domain ID is bad.
        ChkDR( Drm_LeaveDomain_GenerateChallenge( drmAppContext,
												 DRM_REGISTER_NULL_DATA,
												 &oDomainID,
												 customData,
												 customDataSz,
												 pbChallenge,
												 &cbChallenge ) );
    }
    else
    {
        ChkDR( dr );
    }
	
	//NSLog(@"DRM leave domain challenge: %s",(unsigned char*)pbChallenge);
	
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionLeaveDomain];
#else
	[self getServerResponse:productionUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionLeaveDomain];
#endif
	
	//NSLog(@"DRM leave domain response: %s",(unsigned char*)pbResponse);
	@synchronized (self) {
		ChkDR( Drm_LeaveDomain_ProcessResponse( drmAppContext,
											   pbResponse,
											   cbResponse,
											   &dr2 ) );
	}
	
    
ErrorExit:
	
	Oem_MemFree(aidBuf);
	Oem_MemFree(sidBuf);
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
	// These are "standard success values."
	if ( dr == DRM_SUCCESS || dr == DRM_S_FALSE || dr == DRM_S_MORE_DATA  ) {
		[[NSUserDefaults standardUserDefaults] setInteger:BlioDeviceRegisteredStatusUnregistered forKey:kBlioDeviceRegisteredDefaultsKey];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBlioAccountIDDefaultsKey];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBlioServiceIDDefaultsKey];
		return YES;
	}
	
	NSLog(@"DRM error leaving domain: %08X", dr);
	return NO;
}

- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name {
	
	DRM_RESULT dr = DRM_SUCCESS;
    DRM_RESULT dr2 = DRM_SUCCESS;
    DRM_DOMAIN_ID oDomainID;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbChallenge = NULL;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
    //DRM_DOMAIN_ID oDomainIdReturned = {{ 0 }};
	
	if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot join domain because DRM is not initialized.");
        return NO;
    }
	
	if ( token == nil ) {
		NSLog(@"DRM error attempting to join domain outside login session.");
		return NO;
	}
	
	DRM_CHAR* customData = (DRM_CHAR*)[[[[[[NSString stringWithString:@"<CustomData><AuthToken>"] 
										   stringByAppendingString:token] 
										  stringByAppendingString:@"</AuthToken><Category>"]
										 stringByAppendingString:name]
										stringByAppendingString:@"</Category></CustomData>"]
									   UTF8String];
	
	DRM_DWORD customDataSz = (DRM_DWORD)(69 + [name length] + [token length]);
    dr = Drm_JoinDomain_GenerateChallenge( drmAppContext,
										  DRM_REGISTER_NULL_DATA,
										  &oDomainID,
										  NULL,
										  0,
										  customData,
										  customDataSz,
										  pbChallenge,
										  &cbChallenge );
	
    if( dr == DRM_E_BUFFERTOOSMALL )
    {
		ChkMem( pbChallenge = Oem_MemAlloc( cbChallenge ) );
        ChkDR( Drm_JoinDomain_GenerateChallenge( drmAppContext,
												DRM_REGISTER_NULL_DATA,
												&oDomainID,
												NULL,
												0,
												customData,
												customDataSz,
												pbChallenge,
												&cbChallenge ) );
    }
    else
    {
        ChkDR( dr );
    }
	
	//NSLog(@"DRM join domain challenge: %s",(unsigned char*)pbChallenge);
	
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionJoinDomain];
#else
	[self getServerResponse:productionUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionJoinDomain];
#endif
	
		
	//NSLog(@"DRM join domain response: %s",(unsigned char*)pbResponse);
	@synchronized (self) {
		ChkDR( Drm_JoinDomain_ProcessResponse( drmAppContext,
											  pbResponse,
											  cbResponse,
											  &dr2,
											  &oDomainIdReturned ) );
	}
    
ErrorExit:
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
	// These are "standard success values."
	if ( dr == DRM_SUCCESS || dr == DRM_S_FALSE || dr == DRM_S_MORE_DATA  ) {
		[[NSUserDefaults standardUserDefaults] setInteger:BlioDeviceRegisteredStatusRegistered forKey:kBlioDeviceRegisteredDefaultsKey];
		// Retrieve the service ID and account ID and store them in the form required by PlayReady.  
		// They're needed if we want to leave the domain later.
		pbResponse[cbResponse] = '\0';
		NSString* responseStr = [NSString stringWithCString:(const char*)pbResponse encoding:NSUTF8StringEncoding];
		NSString* sid = @"{";
		sid = [[sid stringByAppendingString:[self getTagValue:responseStr xmlTag:@"serviceid"]] stringByAppendingString:@"}"];
		[[NSUserDefaults standardUserDefaults] setObject:sid forKey:kBlioServiceIDDefaultsKey];
		NSString* aid = @"{";
		aid = [[aid stringByAppendingString:[self getTagValue:responseStr xmlTag:@"accountid"]] stringByAppendingString:@"}"];
		[[NSUserDefaults standardUserDefaults] setObject:aid forKey:kBlioAccountIDDefaultsKey];
		return YES;
	}
	
	NSLog(@"DRM error joining domain: %08X", dr);
	return NO;
}

- (DRM_RESULT)acknowledgeLicense:(DRM_LICENSE_RESPONSE*)licenseResponse {
	
    DRM_RESULT dr = DRM_SUCCESS;
    DRM_BYTE *pbChallenge = NULL;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
	
	dr = Drm_LicenseAcq_GenerateAck( drmAppContext, licenseResponse, pbChallenge, &cbChallenge );
	if ( dr == DRM_E_BUFFERTOOSMALL )
	{
		pbChallenge = Oem_MemAlloc( cbChallenge );
		ChkDR( Drm_LicenseAcq_GenerateAck( drmAppContext, licenseResponse, pbChallenge, &cbChallenge ));
	}
	else
	{
		ChkDR( dr );
	}

	//NSLog(@"DRM license acknowledgment challenge: %s",(unsigned char*)pbChallenge);
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcknowledgeLicense];
#else
	rgchURL[cchUrl] = '\0';
	[self getServerResponse:[NSString stringWithCString:(const char*)rgchURL encoding:NSASCIIStringEncoding] challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcknowledgeLicense];
#endif
	//NSLog(@"DRM license acknowledgment response: %s",(unsigned char*)pbResponse);
@synchronized (self) {
	ChkDR( Drm_LicenseAcq_ProcessAckResponse(drmAppContext, pbResponse, cbResponse, NULL) );
}

ErrorExit:
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
	return dr;
											  
}


- (DRM_RESULT)getDRMLicense:(NSString*)token {
	
    DRM_RESULT dr = DRM_SUCCESS;
    DRM_CHAR rgchURL[MAX_URL_SIZE];
    DRM_DWORD cchUrl = MAX_URL_SIZE;
    DRM_BYTE *pbChallenge = NULL;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
    DRM_LICENSE_RESPONSE oLicenseResponse = {0};
	
	if ( token == nil ) {
		NSLog(@"DRM error attempting to acquire license outside login session.");
		return DRM_E_FAIL;
	}
	
	DRM_CHAR* customData = (DRM_CHAR*)[[[[[[NSString stringWithString:@"<CustomData><AuthToken>"] 
										   stringByAppendingString:token] 
										  stringByAppendingString:@"</AuthToken><Version>"]
										 stringByAppendingString:@"2.0"]
										stringByAppendingString:@"</Version></CustomData>"]
										//stringByAppendingString:@"</AuthToken></CustomData>"]
									   UTF8String];
	DRM_DWORD customDataSz = (DRM_DWORD)(70 + [token length]);
	
//@synchronized (self) {
	dr = Drm_LicenseAcq_GenerateChallenge( drmAppContext,
										  NULL,
										  0,
										  NULL,
										  customData,
										  customDataSz,
										  rgchURL,
										  &cchUrl,
										  NULL,
										  0,
										  pbChallenge,
										  &cbChallenge );
	
    
	
    if( dr == DRM_E_BUFFERTOOSMALL )
    {
		cbChallenge += 3696; // ? Additional space needed for account ID
		
        pbChallenge = Oem_MemAlloc( cbChallenge );
        ChkDR( Drm_LicenseAcq_GenerateChallenge( drmAppContext,
												NULL,
												0,
												&oDomainIdReturned,
												customData,
												customDataSz,
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
//}
	//NSLog(@"DRM license challenge: %s",(unsigned char*)pbChallenge);
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcquireLicense];
#else
	rgchURL[cchUrl] = '\0';
	[self getServerResponse:[NSString stringWithCString:(const char*)rgchURL encoding:NSASCIIStringEncoding] challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcquireLicense];
#endif
	//NSLog(@"DRM license response: %s",(unsigned char*)pbResponse);
@synchronized (self) {
    ChkDR( Drm_LicenseAcq_ProcessResponse( drmAppContext,
										  NULL,
										  NULL,
										  pbResponse,
										  cbResponse,
										  &oLicenseResponse ) );
}
    ChkDR( oLicenseResponse.m_dwResult );
    for( int idx = 0; idx < oLicenseResponse.m_cAcks; idx++ )
		ChkDR( oLicenseResponse.m_rgoAcks[idx].m_dwResult );
	
	ChkDR( [self acknowledgeLicense:&oLicenseResponse] );
	
	
ErrorExit:
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
	return dr;
}

- (DRM_RESULT)setHeaderForBookWithID:(NSManagedObjectID *)aBookID {
	DRM_RESULT dr = DRM_SUCCESS;
	
    NSData *headerData = [[[BlioBookManager sharedBookManager] bookWithID:aBookID] manifestDataForKey:BlioManifestDrmHeaderKey];
	
	unsigned char* headerBuff = (unsigned char*)[headerData bytes]; 
	
	//ChkDR( Drm_Reinitialize(drmAppContext) );
    ChkDR( Drm_Content_SetProperty( drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   headerBuff,   
								   [headerData length] ) );
    
    self.headerBookID = aBookID;
    
ErrorExit:
	return dr;
}

- (DRM_RESULT)checkDomain:(NSString*)token {
	DRM_RESULT dr = DRM_SUCCESS;
	
    dr = [self getDRMLicense:token];
	// TODO: get the domain name from the license response
	// Getting DRM_E_XMLNOTFOUND when domain join required!
	if( dr == DRM_E_SERVER_DOMAIN_REQUIRED || dr == DRM_E_XMLNOTFOUND )
    {
		// This shouldn't happen because device registration is a prerequisite for this function.
		// So we assume here that the device should be registered and we go ahead and do it.
		ChkDR( [self joinDomain:token domainName:@"novel"] );
        ChkDR( [self getDRMLicense:token] );
    }
    else
        ChkDR( dr );
	
ErrorExit:
	return dr;
}

- (BOOL)getLicense:(NSString*)token {
    BOOL ret = NO;
    
    if ( !self.drmInitialized ) {
		NSLog(@"DRM error: license cannot be acquired because DRM is not initialized.");
		return ret;
	}
	
	DRM_RESULT dr = DRM_SUCCESS;
	ChkDR([self checkDomain:token]);
        
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		NSLog(@"DRM license error: %08X", dr);
		ret = NO;
	} else {
		NSLog(@"DRM license successfully acquired for bookID: %@", self.headerBookID);
		ret = YES;
	}
    return ret;
}

- (BOOL)decryptData:(NSData *)data {
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: content cannot be decrypted because DRM is not initialized.");
        return FALSE;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;
	unsigned char* dataBuff = NULL;
    
    //@synchronized (self) {
        //if ( ![self.headerBookID isEqual:aBookID] ) { 
        //    ChkDR( [self setHeaderForBookWithID:aBookID] );
        //}
        
        if ( ![self.boundBookID isEqual:self.headerBookID] ) { 
            NSLog(@"Binding to license.");
			
			// Search for a license to bind to with the Read right.
			const DRM_CONST_STRING *rgpdstrRights[1] = {0};
			DRM_CONST_STRING readRight;
			readRight.pwszString = [DrmGlobals getDrmGlobals].readRight.pwszString;
			readRight.cchString = [DrmGlobals getDrmGlobals].readRight.cchString;
			// Roundabout assignment needed to get around compiler complaint.
			rgpdstrRights[0] = &readRight; 
			int bufferSz = __CB_DECL(SIZEOF(DRM_CIPHER_CONTEXT));
			for (int i=0;i<bufferSz;++i)
				oDecryptContext.rgbBuffer[i] = 0;
			ChkDR( Drm_Reader_Bind( drmAppContext,
								   rgpdstrRights,
								   NO_OF(rgpdstrRights),
								   NULL, 
								   NULL,
								   &oDecryptContext ) );
            
            self.boundBookID = self.headerBookID;
			
        }
        DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};
        dataBuff = (unsigned char*)[data bytes]; 
        ChkDR(Drm_Reader_Decrypt (&oDecryptContext,
                                  &oCtrContext,
                                  dataBuff, 
                                  [data length]));
        
        // At this point, the buffer is PlayReady-decrypted.
        
	ErrorExit:
		if (dr != DRM_SUCCESS) {
            NSLog(@"DRM decryption error: %08X",dr);
            self.headerBookID = nil;
            self.boundBookID = nil;
            return NO;
        }
    //}
    
    // This XOR step is to undo an additional encryption step that was needed for .NET environment.
    for (int i=0;i<[data length];++i)
        dataBuff[i] ^= 0xA0;
    
    return YES;
}


@end

