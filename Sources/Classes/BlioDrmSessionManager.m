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

// Domain controller URL must be hard-coded instead of parsed from a book's header 
// because registration can be done proactively from the UI.
#ifdef TEST_MODE
NSString* testUrl = @"http://prl.kreader.net/PlayReady/service/LicenseAcquisition.asmx";
#else
NSString* productionUrl = @"https://bookvault.blioreader.com/PlayReady/service/LicenseAcquisition.asmx";
#endif

@interface BlioDrmSessionManager()

struct BlioDrmSessionManagerDrmIVars {
    DRM_APP_CONTEXT* drmAppContext;
    DRM_DECRYPT_CONTEXT  drmDecryptContext;
    DRM_BYTE drmRevocationBuffer[REVOCATION_BUFFER_SIZE];
};

@property (nonatomic, retain) NSManagedObjectID *headerBookID;
@property (nonatomic, retain) NSManagedObjectID *boundBookID;
@property (nonatomic, retain) NSString* serverResponse;

- (void)initialize;
- (DRM_RESULT)setHeaderForBookWithID:(NSManagedObjectID *)aBookID;
-(DRM_DOMAIN_ID)domainIDFromSavedRegistration;
@end

@implementation BlioDrmSessionManager

@synthesize drmInitialized;
@synthesize headerBookID, boundBookID, serverResponse;


-(void) dealloc {
	Drm_Uninitialize(drmIVars->drmAppContext); 
	Oem_MemFree(drmIVars->drmAppContext);
    self.headerBookID = nil;
    self.boundBookID = nil;
    
    free(drmIVars);
	[super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID 
{
    if((self = [super init])) {
		self.headerBookID = aBookID;
        drmIVars = calloc(1, sizeof(struct BlioDrmSessionManagerDrmIVars));
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
	drmIVars->drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	DRM_RESULT dr = DRM_SUCCESS;	
	@synchronized (self) {
		ChkDR( Drm_Initialize( drmIVars->drmAppContext,
							  NULL,
							  &dstrDataStoreFile ) );
		
		ChkDR( Drm_Revocation_SetBuffer( drmIVars->drmAppContext, 
										drmIVars->drmRevocationBuffer, 
										SIZEOF(drmIVars->drmRevocationBuffer)));
		
		if ( self.headerBookID != nil )
			// Device registration does not require a book. 
			ChkDR( [self setHeaderForBookWithID:self.headerBookID] );
	}
	
ErrorExit:
	if ( dr != DRM_SUCCESS ) {
		//NSLog(@"DRM initialization error: %08X",dr);
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:[NSLocalizedStringWithDefaultValue(@"PLAYREADY_INITIALIZATION_FAILED",nil,[NSBundle mainBundle],@"There was an initialization error. Please contact Blio technical support with the error code: ",@"Alert message shown when DRM initialization fails.")
											  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr]]
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		self.drmInitialized = NO;
		return;
	}
	self.drmInitialized = YES;
}

- (BOOL)reportReading {
    NSLog(@"Report reading for book with ID %@", self.headerBookID);
    
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot report reading because DRM is not initialized.");
        return NO;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;   
	@synchronized (self) {		
		ChkDR( Drm_Reader_Commit( drmIVars->drmAppContext,
								 NULL, 
								 NULL ) ); 
	}
ErrorExit:
	if (dr != DRM_SUCCESS) {
		NSLog(@"DRM commit error: %08X",dr);
		/*
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:[NSLocalizedStringWithDefaultValue(@"REPORTING_FAILED",nil,[NSBundle mainBundle],@"There was an error in book processing. Please contact Blio technical support with the error code: ",@"Alert message shown when book reporting fails.")
											  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr]]
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		 */
        return NO;
	}
    return YES;
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
			return [xmlStr substringWithRange:valRange];
		}
	}
	return nil;
}

- (BOOL)checkPriorityError:(DRM_RESULT)result {
	if (result==DRM_E_SERVER_COMPUTER_LIMIT_REACHED || result==DRM_E_SERVER_DEVICE_LIMIT_REACHED) {
		[BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
									 title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"OVER_DEVICE_LIMIT",nil,[NSBundle mainBundle],@"You are at your limit of five registered devices.  You must deregister another device before you can register this one.",@"Description of device limit error.")
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_LICEVAL_LICENSE_REVOKED) { 
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"LICENSE_REVOKED",nil,[NSBundle mainBundle],@"The license for one your books has been revoked.  Please contact Blio technical support.",@"Description of license revocation.")
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_CERTIFICATE_REVOKED) {
		[BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
											  title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"CERTIFICATE_REVOKED",nil,[NSBundle mainBundle],@"A certificate on your device has been revoked.  Please contact Blio technical support.",@"Description of certificate revocation.")
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_DEVCERT_REVOKED) {
		[BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
											  title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"DEVICE_REVOKED",nil,[NSBundle mainBundle],@"Your device certificate has been revoked.  Please contact Blio technical support.",@"Description of device certificate revocation.")
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_LICENSEEXPIRED) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
											message:NSLocalizedStringWithDefaultValue(@"LICENSE_EXPIRED",nil,[NSBundle mainBundle],@"The license for this book has expired.",@"Description of license expiration.")
										   delegate:nil 
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_LICENSENOTFOUND) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
											message:NSLocalizedStringWithDefaultValue(@"LICENSE_NOT_FOUND",nil,[NSBundle mainBundle],@"This book is not licensed.",@"Description of license absence.")
										   delegate:nil 
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK", nil];
		return YES;
	}
	else if (result==DRM_E_XMLNOTFOUND) {
        NSString* msg = [self getTagValue:self.serverResponse xmlTag:@"Message"];
        if ( !msg )
            msg = [self getTagValue:self.serverResponse xmlTag:@"faultstring"];
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
                                    message:msg
                                    delegate:nil 
                           cancelButtonTitle:nil
                           otherButtonTitles:@"OK", nil];
		return YES;
	}
	
	return NO;
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
		NSLog(@"DRM error: attempting to leave domain outside login session.");
		return NO;
	}
	
	NSDictionary * registrationRecords = [[BlioStoreManager sharedInstance] registrationRecords];
	if ( [registrationRecords objectForKey:kBlioServiceIDDefaultsKey] != nil )
		 oDomainID = [self domainIDFromSavedRegistration];
	else {
		NSLog(@"DRM error: attempting to leave domain with no domain ID information.");
		return NO;
	}
	
	DRM_CHAR* customData = (DRM_CHAR*)[[[[NSString stringWithString:@"<CustomData><AuthToken>"] 
										 stringByAppendingString:token] 
										stringByAppendingString:@"</AuthToken></CustomData>"]
									   UTF8String];
	DRM_DWORD customDataSz = (DRM_DWORD)(48 + [token length]);
	
	dr = Drm_LeaveDomain_GenerateChallenge( drmIVars->drmAppContext,
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
        ChkDR( Drm_LeaveDomain_GenerateChallenge( drmIVars->drmAppContext,
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
		ChkDR( Drm_LeaveDomain_ProcessResponse( drmIVars->drmAppContext,
											   pbResponse,
											   cbResponse,
											   &dr2 ) );
	}
	
    
ErrorExit:
	
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
	// These are "standard success values."
	if ( dr == DRM_SUCCESS || dr == DRM_S_FALSE || dr == DRM_S_MORE_DATA  ) {
		[[BlioStoreManager sharedInstance] setDeviceRegisteredSettingOnly:BlioDeviceRegisteredStatusUnregistered forSourceID:BlioBookSourceOnlineStore];
		[[BlioStoreManager sharedInstance] saveRegistrationAccountID:nil serviceID:nil];
		//		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBlioAccountIDDefaultsKey];
		//		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBlioServiceIDDefaultsKey];
		return YES;
	}
	
	// Not clear why result and status codes are not the same, but
	// we check both to be sure.  Though no priority errors are
	// expected for leaving a domain.
	if ([self checkPriorityError:dr2])
		return NO;
	else if (([self checkPriorityError:dr]))
		// I don't expect to ever get here, if there's a priority 
		// condition it should be returned by the server.
		return NO;
	
	//NSLog(@"DRM error leaving domain: %08X", dr);
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
								 message:[NSLocalizedStringWithDefaultValue(@"DEREGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to deregister device. Please contact Blio technical support with the error code: ",@"Alert message shown when device deregistration fails.")
										  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr2]]
								delegate:nil 
					   cancelButtonTitle:nil
					   otherButtonTitles:@"OK", nil];
	return NO;
}
- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name {
	return [self joinDomain:token domainName:name alertAlways:NO];
}

- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name alertAlways:(BOOL)alertFlag {
	DRM_RESULT dr = DRM_SUCCESS;
    DRM_RESULT dr2 = DRM_SUCCESS;
    DRM_DOMAIN_ID oDomainID;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbChallenge = NULL;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
    DRM_DOMAIN_ID oDomainIdReturned = {{ 0 }};
	
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
    dr = Drm_JoinDomain_GenerateChallenge( drmIVars->drmAppContext,
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
        ChkDR( Drm_JoinDomain_GenerateChallenge( drmIVars->drmAppContext,
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
	
    pbChallenge[cbChallenge] = '\0';
	//NSLog(@"DRM join domain challenge: %s",(unsigned char*)pbChallenge);
	
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionJoinDomain];
#else
	[self getServerResponse:productionUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionJoinDomain];
#endif
	//NSLog(@"DRM join domain response: %s",(unsigned char*)pbResponse);
	@synchronized (self) {
		ChkDR( Drm_JoinDomain_ProcessResponse( drmIVars->drmAppContext,
											  pbResponse,
											  cbResponse,
											  &dr2,
											  &oDomainIdReturned ) );
	}
    
ErrorExit:
	if ( pbChallenge )
		Oem_MemFree(pbChallenge);
    pbResponse[cbResponse] = '\0';
    self.serverResponse = [NSString stringWithCString:(const char*)pbResponse encoding:NSUTF8StringEncoding];
   // These are "standard success values."
	if ( dr == DRM_SUCCESS || dr == DRM_S_FALSE || dr == DRM_S_MORE_DATA  ) {
		[[BlioStoreManager sharedInstance] setDeviceRegisteredSettingOnly:BlioDeviceRegisteredStatusRegistered forSourceID:BlioBookSourceOnlineStore];
		// Retrieve the service ID and account ID and store them in the form required by PlayReady.  
		// They're needed if we want to leave the domain later.
		NSString* sid = @"{";
		sid = [[sid stringByAppendingString:[self getTagValue:self.serverResponse xmlTag:@"serviceid"]] stringByAppendingString:@"}"];
		//		[[NSUserDefaults standardUserDefaults] setObject:sid forKey:kBlioServiceIDDefaultsKey];
		NSString* aid = @"{";
		aid = [[aid stringByAppendingString:[self getTagValue:self.serverResponse xmlTag:@"accountid"]] stringByAppendingString:@"}"];
		//		[[NSUserDefaults standardUserDefaults] setObject:aid forKey:kBlioAccountIDDefaultsKey];
		[[BlioStoreManager sharedInstance] saveRegistrationAccountID:aid serviceID:sid];
		return YES;
	}
	
	// Not clear why result and status codes are not the same, but
	// they're not always so we check both to be sure. 
	if ([self checkPriorityError:dr2])
		return NO;
	else if (([self checkPriorityError:dr]))
		// I didn't expect to ever get here, but turns out it's
        // possible.  A priority condition is not always 
		// reported in the server error code.
		return NO;
	
	//NSLog(@"DRM error joining domain: %08X", dr);
	if (alertFlag) {
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
								 message:[NSLocalizedStringWithDefaultValue(@"REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to register device. Please contact Blio technical support with the error code: ",@"Alert message shown when device registration fails.")
										  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr2]]
								delegate:nil 
					   cancelButtonTitle:nil
					   otherButtonTitles:@"OK", nil];
	}
	else {
		[BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
												title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
											  message:[NSLocalizedStringWithDefaultValue(@"REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to register device. Please contact Blio technical support with the error code: ",@"Alert message shown when device registration fails.")
													   stringByAppendingString:[NSString stringWithFormat:@"%08X", dr2]]
											 delegate:nil 
									cancelButtonTitle:nil
									otherButtonTitles:@"OK", nil];
	}
	return NO;
}

- (DRM_RESULT)acknowledgeLicense:(DRM_LICENSE_RESPONSE*)licenseResponse {
	
    DRM_RESULT dr = DRM_SUCCESS;
    DRM_BYTE *pbChallenge = NULL;
    DRM_DWORD cbChallenge = 0;
    DRM_BYTE *pbResponse = NULL;
    DRM_DWORD cbResponse = 0;
	
	dr = Drm_LicenseAcq_GenerateAck( drmIVars->drmAppContext, licenseResponse, pbChallenge, &cbChallenge );
	if ( dr == DRM_E_BUFFERTOOSMALL )
	{
		pbChallenge = Oem_MemAlloc( cbChallenge );
		ChkDR( Drm_LicenseAcq_GenerateAck( drmIVars->drmAppContext, licenseResponse, pbChallenge, &cbChallenge ));
	}
	else
	{
		ChkDR( dr );
	}
	
	//NSLog(@"DRM license acknowledgment challenge: %s",(unsigned char*)pbChallenge);
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcknowledgeLicense];
#else
	//DRM_CHAR rgchURL[MAX_URL_SIZE];
    //rgchURL[0] = '\0';
	//[self getServerResponse:[NSString stringWithCString:(const char*)rgchURL encoding:NSASCIIStringEncoding] challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcknowledgeLicense];
	[self getServerResponse:productionUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcknowledgeLicense];
#endif
	//NSLog(@"DRM license acknowledgment response: %s",(unsigned char*)pbResponse);
	@synchronized (self) {
		ChkDR( Drm_LicenseAcq_ProcessAckResponse(drmIVars->drmAppContext, pbResponse, cbResponse, NULL) );
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
	
	// This should be a valid domain ID since registration is a prerequisite for 
	// license acquistion.  If for some reason it is not, the server should return 
	// an error that a domain join is required, and no license will be acquired.
	// This will invoke logic higher up (in checkDomain) to attempt a domain join.
	DRM_DOMAIN_ID oDomainIdFromNSUserDefaults = [self domainIDFromSavedRegistration];
	
	
	dr = Drm_LicenseAcq_GenerateChallenge( drmIVars->drmAppContext,
										  NULL,
										  0,
										  &oDomainIdFromNSUserDefaults,
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
		pbChallenge = Oem_MemAlloc( cbChallenge );
        ChkDR( Drm_LicenseAcq_GenerateChallenge( drmIVars->drmAppContext,
												NULL,
												0,
												&oDomainIdFromNSUserDefaults,
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
		
	//NSLog(@"DRM license challenge: %s",(unsigned char*)pbChallenge);
#ifdef TEST_MODE
	[self getServerResponse:testUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcquireLicense];
#else
	//rgchURL[cchUrl] = '\0';
	//NSLog(@"DRM connecting to license server URL retrieved from book header: %@",[NSString stringWithCString:(const char*)rgchURL encoding:NSASCIIStringEncoding]);
	//[self getServerResponse:[NSString stringWithCString:(const char*)rgchURL encoding:NSASCIIStringEncoding] challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcquireLicense];
	[self getServerResponse:productionUrl challengeBuf:pbChallenge challengeSz:&cbChallenge responseBuf:&pbResponse responseSz:&cbResponse soapAction:BlioSoapActionAcquireLicense];
#endif
	NSLog(@"DRM license response: %@",[[[NSString alloc] initWithBytes:pbResponse length:cbResponse encoding:NSASCIIStringEncoding] autorelease]);
	@synchronized (self) {
		ChkDR( Drm_LicenseAcq_ProcessResponse( drmIVars->drmAppContext,
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
	
	//ChkDR( Drm_Reinitialize(drmIVars->drmAppContext) );
    ChkDR( Drm_Content_SetProperty( drmIVars->drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   headerBuff,   
								   [headerData length] ) );
    
    self.headerBookID = aBookID;
    
ErrorExit:
	return dr;
}

-(DRM_DOMAIN_ID)domainIDFromSavedRegistration {
	DRM_DOMAIN_ID oDomainIdFromNSUserDefaults;

	// construct Domain ID from user-specific values in NSUserDefaults		
	NSDictionary * registrationRecords = [[BlioStoreManager sharedInstance] registrationRecords];
	NSString* accountidStr = [registrationRecords objectForKey:kBlioAccountIDDefaultsKey];
	NSString* serviceidStr = [registrationRecords objectForKey:kBlioServiceIDDefaultsKey];
	
	if ( accountidStr == nil ) 
		accountidStr = @"";
	if ( serviceidStr == nil ) 
		serviceidStr = @"";
	
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
	
	DRM_UTL_StringToGuid(&accountId,&oDomainIdFromNSUserDefaults.m_oAccountID);
	DRM_UTL_StringToGuid(&serviceId,&oDomainIdFromNSUserDefaults.m_oServiceID);
	
	Oem_MemFree(aidBuf);
	Oem_MemFree(sidBuf);

	return oDomainIdFromNSUserDefaults;
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
    
    if ( !self.drmInitialized ) {
		NSLog(@"DRM error: license cannot be acquired because DRM is not initialized.");
		return NO;
	}
	
	DRM_RESULT dr = DRM_SUCCESS;
	ChkDR([self checkDomain:token]);
	
ErrorExit:	
	if ( dr == DRM_SUCCESS || dr == DRM_S_FALSE || dr == DRM_S_MORE_DATA  ) {
		NSLog(@"DRM license successfully acquired for bookID: %@", self.headerBookID);
		return YES;
	}
	if ([self checkPriorityError:dr])
		return NO;
	// Not sure at this point whether to report to the user or just log.
	NSLog(@"DRM license acquisition error: %08X",dr);
	/*
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
								 message:[NSLocalizedStringWithDefaultValue(@"LICENSE_ACQUISITION_FAILED",nil,[NSBundle mainBundle],@"Unable to obtain license for book. Please contact Blio technical support with the error code: ",@"Alert message shown when device registration fails.")
										  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr]]
								delegate:nil 
					   cancelButtonTitle:nil
					   otherButtonTitles:@"OK", nil];
	*/
	return NO;
	
}

- (BOOL)bindToLicense {
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot bind to license because DRM is not initialized.");
        return FALSE;
    }
    DRM_RESULT dr = DRM_SUCCESS;
	if ( ![self.boundBookID isEqual:self.headerBookID] ) { 
		// Search for a license to bind to with the Read right.
		const DRM_CONST_STRING *rgpdstrRights[1] = {0};
		DRM_CONST_STRING readRight;
		readRight.pwszString = [DrmGlobals getDrmGlobals].readRight.pwszString;
		readRight.cchString = [DrmGlobals getDrmGlobals].readRight.cchString;
		// Roundabout assignment needed to get around compiler complaint.
		rgpdstrRights[0] = &readRight; 
		int bufferSz = __CB_DECL(SIZEOF(DRM_CIPHER_CONTEXT));
		for (int i=0;i<bufferSz;++i)
			(drmIVars->drmDecryptContext).rgbBuffer[i] = 0;
		ChkDR( Drm_Reader_Bind( drmIVars->drmAppContext,
							   rgpdstrRights,
							   NO_OF(rgpdstrRights),
							   NULL, 
							   NULL,
							   &drmIVars->drmDecryptContext ) );
		self.boundBookID = self.headerBookID;
	}
	
ErrorExit:
	if ([self checkPriorityError:dr])
		return NO;
	if (dr != DRM_SUCCESS) {
		//NSLog(@"DRM bind error: %08X",dr);
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:[NSLocalizedStringWithDefaultValue(@"DECRYPTION_FAILED",nil,[NSBundle mainBundle],@"Unable to open book. Please contact Blio technical support with the error code: ",@"Alert message shown when book decryption fails.")
											  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr]]
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		self.headerBookID = nil;
		self.boundBookID = nil;
		return NO;
	}
    return YES;
}

- (BOOL)decryptData:(NSData *)data {
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: content cannot be decrypted because DRM is not initialized.");
        return FALSE;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;
	/*        
	 if ( ![self.boundBookID isEqual:self.headerBookID] ) { 
	 //NSLog(@"Binding to license.");
	 
	 // Search for a license to bind to with the Read right.
	 const DRM_CONST_STRING *rgpdstrRights[1] = {0};
	 DRM_CONST_STRING readRight;
	 readRight.pwszString = [DrmGlobals getDrmGlobals].readRight.pwszString;
	 readRight.cchString = [DrmGlobals getDrmGlobals].readRight.cchString;
	 // Roundabout assignment needed to get around compiler complaint.
	 rgpdstrRights[0] = &readRight; 
	 int bufferSz = __CB_DECL(SIZEOF(DRM_CIPHER_CONTEXT));
	 for (int i=0;i<bufferSz;++i)
	 drmIVars->drmDecryptContext.rgbBuffer[i] = 0;
	 ChkDR( Drm_Reader_Bind( drmIVars->drmAppContext,
	 rgpdstrRights,
	 NO_OF(rgpdstrRights),
	 NULL, 
	 NULL,
	 &drmIVars->drmDecryptContext ) );
	 
	 self.boundBookID = self.headerBookID;
	 }
	 */	
	
	DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};
	unsigned char* dataBuff = (unsigned char*)[data bytes]; 
	ChkDR(Drm_Reader_Decrypt (&drmIVars->drmDecryptContext,
							  &oCtrContext,
							  dataBuff, 
							  [data length]));
	// At this point, the buffer is PlayReady-decrypted.
	
ErrorExit:
	if (dr != DRM_SUCCESS) {
		//NSLog(@"DRM decryption error: %08X",dr);
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title") 
									 message:[NSLocalizedStringWithDefaultValue(@"DECRYPTION_FAILED",nil,[NSBundle mainBundle],@"Unable to open book. Please contact Blio technical support with the error code: ",@"Alert message shown when book decryption fails.")
											  stringByAppendingString:[NSString stringWithFormat:@"%08X", dr]]
									delegate:nil 
						   cancelButtonTitle:nil
						   otherButtonTitles:@"OK", nil];
		self.headerBookID = nil;
		self.boundBookID = nil;
		return NO;
	}
    // This XOR step is to undo an additional encryption step that was needed for .NET environment.
    for (int i=0;i<[data length];++i)
        dataBuff[i] ^= 0xA0;
    return YES;
}


@end

