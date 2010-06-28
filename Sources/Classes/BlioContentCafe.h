#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"
@class ContentCafe_Test1;
@class ContentCafe_Test1Response;
@class ContentCafe_ContentCafeXML;
@class ContentCafe_Search;
@class ContentCafe_RequestItems;
@class ContentCafe_SearchOptions;
@class ContentCafe_SearchGroups;
@class ContentCafe_SearchResults;
@class ContentCafe_SearchSortBy;
@class ContentCafe_SearchGroup;
@class ContentCafe_SearchItem;
@class ContentCafe_ProductItem;
@class ContentCafe_Title;
@class ContentCafe_CodeLiteral;
@class ContentCafe_RequestItem;
@class ContentCafe_Key;
@class ContentCafe_Content;
@class ContentCafe_Environment;
@class ContentCafe_MemberItem;
@class ContentCafe_MemberItems;
@class ContentCafe_AvailableContent;
@class ContentCafe_AnnotationSummaryItems;
@class ContentCafe_AnnotationItems;
@class ContentCafe_ReviewSummaryItems;
@class ContentCafe_ReviewItems;
@class ContentCafe_BiographySummaryItems;
@class ContentCafe_BiographyItems;
@class ContentCafe_FlapSummaryItems;
@class ContentCafe_FlapItems;
@class ContentCafe_InventorySummaryItems;
@class ContentCafe_InventoryItems;
@class ContentCafe_DemandSummaryItems;
@class ContentCafe_DemandItems;
@class ContentCafe_DemandHistorySummaryItems;
@class ContentCafe_DemandHistoryItems;
@class ContentCafe_JacketSummaryItems;
@class ContentCafe_JacketItems;
@class ContentCafe_TocSummaryItems;
@class ContentCafe_TocItems;
@class ContentCafe_ExcerptSummaryItems;
@class ContentCafe_ExcerptItems;
@class ContentCafe_ProductSummaryItems;
@class ContentCafe_ProductItems;
@class ContentCafe_MuzeSummaryItems;
@class ContentCafe_Muze;
@class ContentCafe_ReviewPublicationItems;
@class ContentCafe_InventoryAvailabilityItems;
@class ContentCafe_MemberLinkItems;
@class ContentCafe_InventoryAvailabilityItem;
@class ContentCafe_MemberLinkItem;
@class ContentCafe_AnnotationSummaryItem;
@class ContentCafe_AnnotationItem;
@class ContentCafe_ReviewSummaryItem;
@class ContentCafe_ReviewItem;
@class ContentCafe_BiographySummaryItem;
@class ContentCafe_BiographyItem;
@class ContentCafe_FlapSummaryItem;
@class ContentCafe_FlapItem;
@class ContentCafe_InventorySummaryItem;
@class ContentCafe_InventoryItem;
@class ContentCafe_DemandSummaryItem;
@class ContentCafe_DemandItem;
@class ContentCafe_DemandHistorySummaryItem;
@class ContentCafe_DemandHistoryItem;
@class ContentCafe_JacketSummaryItem;
@class ContentCafe_JacketItem;
@class ContentCafe_JacketElement;
@class ContentCafe_TocSummaryItem;
@class ContentCafe_TocItem;
@class ContentCafe_ExcerptSummaryItem;
@class ContentCafe_ExcerptItem;
@class ContentCafe_ProductSummaryItem;
@class ContentCafe_MuzeSummaryItem;
@class ContentCafe_Test2;
@class ContentCafe_Test2Response;
@class ContentCafe_Test3;
@class ContentCafe_Test3Response;
@class ContentCafe_Test4;
@class ContentCafe_Test4Response;
@class ContentCafe_XmlPost;
@class ContentCafe_XmlPostResponse;
@class ContentCafe_XmlString;
@class ContentCafe_XmlStringResponse;
@class ContentCafe_XmlClass;
@class ContentCafe_XmlClassResponse;
@class ContentCafe_Single;
@class ContentCafe_SingleResponse;
@interface ContentCafe_Test1 : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test1 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end

typedef enum {
	ContentCafe_SearchSortField_none = 0,
	ContentCafe_SearchSortField_Undefined,
	ContentCafe_SearchSortField_ISBN,
	ContentCafe_SearchSortField_UPC,
	ContentCafe_SearchSortField_Title,
	ContentCafe_SearchSortField_Author,
	ContentCafe_SearchSortField_Updated,
} ContentCafe_SearchSortField;

ContentCafe_SearchSortField ContentCafe_SearchSortField_enumFromString(NSString *string);
NSString * ContentCafe_SearchSortField_stringFromEnum(ContentCafe_SearchSortField enumValue);
typedef enum {
	ContentCafe_SearchSortOrderType_none = 0,
	ContentCafe_SearchSortOrderType_Ascending,
	ContentCafe_SearchSortOrderType_Descending,
} ContentCafe_SearchSortOrderType;
ContentCafe_SearchSortOrderType ContentCafe_SearchSortOrderType_enumFromString(NSString *string);
NSString * ContentCafe_SearchSortOrderType_stringFromEnum(ContentCafe_SearchSortOrderType enumValue);

// ContentCafe_SearchSortField is an enum not an interface so this looks like a bug
@interface ContentCafe_SearchSortBy : NSObject /*was  : ContentCafe_SearchSortField*/ {
	
/* elements */
/* attributes */
	ContentCafe_SearchSortOrderType Order;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchSortBy *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (assign) ContentCafe_SearchSortOrderType Order;
@end
@interface ContentCafe_SearchOptions : NSObject {
	
/* elements */
	NSNumber * MaxRecords;
	NSNumber * Offset;
	USBoolean * ShowQuery;
	NSMutableArray *SortBy;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchOptions *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * MaxRecords;
@property (retain) NSNumber * Offset;
@property (retain) USBoolean * ShowQuery;
- (void)addSortBy:(ContentCafe_SearchSortBy *)toAdd;
@property (readonly) NSMutableArray * SortBy;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	ContentCafe_SearchIndex_none = 0,
	ContentCafe_SearchIndex_Undefined,
	ContentCafe_SearchIndex_ISBN_String,
	ContentCafe_SearchIndex_UPC_String,
	ContentCafe_SearchIndex_Title_String,
	ContentCafe_SearchIndex_Author_String,
	ContentCafe_SearchIndex_BTKey_String,
	ContentCafe_SearchIndex_ISBN_Keyword,
	ContentCafe_SearchIndex_UPC_Keyword,
	ContentCafe_SearchIndex_Title_Keyword,
	ContentCafe_SearchIndex_Author_Keyword,
	ContentCafe_SearchIndex_GeneralSubject_Keyword,
	ContentCafe_SearchIndex_LibrarySubject_Keyword,
	ContentCafe_SearchIndex_Series_Keyword,
	ContentCafe_SearchIndex_ALL_Keyword,
} ContentCafe_SearchIndex;
ContentCafe_SearchIndex ContentCafe_SearchIndex_enumFromString(NSString *string);
NSString * ContentCafe_SearchIndex_stringFromEnum(ContentCafe_SearchIndex enumValue);
typedef enum {
	ContentCafe_SearchComparisonType_none = 0,
	ContentCafe_SearchComparisonType_Equals,
	ContentCafe_SearchComparisonType_GreaterThan,
	ContentCafe_SearchComparisonType_LessThan,
	ContentCafe_SearchComparisonType_GreaterThanOrEqualTo,
	ContentCafe_SearchComparisonType_LessThanOrEqualTo,
	ContentCafe_SearchComparisonType_NotEqualTo,
	ContentCafe_SearchComparisonType_NotLessThan,
	ContentCafe_SearchComparisonType_NotGreaterThan,
	ContentCafe_SearchComparisonType_Like,
	ContentCafe_SearchComparisonType_In,
	ContentCafe_SearchComparisonType_Between,
} ContentCafe_SearchComparisonType;
ContentCafe_SearchComparisonType ContentCafe_SearchComparisonType_enumFromString(NSString *string);
NSString * ContentCafe_SearchComparisonType_stringFromEnum(ContentCafe_SearchComparisonType enumValue);
typedef enum {
	ContentCafe_SearchConnectorType_none = 0,
	ContentCafe_SearchConnectorType_AND,
	ContentCafe_SearchConnectorType_OR,
	ContentCafe_SearchConnectorType_NOT,
} ContentCafe_SearchConnectorType;
ContentCafe_SearchConnectorType ContentCafe_SearchConnectorType_enumFromString(NSString *string);
NSString * ContentCafe_SearchConnectorType_stringFromEnum(ContentCafe_SearchConnectorType enumValue);
@interface ContentCafe_SearchItem : NSObject {
	
/* elements */
	ContentCafe_SearchIndex Index;
	ContentCafe_SearchComparisonType Comparison;
	NSString * Value;
/* attributes */
	ContentCafe_SearchConnectorType Connector;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (assign) ContentCafe_SearchIndex Index;
@property (assign) ContentCafe_SearchComparisonType Comparison;
@property (retain) NSString * Value;
/* attributes */
- (NSDictionary *)attributes;
@property (assign) ContentCafe_SearchConnectorType Connector;
@end
@interface ContentCafe_SearchGroup : NSObject {
	
/* elements */
	NSMutableArray *SearchItem;
/* attributes */
	ContentCafe_SearchConnectorType Connector;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchGroup *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addSearchItem:(ContentCafe_SearchItem *)toAdd;
@property (readonly) NSMutableArray * SearchItem;
/* attributes */
- (NSDictionary *)attributes;
@property (assign) ContentCafe_SearchConnectorType Connector;
@end
@interface ContentCafe_SearchGroups : NSObject {
	
/* elements */
	NSMutableArray *SearchGroup;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchGroups *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addSearchGroup:(ContentCafe_SearchGroup *)toAdd;
@property (readonly) NSMutableArray * SearchGroup;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Title : NSString  {
	
/* elements */
/* attributes */
	NSString * LeadingArticle;
	// Added:
	NSString * Value;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Title *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * LeadingArticle;
@property (retain) NSString * Value;
@end
@interface ContentCafe_CodeLiteral : NSString  {
	
/* elements */
/* attributes */
	NSString * Code;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_CodeLiteral *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * Code;
@end
@interface ContentCafe_ProductItem : NSObject {
	
/* elements */
	NSString * ISBN;
	NSString * UPC;
	ContentCafe_Title * Title;
	NSString * Author;
	ContentCafe_CodeLiteral * Source;
	ContentCafe_CodeLiteral * Product;
	ContentCafe_CodeLiteral * Supplier;
	NSString * Series;
	NSString * ListPrice;
	NSString * PubDate;
	ContentCafe_CodeLiteral * Format;
	ContentCafe_CodeLiteral * Report;
	NSString * BTKey;
	NSString * Dewey;
	NSString * LCCN;
	NSString * Edition;
	NSString * Volume;
	NSString * LCClass;
	NSString * ISSN;
	ContentCafe_CodeLiteral * Language;
	ContentCafe_CodeLiteral * RatingGradeLevel;
	NSMutableArray *GeneralSubject;
	NSMutableArray *LibrarySubject;
	NSMutableArray *Attribute;
	NSMutableArray *ReviewCode;
	NSString * LexileCode;
	NSString * Pagination;
	NSString * Created;
	NSString * Updated;
	NSString * Active;
	NSString * Returnable;
	NSString * DiscountKey;
	NSString * Width;
	NSString * Height;
	NSString * Depth;
	NSString * Weight;
	NSString * CPSIA_Warning;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ProductItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * ISBN;
@property (retain) NSString * UPC;
@property (retain) ContentCafe_Title * Title;
@property (retain) NSString * Author;
@property (retain) ContentCafe_CodeLiteral * Source;
@property (retain) ContentCafe_CodeLiteral * Product;
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSString * Series;
@property (retain) NSString * ListPrice;
@property (retain) NSString * PubDate;
@property (retain) ContentCafe_CodeLiteral * Format;
@property (retain) ContentCafe_CodeLiteral * Report;
@property (retain) NSString * BTKey;
@property (retain) NSString * Dewey;
@property (retain) NSString * LCCN;
@property (retain) NSString * Edition;
@property (retain) NSString * Volume;
@property (retain) NSString * LCClass;
@property (retain) NSString * ISSN;
@property (retain) ContentCafe_CodeLiteral * Language;
@property (retain) ContentCafe_CodeLiteral * RatingGradeLevel;
- (void)addGeneralSubject:(NSString *)toAdd;
@property (readonly) NSMutableArray * GeneralSubject;
- (void)addLibrarySubject:(NSString *)toAdd;
@property (readonly) NSMutableArray * LibrarySubject;
- (void)addAttribute:(NSString *)toAdd;
@property (readonly) NSMutableArray * Attribute;
- (void)addReviewCode:(NSString *)toAdd;
@property (readonly) NSMutableArray * ReviewCode;
@property (retain) NSString * LexileCode;
@property (retain) NSString * Pagination;
@property (retain) NSString * Created;
@property (retain) NSString * Updated;
@property (retain) NSString * Active;
@property (retain) NSString * Returnable;
@property (retain) NSString * DiscountKey;
@property (retain) NSString * Width;
@property (retain) NSString * Height;
@property (retain) NSString * Depth;
@property (retain) NSString * Weight;
@property (retain) NSString * CPSIA_Warning;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_SearchResults : NSObject {
	
/* elements */
	NSMutableArray *ProductItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SearchResults *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addProductItem:(ContentCafe_ProductItem *)toAdd;
@property (readonly) NSMutableArray * ProductItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Search : NSObject {
	
/* elements */
	ContentCafe_SearchOptions * SearchOptions;
	ContentCafe_SearchGroups * SearchGroups;
	NSString * SearchQuery;
	ContentCafe_SearchResults * SearchResults;
/* attributes */
	NSString * UserID;
	NSString * Password;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Search *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_SearchOptions * SearchOptions;
@property (retain) ContentCafe_SearchGroups * SearchGroups;
@property (retain) NSString * SearchQuery;
@property (retain) ContentCafe_SearchResults * SearchResults;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * UserID;
@property (retain) NSString * Password;
@end
typedef enum {
	ContentCafe_KeyType_none = 0,
	ContentCafe_KeyType_Undefined,
	ContentCafe_KeyType_ISBN,
	ContentCafe_KeyType_UPC,
	ContentCafe_KeyType_ID,
} ContentCafe_KeyType;
ContentCafe_KeyType ContentCafe_KeyType_enumFromString(NSString *string);
NSString * ContentCafe_KeyType_stringFromEnum(ContentCafe_KeyType enumValue);
@interface ContentCafe_Key : NSString  {
	
/* elements */
/* attributes */
	ContentCafe_KeyType Type;
	NSString * Original;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Key *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (assign) ContentCafe_KeyType Type;
@property (retain) NSString * Original;
@end
typedef enum {
	ContentCafe_ContentType_none = 0,
	ContentCafe_ContentType_Undefined,
	ContentCafe_ContentType_Environment,
	ContentCafe_ContentType_Member,
	ContentCafe_ContentType_AllMembers,
	ContentCafe_ContentType_AvailableContent,
	ContentCafe_ContentType_AnnotationSummary,
	ContentCafe_ContentType_AnnotationBrief,
	ContentCafe_ContentType_AnnotationDetail,
	ContentCafe_ContentType_ReviewSummary,
	ContentCafe_ContentType_ReviewBrief,
	ContentCafe_ContentType_ReviewDetail,
	ContentCafe_ContentType_BiographySummary,
	ContentCafe_ContentType_BiographyBrief,
	ContentCafe_ContentType_BiographyDetail,
	ContentCafe_ContentType_FlapSummary,
	ContentCafe_ContentType_FlapBrief,
	ContentCafe_ContentType_FlapDetail,
	ContentCafe_ContentType_InventorySummary,
	ContentCafe_ContentType_InventoryBrief,
	ContentCafe_ContentType_InventoryDetail,
	ContentCafe_ContentType_DemandSummary,
	ContentCafe_ContentType_DemandBrief,
	ContentCafe_ContentType_DemandDetail,
	ContentCafe_ContentType_DemandHistorySummary,
	ContentCafe_ContentType_DemandHistoryBrief,
	ContentCafe_ContentType_DemandHistoryDetail,
	ContentCafe_ContentType_JacketSummary,
	ContentCafe_ContentType_JacketBrief,
	ContentCafe_ContentType_JacketDetail,
	ContentCafe_ContentType_TocSummary,
	ContentCafe_ContentType_TocBrief,
	ContentCafe_ContentType_TocDetail,
	ContentCafe_ContentType_ExcerptSummary,
	ContentCafe_ContentType_ExcerptBrief,
	ContentCafe_ContentType_ExcerptDetail,
	ContentCafe_ContentType_ProductSummary,
	ContentCafe_ContentType_ProductBrief,
	ContentCafe_ContentType_ProductDetail,
	ContentCafe_ContentType_MuzeSummary,
	ContentCafe_ContentType_MuzeVideoRelease,
	ContentCafe_ContentType_MuzeSimilarCinema,
	ContentCafe_ContentType_MuzePopularMusic,
	ContentCafe_ContentType_MuzeClassicalMusic,
	ContentCafe_ContentType_MuzeEssentialArtists,
	ContentCafe_ContentType_MuzeGames,
} ContentCafe_ContentType;
ContentCafe_ContentType ContentCafe_ContentType_enumFromString(NSString *string);
NSString * ContentCafe_ContentType_stringFromEnum(ContentCafe_ContentType enumValue);

// ContentCafe_ContentType is an enum, not an interface so this looks like a bug
@interface ContentCafe_Content : NSObject /*was : ContentCafe_ContentType*/ {
	
/* elements */
/* attributes */
	NSString * Type;
	NSString * Encoding;
	NSString * VendorID;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Content *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * Type;
@property (retain) NSString * Encoding;
@property (retain) NSString * VendorID;
@end
@interface ContentCafe_Environment : NSObject {
	
/* elements */
	NSString * RawUrl;
	NSString * Path;
	NSString * RequestType;
	NSNumber * ContentLength;
	NSString * ContentType;
	NSString * LocalAddress;
	NSString * ServerName;
	NSString * ServerPort;
	NSString * ServerProtocol;
	NSString * ServerSoftware;
	NSString * MachineName;
	NSString * Browser;
	NSString * UserAgent;
	NSString * UserHostAddress;
	NSString * UserHostName;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Environment *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * RawUrl;
@property (retain) NSString * Path;
@property (retain) NSString * RequestType;
@property (retain) NSNumber * ContentLength;
@property (retain) NSString * ContentType;
@property (retain) NSString * LocalAddress;
@property (retain) NSString * ServerName;
@property (retain) NSString * ServerPort;
@property (retain) NSString * ServerProtocol;
@property (retain) NSString * ServerSoftware;
@property (retain) NSString * MachineName;
@property (retain) NSString * Browser;
@property (retain) NSString * UserAgent;
@property (retain) NSString * UserHostAddress;
@property (retain) NSString * UserHostName;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ReviewPublicationItems : NSObject {
	
/* elements */
	NSMutableArray *ReviewPublicationItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ReviewPublicationItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addReviewPublicationItem:(ContentCafe_CodeLiteral *)toAdd;
@property (readonly) NSMutableArray * ReviewPublicationItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_InventoryAvailabilityItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventoryAvailabilityItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_InventoryAvailabilityItems : NSObject {
	
/* elements */
	NSMutableArray *InventoryAvailabilityItem;
/* attributes */
	NSNumber * Minimum;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventoryAvailabilityItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addInventoryAvailabilityItem:(ContentCafe_InventoryAvailabilityItem *)toAdd;
@property (readonly) NSMutableArray * InventoryAvailabilityItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * Minimum;
@end
@interface ContentCafe_MemberLinkItem : NSObject {
	
/* elements */
	NSString * Description;
	NSString * URL;
	USBoolean * Active;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MemberLinkItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * Description;
@property (retain) NSString * URL;
@property (retain) USBoolean * Active;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_MemberLinkItems : NSObject {
	
/* elements */
	NSMutableArray *MemberLinkItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MemberLinkItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addMemberLinkItem:(ContentCafe_MemberLinkItem *)toAdd;
@property (readonly) NSMutableArray * MemberLinkItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_MemberItem : NSObject {
	
/* elements */
	NSString * UserID;
	NSString * Password;
	USBoolean * Active;
	USBoolean * Admin;
	USBoolean * Annotation;
	USBoolean * Biography;
	USBoolean * Excerpt;
	USBoolean * Flap;
	USBoolean * Inventory;
	USBoolean * Demand;
	USBoolean * DemandHistory;
	USBoolean * Jacket;
	USBoolean * Product;
	USBoolean * Review;
	USBoolean * TOC;
	ContentCafe_ReviewPublicationItems * ReviewPublicationItems;
	ContentCafe_InventoryAvailabilityItems * InventoryAvailabilityItems;
	ContentCafe_MemberLinkItems * MemberLinkItems;
	USBoolean * Search;
	USBoolean * MuzeVideoRelease;
	USBoolean * MuzeSimilarCinema;
	USBoolean * MuzePopularMusic;
	USBoolean * MuzeClassicalMusic;
	USBoolean * MuzeEssentialArtists;
	USBoolean * MuzeGames;
	USBoolean * MuzeJacket;
	USBoolean * MuzeTunes;
	USBoolean * MuzeReels;
	USBoolean * ReserveInventory;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MemberItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * UserID;
@property (retain) NSString * Password;
@property (retain) USBoolean * Active;
@property (retain) USBoolean * Admin;
@property (retain) USBoolean * Annotation;
@property (retain) USBoolean * Biography;
@property (retain) USBoolean * Excerpt;
@property (retain) USBoolean * Flap;
@property (retain) USBoolean * Inventory;
@property (retain) USBoolean * Demand;
@property (retain) USBoolean * DemandHistory;
@property (retain) USBoolean * Jacket;
@property (retain) USBoolean * Product;
@property (retain) USBoolean * Review;
@property (retain) USBoolean * TOC;
@property (retain) ContentCafe_ReviewPublicationItems * ReviewPublicationItems;
@property (retain) ContentCafe_InventoryAvailabilityItems * InventoryAvailabilityItems;
@property (retain) ContentCafe_MemberLinkItems * MemberLinkItems;
@property (retain) USBoolean * Search;
@property (retain) USBoolean * MuzeVideoRelease;
@property (retain) USBoolean * MuzeSimilarCinema;
@property (retain) USBoolean * MuzePopularMusic;
@property (retain) USBoolean * MuzeClassicalMusic;
@property (retain) USBoolean * MuzeEssentialArtists;
@property (retain) USBoolean * MuzeGames;
@property (retain) USBoolean * MuzeJacket;
@property (retain) USBoolean * MuzeTunes;
@property (retain) USBoolean * MuzeReels;
@property (retain) USBoolean * ReserveInventory;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_MemberItems : NSObject {
	
/* elements */
	NSMutableArray *MemberItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MemberItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addMemberItem:(ContentCafe_MemberItem *)toAdd;
@property (readonly) NSMutableArray * MemberItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_AvailableContent : NSObject {
	
/* elements */
	USBoolean * Annotation;
	USBoolean * Biography;
	USBoolean * Excerpt;
	USBoolean * Flap;
	USBoolean * Inventory;
	USBoolean * Demand;
	USBoolean * DemandHistory;
	USBoolean * Jacket;
	USBoolean * Product;
	USBoolean * Review;
	USBoolean * TOC;
	USBoolean * MuzeVideoRelease;
	USBoolean * MuzeSimilarCinema;
	USBoolean * MuzePopularMusic;
	USBoolean * MuzeClassicalMusic;
	USBoolean * MuzeEssentialArtists;
	USBoolean * MuzeGames;
	USBoolean * MuzeJacket;
	USBoolean * CPSIA_Warning;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_AvailableContent *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) USBoolean * Annotation;
@property (retain) USBoolean * Biography;
@property (retain) USBoolean * Excerpt;
@property (retain) USBoolean * Flap;
@property (retain) USBoolean * Inventory;
@property (retain) USBoolean * Demand;
@property (retain) USBoolean * DemandHistory;
@property (retain) USBoolean * Jacket;
@property (retain) USBoolean * Product;
@property (retain) USBoolean * Review;
@property (retain) USBoolean * TOC;
@property (retain) USBoolean * MuzeVideoRelease;
@property (retain) USBoolean * MuzeSimilarCinema;
@property (retain) USBoolean * MuzePopularMusic;
@property (retain) USBoolean * MuzeClassicalMusic;
@property (retain) USBoolean * MuzeEssentialArtists;
@property (retain) USBoolean * MuzeGames;
@property (retain) USBoolean * MuzeJacket;
@property (retain) USBoolean * CPSIA_Warning;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_AnnotationSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_AnnotationSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_AnnotationSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *AnnotationSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_AnnotationSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addAnnotationSummaryItem:(ContentCafe_AnnotationSummaryItem *)toAdd;
@property (readonly) NSMutableArray * AnnotationSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_AnnotationItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSString * Annotation;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_AnnotationItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSString * Annotation;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_AnnotationItems : NSObject {
	
/* elements */
	NSMutableArray *AnnotationItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_AnnotationItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addAnnotationItem:(ContentCafe_AnnotationItem *)toAdd;
@property (readonly) NSMutableArray * AnnotationItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ReviewSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Publication;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ReviewSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Publication;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ReviewSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *ReviewSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ReviewSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addReviewSummaryItem:(ContentCafe_ReviewSummaryItem *)toAdd;
@property (readonly) NSMutableArray * ReviewSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_ReviewItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Publication;
	ContentCafe_CodeLiteral * Issue;
	NSString * Review;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ReviewItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Publication;
@property (retain) ContentCafe_CodeLiteral * Issue;
@property (retain) NSString * Review;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_ReviewItems : NSObject {
	
/* elements */
	NSMutableArray *ReviewItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ReviewItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addReviewItem:(ContentCafe_ReviewItem *)toAdd;
@property (readonly) NSMutableArray * ReviewItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_BiographySummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_BiographySummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_BiographySummaryItems : NSObject {
	
/* elements */
	NSMutableArray *BiographySummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_BiographySummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addBiographySummaryItem:(ContentCafe_BiographySummaryItem *)toAdd;
@property (readonly) NSMutableArray * BiographySummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_BiographyItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSString * Biography;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_BiographyItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSString * Biography;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_BiographyItems : NSObject {
	
/* elements */
	NSMutableArray *BiographyItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_BiographyItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addBiographyItem:(ContentCafe_BiographyItem *)toAdd;
@property (readonly) NSMutableArray * BiographyItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_FlapSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_FlapSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_FlapSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *FlapSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_FlapSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addFlapSummaryItem:(ContentCafe_FlapSummaryItem *)toAdd;
@property (readonly) NSMutableArray * FlapSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_FlapItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	NSString * Flap;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_FlapItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) NSString * Flap;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_FlapItems : NSObject {
	
/* elements */
	NSMutableArray *FlapItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_FlapItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addFlapItem:(ContentCafe_FlapItem *)toAdd;
@property (readonly) NSMutableArray * FlapItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_InventorySummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventorySummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_InventorySummaryItems : NSObject {
	
/* elements */
	NSMutableArray *InventorySummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventorySummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addInventorySummaryItem:(ContentCafe_InventorySummaryItem *)toAdd;
@property (readonly) NSMutableArray * InventorySummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_InventoryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSString * OnHand;
	NSString * OnOrder;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventoryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSString * OnHand;
@property (retain) NSString * OnOrder;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_InventoryItems : NSObject {
	
/* elements */
	NSMutableArray *InventoryItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_InventoryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addInventoryItem:(ContentCafe_InventoryItem *)toAdd;
@property (readonly) NSMutableArray * InventoryItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_DemandSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_DemandSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *DemandSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addDemandSummaryItem:(ContentCafe_DemandSummaryItem *)toAdd;
@property (readonly) NSMutableArray * DemandSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_DemandItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSString * Demand;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSString * Demand;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_DemandItems : NSObject {
	
/* elements */
	NSMutableArray *DemandItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addDemandItem:(ContentCafe_DemandItem *)toAdd;
@property (readonly) NSMutableArray * DemandItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_DemandHistorySummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandHistorySummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_DemandHistorySummaryItems : NSObject {
	
/* elements */
	NSMutableArray *DemandHistorySummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandHistorySummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addDemandHistorySummaryItem:(ContentCafe_DemandHistorySummaryItem *)toAdd;
@property (readonly) NSMutableArray * DemandHistorySummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_DemandHistoryItem : NSObject {
	
/* elements */
	NSNumber * Year;
	NSNumber * Month;
	ContentCafe_CodeLiteral * Supplier;
	ContentCafe_CodeLiteral * Warehouse;
	NSString * Demand;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandHistoryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * Year;
@property (retain) NSNumber * Month;
@property (retain) ContentCafe_CodeLiteral * Supplier;
@property (retain) ContentCafe_CodeLiteral * Warehouse;
@property (retain) NSString * Demand;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_DemandHistoryItems : NSObject {
	
/* elements */
	NSMutableArray *DemandHistoryItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_DemandHistoryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addDemandHistoryItem:(ContentCafe_DemandHistoryItem *)toAdd;
@property (readonly) NSMutableArray * DemandHistoryItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_JacketSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_JacketSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_JacketSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *JacketSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_JacketSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addJacketSummaryItem:(ContentCafe_JacketSummaryItem *)toAdd;
@property (readonly) NSMutableArray * JacketSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_JacketElement : NSString  {
	
/* elements */
/* attributes */
	NSString * Encoding;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_JacketElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * Encoding;
@end
@interface ContentCafe_JacketItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSNumber * Width;
	NSNumber * Height;
	NSString * Format;
	ContentCafe_JacketElement * Jacket;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_JacketItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSNumber * Width;
@property (retain) NSNumber * Height;
@property (retain) NSString * Format;
@property (retain) ContentCafe_JacketElement * Jacket;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_JacketItems : NSObject {
	
/* elements */
	NSMutableArray *JacketItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_JacketItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addJacketItem:(ContentCafe_JacketItem *)toAdd;
@property (readonly) NSMutableArray * JacketItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_TocSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_TocSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_TocSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *TocSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_TocSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addTocSummaryItem:(ContentCafe_TocSummaryItem *)toAdd;
@property (readonly) NSMutableArray * TocSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_TocItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSString * Toc;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_TocItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSString * Toc;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_TocItems : NSObject {
	
/* elements */
	NSMutableArray *TocItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_TocItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addTocItem:(ContentCafe_TocItem *)toAdd;
@property (readonly) NSMutableArray * TocItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ExcerptSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ExcerptSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ExcerptSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *ExcerptSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ExcerptSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addExcerptSummaryItem:(ContentCafe_ExcerptSummaryItem *)toAdd;
@property (readonly) NSMutableArray * ExcerptSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_ExcerptItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSString * Excerpt;
/* attributes */
	NSNumber * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ExcerptItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSString * Excerpt;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * ID_;
@end
@interface ContentCafe_ExcerptItems : NSObject {
	
/* elements */
	NSMutableArray *ExcerptItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ExcerptItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addExcerptItem:(ContentCafe_ExcerptItem *)toAdd;
@property (readonly) NSMutableArray * ExcerptItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ProductSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Source;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ProductSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Source;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_ProductSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *ProductSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ProductSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addProductSummaryItem:(ContentCafe_ProductSummaryItem *)toAdd;
@property (readonly) NSMutableArray * ProductSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_ProductItems : NSObject {
	
/* elements */
	NSMutableArray *ProductItem;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ProductItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addProductItem:(ContentCafe_ProductItem *)toAdd;
@property (readonly) NSMutableArray * ProductItem;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_MuzeSummaryItem : NSObject {
	
/* elements */
	ContentCafe_CodeLiteral * Type;
	NSNumber * Records;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MuzeSummaryItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_CodeLiteral * Type;
@property (retain) NSNumber * Records;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_MuzeSummaryItems : NSObject {
	
/* elements */
	NSMutableArray *MuzeSummaryItem;
/* attributes */
	NSNumber * TotalRecords;
	NSNumber * UniqueRecords;
	NSDate * LastUpdated;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_MuzeSummaryItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addMuzeSummaryItem:(ContentCafe_MuzeSummaryItem *)toAdd;
@property (readonly) NSMutableArray * MuzeSummaryItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSNumber * TotalRecords;
@property (retain) NSNumber * UniqueRecords;
@property (retain) NSDate * LastUpdated;
@end
@interface ContentCafe_Muze : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Muze *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_RequestItem : NSObject {
	
/* elements */
//	ContentCafe_Key * Key;
	NSString * Key;
	NSMutableArray *Content;
	ContentCafe_Environment * Environment;
	ContentCafe_MemberItem * MemberItem;
	ContentCafe_MemberItems * MemberItems;
	ContentCafe_AvailableContent * AvailableContent;
	ContentCafe_AnnotationSummaryItems * AnnotationSummaryItems;
	ContentCafe_AnnotationItems * AnnotationItems;
	ContentCafe_ReviewSummaryItems * ReviewSummaryItems;
	ContentCafe_ReviewItems * ReviewItems;
	ContentCafe_BiographySummaryItems * BiographySummaryItems;
	ContentCafe_BiographyItems * BiographyItems;
	ContentCafe_FlapSummaryItems * FlapSummaryItems;
	ContentCafe_FlapItems * FlapItems;
	ContentCafe_InventorySummaryItems * InventorySummaryItems;
	ContentCafe_InventoryItems * InventoryItems;
	ContentCafe_DemandSummaryItems * DemandSummaryItems;
	ContentCafe_DemandItems * DemandItems;
	ContentCafe_DemandHistorySummaryItems * DemandHistorySummaryItems;
	ContentCafe_DemandHistoryItems * DemandHistoryItems;
	ContentCafe_JacketSummaryItems * JacketSummaryItems;
	ContentCafe_JacketItems * JacketItems;
	ContentCafe_TocSummaryItems * TocSummaryItems;
	ContentCafe_TocItems * TocItems;
	ContentCafe_ExcerptSummaryItems * ExcerptSummaryItems;
	ContentCafe_ExcerptItems * ExcerptItems;
	ContentCafe_ProductSummaryItems * ProductSummaryItems;
	ContentCafe_ProductItems * ProductItems;
	ContentCafe_MuzeSummaryItems * MuzeSummaryItems;
	ContentCafe_Muze * Muze;
/* attributes */
	NSString * ID_;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_RequestItem *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
//@property (retain) ContentCafe_Key * Key;
@property (retain) NSString * Key;
- (void)addContent:(ContentCafe_Content *)toAdd;
@property (readonly) NSMutableArray * Content;
@property (retain) ContentCafe_Environment * Environment;
@property (retain) ContentCafe_MemberItem * MemberItem;
@property (retain) ContentCafe_MemberItems * MemberItems;
@property (retain) ContentCafe_AvailableContent * AvailableContent;
@property (retain) ContentCafe_AnnotationSummaryItems * AnnotationSummaryItems;
@property (retain) ContentCafe_AnnotationItems * AnnotationItems;
@property (retain) ContentCafe_ReviewSummaryItems * ReviewSummaryItems;
@property (retain) ContentCafe_ReviewItems * ReviewItems;
@property (retain) ContentCafe_BiographySummaryItems * BiographySummaryItems;
@property (retain) ContentCafe_BiographyItems * BiographyItems;
@property (retain) ContentCafe_FlapSummaryItems * FlapSummaryItems;
@property (retain) ContentCafe_FlapItems * FlapItems;
@property (retain) ContentCafe_InventorySummaryItems * InventorySummaryItems;
@property (retain) ContentCafe_InventoryItems * InventoryItems;
@property (retain) ContentCafe_DemandSummaryItems * DemandSummaryItems;
@property (retain) ContentCafe_DemandItems * DemandItems;
@property (retain) ContentCafe_DemandHistorySummaryItems * DemandHistorySummaryItems;
@property (retain) ContentCafe_DemandHistoryItems * DemandHistoryItems;
@property (retain) ContentCafe_JacketSummaryItems * JacketSummaryItems;
@property (retain) ContentCafe_JacketItems * JacketItems;
@property (retain) ContentCafe_TocSummaryItems * TocSummaryItems;
@property (retain) ContentCafe_TocItems * TocItems;
@property (retain) ContentCafe_ExcerptSummaryItems * ExcerptSummaryItems;
@property (retain) ContentCafe_ExcerptItems * ExcerptItems;
@property (retain) ContentCafe_ProductSummaryItems * ProductSummaryItems;
@property (retain) ContentCafe_ProductItems * ProductItems;
@property (retain) ContentCafe_MuzeSummaryItems * MuzeSummaryItems;
@property (retain) ContentCafe_Muze * Muze;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * ID_;
@end
@interface ContentCafe_RequestItems : NSObject {
	
/* elements */
	NSMutableArray *RequestItem;
/* attributes */
	NSString * UserID;
	NSString * Password;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_RequestItems *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
- (void)addRequestItem:(ContentCafe_RequestItem *)toAdd;
@property (readonly) NSMutableArray * RequestItem;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSString * UserID;
@property (retain) NSString * Password;
@end
@interface ContentCafe_ContentCafeXML : NSObject {
	
/* elements */
	NSString * Error;
	ContentCafe_Search * Search;
	ContentCafe_RequestItems * RequestItems;
/* attributes */
	NSDate * DateTime;
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_ContentCafeXML *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * Error;
@property (retain) ContentCafe_Search * Search;
@property (retain) ContentCafe_RequestItems * RequestItems;
/* attributes */
- (NSDictionary *)attributes;
@property (retain) NSDate * DateTime;
@end
@interface ContentCafe_Test1Response : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test1Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test2 : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test2Response : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test3 : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test3 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test3Response : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test3Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test4 : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test4 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Test4Response : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Test4Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlPost : NSObject {
	
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlPost *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlPostResponse : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlPostResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlString : NSObject {
	
/* elements */
	NSString * xmlRequest;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlString *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * xmlRequest;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlStringResponse : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlStringResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlClass : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlClass *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_XmlClassResponse : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_XmlClassResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_Single : NSObject {
	
/* elements */
	NSString * userID;
	NSString * password;
	NSString * key;
	NSString * content;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_Single *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * userID;
@property (retain) NSString * password;
@property (retain) NSString * key;
@property (retain) NSString * content;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface ContentCafe_SingleResponse : NSObject {
	
/* elements */
	ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (ContentCafe_SingleResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) ContentCafe_ContentCafeXML * ContentCafe;
/* attributes */
- (NSDictionary *)attributes;
@end
/* Cookies handling provided by http://en.wikibooks.org/wiki/Programming:WebObjects/Web_Services/Web_Service_Provider */
#import <libxml/parser.h>
#import "xsd.h"
#import "BlioContentCafe.h"
@class ContentCafeSoap;
@class ContentCafeSoap12;
@interface ContentCafe : NSObject {
	
}
+ (ContentCafeSoap *)ContentCafeSoap;
+ (ContentCafeSoap12 *)ContentCafeSoap12;
@end
@class ContentCafeSoapResponse;
@class ContentCafeSoapOperation;
@protocol ContentCafeSoapResponseDelegate <NSObject>
- (void) operation:(ContentCafeSoapOperation *)operation completedWithResponse:(ContentCafeSoapResponse *)response;
@end
@interface ContentCafeSoap : NSObject <ContentCafeSoapResponseDelegate> {
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
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(ContentCafeSoapOperation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (ContentCafeSoapResponse *)Test1UsingParameters:(ContentCafe_Test1 *)aParameters ;
- (void)Test1AsyncUsingParameters:(ContentCafe_Test1 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)Test2UsingParameters:(ContentCafe_Test2 *)aParameters ;
- (void)Test2AsyncUsingParameters:(ContentCafe_Test2 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)Test3UsingParameters:(ContentCafe_Test3 *)aParameters ;
- (void)Test3AsyncUsingParameters:(ContentCafe_Test3 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)Test4UsingParameters:(ContentCafe_Test4 *)aParameters ;
- (void)Test4AsyncUsingParameters:(ContentCafe_Test4 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)XmlPostUsingParameters:(ContentCafe_XmlPost *)aParameters ;
- (void)XmlPostAsyncUsingParameters:(ContentCafe_XmlPost *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)XmlStringUsingParameters:(ContentCafe_XmlString *)aParameters ;
- (void)XmlStringAsyncUsingParameters:(ContentCafe_XmlString *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)XmlClassUsingParameters:(ContentCafe_XmlClass *)aParameters ;
- (void)XmlClassAsyncUsingParameters:(ContentCafe_XmlClass *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
- (ContentCafeSoapResponse *)SingleUsingParameters:(ContentCafe_Single *)aParameters ;
- (void)SingleAsyncUsingParameters:(ContentCafe_Single *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate;
@end
@interface ContentCafeSoapOperation : NSOperation {
	ContentCafeSoap *binding;
	ContentCafeSoapResponse *response;
	id<ContentCafeSoapResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) ContentCafeSoap *binding;
@property (readonly) ContentCafeSoapResponse *response;
@property (nonatomic, assign) id<ContentCafeSoapResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate;
@end
@interface ContentCafeSoap_Test1 : ContentCafeSoapOperation {
	ContentCafe_Test1 * parameters;
}
@property (retain) ContentCafe_Test1 * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test1 *)aParameters
;
@end
@interface ContentCafeSoap_Test2 : ContentCafeSoapOperation {
	ContentCafe_Test2 * parameters;
}
@property (retain) ContentCafe_Test2 * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test2 *)aParameters
;
@end
@interface ContentCafeSoap_Test3 : ContentCafeSoapOperation {
	ContentCafe_Test3 * parameters;
}
@property (retain) ContentCafe_Test3 * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test3 *)aParameters
;
@end
@interface ContentCafeSoap_Test4 : ContentCafeSoapOperation {
	ContentCafe_Test4 * parameters;
}
@property (retain) ContentCafe_Test4 * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test4 *)aParameters
;
@end
@interface ContentCafeSoap_XmlPost : ContentCafeSoapOperation {
	ContentCafe_XmlPost * parameters;
}
@property (retain) ContentCafe_XmlPost * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlPost *)aParameters
;
@end
@interface ContentCafeSoap_XmlString : ContentCafeSoapOperation {
	ContentCafe_XmlString * parameters;
}
@property (retain) ContentCafe_XmlString * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlString *)aParameters
;
@end
@interface ContentCafeSoap_XmlClass : ContentCafeSoapOperation {
	ContentCafe_XmlClass * parameters;
}
@property (retain) ContentCafe_XmlClass * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlClass *)aParameters
;
@end
@interface ContentCafeSoap_Single : ContentCafeSoapOperation {
	ContentCafe_Single * parameters;
}
@property (retain) ContentCafe_Single * parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
	parameters:(ContentCafe_Single *)aParameters
;
@end
@interface ContentCafeSoap_envelope : NSObject {
}
+ (ContentCafeSoap_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface ContentCafeSoapResponse : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
@class ContentCafeSoap12Response;
@class ContentCafeSoap12Operation;
@protocol ContentCafeSoap12ResponseDelegate <NSObject>
- (void) operation:(ContentCafeSoap12Operation *)operation completedWithResponse:(ContentCafeSoap12Response *)response;
@end
@interface ContentCafeSoap12 : NSObject <ContentCafeSoap12ResponseDelegate> {
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
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(ContentCafeSoap12Operation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (ContentCafeSoap12Response *)Test1UsingParameters:(ContentCafe_Test1 *)aParameters ;
- (void)Test1AsyncUsingParameters:(ContentCafe_Test1 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)Test2UsingParameters:(ContentCafe_Test2 *)aParameters ;
- (void)Test2AsyncUsingParameters:(ContentCafe_Test2 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)Test3UsingParameters:(ContentCafe_Test3 *)aParameters ;
- (void)Test3AsyncUsingParameters:(ContentCafe_Test3 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)Test4UsingParameters:(ContentCafe_Test4 *)aParameters ;
- (void)Test4AsyncUsingParameters:(ContentCafe_Test4 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)XmlPostUsingParameters:(ContentCafe_XmlPost *)aParameters ;
- (void)XmlPostAsyncUsingParameters:(ContentCafe_XmlPost *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)XmlStringUsingParameters:(ContentCafe_XmlString *)aParameters ;
- (void)XmlStringAsyncUsingParameters:(ContentCafe_XmlString *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)XmlClassUsingParameters:(ContentCafe_XmlClass *)aParameters ;
- (void)XmlClassAsyncUsingParameters:(ContentCafe_XmlClass *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
- (ContentCafeSoap12Response *)SingleUsingParameters:(ContentCafe_Single *)aParameters ;
- (void)SingleAsyncUsingParameters:(ContentCafe_Single *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate;
@end
@interface ContentCafeSoap12Operation : NSOperation {
	ContentCafeSoap12 *binding;
	ContentCafeSoap12Response *response;
	id<ContentCafeSoap12ResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) ContentCafeSoap12 *binding;
@property (readonly) ContentCafeSoap12Response *response;
@property (nonatomic, assign) id<ContentCafeSoap12ResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate;
@end
@interface ContentCafeSoap12_Test1 : ContentCafeSoap12Operation {
	ContentCafe_Test1 * parameters;
}
@property (retain) ContentCafe_Test1 * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test1 *)aParameters
;
@end
@interface ContentCafeSoap12_Test2 : ContentCafeSoap12Operation {
	ContentCafe_Test2 * parameters;
}
@property (retain) ContentCafe_Test2 * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test2 *)aParameters
;
@end
@interface ContentCafeSoap12_Test3 : ContentCafeSoap12Operation {
	ContentCafe_Test3 * parameters;
}
@property (retain) ContentCafe_Test3 * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test3 *)aParameters
;
@end
@interface ContentCafeSoap12_Test4 : ContentCafeSoap12Operation {
	ContentCafe_Test4 * parameters;
}
@property (retain) ContentCafe_Test4 * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_Test4 *)aParameters
;
@end
@interface ContentCafeSoap12_XmlPost : ContentCafeSoap12Operation {
	ContentCafe_XmlPost * parameters;
}
@property (retain) ContentCafe_XmlPost * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlPost *)aParameters
;
@end
@interface ContentCafeSoap12_XmlString : ContentCafeSoap12Operation {
	ContentCafe_XmlString * parameters;
}
@property (retain) ContentCafe_XmlString * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlString *)aParameters
;
@end
@interface ContentCafeSoap12_XmlClass : ContentCafeSoap12Operation {
	ContentCafe_XmlClass * parameters;
}
@property (retain) ContentCafe_XmlClass * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_XmlClass *)aParameters
;
@end
@interface ContentCafeSoap12_Single : ContentCafeSoap12Operation {
	ContentCafe_Single * parameters;
}
@property (retain) ContentCafe_Single * parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
	parameters:(ContentCafe_Single *)aParameters
;
@end
@interface ContentCafeSoap12_envelope : NSObject {
}
+ (ContentCafeSoap12_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface ContentCafeSoap12Response : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
