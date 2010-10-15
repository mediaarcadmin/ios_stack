//
//  BlioFileSharingManager.m
//  BlioApp
//
//  Created by Don Shin on 10/9/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioFileSharingManager.h"
#import "BlioBook.h"
#import "ZipArchive.h"
#import "BlioStoreManager.h"
#import "BlioAppAppDelegate.h"
#import "BlioAlertManager.h"
#import "BlioBookManager.h"
#import "BlioProcessingStandardOperations.h"

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

@interface BlioEPubOPFParserDelegate : NSObject<NSXMLParserDelegate> {
	NSMutableString * _characterString;
	NSString * _fileAs;
	NSString * title;
	NSMutableArray * authors;
}
@property(nonatomic,retain) NSString * title;
@property(nonatomic,retain) NSMutableArray * authors;

@end

@implementation BlioEPubOPFParserDelegate

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

@interface BlioEPubContainerParserDelegate : NSObject<NSXMLParserDelegate> {
	NSString * opfPath;
}
@property(nonatomic,retain) NSString * opfPath;

@end


@implementation BlioEPubContainerParserDelegate

@synthesize opfPath;

-(void)dealloc {
	self.opfPath = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
//	NSLog(@"BlioEPubContainerParserDelegate didStartElement: %@",elementName);
	if ( [elementName isEqualToString:@"rootfile"] ) {
		NSString * fullPath = [attributeDict objectForKey:@"full-path"];
		if (fullPath) {
			self.opfPath = fullPath;
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

@interface BlioXPSDocumentPropertiesParserDelegate : BlioEPubOPFParserDelegate<NSXMLParserDelegate> {

}

@end

@implementation BlioXPSDocumentPropertiesParserDelegate

// for now, same implementation as BlioEPubOPFParserDelegate

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


@implementation BlioImportableBook
@synthesize fileName,filePath,title,authors,sourceSpecificID;
-(void)dealloc {
	self.fileName = nil;
	self.filePath = nil;
	self.title = nil;
	self.authors = nil;
	self.sourceSpecificID = nil;
	[super dealloc];
}
@end

@interface BlioFileSharingManager (PRIVATE) 
+(BlioImportableBook*)importableBookFromFile:(NSString*)aFile;
-(void)scanFileSharingDirectoryInBackground;
@end

@implementation BlioFileSharingManager

@synthesize processingDelegate = _processingDelegate;
@synthesize importableBooks = _importableBooks;
@synthesize isScanningFileSharingDirectory;

+(BlioFileSharingManager*)sharedFileSharingManager
{
	static BlioFileSharingManager * sharedFileSharingManager = nil;
	if (sharedFileSharingManager == nil) {
		sharedFileSharingManager = [[BlioFileSharingManager alloc] init];
	}
	
	return sharedFileSharingManager;
}
- (id)init {
	self = [super init];
	if (self)
	{
		pthread_mutex_init( &scanningMutex, NULL );
		pthread_mutex_init( &importableBooksMutex, NULL );
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationDidBecomeActiveNotification:) name:BlioApplicationDidBecomeActiveNotification object:nil];		
	}
	
	return self;
}


-(void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioApplicationDidBecomeActiveNotification object:nil];	
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
		NSString * fileSharingDirectoryPath = [BlioFileSharingManager fileSharingDirectory];   
		
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
				BlioImportableBook * importableBook = [BlioFileSharingManager importableBookFromFile:file];
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
					if (importableBook && [[NSFileManager defaultManager] fileExistsAtPath:importableBook.filePath]) {
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
+(BlioImportableBook*)importableBookFromFile:(NSString*)aFile {
	BlioImportableBook * importableBook = [[[BlioImportableBook alloc] init] autorelease];
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	importableBook.fileName = aFile;
	importableBook.sourceSpecificID = aFile;
	importableBook.filePath = [[BlioFileSharingManager fileSharingDirectory] stringByAppendingPathComponent:aFile];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	cachePath = [cachePath stringByAppendingPathComponent:aFile];
	
	if ([aFile.pathExtension compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		
		BOOL unzipSuccess = NO;
		ZipArchive* aZipArchive = [[ZipArchive alloc] init];
		if([aZipArchive UnzipOpenFile:importableBook.filePath] ) {
			if (![aZipArchive UnzipFileTo:cachePath overWrite:YES]) {
				NSLog(@"Failed to unzip file from %@ to %@", importableBook.filePath, cachePath);
			} else {
				unzipSuccess = YES;
			}			
			[aZipArchive UnzipCloseFile];
		} else {
			NSLog(@"Failed to open zipfile at path: %@", importableBook.filePath);
		}
		[aZipArchive release];

		if ([[NSFileManager defaultManager] fileExistsAtPath:[cachePath stringByAppendingPathComponent:@"rights.xml"]]) {
			NSLog(@"Rights file exists for epub file, %@; cannot import!",aFile);
			[pool drain];
			return nil;
		}
		NSString * containerPath = [cachePath stringByAppendingPathComponent:@"META-INF/container.xml"];
		NSLog(@"containerPath: %@",containerPath);		
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:containerPath]) {
			NSLog(@"WARNING: containerPath: %@ for file, %@ was not found!",containerPath,aFile);
		}
		else {
			NSURL * containerURL = [NSURL fileURLWithPath:containerPath];
			if (!containerURL) {
				NSLog(@"ERROR: container URL: %@ is not valid!",containerPath);						
			}
			else {
				NSXMLParser * containerParser = [[NSXMLParser alloc] initWithContentsOfURL:containerURL];
				BlioEPubContainerParserDelegate * containerParserDelegate = [[BlioEPubContainerParserDelegate alloc] init];
				[containerParser setDelegate:containerParserDelegate];
				[containerParser parse];
				NSString * opfPath = [containerParserDelegate.opfPath retain];
				[containerParserDelegate release];
				[containerParser release];
				if (opfPath) {
					NSURL * opfURL = [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:opfPath]];
					if (!opfURL) {
						NSLog(@"ERROR: OPF URL: %@ is not valid!",[cachePath stringByAppendingPathComponent:opfPath]);						
					}
					else {
						NSXMLParser * opfParser = [[NSXMLParser alloc] initWithContentsOfURL:opfURL];
						BlioEPubOPFParserDelegate * opfParserDelegate = [[BlioEPubOPFParserDelegate alloc] init];
						[opfParser setDelegate:opfParserDelegate];
						[opfParser parse];
						// grab title and author
						if (opfParserDelegate.title) importableBook.title = opfParserDelegate.title;
						if (opfParserDelegate.authors) importableBook.authors = opfParserDelegate.authors;
						[opfParserDelegate release];
						[opfParser release];
					}
				}
				else {
					NSLog(@"WARNING: path to OPF file is nil!");
				}
				[opfPath release];
			}
		}
		
		// delete cache files
		NSError *anError;
		if (![[NSFileManager defaultManager] removeItemAtPath:cachePath error:&anError]) {
			NSLog(@"Failed to delete unzipped directory at path %@ with error: %@", cachePath, [anError localizedDescription]);
		}
	}
	else if ([aFile.pathExtension compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSLog(@"checking for XPS DRM: %@",[cachePath stringByAppendingPathComponent:BlioXPSKNFBDRMHeaderFile]);
								
		BOOL unzipSuccess = NO;
		ZipArchive* aZipArchive = [[ZipArchive alloc] init];
		if([aZipArchive UnzipOpenFile:importableBook.filePath] ) {
			if (![aZipArchive UnzipFileTo:cachePath overWrite:YES]) {
				NSLog(@"Failed to unzip file from %@ to %@", importableBook.filePath, cachePath);
			} else {
				unzipSuccess = YES;
			}			
			[aZipArchive UnzipCloseFile];
		} else {
			NSLog(@"Failed to open zipfile at path: %@", importableBook.filePath);
		}
		[aZipArchive release];
				
		if ([[NSFileManager defaultManager] fileExistsAtPath:[cachePath stringByAppendingPathComponent:BlioXPSKNFBDRMHeaderFile]]) {
			NSLog(@"DRM Header file exists for XPS file, %@; cannot import!",aFile);
			[pool drain];
			return nil;
		}		
		
		// check if KNFB XPS File (though not unlikely, as most KNFB XPS files would be DRMed)
		NSString * KNFBMetadataPath = [cachePath stringByAppendingPathComponent:BlioXPSKNFBMetadataFile];
		if (![[NSFileManager defaultManager] fileExistsAtPath:KNFBMetadataPath]) {
			NSLog(@"NOTE: KNFBMetadataPath: %@ for file, %@ was not found. Will now check [Content_Types].xml for document properties...",KNFBMetadataPath,aFile);
		}
		else {
			NSURL * KNFBMetadataURL = [NSURL fileURLWithPath:KNFBMetadataPath];
			if (!KNFBMetadataURL) {
				NSLog(@"ERROR: KNFBMetadataURL: %@ is not valid!",KNFBMetadataPath);						
			}
			else {
				NSXMLParser * KNFBMetaDataParser = [[NSXMLParser alloc] initWithContentsOfURL:KNFBMetadataURL];
				BlioXPSKNFBMetadataParserDelegate * KNFBMetadataParserDelegate = [[BlioXPSKNFBMetadataParserDelegate alloc] init];
				[KNFBMetaDataParser setDelegate:KNFBMetadataParserDelegate];
				[KNFBMetaDataParser parse];
				if (KNFBMetadataParserDelegate.title) importableBook.title = KNFBMetadataParserDelegate.title;
				if (KNFBMetadataParserDelegate.authors) importableBook.authors = KNFBMetadataParserDelegate.authors;
				[KNFBMetadataParserDelegate release];
				[KNFBMetaDataParser release];
				if (importableBook.title) return importableBook;
			}
		}
		
		// check [Content_Types].xml for possible document properties reference.
		NSString * contentTypesPath = [cachePath stringByAppendingPathComponent:@"[Content_Types].xml"];
		NSLog(@"contentTypesPath: %@",contentTypesPath);
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:contentTypesPath]) {
			NSLog(@"WARNING: contentTypesPath: %@ for file, %@ was not found!",contentTypesPath,aFile);
		}
		else {
			NSURL * contentTypesURL = [NSURL fileURLWithPath:contentTypesPath];
			if (!contentTypesURL) {
				NSLog(@"ERROR: contentTypes URL: %@ is not valid!",contentTypesPath);						
			}
			else {
				NSXMLParser * contentTypesParser = [[NSXMLParser alloc] initWithContentsOfURL:contentTypesURL];
				BlioXPSContentTypesParserDelegate * contentTypesParserDelegate = [[BlioXPSContentTypesParserDelegate alloc] init];
				[contentTypesParser setDelegate:contentTypesParserDelegate];
				[contentTypesParser parse];
				NSString * documentPropertiesPath = [contentTypesParserDelegate.documentPropertiesPath retain];
				[contentTypesParserDelegate release];
				[contentTypesParser release];
				if (documentPropertiesPath) {
					NSURL * documentPropertiesURL = [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:documentPropertiesPath]];
					if (!documentPropertiesURL) {
						NSLog(@"ERROR: Document Properties URL: %@ is not valid!",[cachePath stringByAppendingPathComponent:documentPropertiesPath]);						
					}
					else {
						NSXMLParser * documentPropertiesParser = [[NSXMLParser alloc] initWithContentsOfURL:documentPropertiesURL];
						BlioXPSDocumentPropertiesParserDelegate * documentPropertiesParserDelegate = [[BlioXPSDocumentPropertiesParserDelegate alloc] init];
						[documentPropertiesParser setDelegate:documentPropertiesParserDelegate];
						[documentPropertiesParser parse];
						// grab title and author
						if (documentPropertiesParserDelegate.title) importableBook.title = documentPropertiesParserDelegate.title;
						if (documentPropertiesParserDelegate.authors) importableBook.authors = documentPropertiesParserDelegate.authors;
						[documentPropertiesParserDelegate release];
						[documentPropertiesParser release];
					}
				}
				else {
					NSLog(@"WARNING: path to Document Properties file is nil!");
				}
				[documentPropertiesPath release];
			}
		}
		
		// delete cache files
		NSError *anError;
		if (![[NSFileManager defaultManager] removeItemAtPath:cachePath error:&anError]) {
			NSLog(@"Failed to delete unzipped directory at path %@ with error: %@", cachePath, [anError localizedDescription]);
		}
	}
	else if ([aFile.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSData *aData = [[NSData alloc] initWithContentsOfFile:importableBook.filePath];
        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)aData);
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithProvider(dataProvider);
		CGPDFDictionaryRef pdfInfo = CGPDFDocumentGetInfo(pdfRef);
		CGPDFStringRef string;
		if (CGPDFDictionaryGetString(pdfInfo, "Title", &string)) {
			CFStringRef s;
			s = CGPDFStringCopyTextString(string);
			if (s != NULL) {
				importableBook.title = (NSString *)s;
				CFRelease(s);			
			}
		}
		if (CGPDFDictionaryGetString(pdfInfo, "Author", &string)) {
			CFStringRef s;
			s = CGPDFStringCopyTextString(string);
			if (s != NULL) {
				importableBook.authors = [NSArray arrayWithObject:(NSString *)s];
				CFRelease(s);			
			}
		}

		CGPDFDocumentRelease(pdfRef);
        CGDataProviderRelease(dataProvider);
        [aData release];
	}
	[pool drain];
	return importableBook;
}
-(void)importBook:(BlioImportableBook*)importableBook {
	NSString * title = nil;
	if (importableBook.title) title = importableBook.title;
	else title = importableBook.fileName;
	
	// check for duplicates
	
	NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    if (!moc) {
        NSLog(@"WARNING: MOC was not able to be obtained from BlioBookManager by BlioFileSharingManager!");
	}
	else {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceSpecificID == %@ && sourceID == %@", importableBook.fileName,[NSNumber numberWithInt:BlioBookSourceFileSharing]]];
		
		NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		
		if (errorExecute) {
			NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
			return;
		}
		if ([results count] >= 1) {
			NSLog(@"Found FileSharing Book in context already- will not add to library. aborting..."); 
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title")
										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"IMPORTABLE_BOOK_ALREADY_FOUND_IN_LIBRARY",nil,[NSBundle mainBundle],@"This book will not be imported because your library already has a book imported from the same file name: %@.",@"Alert message informing the end-user that importing of selected book will not occur because the library already has a book imported from the same file name."),importableBook.fileName]
										delegate:nil 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles: nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioFileSharingImportAborted object:importableBook];
			return;
		}
	}
	if ([[importableBook.fileName pathExtension] compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																		   authors:importableBook.authors   
																		 coverPath:nil
																		  ePubPath:importableBook.fileName 
																		   pdfPath:nil 
																		   xpsPath:nil
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:BlioBookSourceFileSharing 
																  sourceSpecificID:importableBook.sourceSpecificID
																   placeholderOnly:NO
		 ];
		
	}
	else if ([[importableBook.fileName pathExtension] compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																		   authors:importableBook.authors   
																		 coverPath:nil
																		  ePubPath:nil 
																		   pdfPath:importableBook.fileName 
																		   xpsPath:nil
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:BlioBookSourceFileSharing 
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
																		   xpsPath:importableBook.fileName 
																	  textFlowPath:nil 
																	 audiobookPath:nil 
																		  sourceID:BlioBookSourceFileSharing 
																  sourceSpecificID:importableBook.sourceSpecificID
																   placeholderOnly:NO
		 ];		
	}
	
}

-(void)importAllBooks {
	for (NSString * filePath in self.importableBooks) {
//		NSString * title = [filePath lastPathComponent];
//		NSString * authors = [NSMutableArray array];
//		
//		if ([file.pathExtension compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
//			
//			[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
//																			   authors:authors   
//																			 coverPath:nil
//																			  ePubPath:nil 
//																			   pdfPath:nil 
//																			   xpsPath:nil
//																		  textFlowPath:nil 
//																		 audiobookPath:nil 
//																			  sourceID:BlioBookSourceUserFileSharing 
//																	  sourceSpecificID:title
//																	   placeholderOnly:YES
//			 ];
//			 
//		}
//		else if ([file.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
//			
//		}
//		else if ([file.pathExtension compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
//			
//		}
	}
}
- (void)onProcessingCompleteNotification:(NSNotification*)note {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	// delete file from public documents directory.
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [[[note userInfo] objectForKey:@"sourceID"] intValue] == BlioBookSourceFileSharing) {
		NSString * filePath = [[BlioFileSharingManager fileSharingDirectory] stringByAppendingPathComponent:[[note userInfo] objectForKey:@"sourceSpecificID"]];
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
