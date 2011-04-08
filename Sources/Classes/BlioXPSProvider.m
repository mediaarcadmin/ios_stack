//
//  BlioXPSProvider.m
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioXPSProvider.h"
#import "BlioXPSProtocol.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioDrmSessionManager.h"

@interface BlioXPSProvider()

@property (nonatomic, retain) NSManagedObjectID *bookID;

- (BlioDrmSessionManager *)drmSessionManager;

@end

@implementation BlioXPSProvider

@synthesize bookID;

+ (void)initialize {
    if(self == [BlioXPSProvider class]) {
       [BlioXPSProtocol registerXPSProtocol];
    }
} 	

- (void)dealloc {  
    
    [bookID release], bookID = nil;
    [drmSessionManager release], drmSessionManager = nil;
	
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:aBookID];
    NSString *xpsPath = [blioBook xpsPath];
    
    if (xpsPath && (self = [super initWithPath:xpsPath])) {
        bookID = [aBookID retain];
    }
    
    return self;
}

- (BlioDrmSessionManager*)drmSessionManager {
	if ( !drmSessionManager ) {
		drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:self.bookID]; 
		if ([drmSessionManager bindToLicense]) { 
			decryptionAvailable = YES; 
			if (reportingStatus != kKNFBDrmBookReportingStatusComplete) { 
				reportingStatus = kKNFBDrmBookReportingStatusRequired; 
			} 
		} 
	} 
	return drmSessionManager;
}

// Subclassed methods

- (NSString *)bookThumbnailsDirectory {
    NSString *thumbnailsDirectory = nil;
    
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:self.bookID];
    
    NSString *thumbnailsLocation = [blioBook manifestLocationForKey:BlioManifestThumbnailDirectoryKey];
    if ([thumbnailsLocation isEqualToString:BlioManifestEntryLocationXPS]) {
        thumbnailsDirectory = BlioXPSMetaDataDir;
    }
    
    return thumbnailsDirectory;
}

- (id<KNFBDrmBookDecrypter>)drmBookDecrypter {
    return [self drmSessionManager];
}

@end