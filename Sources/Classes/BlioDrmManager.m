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

@interface BlioDrmManager()

@property (nonatomic, retain) NSManagedObjectID *bookID;

@end

@implementation BlioDrmManager

@synthesize drmInitialized;
@synthesize bookID;

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
    
    BlioXPSProvider *xpsProvider = [[[BlioBookManager sharedBookManager] bookWithID:aBookID] xpsProvider];
    NSString *headerPath = @"/Documents/1/Other/KNFB/DrmpHeader.bin";
    NSData *headerData = [xpsProvider dataForComponentAtPath:headerPath];
        
	unsigned char* headerBuff = (unsigned char*)[headerData bytes]; 
	
	ChkDR( Drm_Reinitialize([DrmGlobals getDrmGlobals].drmAppContext) );
    ChkDR( Drm_Content_SetProperty( [DrmGlobals getDrmGlobals].drmAppContext,
								   DRM_CSP_AUTODETECT_HEADER,
								   headerBuff,   
								   [headerData length] ) );
ErrorExit:
	self.bookID = nil;
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

//- (BOOL)decryptComponent:(NSString*)component decryptedBuffer:(unsigned char**)decrBuff decryptedBufferSz:(NSInteger*)decrBuffSz {
- (NSData *)decryptComponent:(NSString*)component forBookWithID:(NSManagedObjectID *)aBookID {
    
    if ( !self.drmInitialized ) {
        NSLog(@"DRM error: content cannot be decrypted because DRM is not initialized.");
        return nil;
    }
    
    BlioXPSProvider *xpsProvider;
    NSData *componentData;
    NSData *uncompressedData;
    unsigned char* componentBuff;
    
    DRM_RESULT dr = DRM_SUCCESS;
    
    @synchronized (self) {
        if ( ![self.bookID isEqual:aBookID] ) { 
            ChkDR( [self setHeaderForBookWithID:aBookID] );
            self.bookID = aBookID;
        }
        
        const DRM_CONST_STRING *rgpdstrRights[1] = {0};
        DRM_DECRYPT_CONTEXT     oDecryptContext  = {{0}};
        DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};
        
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
        
        xpsProvider = [[[BlioBookManager sharedBookManager] bookWithID:aBookID] xpsProvider];
        componentData = [xpsProvider dataForComponentAtPath:component];
        
        componentBuff = (unsigned char*)[componentData bytes]; 
        
        ChkDR(Drm_Reader_Decrypt (&oDecryptContext,
                                  &oCtrContext,
                                  componentBuff, 
                                  [componentData length]));
        
        // At this point, the buffer is PlayReady-decrypted.
        
        ChkDR( Drm_Reader_Commit( [DrmGlobals getDrmGlobals].drmAppContext,
                                 NULL, 
                                 NULL ) ); 
    }
    
    // This XOR step is to undo an additional encryption step that was needed for .NET environment.
    for (int i=0;i<[componentData length];++i)
        componentBuff[i] ^= 0xA0;
    
    // The buffer is fully decrypted now, but gzip compressed; so must decompress.
    //[BlioXpsClient decompress:buffer inBufferSz:[componentData length] outBuffer:decrBuff outBufferSz:decrBuffSz];
    uncompressedData = [xpsProvider decompress:componentData];
    NSLog(@"Uncompressed length %d, from %d", [uncompressedData length], [componentData length]);

        
ErrorExit:
    if ( (uncompressedData != nil) && (dr != DRM_SUCCESS) ) {
        unsigned int drInt = (unsigned int)dr;
        NSLog(@"DRM decryption error: %d",drInt);
        return nil;
    }
    return uncompressedData;
    
#if false   
    DRM_RESULT dr = DRM_SUCCESS;
    const DRM_CONST_STRING *rgpdstrRights[1] = {0};
    DRM_DECRYPT_CONTEXT     oDecryptContext  = {{0}};
    DRM_AES_COUNTER_MODE_CONTEXT oCtrContext = {0};
    
    if ( self.bookChanged ) {
        // Set the header property so we know what license to bind to.
        ChkDR( [self setHeader:self.bookHandle] );
    }
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
    //}
    
    // Get encrypted page from XPS file.
    void* compHandle = [xpsClient openComponent:self.bookHandle componentPath:component];
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
        unsigned int drInt = (unsigned int)dr;
        NSLog(@"DRM decryption error: %d",drInt);
        return NO;
    }
    return YES;
#endif
}

@end
