//
//  BlioImportManager.m
//  BlioApp
//
//  Created by Don Shin on 10/9/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioImportManager.h"
#import "BlioBook.h"
#import "BlioStoreManager.h"
#import "BlioAppAppDelegate.h"
#import "BlioAlertManager.h"
#import "BlioBookManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioEPubMetadataReader.h"
#import "KNFBXMLParserLock.h"

#import <libEucalyptus/EucEPubBook.h>
#import <minizip/unzip.h>

@interface BlioXPSKNFBMetadataParserDelegate : NSObject<NSXMLParserDelegate> {
	NSString * title;
	NSMutableArray * authors;
}
@property(nonatomic,retain) NSString * title;
@property(nonatomic,retain) NSMutableArray * authors;

@end

@implementation BlioXPSKNFBMetadataParserDelegate

@synthesize title,authors;

- (id)init {
	if ((self = [super init])) {
		self.authors = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	self.title = nil;
	self.authors = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	//	NSLog(@"BlioKNFBMetadataParserDelegate didStartElement: %@",elementName);
	if ( [elementName isEqualToString:@"Title"] ) {
		self.title = [attributeDict objectForKey:@"Main"];
	}
	else if ( [elementName isEqualToString:@"Contributor"] ) {
		NSString * author = [attributeDict objectForKey:@"Author"];
		if (author) {
			NSArray * preTrimmedAuthors = [author componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
			for (NSString * preTrimmedAuthor in preTrimmedAuthors) {
				[self.authors addObject:[preTrimmedAuthor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			}
		}		
	}
	
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
}
@end

@interface BlioXPSDocumentPropertiesParserDelegate : NSObject<NSXMLParserDelegate> {
	NSMutableString * _characterString;
	NSString * _fileAs;
	NSString * title;
	NSMutableArray * authors;
}
@property(nonatomic,retain) NSString * title;
@property(nonatomic,retain) NSMutableArray * authors;

@end

@implementation BlioXPSDocumentPropertiesParserDelegate

@synthesize title,authors;

- (id)init {
	if ((self = [super init])) {
		self.authors = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	if (_characterString) [_characterString release];
	self.title = nil;
	self.authors = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
//	NSLog(@"OPFParserDelegate didStartElement: %@",elementName);
	if ( [elementName isEqualToString:@"creator"] ) {
		_fileAs = [[attributeDict objectForKey:@"file-as"] retain];
	}
	if (_characterString) {
        [_characterString release];
        _characterString = nil;
    }	
	
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (!_characterString) {
        _characterString = [[NSMutableString alloc] initWithCapacity:50];
    }
    [_characterString appendString:string];
//	NSLog(@"_characterString (%i chars): %@",[_characterString length],_characterString);
	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ( [elementName isEqualToString:@"title"] || [elementName rangeOfString:@":title"].location != NSNotFound) {
		self.title = _characterString;
	}
	if ( [elementName isEqualToString:@"creator"] || [elementName rangeOfString:@":creator"].location != NSNotFound) {
		if (_fileAs) {
			[self.authors addObject:_fileAs];
			[_fileAs release];
			_fileAs = nil;
		}
		else if (_characterString) [self.authors addObject:[BlioBook canonicalNameFromStandardName:_characterString]];
	}
	if (_characterString) {
        [_characterString release];
        _characterString = nil;
    }	
}
@end

@interface BlioXPSContentTypesParserDelegate : NSObject<NSXMLParserDelegate> {
	NSString * documentPropertiesPath;
}
@property(nonatomic,retain) NSString * documentPropertiesPath;

@end


@implementation BlioXPSContentTypesParserDelegate

@synthesize documentPropertiesPath;

-(void)dealloc {
	self.documentPropertiesPath = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
//	NSLog(@"BlioXPSContentTypesParserDelegate didStartElement: %@",elementName);
	if([[attributeDict objectForKey:@"ContentType"] isEqualToString:@"application/vnd.openxmlformats-package.core-properties+xml"]) {
		NSString * PartName = [attributeDict objectForKey:@"PartName"];
		if (PartName) {
			self.documentPropertiesPath = PartName;
		}		
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//	NSLog(@"found characters: %@",string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	//	NSLog(@"didEndElement: %@",elementName);
}

@end


@interface BlioImportableBook () <BlioEPubMetadataReaderDataProvider>{
    unzFile _ePubUnzipHandle;
}
@end

@implementation BlioImportableBook  

@synthesize fileName,filePath,title,authors,sourceID,sourceSpecificID,isDRM;

-(void)dealloc {
	self.fileName = nil;
	self.filePath = nil;
	self.title = nil;
	self.authors = nil;
	self.sourceSpecificID = nil;
	[super dealloc];
}

- (NSString *)goodFilenameForZipFilename:(NSString *)filename
{
    while(filename.length && [filename characterAtIndex:0] == '/') {
        // Strip leading '/'es.
        filename = [filename substringFromIndex:1];
    }
    return filename.length ? filename : nil;
}

- (NSData *)copyDataForFile:(NSString *)filename inUnzFile:(unzFile)unzFile
{
    NSMutableData *ret = nil;
    filename = [self goodFilenameForZipFilename:filename];
    if(filename) {
        if(unzLocateFile(unzFile, [filename UTF8String], 1) != UNZ_OK) {
            NSLog(@"WARNING: '%@' in zip could not be located!", filename);
        } else {
            if(unzOpenCurrentFile(unzFile) != UNZ_OK) {
                NSLog(@"WARNING: '%@' in zip could not be opened!", filename);
            } else {
                unz_file_info fileInfo;
                if(unzGetCurrentFileInfo(unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK) {
                    NSLog(@"WARNING: '%@' in zip could not get file info!", filename);
                } else {
                    ret = [[NSMutableData alloc] initWithLength:fileInfo.uncompressed_size];
                    if(unzReadCurrentFile(unzFile, ret.mutableBytes, fileInfo.uncompressed_size) != fileInfo.uncompressed_size) {
                        NSLog(@"WARNING: '%@' in zip could not read file!", filename);
                        [ret release];
                        ret = nil;                    
                    }
                }
                unzCloseCurrentFile(unzFile);
            }
        }
    }
    return ret;
}

- (BOOL)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader componentExistsAtPath:(NSString *)path
{
    path = [self goodFilenameForZipFilename:path];
    if(path) {
        return unzLocateFile(_ePubUnzipHandle, [path UTF8String], 1) == UNZ_OK;
    }
    return NO;
}

- (NSData *)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader copyDataForComponentAtPath:(NSString *)path
{
    return [self copyDataForFile:path inUnzFile:_ePubUnzipHandle];
}

- (BlioImportableBook*)analyzeImportableBook {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    BlioImportableBook *toReturn = nil;
    
	if ([self.fileName.pathExtension compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSLog(@"Examining ePub %@", self.filePath);
        
        _ePubUnzipHandle = unzOpen([self.filePath fileSystemRepresentation]);
        if(!_ePubUnzipHandle) {
            NSLog(@"Could not open ePub file \"%@\" as zip; cannot import!", self.fileName);
        } else {
            BlioEPubMetadataReader *metadataReader = [[BlioEPubMetadataReader alloc] initWithDataProvider:self];
            if(metadataReader) {
                BOOL continueImporting = YES;

                if(metadataReader.hasRightsXML) {
                    self.isDRM = YES;
#ifdef TEST_MODE
                    NSLog(@"rights.xml file exists for ePub file \"%@\"; will import anyways in test mode...", self.fileName);
#else
                    NSLog(@"rights.xml file exists for ePub file \"%@\"; cannot import!", self.fileName);
                    toReturn = self;
                    continueImporting = NO;
#endif			
                }
                
                if(continueImporting && metadataReader.hasEncryptionXML) {
                    NSString *unknownEncryptionAlgorithm = metadataReader.unknownEncryptionAlgorithm;
                    if(unknownEncryptionAlgorithm) {
                        self.isDRM = YES;
                        toReturn = self;
#ifdef TEST_MODE
                        NSLog(@"encryption.xml file references unknown encryption algorithm \"%@\" for ePub file \"%@\"; will import anyways in test mode...", unknownEncryptionAlgorithm, self.fileName);
#else
                        NSLog(@"encryption.xml file references unknown encryption algorithm \"%@\" for ePub file \"%@\"; cannot import!", unknownEncryptionAlgorithm, self.fileName);
                        continueImporting = NO;
#endif			
                    }
                }
                
                if(continueImporting) {
                    if(!metadataReader.hasContainerXML) {
                        NSLog(@"WARNING: could not find continer.xml for %@!", self.fileName);
                    } else {
                        if(!metadataReader.hasPackageFile) {
                            NSLog(@"WARNING: could not find opf file for %@!", self.fileName);
                        } else {
                            if (metadataReader.title) self.title = metadataReader.title;
                            if (metadataReader.authors) self.authors = metadataReader.authors;
                            
                            toReturn = self;
                        }
                    }
                }
                
            }
            [metadataReader release];
            
            unzClose(_ePubUnzipHandle);
            _ePubUnzipHandle = NULL;
        }
    }
	else if ([self.fileName.pathExtension compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSLog(@"Examining XPS %@", self.filePath);
        unzFile xpsUnzipHandle = unzOpen([self.filePath fileSystemRepresentation]);
        if(!xpsUnzipHandle) {
            NSLog(@"ERROR: Could not open XPS file, %@; cannot import!",self.fileName);
        } else {
            NSString * localDRMPath = BlioXPSKNFBDRMHeaderFile;
            if ([[localDRMPath substringToIndex:1] isEqualToString:@"/"]) localDRMPath = [localDRMPath substringFromIndex:1];
            NSLog(@"Checking for XPS DRM: %@, %@", self.fileName, localDRMPath);
			
#ifdef TEST_MODE
            if(unzLocateFile(xpsUnzipHandle, [localDRMPath UTF8String], 1) != UNZ_END_OF_LIST_OF_FILE) {
                NSLog(@"DRM Header file exists for XPS file, %@; cannot import!",self.fileName);
                self.isDRM = YES;
                toReturn = self;
            } {
#else			
				if(unzLocateFile(xpsUnzipHandle, [localDRMPath UTF8String], 1) != UNZ_END_OF_LIST_OF_FILE) {
					NSLog(@"DRM Header file exists for XPS file, %@; cannot import!",self.fileName);
					self.isDRM = YES;
					toReturn = self;
				} else {
#endif							
                NSData *KNFBMetadataXML = [self copyDataForFile:BlioXPSKNFBMetadataFile inUnzFile:xpsUnzipHandle];
                if(KNFBMetadataXML) {
                    BlioXPSKNFBMetadataParserDelegate * KNFBMetadataParserDelegate = [[BlioXPSKNFBMetadataParserDelegate alloc] init];
                    @synchronized([KNFBXMLParserLock sharedLock]) {
                        NSXMLParser * KNFBMetaDataParser = [[NSXMLParser alloc] initWithData:KNFBMetadataXML];
                        [KNFBMetaDataParser setDelegate:KNFBMetadataParserDelegate];
                        [KNFBMetaDataParser parse];
                        [KNFBMetaDataParser release];
                    }
                    if (KNFBMetadataParserDelegate.title) self.title = KNFBMetadataParserDelegate.title;
                    if (KNFBMetadataParserDelegate.authors) self.authors = KNFBMetadataParserDelegate.authors;
                    [KNFBMetadataParserDelegate release];
                    [KNFBMetadataXML release];
                    
                    toReturn = self;
                    
                    if(!self.title) {
                        NSLog(@"NOTE: Title not found in KNFB Metadata for file %@. Will now check [Content_Types].xml for document properties...",self.fileName);   
                    }
                } else {
                    NSLog(@"NOTE: KNFB Metadata for file %@ was not found. Will now check [Content_Types].xml for document properties...",self.fileName);   
                }
                if(!self.title) {
                    NSString *contentTypesPath = @"[Content_Types].xml";
                    NSData *contentTypesPathXML = [self copyDataForFile:contentTypesPath inUnzFile:xpsUnzipHandle];
                    if(!contentTypesPathXML) {
                        NSLog(@"ERROR: Could not find %@ for XPS file, %@!",contentTypesPath,self.fileName);						
                    } else {
                        BlioXPSContentTypesParserDelegate * contentTypesParserDelegate = [[BlioXPSContentTypesParserDelegate alloc] init];
                        @synchronized([KNFBXMLParserLock sharedLock]) {
                            NSXMLParser * contentTypesParser = [[NSXMLParser alloc] initWithData:contentTypesPathXML];
                            [contentTypesParser setDelegate:contentTypesParserDelegate];
                            [contentTypesParser parse];
                            [contentTypesParser release];
                        }
                        NSString *documentPropertiesPath = [contentTypesParserDelegate.documentPropertiesPath retain];
                        [contentTypesParserDelegate release];
                        [contentTypesPathXML release];
                        
                        if(!documentPropertiesPath) {
                            NSLog(@"ERROR: Could not find document properties path in %@ for XPS file, %@!",contentTypesPath,self.fileName);						
                        } else {
                            NSData *documentPropertiesXML = [self copyDataForFile:documentPropertiesPath inUnzFile:xpsUnzipHandle];
                            if(!documentPropertiesXML) {
                                NSLog(@"ERROR: Could not find document properties file '%@' for XPS file, %@!",documentPropertiesPath,self.fileName);						
                            } else {
                                BlioXPSDocumentPropertiesParserDelegate * documentPropertiesParserDelegate = [[BlioXPSDocumentPropertiesParserDelegate alloc] init];
                                @synchronized([KNFBXMLParserLock sharedLock]) {
                                    NSXMLParser * documentPropertiesParser = [[NSXMLParser alloc] initWithData:documentPropertiesXML];
                                    [documentPropertiesParser setDelegate:documentPropertiesParserDelegate];
                                    [documentPropertiesParser parse];
                                    [documentPropertiesParser release];
                                }
                                // grab title and author
                                if (documentPropertiesParserDelegate.title) self.title = documentPropertiesParserDelegate.title;
                                if (documentPropertiesParserDelegate.authors) self.authors = documentPropertiesParserDelegate.authors;
                                [documentPropertiesParserDelegate release];
                                [documentPropertiesXML release];
                                
                                toReturn = self;
                            }
                            [documentPropertiesPath release];
                        }
                            
                    }
                }
            }
            unzClose(xpsUnzipHandle);
        }
	}
	else if ([self.fileName.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSData *aData = [[NSData alloc] initWithContentsOfMappedFile:self.filePath];
        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)aData);
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithProvider(dataProvider);
		CGPDFDictionaryRef pdfInfo = CGPDFDocumentGetInfo(pdfRef);
		CGPDFStringRef string;
		if (CGPDFDictionaryGetString(pdfInfo, "Title", &string)) {
			CFStringRef s;
			s = CGPDFStringCopyTextString(string);
			if (s != NULL) {
				self.title = (NSString *)s;
				CFRelease(s);			
			}
		}
		if (CGPDFDictionaryGetString(pdfInfo, "Author", &string)) {
			CFStringRef s;
			s = CGPDFStringCopyTextString(string);
			if (s != NULL) {
				self.authors = [NSArray arrayWithObject:(NSString *)s];
				CFRelease(s);			
			}
		}

        toReturn = self;

		CGPDFDocumentRelease(pdfRef);
        CGDataProviderRelease(dataProvider);
        [aData release];
	}
	[pool drain];
    
	return toReturn;
}

@end

@interface BlioImportManager (PRIVATE) 
+(BlioImportableBook*)importableBookFromSharedFile:(NSString*)aFile;
+(BlioImportableBook*)importableBookFromFilePath:(NSString*)aFilePath;
-(void)scanFileSharingDirectoryInBackground;
@end

@implementation BlioImportManager

@synthesize processingDelegate = _processingDelegate;
@synthesize importableBooks = _importableBooks;
@synthesize isScanningFileSharingDirectory;

+(BlioImportManager*)sharedImportManager
{
	static BlioImportManager * sharedImportManager = nil;
	if (sharedImportManager == nil) {
		sharedImportManager = [[BlioImportManager alloc] init];
	}
	
	return sharedImportManager;
}
- (id)init {
	self = [super init];
	if (self)
	{
		pthread_mutex_init( &scanningMutex, NULL );
		pthread_mutex_init( &importableBooksMutex, NULL );
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];		
	}
	
	return self;
}


-(void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];	
	self.importableBooks = nil;
	pthread_mutex_destroy(&scanningMutex);
	pthread_mutex_destroy(&importableBooksMutex);
	[super dealloc];
}
+(NSString*)fileSharingDirectory {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths && [paths count] > 0) return [paths objectAtIndex:0];	
	return nil;
}
+(NSString*)inboxDirectory {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths && [paths count] > 0) return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Inbox"];	
	return nil;
}
-(void)scanFileSharingDirectory {
	if (scanningThread) {
		NSLog(@"already scanning file sharing directory, cancelling current scanning thread...");
		[scanningThread cancel];
	}
	[self scanFileSharingDirectoryInBackground];
}
-(void)scanFileSharingDirectoryInBackground {
	if ([NSThread isMainThread]) {
		[NSThread detachNewThreadSelector:@selector(scanFileSharingDirectoryInBackground) toTarget:self withObject:nil];
		return;
	}
		pthread_mutex_lock( &scanningMutex );
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		NSLog(@"within lock, proceeding with scanning...");
		NSLog(@"%@", NSStringFromSelector(_cmd));
		self.isScanningFileSharingDirectory = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingScanStarted object:self];
		scanningThread = [NSThread currentThread];
		NSString * fileSharingDirectoryPath = [BlioImportManager fileSharingDirectory];   
		
		NSError * error;
		NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileSharingDirectoryPath error:&error];
		if (files == nil) {
			NSLog(@"Error reading contents of File Sharing Directory: %@", [error localizedDescription]);
			return;
		}
	if ([scanningThread isCancelled]) {
		self.isScanningFileSharingDirectory = NO;
		scanningThread = nil;
		NSLog(@"old thread exiting...");
		[pool drain];
		pthread_mutex_unlock( &scanningMutex );
		[NSThread exit];
	}
	self.importableBooks = [NSMutableArray array];
		for (NSString * file in files) {
			if ([file.pathExtension compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame || [file.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame || [file.pathExtension compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				BlioImportableBook * importableBook = [BlioImportManager importableBookFromSharedFile:file];
				pthread_mutex_lock( &importableBooksMutex );
					if ([scanningThread isCancelled]) {
						self.isScanningFileSharingDirectory = NO;
						scanningThread = nil;
						NSLog(@"old thread exiting within file loop...");
						[pool drain];
						pthread_mutex_unlock( &importableBooksMutex );
						pthread_mutex_unlock( &scanningMutex );
						[NSThread exit];
					}
#ifdef TEST_MODE
				if (importableBook && [[NSFileManager defaultManager] fileExistsAtPath:importableBook.filePath]) {
#else			
				if (importableBook && !importableBook.isDRM && [[NSFileManager defaultManager] fileExistsAtPath:importableBook.filePath]) {
#endif				
						NSLog(@"adding importableBook: %@ to array...",importableBook.fileName);
						[self.importableBooks addObject:importableBook];
						[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingScanUpdate object:self];
					}
				pthread_mutex_unlock( &importableBooksMutex );
			}
		}	
		self.isScanningFileSharingDirectory = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingScanFinished object:self];
		[pool drain];
		scanningThread = nil;
	pthread_mutex_unlock( &scanningMutex );
}
    
+(BlioImportableBook*)importableBookFromFilePath:(NSString*)aFilePath {
	BlioImportableBook * importableBook = [[[BlioImportableBook alloc] init] autorelease];
		
	importableBook.fileName = [aFilePath lastPathComponent];
	importableBook.sourceID = BlioBookSourceOtherApplications;
	importableBook.sourceSpecificID = importableBook.fileName;
	importableBook.filePath = aFilePath;
	return [importableBook analyzeImportableBook];
}

+(BlioImportableBook*)importableBookFromSharedFile:(NSString*)aFile {
	BlioImportableBook * importableBook = [[[BlioImportableBook alloc] init] autorelease];
		
	importableBook.fileName = aFile;
	importableBook.sourceID = BlioBookSourceFileSharing;
	importableBook.sourceSpecificID = aFile;
	importableBook.filePath = [[BlioImportManager fileSharingDirectory] stringByAppendingPathComponent:aFile];
	return [importableBook analyzeImportableBook];
}	
    
-(void)importBookFromFilePath:(NSString*)aFilePath {
	if ([NSThread isMainThread]) {
		[NSThread detachNewThreadSelector:@selector(importBookFromFilePath:) toTarget:self withObject:aFilePath];
		return;
	}
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	BlioImportableBook * importableBook = [BlioImportManager importableBookFromFilePath:aFilePath];
	
	
	if (importableBook.isDRM) {
#ifdef TEST_MODE
		NSLog(@"Importable Book is DRMed but still processing in test mode...");
#else			
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Book Protected",@"\"Book Protected\" alert message title")
									 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"IMPORTABLE_BOOK_HAS_DRM",nil,[NSBundle mainBundle],@"The file %@ will not be imported because it is copy-protected.",@"Alert message informing the end-user that importing of book from another application will not occur because DRM was found."),importableBook.fileName]
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];
		NSError *anError;
		if (![[NSFileManager defaultManager] removeItemAtPath:importableBook.filePath error:&anError]) {
			NSLog(@"Failed to delete DRM-ed file %@ in the Documents/Inbox Directory with error: %@", importableBook.fileName, [anError localizedDescription]);
		}
		else NSLog(@"Successfully deleted DRM-ed file %@ in the Documents/Inbox Directory.", importableBook.fileName);		
		return;
#endif
	}
	
	[self performSelectorOnMainThread:@selector(importBook:) withObject:importableBook waitUntilDone:NO];
	[pool drain];
}
-(void)importBook:(BlioImportableBook*)importableBook {
	if (!importableBook) return;
	// check for duplicates
	NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
	if (!moc) {
		NSLog(@"WARNING: MOC was not able to be obtained from BlioBookManager by BlioImportManager! Aborting import...");
		return;
	}
	else {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceSpecificID == %@ && sourceID == %@ && processingState == %@", importableBook.fileName,[NSNumber numberWithInt:importableBook.sourceID],[NSNumber numberWithInt:kBlioBookProcessingStateComplete]]];
		
		NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		
		if (errorExecute) {
			NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
			return;
		}
		if ([results count] >= 1) {
			NSLog(@"Found completed imported Book in context already- will not add to library. aborting..."); 
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Book Already Imported",@"\"Book Already Imported\" alert message title")
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"IMPORTABLE_BOOK_ALREADY_FOUND_IN_LIBRARY",nil,[NSBundle mainBundle],@"This book will not be imported because your library already has a book imported from the same file name: %@.",@"Alert message informing the end-user that importing of selected book will not occur because the library already has a book imported from the same file name."),importableBook.fileName]
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles: nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingImportAborted object:importableBook];
			return;
		}
	}
	
	NSString * finalFilePath = nil;

	if (importableBook.sourceID == BlioBookSourceFileSharing) {
		finalFilePath = importableBook.fileName;
	}
	else if (importableBook.sourceID == BlioBookSourceOtherApplications) {
		finalFilePath = importableBook.filePath;
	}
	
	NSString * title = nil;
	if (importableBook.title && [importableBook.title length] > 0 && [importableBook.title compare:@"untitled" options:NSCaseInsensitiveSearch] != NSOrderedSame) title = importableBook.title;
	else title = importableBook.fileName;
	
	if ([[importableBook.fileName pathExtension] compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																		   authors:importableBook.authors   
																		 coverPath:nil
																		  ePubPath:finalFilePath 
																		   pdfPath:nil 
																		   xpsPath:nil
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:importableBook.sourceID 
																  sourceSpecificID:importableBook.sourceSpecificID
																   placeholderOnly:NO
		 ];
		
	}
	else if ([[importableBook.fileName pathExtension] compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																		   authors:importableBook.authors   
																		 coverPath:nil
																		  ePubPath:nil 
																		   pdfPath:finalFilePath 
																		   xpsPath:nil
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:importableBook.sourceID 
																  sourceSpecificID:importableBook.sourceSpecificID
																   placeholderOnly:NO
		 ];
		
	}
	else if ([[importableBook.fileName pathExtension] compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																		   authors:importableBook.authors   
																		 coverPath:nil
																		  ePubPath:nil
																		   pdfPath:nil 
																		   xpsPath:finalFilePath 
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:importableBook.sourceID 
																  sourceSpecificID:importableBook.sourceSpecificID
																   placeholderOnly:NO
		 ];		
	}
	
}

- (void)onProcessingCompleteNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:note waitUntilDone:NO];
		return;
	}
	NSLog(@"%@", NSStringFromSelector(_cmd));
	// delete file from public documents directory.
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [[[note userInfo] objectForKey:@"sourceID"] intValue] == BlioBookSourceFileSharing) {
		NSString * filePath = [[BlioImportManager fileSharingDirectory] stringByAppendingPathComponent:[[note userInfo] objectForKey:@"sourceSpecificID"]];
		pthread_mutex_lock( &importableBooksMutex );
		BlioImportableBook * importableBookToBeDeleted = nil;
		for (BlioImportableBook * importableBook in self.importableBooks) {
			if ([importableBook.fileName isEqualToString:[[note userInfo] objectForKey:@"sourceSpecificID"]]) importableBookToBeDeleted = importableBook;
		}
		if (importableBookToBeDeleted) [self.importableBooks removeObject:importableBookToBeDeleted];
		NSError *anError;
		if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&anError]) {
			NSLog(@"Failed to delete imported file %@ in the Documents Directory with error: %@", [[note userInfo] objectForKey:@"sourceSpecificID"], [anError localizedDescription]);
		}
		else NSLog(@"Successfully deleted imported file %@ in the Documents Directory.", [[note userInfo] objectForKey:@"sourceSpecificID"]);
		pthread_mutex_unlock( &importableBooksMutex );
	}
	// delete file from inbox directory.
	else if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [[[note userInfo] objectForKey:@"sourceID"] intValue] == BlioBookSourceOtherApplications) {
		NSString * filePath = [[BlioImportManager inboxDirectory] stringByAppendingPathComponent:[[note userInfo] objectForKey:@"sourceSpecificID"]];
		NSError *anError;
		if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&anError]) {
			NSLog(@"Failed to delete imported file %@ in the Documents/Inbox Directory with error: %@", [[note userInfo] objectForKey:@"sourceSpecificID"], [anError localizedDescription]);
		}
		else NSLog(@"Successfully deleted imported file %@ in the Documents/Inbox Directory.", [[note userInfo] objectForKey:@"sourceSpecificID"]);
	}
}
- (void)onApplicationDidBecomeActiveNotification:(NSNotification*)note {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	pthread_mutex_lock( &importableBooksMutex );
		if (scanningThread) {
			NSLog(@"already scanning file sharing directory, cancelling current scanning thread...");
			[scanningThread cancel];
		}	
		[self.importableBooks removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingScanUpdate object:self];
	pthread_mutex_unlock( &importableBooksMutex );
	[self scanFileSharingDirectoryInBackground];
}

@end
