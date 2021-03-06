#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"

@class BookVault_RegisterSale;
@class BookVault_RegisterSaleResponse;
@class BookVault_RegisterSaleResult;
@class BookVault_VaultContentsWithToken;
@class BookVault_VaultContentsWithTokenEx;
@class BookVault_VaultContentsWithTokenResponse;
@class BookVault_VaultContentsWithTokenExResponse;
@class BookVault_VaultContentsResult;
@class BookVault_ArrayOfString;
@class BookVault_ArrayOfBookOwnershipInfo;
@class BookVault_BookOwnershipInfo;
@class BookVault_VaultContents;
@class BookVault_VaultContentsResponse;
@class BookVault_RequestDownloadWithToken;
@class BookVault_RequestDownloadWithTokenResponse;
@class BookVault_RequestDownloadResult;
@class BookVault_RequestDownload;
@class BookVault_RequestDownloadResponse;
@class BookVault_Login;
@class BookVault_LoginResponse;
@class BookVault_LoginResult;
@class BookVault_DeleteBook;
@class BookVault_DeleteBookResponse;
@class BookVault_DeleteBookResult;

static NSString * const BlioBookVaultResponseTypeRegisterSale = @"RegisterSaleResponse";
static NSString * const BlioBookVaultResponseTypeVaultContentsWithToken = @"VaultContentsWithTokenResponse";
static NSString * const BlioBookVaultResponseTypeVaultContentsWithTokenEx = @"VaultContentsWithTokenExResponse";
static NSString * const BlioBookVaultResponseTypeVaultContents = @"VaultContentsResponse";
static NSString * const BlioBookVaultResponseTypeRequestDownloadWithToken = @"RequestDownloadWithTokenResponse";
static NSString * const BlioBookVaultResponseTypeRequestDownloadWithTokenEx = @"RequestDownloadWithTokenExResponse";
static NSString * const BlioBookVaultResponseTypeRequestClientDownloadWithTokenEx = @"RequestClientDownloadWithTokenExResponse";
static NSString * const BlioBookVaultResponseTypeRequestDownload = @"RequestDownloadResponse";
static NSString * const BlioBookVaultResponseTypeLogin = @"LoginResponse";
static NSString * const BlioBookVaultResponseTypeDeleteBook = @"DeleteBook";

@interface BookVault_DeleteBook : NSObject {
	
	/* elements */
	NSString * token;
	NSString * ISBN;
	NSNumber * productTypeId;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_DeleteBook *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
@property (retain) NSString * ISBN;
@property (retain) NSNumber * productTypeId;
/* attributes */
- (NSDictionary *)attributes;
@end

@interface BookVault_DeleteBookResult : NSObject {
	
    /* elements */
	NSNumber * ReturnCode;
	NSString * Message;
    /* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_DeleteBookResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_DeleteBookResponse : NSObject {
	
    /* elements */
	BookVault_DeleteBookResult * DeleteBookResult;
    /* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_DeleteBookResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_DeleteBookResult * DeleteBookResult;
/* attributes */
- (NSDictionary *)attributes;
@end

@interface BookVault_RegisterSale : NSObject {
	
/* elements */
	NSString * authId;
	NSString * authToken;
	NSString * uuid;
	NSNumber * siteId;
	NSString * productId;
	NSString * isbn;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RegisterSale *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * authId;
@property (retain) NSString * authToken;
@property (retain) NSString * uuid;
@property (retain) NSNumber * siteId;
@property (retain) NSString * productId;
@property (retain) NSString * isbn;
/* attributes */
- (NSDictionary *)attributes;
@end

@interface BookVault_RegisterSaleResult : NSObject {
	
/* elements */
	NSNumber * ReturnCode;
	NSString * Message;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RegisterSaleResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RegisterSaleResponse : NSObject {
	
/* elements */
	BookVault_RegisterSaleResult * RegisterSaleResult;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RegisterSaleResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_RegisterSaleResult * RegisterSaleResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsWithToken : NSObject {
	
/* elements */
	NSString * token;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsWithToken *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsWithTokenEx : NSObject {
	
	/* elements */
	NSString * token;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsWithTokenEx *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_ArrayOfString : NSObject {
	
/* elements */
	NSMutableArray *string;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_ArrayOfString *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addString:(NSString *)toAdd;
@property (readonly) NSMutableArray * string;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_ArrayOfBookOwnershipInfo : NSObject {
	
	/* elements */
	NSMutableArray *BookOwnershipInfo;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_ArrayOfBookOwnershipInfo *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addBookOwnershipInfo:(BookVault_BookOwnershipInfo *)toAdd;
@property (readonly) NSMutableArray * BookOwnershipInfo;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_BookOwnershipInfo : NSObject {
	
	/* elements */
	NSString * ISBN;
	NSNumber * ProductTypeId;
	NSString * ProductTypeName;
	NSNumber * FormatTypeId;
	NSString * FormatTypeName;
	NSString * ExpirationDate;
	NSNumber * RecordStatusId;
	NSString * RecordStatusName;
	NSString * TransactionType;
	NSNumber * NumDownloads;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_BookOwnershipInfo *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * ISBN;
@property (retain) NSNumber * ProductTypeId;
@property (retain) NSString * ProductTypeName;
@property (retain) NSNumber * FormatTypeId;
@property (retain) NSString * FormatTypeName;
@property (retain) NSString * ExpirationDate;
@property (retain) NSNumber * RecordStatusId;
@property (retain) NSString * RecordStatusName;
@property (retain) NSString * TransactionType;
@property (retain) NSNumber * NumDownloads;
/* attributes */
- (NSDictionary *)attributes;
@end

@interface BookVault_VaultContentsResult : NSObject {
	
	/* elements */
	NSNumber * ReturnCode;
	NSString * Message;
	BookVault_ArrayOfString * Contents;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
@property (retain) BookVault_ArrayOfString * Contents;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsExResult : NSObject {
	
	/* elements */
	NSNumber * ReturnCode;
	NSString * Message;
	BookVault_ArrayOfBookOwnershipInfo * Contents;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsExResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
@property (retain) BookVault_ArrayOfBookOwnershipInfo * Contents;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsWithTokenResponse : NSObject {
	
/* elements */
	BookVault_VaultContentsResult * VaultContentsWithTokenResult;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsWithTokenResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_VaultContentsResult * VaultContentsWithTokenResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsWithTokenExResponse : NSObject {
	
	/* elements */
	BookVault_VaultContentsExResult * VaultContentsWithTokenExResult;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsWithTokenExResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_VaultContentsExResult * VaultContentsWithTokenExResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContents : NSObject {
	
/* elements */
	NSString * username;
	NSString * password;
	NSNumber * siteId;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContents *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * username;
@property (retain) NSString * password;
@property (retain) NSNumber * siteId;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_VaultContentsResponse : NSObject {
	
/* elements */
	BookVault_VaultContentsResult * VaultContentsResult;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_VaultContentsResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_VaultContentsResult * VaultContentsResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadWithToken : NSObject {
	
	/* elements */
	NSString * token;
	NSString * isbn;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadWithToken *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
@property (retain) NSString * isbn;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadWithTokenEx : NSObject {
	
	/* elements */
	NSString * token;
	NSString * isbn;
	NSNumber * productType;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadWithTokenEx *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
@property (retain) NSString * isbn;
@property (retain) NSNumber * productType;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestClientDownloadWithTokenEx : NSObject {
	
	/* elements */
	NSString * token;
	NSString * isbn;
	NSNumber * productType;
	NSString * clientInfo;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestClientDownloadWithTokenEx *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * token;
@property (retain) NSString * isbn;
@property (retain) NSNumber * productType;
@property (retain) NSString * clientInfo;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadResult : NSObject {
	
    /* elements */
	NSNumber * ReturnCode;
	NSString * Message;
	NSString * Url;
    /* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
@property (retain) NSString * Url;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadWithTokenResponse : NSObject {
	
	/* elements */
	BookVault_RequestDownloadResult * RequestDownloadWithTokenResult;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadWithTokenResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_RequestDownloadResult * RequestDownloadWithTokenResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadWithTokenExResponse : NSObject {
	
	/* elements */
	BookVault_RequestDownloadResult * RequestDownloadWithTokenExResult;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadWithTokenExResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_RequestDownloadResult * RequestDownloadWithTokenExResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestClientDownloadWithTokenExResponse : NSObject {
	
	/* elements */
	BookVault_RequestDownloadResult * RequestClientDownloadWithTokenExResult;
	/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestClientDownloadWithTokenExResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_RequestDownloadResult * RequestClientDownloadWithTokenExResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownload : NSObject {
	
/* elements */
	NSString * username;
	NSString * password;
	NSNumber * siteId;
	NSString * isbn;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownload *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * username;
@property (retain) NSString * password;
@property (retain) NSNumber * siteId;
@property (retain) NSString * isbn;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_RequestDownloadResponse : NSObject {
	
/* elements */
	BookVault_RequestDownloadResult * RequestDownloadResult;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_RequestDownloadResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_RequestDownloadResult * RequestDownloadResult;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_Login : NSObject {
	
/* elements */
	NSString * username;
	NSString * password;
	NSNumber * siteId;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_Login *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * username;
@property (retain) NSString * password;
@property (retain) NSNumber * siteId;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_LoginResult : NSObject {
	
/* elements */
	NSNumber * ReturnCode;
	NSString * Message;
	NSString * Token;
	NSNumber * Timeout;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_LoginResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * ReturnCode;
@property (retain) NSString * Message;
@property (retain) NSString * Token;
@property (retain) NSNumber * Timeout;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface BookVault_LoginResponse : NSObject {
	
/* elements */
	BookVault_LoginResult * LoginResult;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (BookVault_LoginResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) BookVault_LoginResult * LoginResult;
/* attributes */
- (NSDictionary *)attributes;
@end
/* Cookies handling provided by http://en.wikibooks.org/wiki/Programming:WebObjects/Web_Services/Web_Service_Provider */
#import <libxml/parser.h>
#import "xsd.h"
#import "BlioBookVault.h"
@class BookVaultSoap;
@class BookVaultSoap12;
@interface BookVault : NSObject {
	
}
+ (BookVaultSoap *)BookVaultSoap;
+ (BookVaultSoap12 *)BookVaultSoap12;
@end
@class BookVaultSoapResponse;
@class BookVaultSoapOperation;
@protocol BookVaultSoapResponseDelegate <NSObject>
- (void) operation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response;
@end
@interface BookVaultSoap : NSObject <BookVaultSoapResponseDelegate> {
	NSURL *address;
	NSTimeInterval defaultTimeout;
	NSMutableArray *cookies;
	BOOL logXMLInOut;
	BOOL synchronousOperationComplete;
	NSString *authUsername;
	NSString *authPassword;
}
@property (copy) NSURL *address;
@property (assign) BOOL logXMLInOut;
@property (assign) NSTimeInterval defaultTimeout;
@property (nonatomic, retain) NSMutableArray *cookies;
@property (nonatomic, retain) NSString *authUsername;
@property (nonatomic, retain) NSString *authPassword;
- (id)initWithAddress:(NSString *)anAddress;
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(BookVaultSoapOperation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (BookVaultSoapResponse *)DeleteBookUsingParameters:(BookVault_DeleteBook *)aParameters ;
- (void)DeleteBookAsyncUsingParameters:(BookVault_DeleteBook *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)RegisterSaleUsingParameters:(BookVault_RegisterSale *)aParameters ;
- (void)RegisterSaleAsyncUsingParameters:(BookVault_RegisterSale *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)VaultContentsWithTokenUsingParameters:(BookVault_VaultContentsWithToken *)aParameters ;
- (void)VaultContentsWithTokenAsyncUsingParameters:(BookVault_VaultContentsWithToken *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (void)VaultContentsWithTokenExAsyncUsingParameters:(BookVault_VaultContentsWithTokenEx *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)VaultContentsUsingParameters:(BookVault_VaultContents *)aParameters ;
- (void)VaultContentsAsyncUsingParameters:(BookVault_VaultContents *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)RequestDownloadWithTokenUsingParameters:(BookVault_RequestDownloadWithToken *)aParameters ;
- (BookVaultSoapResponse *)RequestDownloadWithTokenExUsingParameters:(BookVault_RequestDownloadWithTokenEx *)aParameters ;
- (BookVaultSoapResponse *)RequestClientDownloadWithTokenExUsingParameters:(BookVault_RequestClientDownloadWithTokenEx *)aParameters ;
- (void)RequestDownloadWithTokenAsyncUsingParameters:(BookVault_RequestDownloadWithToken *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)RequestDownloadUsingParameters:(BookVault_RequestDownload *)aParameters ;
- (void)RequestDownloadAsyncUsingParameters:(BookVault_RequestDownload *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
- (BookVaultSoapResponse *)LoginUsingParameters:(BookVault_Login *)aParameters ;
- (void)LoginAsyncUsingParameters:(BookVault_Login *)aParameters  delegate:(id<BookVaultSoapResponseDelegate>)responseDelegate;
@end
@interface BookVaultSoapOperation : NSOperation {
	BookVaultSoap *binding;
	BookVaultSoapResponse *response;
	id<BookVaultSoapResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) BookVaultSoap *binding;
@property (readonly) BookVaultSoapResponse *response;
@property (nonatomic, assign) id<BookVaultSoapResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate;
@end
@interface BookVaultSoap_DeleteBook : BookVaultSoapOperation {
	BookVault_DeleteBook * parameters;
}
@property (retain) BookVault_DeleteBook * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
           parameters:(BookVault_DeleteBook *)aParameters
;
@end
@interface BookVaultSoap_RegisterSale : BookVaultSoapOperation {
	BookVault_RegisterSale * parameters;
}
@property (retain) BookVault_RegisterSale * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_RegisterSale *)aParameters
;
@end
@interface BookVaultSoap_VaultContentsWithToken : BookVaultSoapOperation {
	BookVault_VaultContentsWithToken * parameters;
}
@property (retain) BookVault_VaultContentsWithToken * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_VaultContentsWithToken *)aParameters;
@end
@interface BookVaultSoap_VaultContentsWithTokenEx : BookVaultSoapOperation {
	BookVault_VaultContentsWithTokenEx * parameters;
}
@property (retain) BookVault_VaultContentsWithTokenEx * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
		   parameters:(BookVault_VaultContentsWithTokenEx *)aParameters;
@end
@interface BookVaultSoap_VaultContents : BookVaultSoapOperation {
	BookVault_VaultContents * parameters;
}
@property (retain) BookVault_VaultContents * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_VaultContents *)aParameters
;
@end
@interface BookVaultSoap_RequestDownloadWithToken : BookVaultSoapOperation {
	BookVault_RequestDownloadWithToken * parameters;
}
@property (retain) BookVault_RequestDownloadWithToken * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_RequestDownloadWithToken *)aParameters
;
@end
@interface BookVaultSoap_RequestDownloadWithTokenEx : BookVaultSoapOperation {
	BookVault_RequestDownloadWithTokenEx * parameters;
}
@property (retain) BookVault_RequestDownloadWithTokenEx * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
		   parameters:(BookVault_RequestDownloadWithTokenEx *)aParameters
;
@end
@interface BookVaultSoap_RequestClientDownloadWithTokenEx : BookVaultSoapOperation {
	BookVault_RequestClientDownloadWithTokenEx * parameters;
}
@property (retain) BookVault_RequestClientDownloadWithTokenEx * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
		   parameters:(BookVault_RequestClientDownloadWithTokenEx *)aParameters
;
@end

@interface BookVaultSoap_RequestDownload : BookVaultSoapOperation {
	BookVault_RequestDownload * parameters;
}
@property (retain) BookVault_RequestDownload * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_RequestDownload *)aParameters
;
@end
@interface BookVaultSoap_Login : BookVaultSoapOperation {
	BookVault_Login * parameters;
}
@property (retain) BookVault_Login * parameters;
- (id)initWithBinding:(BookVaultSoap *)aBinding delegate:(id<BookVaultSoapResponseDelegate>)aDelegate
	parameters:(BookVault_Login *)aParameters
;
@end
@interface BookVaultSoap_envelope : NSObject {
}
+ (BookVaultSoap_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface BookVaultSoapResponse : NSObject {
	NSString * responseType;
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSString * responseType;
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
@class BookVaultSoap12Response;
@class BookVaultSoap12Operation;
@protocol BookVaultSoap12ResponseDelegate <NSObject>
- (void) operation:(BookVaultSoap12Operation *)operation completedWithResponse:(BookVaultSoap12Response *)response;
@end
@interface BookVaultSoap12 : NSObject <BookVaultSoap12ResponseDelegate> {
	NSURL *address;
	NSTimeInterval defaultTimeout;
	NSMutableArray *cookies;
	BOOL logXMLInOut;
	BOOL synchronousOperationComplete;
	NSString *authUsername;
	NSString *authPassword;
}
@property (copy) NSURL *address;
@property (assign) BOOL logXMLInOut;
@property (assign) NSTimeInterval defaultTimeout;
@property (nonatomic, retain) NSMutableArray *cookies;
@property (nonatomic, retain) NSString *authUsername;
@property (nonatomic, retain) NSString *authPassword;
- (id)initWithAddress:(NSString *)anAddress;
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(BookVaultSoap12Operation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (BookVaultSoap12Response *)DeleteBookUsingParameters:(BookVault_DeleteBook *)aParameters ;
- (void)DeleteBookAsyncUsingParameters:(BookVault_DeleteBook *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)RegisterSaleUsingParameters:(BookVault_RegisterSale *)aParameters ;
- (void)RegisterSaleAsyncUsingParameters:(BookVault_RegisterSale *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)VaultContentsWithTokenUsingParameters:(BookVault_VaultContentsWithToken *)aParameters ;
- (void)VaultContentsWithTokenAsyncUsingParameters:(BookVault_VaultContentsWithToken *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)VaultContentsUsingParameters:(BookVault_VaultContents *)aParameters ;
- (void)VaultContentsAsyncUsingParameters:(BookVault_VaultContents *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)RequestDownloadWithTokenUsingParameters:(BookVault_RequestDownloadWithToken *)aParameters ;
- (void)RequestDownloadWithTokenAsyncUsingParameters:(BookVault_RequestDownloadWithToken *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)RequestDownloadUsingParameters:(BookVault_RequestDownload *)aParameters ;
- (void)RequestDownloadAsyncUsingParameters:(BookVault_RequestDownload *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
- (BookVaultSoap12Response *)LoginUsingParameters:(BookVault_Login *)aParameters ;
- (void)LoginAsyncUsingParameters:(BookVault_Login *)aParameters  delegate:(id<BookVaultSoap12ResponseDelegate>)responseDelegate;
@end
@interface BookVaultSoap12Operation : NSOperation {
	BookVaultSoap12 *binding;
	BookVaultSoap12Response *response;
	id<BookVaultSoap12ResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) BookVaultSoap12 *binding;
@property (readonly) BookVaultSoap12Response *response;
@property (nonatomic, assign) id<BookVaultSoap12ResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate;
@end
@interface BookVaultSoap12_DeleteBook : BookVaultSoap12Operation {
	BookVault_DeleteBook * parameters;
}
@property (retain) BookVault_DeleteBook * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
           parameters:(BookVault_DeleteBook *)aParameters
;
@end
@interface BookVaultSoap12_RegisterSale : BookVaultSoap12Operation {
	BookVault_RegisterSale * parameters;
}
@property (retain) BookVault_RegisterSale * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_RegisterSale *)aParameters
;
@end
@interface BookVaultSoap12_VaultContentsWithToken : BookVaultSoap12Operation {
	BookVault_VaultContentsWithToken * parameters;
}
@property (retain) BookVault_VaultContentsWithToken * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_VaultContentsWithToken *)aParameters;
@end
@interface BookVaultSoap12_VaultContentsWithTokenEx : BookVaultSoap12Operation {
	BookVault_VaultContentsWithTokenEx * parameters;
}
@property (retain) BookVault_VaultContentsWithTokenEx * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
		   parameters:(BookVault_VaultContentsWithTokenEx *)aParameters;
@end
@interface BookVaultSoap12_VaultContents : BookVaultSoap12Operation {
	BookVault_VaultContents * parameters;
}
@property (retain) BookVault_VaultContents * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_VaultContents *)aParameters
;
@end
@interface BookVaultSoap12_RequestDownloadWithToken : BookVaultSoap12Operation {
	BookVault_RequestDownloadWithToken * parameters;
}
@property (retain) BookVault_RequestDownloadWithToken * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_RequestDownloadWithToken *)aParameters
;
@end
@interface BookVaultSoap12_RequestDownload : BookVaultSoap12Operation {
	BookVault_RequestDownload * parameters;
}
@property (retain) BookVault_RequestDownload * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_RequestDownload *)aParameters
;
@end
@interface BookVaultSoap12_Login : BookVaultSoap12Operation {
	BookVault_Login * parameters;
}
@property (retain) BookVault_Login * parameters;
- (id)initWithBinding:(BookVaultSoap12 *)aBinding delegate:(id<BookVaultSoap12ResponseDelegate>)aDelegate
	parameters:(BookVault_Login *)aParameters
;
@end
@interface BookVaultSoap12_envelope : NSObject {
}
+ (BookVaultSoap12_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface BookVaultSoap12Response : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
