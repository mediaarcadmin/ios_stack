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
#import "XpsSdk.h"
#import "BlioBook.h"
#import "BlioXPSProvider.h"
#import "BlioAlertManager.h"

// Unfortunately can't go in DrmGlobals and shouldn't be part of interface.
DRM_DECRYPT_CONTEXT  oDecryptContext;

@interface BlioDrmManager()

@property (nonatomic, retain) NSManagedObjectID *bookID;

- (DRM_RESULT)setHeaderForBookWithID:(NSManagedObjectID *)aBookID;
-(void)decrementLicenseCooldownTimer:(NSTimer *)aTimer;

@end

@implementation BlioDrmManager

@synthesize drmInitialized;
@synthesize bookID;
@synthesize licenseCooldownTime;
@synthesize licenseCooldownTimer;

+ (BlioDrmManager*)getDrmManager {
	static BlioDrmManager* drmManager = nil;  
	if ( drmManager == nil ) {
		drmManager = [[BlioDrmManager alloc] init];
	}
	return drmManager;
}

-(void) dealloc {
	Oem_MemFree([DrmGlobals getDrmGlobals].drmAppContext);
    self.bookID = nil;
	self.licenseCooldownTimer = nil;
	[super dealloc];
}

- (void)initialize {
	
	// delete store from previous run.
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	//NSString *documentsDirectory = [paths objectAtIndex:0];
	//NSString* strDataStore = [documentsDirectory stringByAppendingString:@"/playready.hds"];
	//int res = remove([strDataStore cStringUsingEncoding:NSASCIIStringEncoding]);
	//if ( !res )
	//	NSLog(@"DRM successfully deleted store from previous session.");
	
	// Data store.
	DRM_CONST_STRING  dstrDataStoreFile = CREATE_DRM_STRING( HDS_STORE_FILE );
	dstrDataStoreFile.pwszString = [DrmGlobals getDrmGlobals].dataStore.pwszString;
	dstrDataStoreFile.cchString = [DrmGlobals getDrmGlobals].dataStore.cchString;
	[DrmGlobals getDrmGlobals].drmAppContext = Oem_MemAlloc( SIZEOF( DRM_APP_CONTEXT ) );
	
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
	DRM_RESULT dr = DRM_SUCCESS;
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

- (void)reportReadingForBookWithID:(NSManagedObjectID *)aBookID {
    NSLog(@"Report reading for book with ID %@", aBookID);
    
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: cannot report reading because DRM is not initialized.");
        return;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;    
    @synchronized (self) {
        if ( ![self.bookID isEqual:aBookID] ) { 
            ChkDR( [self setHeaderForBookWithID:aBookID] );
            self.bookID = aBookID;
        }

        ChkDR( Drm_Reader_Commit( [DrmGlobals getDrmGlobals].drmAppContext,
                                 NULL, 
                                 NULL ) ); 
    ErrorExit:
        if (dr != DRM_SUCCESS) {
            unsigned int drInt = (unsigned int)dr;
            NSLog(@"DRM commit error: %d",drInt);
        }
    }
}

- (DRM_RESULT)getDRMLicense {

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
	//NSLog(@"DRM license challenge: %s",(unsigned char*)pbChallenge);
    
	BlioLicenseClient* licenseClient = [[BlioLicenseClient alloc] initWithMessage:(const void*)pbChallenge 
																	  messageSize:cbChallenge];
    
    
    NSData *drmResponse = [licenseClient getResponseSynchronously];
    
    if (drmResponse == nil) {
        return DRM_S_FALSE;
    } else {
        pbResponse = (DRM_BYTE *)[drmResponse bytes];
        cbResponse = [drmResponse length];
    }

    [licenseClient release];

	//NSLog(@"DRM license response: %s",(unsigned char*)pbResponse);
		
    ChkDR( Drm_LicenseAcq_ProcessResponse( [DrmGlobals getDrmGlobals].drmAppContext,
										  NULL,
										  NULL,
										  pbResponse,
										  cbResponse,
										  &oLicenseResponse ) );
	
    ChkDR( oLicenseResponse.m_dwResult );
    for( int idx = 0; idx < oLicenseResponse.m_cAcks; idx++ )
		ChkDR( oLicenseResponse.m_rgoAcks[idx].m_dwResult );
	
ErrorExit:
	return dr;
}

- (DRM_RESULT)setHeaderForBookWithID:(NSManagedObjectID *)aBookID {
	DRM_RESULT dr = DRM_SUCCESS;
    
    NSData *headerData = [[[BlioBookManager sharedBookManager] bookWithID:aBookID] manifestDataForKey:@"drmHeaderFilename"];
        
	unsigned char* headerBuff = (unsigned char*)[headerData bytes]; 
	
	ChkDR( Drm_Reinitialize([DrmGlobals getDrmGlobals].drmAppContext) );
    ChkDR( Drm_Content_SetProperty( [DrmGlobals getDrmGlobals].drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   headerBuff,   
								   [headerData length] ) );
ErrorExit:
	return dr;
}

- (BOOL)getLicenseForBookWithID:(NSManagedObjectID *)aBookID {
    BOOL ret = NO;
    
    if ( !self.drmInitialized ) {
		NSLog(@"DRM error: license cannot be acquired because DRM is not initialized.");
		return ret;
	}
     
    @synchronized (self) {
        DRM_RESULT dr = DRM_SUCCESS;
        if ( ![self.bookID isEqual:aBookID] ) { 
            ChkDR( [self setHeaderForBookWithID:aBookID] );
            self.bookID = aBookID;
        }
        
        ChkDR( [self getDRMLicense] );
        
    ErrorExit:
        if ( dr != DRM_SUCCESS ) {
            NSLog(@"DRM license error: %d",dr);
            ret = NO;
        } else {
            NSLog(@"DRM license successfully acquired for bookID: %@", self.bookID);
            ret = YES;
        }
    }
    return ret;
}

- (BOOL)decryptData:(NSData *)data forBookWithID:(NSManagedObjectID *)aBookID {
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: content cannot be decrypted because DRM is not initialized.");
        return FALSE;
    }
    
    DRM_RESULT dr = DRM_SUCCESS;
	unsigned char* dataBuff = NULL;
    
    @synchronized (self) {
        if ( ![self.bookID isEqual:aBookID] ) { 
			NSLog(@"Binding to license.");
            ChkDR( [self setHeaderForBookWithID:aBookID] );
            self.bookID = aBookID;

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
			ChkDR( Drm_Reader_Bind( [DrmGlobals getDrmGlobals].drmAppContext,
								   rgpdstrRights,
								   NO_OF(rgpdstrRights),
								   NULL, 
								   NULL,
								   &oDecryptContext ) );
        
        }
        DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};
        dataBuff = (unsigned char*)[data bytes]; 
        ChkDR(Drm_Reader_Decrypt (&oDecryptContext,
                                  &oCtrContext,
                                  dataBuff, 
                                  [data length]));
        
        // At this point, the buffer is PlayReady-decrypted.
		
    }
    
ErrorExit:
    if (dr != DRM_SUCCESS) {
        unsigned int drInt = (unsigned int)dr;
        NSLog(@"DRM decryption error: %08X",drInt);
        self.bookID = nil;
        return NO;
    }
    
    // This XOR step is to undo an additional encryption step that was needed for .NET environment.
    for (int i=0;i<[data length];++i)
        dataBuff[i] ^= 0xA0;
    
    return YES;
}
- (void)resetLicenseCooldownTimer {
	licenseCooldownTime = BlioDrmManagerInitialLicenseCooldownTime;
}
- (void)startLicenseCooldownTimer {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(startLicenseCooldownTimer) withObject:nil waitUntilDone:NO];
        return;
    }
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
								 message:NSLocalizedStringWithDefaultValue(@"DRM_LICENSE_ACQUISITION_ERROR",nil,[NSBundle mainBundle],@"The Blio App experienced a problem during license acquisition for your paid books. Please try restarting your paid book downloads later.",@"Alert message informing the end-user that an issue occurred during license acquisition, and encouraging the user to restart the downloading process later.")
								delegate:nil
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil];	
	self.licenseCooldownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(decrementLicenseCooldownTimer:) userInfo:nil repeats:YES];
}
-(void)decrementLicenseCooldownTimer:(NSTimer *)aTimer {
//	NSLog(@"decrementLicenseCooldownTimer entered. licenseCooldownTime: %i",licenseCooldownTime);
	licenseCooldownTime--;
	if (licenseCooldownTime <= 0) {
		NSLog(@"BlioDrmManager is ready to receive license acquisition requests again.");
		[aTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:NO];
		self.licenseCooldownTimer = nil;
	}
}
@end
