//
//  BlioEPubMetadataReader.m
//  BlioApp
//
//  Created by James Montgomerie on 05/03/2012.
//  Copyright (c) 2012 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubMetadataReader.h"
#import "BlioBook.h"

#import "KNFBXMLParserLock.h"

#import <libEucalyptus/EucEPubBook.h>

@interface BlioEPubEncryptionParserDelegate : NSObject<NSXMLParserDelegate>
@property(nonatomic,retain) NSString *unknownEncryptionAlgorithm;
@end

@implementation BlioEPubEncryptionParserDelegate

@synthesize unknownEncryptionAlgorithm;

- (void)dealloc {
    self.unknownEncryptionAlgorithm = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ( [elementName isEqualToString:@"EncryptionMethod"] ) {
		NSString * algorithm = [attributeDict objectForKey:@"Algorithm"];
		if (algorithm) {
            if(![[EucEPubBook knownEncryptionAlgorithms] containsObject:algorithm]) {
                self.unknownEncryptionAlgorithm = algorithm;
                [parser abortParsing];
            }
		}
	}
}

@end


@interface BlioEPubContainerParserDelegate : NSObject<NSXMLParserDelegate>
@property(nonatomic,retain) NSString *opfPath;
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
	if ( [elementName isEqualToString:@"rootfile"] ) {
		NSString * fullPath = [attributeDict objectForKey:@"full-path"];
		if (fullPath) {
			self.opfPath = fullPath;
		}
	}
}

@end


@interface BlioEPubOPFParserDelegate : NSObject<NSXMLParserDelegate> {
	NSMutableString * _characterString;
	NSString * _fileAs;
}
@property(nonatomic, retain) NSDecimalNumber *version;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSMutableArray *authors;
@end

@implementation BlioEPubOPFParserDelegate

@synthesize version, title, authors;

- (id)init {
	if ((self = [super init])) {
		self.authors = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	if (_characterString) {
        [_characterString release];
    }
    self.version = nil;
	self.title = nil;
	self.authors = nil;
	[super dealloc];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ( [elementName isEqualToString:@"package"] || [elementName rangeOfString:@":package"].location != NSNotFound) {
        NSString *versionString = [attributeDict objectForKey:@"version"];
        if ( versionString ) {
            self.version = [NSDecimalNumber decimalNumberWithString:versionString
                                                             locale:[NSDictionary dictionaryWithObject:@"." 
                                                                                                forKey:@"NSDecimalSeparator"]];
        }
    }
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
        _characterString = [[NSMutableString alloc] init];
    }
    [_characterString appendString:string];
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

@interface BlioEPubMetadataReader ()

@property (nonatomic, assign) id<BlioEPubMetadataReaderDataProvider> dataProvider;

@property (nonatomic, assign) BOOL hasRightsXML;

@property (nonatomic, assign) BOOL hasEncryptionXML;
@property (nonatomic, retain) NSString *unknownEncryptionAlgorithm;

@property (nonatomic, assign) BOOL hasContainerXML;

@property (nonatomic, assign) BOOL hasPackageFile;

@property (nonatomic, retain) NSDecimalNumber *packageVersion;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *authors;

@end

@implementation BlioEPubMetadataReader 

@synthesize dataProvider;

@synthesize hasRightsXML;

@synthesize hasEncryptionXML;
@synthesize unknownEncryptionAlgorithm;

@synthesize hasContainerXML;

@synthesize hasPackageFile;
@synthesize packageVersion, title, authors;

- (id)initWithDataProvider:(id<BlioEPubMetadataReaderDataProvider>)dataProviderIn
{
    if((self = [super init])) {
        self.dataProvider = dataProviderIn;
        
        if([self.dataProvider blioEPubMetadataReader:self componentExistsAtPath:@"META-INF/rights.xml"]) {
            self.hasRightsXML = YES;
        }
        
        NSData *encryptionXMLData = [self.dataProvider blioEPubMetadataReader:self copyDataForComponentAtPath:@"META-INF/encryption.xml"];
        if(encryptionXMLData) {
            self.hasEncryptionXML = YES;
            BlioEPubEncryptionParserDelegate *encryptionParserDelegate = [[BlioEPubEncryptionParserDelegate alloc] init];
            @synchronized([KNFBXMLParserLock sharedLock]) {
                NSXMLParser * containerParser = [[NSXMLParser alloc] initWithData:encryptionXMLData];
                containerParser.shouldProcessNamespaces = YES;
                [containerParser setDelegate:encryptionParserDelegate];
                [containerParser parse];
                [containerParser release];
            }
            self.unknownEncryptionAlgorithm = [[encryptionParserDelegate.unknownEncryptionAlgorithm retain] autorelease];
            [encryptionParserDelegate release];
            [encryptionXMLData release];
        }

        NSData *containerXMLData = [self.dataProvider blioEPubMetadataReader:self copyDataForComponentAtPath:@"META-INF/container.xml"];
        if(containerXMLData) {
            self.hasContainerXML = YES;
            BlioEPubContainerParserDelegate *containerParserDelegate = [[BlioEPubContainerParserDelegate alloc] init];
            @synchronized([KNFBXMLParserLock sharedLock]) {
                NSXMLParser * containerParser = [[NSXMLParser alloc] initWithData:containerXMLData];
                [containerParser setDelegate:containerParserDelegate];
                [containerParser parse];
                [containerParser release];
            }
            NSString *opfPath = [containerParserDelegate.opfPath retain];
            [containerParserDelegate release];
            [containerXMLData release];
            
            if(opfPath) {
                NSData *opfXMLData = [self.dataProvider blioEPubMetadataReader:self copyDataForComponentAtPath:opfPath];
                if(opfXMLData) {
                    self.hasPackageFile = YES;
                    BlioEPubOPFParserDelegate *opfParserDelegate = [[BlioEPubOPFParserDelegate alloc] init];
                    @synchronized([KNFBXMLParserLock sharedLock]) {
                        NSXMLParser * opfParser = [[NSXMLParser alloc] initWithData:opfXMLData];
                        [opfParser setDelegate:opfParserDelegate];
                        [opfParser parse];
                        [opfParser release];
                    }
                    self.packageVersion = opfParserDelegate.version;
                    self.title = opfParserDelegate.title;
                    self.authors = opfParserDelegate.authors;
                    
                    [opfParserDelegate release];
                    [opfXMLData release];
                }
                [opfPath release];
            }
        } 
    }
    return self;
}
       
- (void)dealloc 
{
    self.unknownEncryptionAlgorithm = nil;
    self.packageVersion = nil;
    self.title = nil;
    self.authors = nil;
    
    [super dealloc];
}

@end
