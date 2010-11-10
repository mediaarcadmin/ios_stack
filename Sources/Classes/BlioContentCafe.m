#import "BlioContentCafe.h"
#import <libxml/xmlstring.h>
#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif
@implementation ContentCafe_Test1
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test1");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test1 *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test1 *newObject = [[ContentCafe_Test1 new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
ContentCafe_SearchSortField ContentCafe_SearchSortField_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Undefined"]) {
		return ContentCafe_SearchSortField_Undefined;
	}
	if([string isEqualToString:@"ISBN"]) {
		return ContentCafe_SearchSortField_ISBN;
	}
	if([string isEqualToString:@"UPC"]) {
		return ContentCafe_SearchSortField_UPC;
	}
	if([string isEqualToString:@"Title"]) {
		return ContentCafe_SearchSortField_Title;
	}
	if([string isEqualToString:@"Author"]) {
		return ContentCafe_SearchSortField_Author;
	}
	if([string isEqualToString:@"Updated"]) {
		return ContentCafe_SearchSortField_Updated;
	}
	
	return ContentCafe_SearchSortField_none;
}
NSString * ContentCafe_SearchSortField_stringFromEnum(ContentCafe_SearchSortField enumValue)
{
	switch (enumValue) {
		case ContentCafe_SearchSortField_Undefined:
			return @"Undefined";
			break;
		case ContentCafe_SearchSortField_ISBN:
			return @"ISBN";
			break;
		case ContentCafe_SearchSortField_UPC:
			return @"UPC";
			break;
		case ContentCafe_SearchSortField_Title:
			return @"Title";
			break;
		case ContentCafe_SearchSortField_Author:
			return @"Author";
			break;
		case ContentCafe_SearchSortField_Updated:
			return @"Updated";
			break;
		default:
			return @"";
	}
}
ContentCafe_SearchSortOrderType ContentCafe_SearchSortOrderType_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Ascending"]) {
		return ContentCafe_SearchSortOrderType_Ascending;
	}
	if([string isEqualToString:@"Descending"]) {
		return ContentCafe_SearchSortOrderType_Descending;
	}
	
	return ContentCafe_SearchSortOrderType_none;
}
NSString * ContentCafe_SearchSortOrderType_stringFromEnum(ContentCafe_SearchSortOrderType enumValue)
{
	switch (enumValue) {
		case ContentCafe_SearchSortOrderType_Ascending:
			return @"Ascending";
			break;
		case ContentCafe_SearchSortOrderType_Descending:
			return @"Descending";
			break;
		default:
			return @"";
	}
}
@implementation ContentCafe_SearchSortBy
- (id)init
{
	if((self = [super init])) {
		Order = 0;
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchSortBy");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Order != 0) {
		xmlSetProp(node, (const xmlChar*)"Order", (const xmlChar*)[ContentCafe_SearchSortOrderType_stringFromEnum(self.Order) UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithInt:(int)self.Order] forKey:@"Order"];
	
	return attributes;
}
@synthesize Order;
+ (ContentCafe_SearchSortBy *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchSortBy *newObject = [[ContentCafe_SearchSortBy new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Order");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Order = ContentCafe_SearchSortOrderType_enumFromString(attrString);
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_SearchOptions
- (id)init
{
	if((self = [super init])) {
		MaxRecords = 0;
		Offset = 0;
		ShowQuery = 0;
		SortBy = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(MaxRecords != nil) [MaxRecords release];
	if(Offset != nil) [Offset release];
	if(ShowQuery != nil) [ShowQuery release];
	if(SortBy != nil) [SortBy release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchOptions");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.MaxRecords != 0) {
		xmlAddChild(node, [self.MaxRecords xmlNodeForDoc:node->doc elementName:@"MaxRecords"]);
	}
	if(self.Offset != 0) {
		xmlAddChild(node, [self.Offset xmlNodeForDoc:node->doc elementName:@"Offset"]);
	}
	if(self.ShowQuery != 0) {
		xmlAddChild(node, [self.ShowQuery xmlNodeForDoc:node->doc elementName:@"ShowQuery"]);
	}
	if(self.SortBy != 0) {
		for(ContentCafe_SearchSortBy * child in self.SortBy) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"SortBy"]);
		}
	}
}
/* elements */
@synthesize MaxRecords;
@synthesize Offset;
@synthesize ShowQuery;
@synthesize SortBy;
- (void)addSortBy:(ContentCafe_SearchSortBy *)toAdd
{
	if(toAdd != nil) [SortBy addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_SearchOptions *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchOptions *newObject = [[ContentCafe_SearchOptions new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MaxRecords")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MaxRecords = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Offset")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Offset = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ShowQuery")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ShowQuery = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SortBy")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchSortBy class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.SortBy addObject:newChild];
			}
		}
	}
}
@end
ContentCafe_SearchIndex ContentCafe_SearchIndex_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Undefined"]) {
		return ContentCafe_SearchIndex_Undefined;
	}
	if([string isEqualToString:@"ISBN_String"]) {
		return ContentCafe_SearchIndex_ISBN_String;
	}
	if([string isEqualToString:@"UPC_String"]) {
		return ContentCafe_SearchIndex_UPC_String;
	}
	if([string isEqualToString:@"Title_String"]) {
		return ContentCafe_SearchIndex_Title_String;
	}
	if([string isEqualToString:@"Author_String"]) {
		return ContentCafe_SearchIndex_Author_String;
	}
	if([string isEqualToString:@"BTKey_String"]) {
		return ContentCafe_SearchIndex_BTKey_String;
	}
	if([string isEqualToString:@"ISBN_Keyword"]) {
		return ContentCafe_SearchIndex_ISBN_Keyword;
	}
	if([string isEqualToString:@"UPC_Keyword"]) {
		return ContentCafe_SearchIndex_UPC_Keyword;
	}
	if([string isEqualToString:@"Title_Keyword"]) {
		return ContentCafe_SearchIndex_Title_Keyword;
	}
	if([string isEqualToString:@"Author_Keyword"]) {
		return ContentCafe_SearchIndex_Author_Keyword;
	}
	if([string isEqualToString:@"GeneralSubject_Keyword"]) {
		return ContentCafe_SearchIndex_GeneralSubject_Keyword;
	}
	if([string isEqualToString:@"LibrarySubject_Keyword"]) {
		return ContentCafe_SearchIndex_LibrarySubject_Keyword;
	}
	if([string isEqualToString:@"Series_Keyword"]) {
		return ContentCafe_SearchIndex_Series_Keyword;
	}
	if([string isEqualToString:@"ALL_Keyword"]) {
		return ContentCafe_SearchIndex_ALL_Keyword;
	}
	
	return ContentCafe_SearchIndex_none;
}
NSString * ContentCafe_SearchIndex_stringFromEnum(ContentCafe_SearchIndex enumValue)
{
	switch (enumValue) {
		case ContentCafe_SearchIndex_Undefined:
			return @"Undefined";
			break;
		case ContentCafe_SearchIndex_ISBN_String:
			return @"ISBN_String";
			break;
		case ContentCafe_SearchIndex_UPC_String:
			return @"UPC_String";
			break;
		case ContentCafe_SearchIndex_Title_String:
			return @"Title_String";
			break;
		case ContentCafe_SearchIndex_Author_String:
			return @"Author_String";
			break;
		case ContentCafe_SearchIndex_BTKey_String:
			return @"BTKey_String";
			break;
		case ContentCafe_SearchIndex_ISBN_Keyword:
			return @"ISBN_Keyword";
			break;
		case ContentCafe_SearchIndex_UPC_Keyword:
			return @"UPC_Keyword";
			break;
		case ContentCafe_SearchIndex_Title_Keyword:
			return @"Title_Keyword";
			break;
		case ContentCafe_SearchIndex_Author_Keyword:
			return @"Author_Keyword";
			break;
		case ContentCafe_SearchIndex_GeneralSubject_Keyword:
			return @"GeneralSubject_Keyword";
			break;
		case ContentCafe_SearchIndex_LibrarySubject_Keyword:
			return @"LibrarySubject_Keyword";
			break;
		case ContentCafe_SearchIndex_Series_Keyword:
			return @"Series_Keyword";
			break;
		case ContentCafe_SearchIndex_ALL_Keyword:
			return @"ALL_Keyword";
			break;
		default:
			return @"";
	}
}
ContentCafe_SearchComparisonType ContentCafe_SearchComparisonType_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Equals"]) {
		return ContentCafe_SearchComparisonType_Equals;
	}
	if([string isEqualToString:@"GreaterThan"]) {
		return ContentCafe_SearchComparisonType_GreaterThan;
	}
	if([string isEqualToString:@"LessThan"]) {
		return ContentCafe_SearchComparisonType_LessThan;
	}
	if([string isEqualToString:@"GreaterThanOrEqualTo"]) {
		return ContentCafe_SearchComparisonType_GreaterThanOrEqualTo;
	}
	if([string isEqualToString:@"LessThanOrEqualTo"]) {
		return ContentCafe_SearchComparisonType_LessThanOrEqualTo;
	}
	if([string isEqualToString:@"NotEqualTo"]) {
		return ContentCafe_SearchComparisonType_NotEqualTo;
	}
	if([string isEqualToString:@"NotLessThan"]) {
		return ContentCafe_SearchComparisonType_NotLessThan;
	}
	if([string isEqualToString:@"NotGreaterThan"]) {
		return ContentCafe_SearchComparisonType_NotGreaterThan;
	}
	if([string isEqualToString:@"Like"]) {
		return ContentCafe_SearchComparisonType_Like;
	}
	if([string isEqualToString:@"In"]) {
		return ContentCafe_SearchComparisonType_In;
	}
	if([string isEqualToString:@"Between"]) {
		return ContentCafe_SearchComparisonType_Between;
	}
	
	return ContentCafe_SearchComparisonType_none;
}
NSString * ContentCafe_SearchComparisonType_stringFromEnum(ContentCafe_SearchComparisonType enumValue)
{
	switch (enumValue) {
		case ContentCafe_SearchComparisonType_Equals:
			return @"Equals";
			break;
		case ContentCafe_SearchComparisonType_GreaterThan:
			return @"GreaterThan";
			break;
		case ContentCafe_SearchComparisonType_LessThan:
			return @"LessThan";
			break;
		case ContentCafe_SearchComparisonType_GreaterThanOrEqualTo:
			return @"GreaterThanOrEqualTo";
			break;
		case ContentCafe_SearchComparisonType_LessThanOrEqualTo:
			return @"LessThanOrEqualTo";
			break;
		case ContentCafe_SearchComparisonType_NotEqualTo:
			return @"NotEqualTo";
			break;
		case ContentCafe_SearchComparisonType_NotLessThan:
			return @"NotLessThan";
			break;
		case ContentCafe_SearchComparisonType_NotGreaterThan:
			return @"NotGreaterThan";
			break;
		case ContentCafe_SearchComparisonType_Like:
			return @"Like";
			break;
		case ContentCafe_SearchComparisonType_In:
			return @"In";
			break;
		case ContentCafe_SearchComparisonType_Between:
			return @"Between";
			break;
		default:
			return @"";
	}
}
ContentCafe_SearchConnectorType ContentCafe_SearchConnectorType_enumFromString(NSString *string)
{
	if([string isEqualToString:@"AND"]) {
		return ContentCafe_SearchConnectorType_AND;
	}
	if([string isEqualToString:@"OR"]) {
		return ContentCafe_SearchConnectorType_OR;
	}
	if([string isEqualToString:@"NOT"]) {
		return ContentCafe_SearchConnectorType_NOT;
	}
	
	return ContentCafe_SearchConnectorType_none;
}
NSString * ContentCafe_SearchConnectorType_stringFromEnum(ContentCafe_SearchConnectorType enumValue)
{
	switch (enumValue) {
		case ContentCafe_SearchConnectorType_AND:
			return @"AND";
			break;
		case ContentCafe_SearchConnectorType_OR:
			return @"OR";
			break;
		case ContentCafe_SearchConnectorType_NOT:
			return @"NOT";
			break;
		default:
			return @"";
	}
}
@implementation ContentCafe_SearchItem
- (id)init
{
	if((self = [super init])) {
		Index = 0;
		Comparison = 0;
		Value = 0;
		Connector = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Value != nil) [Value release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Connector != 0) {
		xmlSetProp(node, (const xmlChar*)"Connector", (const xmlChar*)[ContentCafe_SearchConnectorType_stringFromEnum(self.Connector) UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Index != 0) {
		xmlNewChild(node, NULL, (const xmlChar*)"Index", (const xmlChar*)[ContentCafe_SearchIndex_stringFromEnum(self.Index) UTF8String]);
	}
	if(self.Comparison != 0) {
		xmlNewChild(node, NULL, (const xmlChar*)"Comparison", (const xmlChar*)[ContentCafe_SearchComparisonType_stringFromEnum(self.Comparison) UTF8String]);
	}
	if(self.Value != 0) {
		xmlAddChild(node, [self.Value xmlNodeForDoc:node->doc elementName:@"Value"]);
	}
}
/* elements */
@synthesize Index;
@synthesize Comparison;
@synthesize Value;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithInt:(int)self.Connector] forKey:@"Connector"];
	
	return attributes;
}
@synthesize Connector;
+ (ContentCafe_SearchItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchItem *newObject = [[ContentCafe_SearchItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Connector");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Connector = ContentCafe_SearchConnectorType_enumFromString(attrString);
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Index")) {
				
				ContentCafe_SearchIndex enumRepresentation = ContentCafe_SearchIndex_enumFromString(elementString);
				self.Index = enumRepresentation;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Comparison")) {
				
				ContentCafe_SearchComparisonType enumRepresentation = ContentCafe_SearchComparisonType_enumFromString(elementString);
				self.Comparison = enumRepresentation;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Value")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Value = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_SearchGroup
- (id)init
{
	if((self = [super init])) {
		SearchItem = [[NSMutableArray alloc] init];
		Connector = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(SearchItem != nil) [SearchItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchGroup");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Connector != 0) {
		xmlSetProp(node, (const xmlChar*)"Connector", (const xmlChar*)[ContentCafe_SearchConnectorType_stringFromEnum(self.Connector) UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.SearchItem != 0) {
		for(ContentCafe_SearchItem * child in self.SearchItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"SearchItem"]);
		}
	}
}
/* elements */
@synthesize SearchItem;
- (void)addSearchItem:(ContentCafe_SearchItem *)toAdd
{
	if(toAdd != nil) [SearchItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithInt:(int)self.Connector] forKey:@"Connector"];
	
	return attributes;
}
@synthesize Connector;
+ (ContentCafe_SearchGroup *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchGroup *newObject = [[ContentCafe_SearchGroup new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Connector");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Connector = ContentCafe_SearchConnectorType_enumFromString(attrString);
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.SearchItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_SearchGroups
- (id)init
{
	if((self = [super init])) {
		SearchGroup = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(SearchGroup != nil) [SearchGroup release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchGroups");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.SearchGroup != 0) {
		for(ContentCafe_SearchGroup * child in self.SearchGroup) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"SearchGroup"]);
		}
	}
}
/* elements */
@synthesize SearchGroup;
- (void)addSearchGroup:(ContentCafe_SearchGroup *)toAdd
{
	if(toAdd != nil) [SearchGroup addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_SearchGroups *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchGroups *newObject = [[ContentCafe_SearchGroups new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchGroup")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchGroup class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.SearchGroup addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_Title
- (id)init
{
	if((self = [super init])) {
		LeadingArticle = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(LeadingArticle != nil) [LeadingArticle release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Title");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.LeadingArticle != 0) {
		xmlSetProp(node, (const xmlChar*)"LeadingArticle", (const xmlChar*)[[self.LeadingArticle description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
	[attribs setObject:self.LeadingArticle forKey:@"LeadingArticle"];
	
	return attribs;
}
@synthesize LeadingArticle, Value;
+ (ContentCafe_Title *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Title *newObject = [[ContentCafe_Title new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "LeadingArticle");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.LeadingArticle = attrString;
		xmlFree(attrValue);
	}
	// Add attribute for the element content, lifted from ProductItem deserialization code.
	// Probably a better way to do this but heck it works.
	xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
	NSString *elementString = nil;
	if(elementText != NULL) {
		elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
		//[elementString self]; // avoid compiler warning for unused var
		xmlFree(elementText);
	}
	self.Value = elementString;
	
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_CodeLiteral
- (id)init
{
	if((self = [super init])) {
		Code = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Code != nil) [Code release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:CodeLiteral");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Code != 0) {
		xmlSetProp(node, (const xmlChar*)"Code", (const xmlChar*)[[self.Code description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.Code forKey:@"Code"];
	
	return attributes;
}
@synthesize Code;
+ (ContentCafe_CodeLiteral *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_CodeLiteral *newObject = [[ContentCafe_CodeLiteral new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Code");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Code = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_ProductItem
- (id)init
{
	if((self = [super init])) {
		ISBN = 0;
		UPC = 0;
		Title = 0;
		Author = 0;
		Source = 0;
		Product = 0;
		Supplier = 0;
		Series = 0;
		ListPrice = 0;
		PubDate = 0;
		Format = 0;
		Report = 0;
		BTKey = 0;
		Dewey = 0;
		LCCN = 0;
		Edition = 0;
		Volume = 0;
		LCClass = 0;
		ISSN = 0;
		Language = 0;
		RatingGradeLevel = 0;
		GeneralSubject = [[NSMutableArray alloc] init];
		LibrarySubject = [[NSMutableArray alloc] init];
		Attribute = [[NSMutableArray alloc] init];
		ReviewCode = [[NSMutableArray alloc] init];
		LexileCode = 0;
		Pagination = 0;
		Created = 0;
		Updated = 0;
		Active = 0;
		Returnable = 0;
		DiscountKey = 0;
		Width = 0;
		Height = 0;
		Depth = 0;
		Weight = 0;
		CPSIA_Warning = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(ISBN != nil) [ISBN release];
	if(UPC != nil) [UPC release];
	if(Title != nil) [Title release];
	if(Author != nil) [Author release];
	if(Source != nil) [Source release];
	if(Product != nil) [Product release];
	if(Supplier != nil) [Supplier release];
	if(Series != nil) [Series release];
	if(ListPrice != nil) [ListPrice release];
	if(PubDate != nil) [PubDate release];
	if(Format != nil) [Format release];
	if(Report != nil) [Report release];
	if(BTKey != nil) [BTKey release];
	if(Dewey != nil) [Dewey release];
	if(LCCN != nil) [LCCN release];
	if(Edition != nil) [Edition release];
	if(Volume != nil) [Volume release];
	if(LCClass != nil) [LCClass release];
	if(ISSN != nil) [ISSN release];
	if(Language != nil) [Language release];
	if(RatingGradeLevel != nil) [RatingGradeLevel release];
	if(GeneralSubject != nil) [GeneralSubject release];
	if(LibrarySubject != nil) [LibrarySubject release];
	if(Attribute != nil) [Attribute release];
	if(ReviewCode != nil) [ReviewCode release];
	if(LexileCode != nil) [LexileCode release];
	if(Pagination != nil) [Pagination release];
	if(Created != nil) [Created release];
	if(Updated != nil) [Updated release];
	if(Active != nil) [Active release];
	if(Returnable != nil) [Returnable release];
	if(DiscountKey != nil) [DiscountKey release];
	if(Width != nil) [Width release];
	if(Height != nil) [Height release];
	if(Depth != nil) [Depth release];
	if(Weight != nil) [Weight release];
	if(CPSIA_Warning != nil) [CPSIA_Warning release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ProductItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ISBN != 0) {
		xmlAddChild(node, [self.ISBN xmlNodeForDoc:node->doc elementName:@"ISBN"]);
	}
	if(self.UPC != 0) {
		xmlAddChild(node, [self.UPC xmlNodeForDoc:node->doc elementName:@"UPC"]);
	}
	if(self.Title != 0) {
		xmlAddChild(node, [self.Title xmlNodeForDoc:node->doc elementName:@"Title"]);
	}
	if(self.Author != 0) {
		xmlAddChild(node, [self.Author xmlNodeForDoc:node->doc elementName:@"Author"]);
	}
	if(self.Source != 0) {
		xmlAddChild(node, [self.Source xmlNodeForDoc:node->doc elementName:@"Source"]);
	}
	if(self.Product != 0) {
		xmlAddChild(node, [self.Product xmlNodeForDoc:node->doc elementName:@"Product"]);
	}
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Series != 0) {
		xmlAddChild(node, [self.Series xmlNodeForDoc:node->doc elementName:@"Series"]);
	}
	if(self.ListPrice != 0) {
		xmlAddChild(node, [self.ListPrice xmlNodeForDoc:node->doc elementName:@"ListPrice"]);
	}
	if(self.PubDate != 0) {
		xmlAddChild(node, [self.PubDate xmlNodeForDoc:node->doc elementName:@"PubDate"]);
	}
	if(self.Format != 0) {
		xmlAddChild(node, [self.Format xmlNodeForDoc:node->doc elementName:@"Format"]);
	}
	if(self.Report != 0) {
		xmlAddChild(node, [self.Report xmlNodeForDoc:node->doc elementName:@"Report"]);
	}
	if(self.BTKey != 0) {
		xmlAddChild(node, [self.BTKey xmlNodeForDoc:node->doc elementName:@"BTKey"]);
	}
	if(self.Dewey != 0) {
		xmlAddChild(node, [self.Dewey xmlNodeForDoc:node->doc elementName:@"Dewey"]);
	}
	if(self.LCCN != 0) {
		xmlAddChild(node, [self.LCCN xmlNodeForDoc:node->doc elementName:@"LCCN"]);
	}
	if(self.Edition != 0) {
		xmlAddChild(node, [self.Edition xmlNodeForDoc:node->doc elementName:@"Edition"]);
	}
	if(self.Volume != 0) {
		xmlAddChild(node, [self.Volume xmlNodeForDoc:node->doc elementName:@"Volume"]);
	}
	if(self.LCClass != 0) {
		xmlAddChild(node, [self.LCClass xmlNodeForDoc:node->doc elementName:@"LCClass"]);
	}
	if(self.ISSN != 0) {
		xmlAddChild(node, [self.ISSN xmlNodeForDoc:node->doc elementName:@"ISSN"]);
	}
	if(self.Language != 0) {
		xmlAddChild(node, [self.Language xmlNodeForDoc:node->doc elementName:@"Language"]);
	}
	if(self.RatingGradeLevel != 0) {
		xmlAddChild(node, [self.RatingGradeLevel xmlNodeForDoc:node->doc elementName:@"RatingGradeLevel"]);
	}
	if(self.GeneralSubject != 0) {
		for(NSString * child in self.GeneralSubject) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"GeneralSubject"]);
		}
	}
	if(self.LibrarySubject != 0) {
		for(NSString * child in self.LibrarySubject) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"LibrarySubject"]);
		}
	}
	if(self.Attribute != 0) {
		for(NSString * child in self.Attribute) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"Attribute"]);
		}
	}
	if(self.ReviewCode != 0) {
		for(NSString * child in self.ReviewCode) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ReviewCode"]);
		}
	}
	if(self.LexileCode != 0) {
		xmlAddChild(node, [self.LexileCode xmlNodeForDoc:node->doc elementName:@"LexileCode"]);
	}
	if(self.Pagination != 0) {
		xmlAddChild(node, [self.Pagination xmlNodeForDoc:node->doc elementName:@"Pagination"]);
	}
	if(self.Created != 0) {
		xmlAddChild(node, [self.Created xmlNodeForDoc:node->doc elementName:@"Created"]);
	}
	if(self.Updated != 0) {
		xmlAddChild(node, [self.Updated xmlNodeForDoc:node->doc elementName:@"Updated"]);
	}
	if(self.Active != 0) {
		xmlAddChild(node, [self.Active xmlNodeForDoc:node->doc elementName:@"Active"]);
	}
	if(self.Returnable != 0) {
		xmlAddChild(node, [self.Returnable xmlNodeForDoc:node->doc elementName:@"Returnable"]);
	}
	if(self.DiscountKey != 0) {
		xmlAddChild(node, [self.DiscountKey xmlNodeForDoc:node->doc elementName:@"DiscountKey"]);
	}
	if(self.Width != 0) {
		xmlAddChild(node, [self.Width xmlNodeForDoc:node->doc elementName:@"Width"]);
	}
	if(self.Height != 0) {
		xmlAddChild(node, [self.Height xmlNodeForDoc:node->doc elementName:@"Height"]);
	}
	if(self.Depth != 0) {
		xmlAddChild(node, [self.Depth xmlNodeForDoc:node->doc elementName:@"Depth"]);
	}
	if(self.Weight != 0) {
		xmlAddChild(node, [self.Weight xmlNodeForDoc:node->doc elementName:@"Weight"]);
	}
	if(self.CPSIA_Warning != 0) {
		xmlAddChild(node, [self.CPSIA_Warning xmlNodeForDoc:node->doc elementName:@"CPSIA_Warning"]);
	}
}
/* elements */
@synthesize ISBN;
@synthesize UPC;
@synthesize Title;
@synthesize Author;
@synthesize Source;
@synthesize Product;
@synthesize Supplier;
@synthesize Series;
@synthesize ListPrice;
@synthesize PubDate;
@synthesize Format;
@synthesize Report;
@synthesize BTKey;
@synthesize Dewey;
@synthesize LCCN;
@synthesize Edition;
@synthesize Volume;
@synthesize LCClass;
@synthesize ISSN;
@synthesize Language;
@synthesize RatingGradeLevel;
@synthesize GeneralSubject;
- (void)addGeneralSubject:(NSString *)toAdd
{
	if(toAdd != nil) [GeneralSubject addObject:toAdd];
}
@synthesize LibrarySubject;
- (void)addLibrarySubject:(NSString *)toAdd
{
	if(toAdd != nil) [LibrarySubject addObject:toAdd];
}
@synthesize Attribute;
- (void)addAttribute:(NSString *)toAdd
{
	if(toAdd != nil) [Attribute addObject:toAdd];
}
@synthesize ReviewCode;
- (void)addReviewCode:(NSString *)toAdd
{
	if(toAdd != nil) [ReviewCode addObject:toAdd];
}
@synthesize LexileCode;
@synthesize Pagination;
@synthesize Created;
@synthesize Updated;
@synthesize Active;
@synthesize Returnable;
@synthesize DiscountKey;
@synthesize Width;
@synthesize Height;
@synthesize Depth;
@synthesize Weight;
@synthesize CPSIA_Warning;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_ProductItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ProductItem *newObject = [[ContentCafe_ProductItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ISBN")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ISBN = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "UPC")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.UPC = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Title")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Title class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Title = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Author")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Author = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Source")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Source = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Product")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Product = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Series")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Series = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ListPrice")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ListPrice = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "PubDate")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.PubDate = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Format")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Format = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Report")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Report = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "BTKey")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.BTKey = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Dewey")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Dewey = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "LCCN")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.LCCN = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Edition")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Edition = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Volume")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Volume = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "LCClass")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.LCClass = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ISSN")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ISSN = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Language")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Language = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "RatingGradeLevel")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.RatingGradeLevel = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "GeneralSubject")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.GeneralSubject addObject:newChild];
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "LibrarySubject")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.LibrarySubject addObject:newChild];
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Attribute")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.Attribute addObject:newChild];
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewCode")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ReviewCode addObject:newChild];
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "LexileCode")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.LexileCode = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Pagination")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Pagination = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Created")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Created = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Updated")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Updated = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Active")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Active = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Returnable")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Returnable = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DiscountKey")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DiscountKey = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Width")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Width = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Height")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Height = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Depth")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Depth = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Weight")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Weight = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "CPSIA_Warning")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.CPSIA_Warning = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_SearchResults
- (id)init
{
	if((self = [super init])) {
		ProductItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(ProductItem != nil) [ProductItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SearchResults");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ProductItem != 0) {
		for(ContentCafe_ProductItem * child in self.ProductItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ProductItem"]);
		}
	}
}
/* elements */
@synthesize ProductItem;
- (void)addProductItem:(ContentCafe_ProductItem *)toAdd
{
	if(toAdd != nil) [ProductItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_SearchResults *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SearchResults *newObject = [[ContentCafe_SearchResults new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ProductItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ProductItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ProductItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_Search
- (id)init
{
	if((self = [super init])) {
		SearchOptions = 0;
		SearchGroups = 0;
		SearchQuery = 0;
		SearchResults = 0;
		UserID = 0;
		Password = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(SearchOptions != nil) [SearchOptions release];
	if(SearchGroups != nil) [SearchGroups release];
	if(SearchQuery != nil) [SearchQuery release];
	if(SearchResults != nil) [SearchResults release];
	if(UserID != nil) [UserID release];
	if(Password != nil) [Password release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Search");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.UserID != 0) {
		xmlSetProp(node, (const xmlChar*)"UserID", (const xmlChar*)[[self.UserID description] UTF8String]);
	}
	if(self.Password != 0) {
		xmlSetProp(node, (const xmlChar*)"Password", (const xmlChar*)[[self.Password description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.SearchOptions != 0) {
		xmlAddChild(node, [self.SearchOptions xmlNodeForDoc:node->doc elementName:@"SearchOptions"]);
	}
	if(self.SearchGroups != 0) {
		xmlAddChild(node, [self.SearchGroups xmlNodeForDoc:node->doc elementName:@"SearchGroups"]);
	}
	if(self.SearchQuery != 0) {
		xmlAddChild(node, [self.SearchQuery xmlNodeForDoc:node->doc elementName:@"SearchQuery"]);
	}
	if(self.SearchResults != 0) {
		xmlAddChild(node, [self.SearchResults xmlNodeForDoc:node->doc elementName:@"SearchResults"]);
	}
}
/* elements */
@synthesize SearchOptions;
@synthesize SearchGroups;
@synthesize SearchQuery;
@synthesize SearchResults;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.UserID forKey:@"UserID"];
	[attributes setObject:self.Password forKey:@"Password"];
	
	return attributes;
}
@synthesize UserID;
@synthesize Password;
+ (ContentCafe_Search *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Search *newObject = [[ContentCafe_Search new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "UserID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UserID = attrString;
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "Password");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Password = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchOptions")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchOptions class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.SearchOptions = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchGroups")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchGroups class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.SearchGroups = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchQuery")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.SearchQuery = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "SearchResults")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_SearchResults class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.SearchResults = newChild;
			}
		}
	}
}
@end
ContentCafe_KeyType ContentCafe_KeyType_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Undefined"]) {
		return ContentCafe_KeyType_Undefined;
	}
	if([string isEqualToString:@"ISBN"]) {
		return ContentCafe_KeyType_ISBN;
	}
	if([string isEqualToString:@"UPC"]) {
		return ContentCafe_KeyType_UPC;
	}
	if([string isEqualToString:@"ID"]) {
		return ContentCafe_KeyType_ID;
	}
	
	return ContentCafe_KeyType_none;
}
NSString * ContentCafe_KeyType_stringFromEnum(ContentCafe_KeyType enumValue)
{
	switch (enumValue) {
		case ContentCafe_KeyType_Undefined:
			return @"Undefined";
			break;
		case ContentCafe_KeyType_ISBN:
			return @"ISBN";
			break;
		case ContentCafe_KeyType_UPC:
			return @"UPC";
			break;
		case ContentCafe_KeyType_ID:
			return @"ID";
			break;
		default:
			return @"";
	}
}
@implementation ContentCafe_Key
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Original = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Original != nil) [Original release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Key");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlSetProp(node, (const xmlChar*)"Type", (const xmlChar*)[ContentCafe_KeyType_stringFromEnum(self.Type) UTF8String]);
	}
	if(self.Original != 0) {
		xmlSetProp(node, (const xmlChar*)"Original", (const xmlChar*)[[self.Original description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithInt:(int)self.Type] forKey:@"Type"];
	[attributes setObject:self.Original forKey:@"Original"];
	
	return attributes;
}
@synthesize Type;
@synthesize Original;
+ (ContentCafe_Key *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Key *newObject = [[ContentCafe_Key new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Type");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Type = ContentCafe_KeyType_enumFromString(attrString);
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "Original");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Original = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
ContentCafe_ContentType ContentCafe_ContentType_enumFromString(NSString *string)
{
	if([string isEqualToString:@"Undefined"]) {
		return ContentCafe_ContentType_Undefined;
	}
	if([string isEqualToString:@"Environment"]) {
		return ContentCafe_ContentType_Environment;
	}
	if([string isEqualToString:@"Member"]) {
		return ContentCafe_ContentType_Member;
	}
	if([string isEqualToString:@"AllMembers"]) {
		return ContentCafe_ContentType_AllMembers;
	}
	if([string isEqualToString:@"AvailableContent"]) {
		return ContentCafe_ContentType_AvailableContent;
	}
	if([string isEqualToString:@"AnnotationSummary"]) {
		return ContentCafe_ContentType_AnnotationSummary;
	}
	if([string isEqualToString:@"AnnotationBrief"]) {
		return ContentCafe_ContentType_AnnotationBrief;
	}
	if([string isEqualToString:@"AnnotationDetail"]) {
		return ContentCafe_ContentType_AnnotationDetail;
	}
	if([string isEqualToString:@"ReviewSummary"]) {
		return ContentCafe_ContentType_ReviewSummary;
	}
	if([string isEqualToString:@"ReviewBrief"]) {
		return ContentCafe_ContentType_ReviewBrief;
	}
	if([string isEqualToString:@"ReviewDetail"]) {
		return ContentCafe_ContentType_ReviewDetail;
	}
	if([string isEqualToString:@"BiographySummary"]) {
		return ContentCafe_ContentType_BiographySummary;
	}
	if([string isEqualToString:@"BiographyBrief"]) {
		return ContentCafe_ContentType_BiographyBrief;
	}
	if([string isEqualToString:@"BiographyDetail"]) {
		return ContentCafe_ContentType_BiographyDetail;
	}
	if([string isEqualToString:@"FlapSummary"]) {
		return ContentCafe_ContentType_FlapSummary;
	}
	if([string isEqualToString:@"FlapBrief"]) {
		return ContentCafe_ContentType_FlapBrief;
	}
	if([string isEqualToString:@"FlapDetail"]) {
		return ContentCafe_ContentType_FlapDetail;
	}
	if([string isEqualToString:@"InventorySummary"]) {
		return ContentCafe_ContentType_InventorySummary;
	}
	if([string isEqualToString:@"InventoryBrief"]) {
		return ContentCafe_ContentType_InventoryBrief;
	}
	if([string isEqualToString:@"InventoryDetail"]) {
		return ContentCafe_ContentType_InventoryDetail;
	}
	if([string isEqualToString:@"DemandSummary"]) {
		return ContentCafe_ContentType_DemandSummary;
	}
	if([string isEqualToString:@"DemandBrief"]) {
		return ContentCafe_ContentType_DemandBrief;
	}
	if([string isEqualToString:@"DemandDetail"]) {
		return ContentCafe_ContentType_DemandDetail;
	}
	if([string isEqualToString:@"DemandHistorySummary"]) {
		return ContentCafe_ContentType_DemandHistorySummary;
	}
	if([string isEqualToString:@"DemandHistoryBrief"]) {
		return ContentCafe_ContentType_DemandHistoryBrief;
	}
	if([string isEqualToString:@"DemandHistoryDetail"]) {
		return ContentCafe_ContentType_DemandHistoryDetail;
	}
	if([string isEqualToString:@"JacketSummary"]) {
		return ContentCafe_ContentType_JacketSummary;
	}
	if([string isEqualToString:@"JacketBrief"]) {
		return ContentCafe_ContentType_JacketBrief;
	}
	if([string isEqualToString:@"JacketDetail"]) {
		return ContentCafe_ContentType_JacketDetail;
	}
	if([string isEqualToString:@"TocSummary"]) {
		return ContentCafe_ContentType_TocSummary;
	}
	if([string isEqualToString:@"TocBrief"]) {
		return ContentCafe_ContentType_TocBrief;
	}
	if([string isEqualToString:@"TocDetail"]) {
		return ContentCafe_ContentType_TocDetail;
	}
	if([string isEqualToString:@"ExcerptSummary"]) {
		return ContentCafe_ContentType_ExcerptSummary;
	}
	if([string isEqualToString:@"ExcerptBrief"]) {
		return ContentCafe_ContentType_ExcerptBrief;
	}
	if([string isEqualToString:@"ExcerptDetail"]) {
		return ContentCafe_ContentType_ExcerptDetail;
	}
	if([string isEqualToString:@"ProductSummary"]) {
		return ContentCafe_ContentType_ProductSummary;
	}
	if([string isEqualToString:@"ProductBrief"]) {
		return ContentCafe_ContentType_ProductBrief;
	}
	if([string isEqualToString:@"ProductDetail"]) {
		return ContentCafe_ContentType_ProductDetail;
	}
	if([string isEqualToString:@"MuzeSummary"]) {
		return ContentCafe_ContentType_MuzeSummary;
	}
	if([string isEqualToString:@"MuzeVideoRelease"]) {
		return ContentCafe_ContentType_MuzeVideoRelease;
	}
	if([string isEqualToString:@"MuzeSimilarCinema"]) {
		return ContentCafe_ContentType_MuzeSimilarCinema;
	}
	if([string isEqualToString:@"MuzePopularMusic"]) {
		return ContentCafe_ContentType_MuzePopularMusic;
	}
	if([string isEqualToString:@"MuzeClassicalMusic"]) {
		return ContentCafe_ContentType_MuzeClassicalMusic;
	}
	if([string isEqualToString:@"MuzeEssentialArtists"]) {
		return ContentCafe_ContentType_MuzeEssentialArtists;
	}
	if([string isEqualToString:@"MuzeGames"]) {
		return ContentCafe_ContentType_MuzeGames;
	}
	
	return ContentCafe_ContentType_none;
}
NSString * ContentCafe_ContentType_stringFromEnum(ContentCafe_ContentType enumValue)
{
	switch (enumValue) {
		case ContentCafe_ContentType_Undefined:
			return @"Undefined";
			break;
		case ContentCafe_ContentType_Environment:
			return @"Environment";
			break;
		case ContentCafe_ContentType_Member:
			return @"Member";
			break;
		case ContentCafe_ContentType_AllMembers:
			return @"AllMembers";
			break;
		case ContentCafe_ContentType_AvailableContent:
			return @"AvailableContent";
			break;
		case ContentCafe_ContentType_AnnotationSummary:
			return @"AnnotationSummary";
			break;
		case ContentCafe_ContentType_AnnotationBrief:
			return @"AnnotationBrief";
			break;
		case ContentCafe_ContentType_AnnotationDetail:
			return @"AnnotationDetail";
			break;
		case ContentCafe_ContentType_ReviewSummary:
			return @"ReviewSummary";
			break;
		case ContentCafe_ContentType_ReviewBrief:
			return @"ReviewBrief";
			break;
		case ContentCafe_ContentType_ReviewDetail:
			return @"ReviewDetail";
			break;
		case ContentCafe_ContentType_BiographySummary:
			return @"BiographySummary";
			break;
		case ContentCafe_ContentType_BiographyBrief:
			return @"BiographyBrief";
			break;
		case ContentCafe_ContentType_BiographyDetail:
			return @"BiographyDetail";
			break;
		case ContentCafe_ContentType_FlapSummary:
			return @"FlapSummary";
			break;
		case ContentCafe_ContentType_FlapBrief:
			return @"FlapBrief";
			break;
		case ContentCafe_ContentType_FlapDetail:
			return @"FlapDetail";
			break;
		case ContentCafe_ContentType_InventorySummary:
			return @"InventorySummary";
			break;
		case ContentCafe_ContentType_InventoryBrief:
			return @"InventoryBrief";
			break;
		case ContentCafe_ContentType_InventoryDetail:
			return @"InventoryDetail";
			break;
		case ContentCafe_ContentType_DemandSummary:
			return @"DemandSummary";
			break;
		case ContentCafe_ContentType_DemandBrief:
			return @"DemandBrief";
			break;
		case ContentCafe_ContentType_DemandDetail:
			return @"DemandDetail";
			break;
		case ContentCafe_ContentType_DemandHistorySummary:
			return @"DemandHistorySummary";
			break;
		case ContentCafe_ContentType_DemandHistoryBrief:
			return @"DemandHistoryBrief";
			break;
		case ContentCafe_ContentType_DemandHistoryDetail:
			return @"DemandHistoryDetail";
			break;
		case ContentCafe_ContentType_JacketSummary:
			return @"JacketSummary";
			break;
		case ContentCafe_ContentType_JacketBrief:
			return @"JacketBrief";
			break;
		case ContentCafe_ContentType_JacketDetail:
			return @"JacketDetail";
			break;
		case ContentCafe_ContentType_TocSummary:
			return @"TocSummary";
			break;
		case ContentCafe_ContentType_TocBrief:
			return @"TocBrief";
			break;
		case ContentCafe_ContentType_TocDetail:
			return @"TocDetail";
			break;
		case ContentCafe_ContentType_ExcerptSummary:
			return @"ExcerptSummary";
			break;
		case ContentCafe_ContentType_ExcerptBrief:
			return @"ExcerptBrief";
			break;
		case ContentCafe_ContentType_ExcerptDetail:
			return @"ExcerptDetail";
			break;
		case ContentCafe_ContentType_ProductSummary:
			return @"ProductSummary";
			break;
		case ContentCafe_ContentType_ProductBrief:
			return @"ProductBrief";
			break;
		case ContentCafe_ContentType_ProductDetail:
			return @"ProductDetail";
			break;
		case ContentCafe_ContentType_MuzeSummary:
			return @"MuzeSummary";
			break;
		case ContentCafe_ContentType_MuzeVideoRelease:
			return @"MuzeVideoRelease";
			break;
		case ContentCafe_ContentType_MuzeSimilarCinema:
			return @"MuzeSimilarCinema";
			break;
		case ContentCafe_ContentType_MuzePopularMusic:
			return @"MuzePopularMusic";
			break;
		case ContentCafe_ContentType_MuzeClassicalMusic:
			return @"MuzeClassicalMusic";
			break;
		case ContentCafe_ContentType_MuzeEssentialArtists:
			return @"MuzeEssentialArtists";
			break;
		case ContentCafe_ContentType_MuzeGames:
			return @"MuzeGames";
			break;
		default:
			return @"";
	}
}
@implementation ContentCafe_Content
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Encoding = 0;
		VendorID = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Encoding != nil) [Encoding release];
	if(VendorID != nil) [VendorID release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Content");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlSetProp(node, (const xmlChar*)"Type", (const xmlChar*)[[self.Type description] UTF8String]);
	}
	if(self.Encoding != 0) {
		xmlSetProp(node, (const xmlChar*)"Encoding", (const xmlChar*)[[self.Encoding description] UTF8String]);
	}
	if(self.VendorID != 0) {
		xmlSetProp(node, (const xmlChar*)"VendorID", (const xmlChar*)[[self.VendorID description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.Type forKey:@"Type"];
	[attributes setObject:self.Encoding forKey:@"Encoding"];
	[attributes setObject:self.VendorID forKey:@"VendorID"];
	
	return attributes;
}
@synthesize Type;
@synthesize Encoding;
@synthesize VendorID;
+ (ContentCafe_Content *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Content *newObject = [[ContentCafe_Content new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Type");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Type = attrString;
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "Encoding");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Encoding = attrString;
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "VendorID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.VendorID = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_Environment
- (id)init
{
	if((self = [super init])) {
		RawUrl = 0;
		Path = 0;
		RequestType = 0;
		ContentLength = 0;
		ContentType = 0;
		LocalAddress = 0;
		ServerName = 0;
		ServerPort = 0;
		ServerProtocol = 0;
		ServerSoftware = 0;
		MachineName = 0;
		Browser = 0;
		UserAgent = 0;
		UserHostAddress = 0;
		UserHostName = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(RawUrl != nil) [RawUrl release];
	if(Path != nil) [Path release];
	if(RequestType != nil) [RequestType release];
	if(ContentLength != nil) [ContentLength release];
	if(ContentType != nil) [ContentType release];
	if(LocalAddress != nil) [LocalAddress release];
	if(ServerName != nil) [ServerName release];
	if(ServerPort != nil) [ServerPort release];
	if(ServerProtocol != nil) [ServerProtocol release];
	if(ServerSoftware != nil) [ServerSoftware release];
	if(MachineName != nil) [MachineName release];
	if(Browser != nil) [Browser release];
	if(UserAgent != nil) [UserAgent release];
	if(UserHostAddress != nil) [UserHostAddress release];
	if(UserHostName != nil) [UserHostName release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Environment");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.RawUrl != 0) {
		xmlAddChild(node, [self.RawUrl xmlNodeForDoc:node->doc elementName:@"RawUrl"]);
	}
	if(self.Path != 0) {
		xmlAddChild(node, [self.Path xmlNodeForDoc:node->doc elementName:@"Path"]);
	}
	if(self.RequestType != 0) {
		xmlAddChild(node, [self.RequestType xmlNodeForDoc:node->doc elementName:@"RequestType"]);
	}
	if(self.ContentLength != 0) {
		xmlAddChild(node, [self.ContentLength xmlNodeForDoc:node->doc elementName:@"ContentLength"]);
	}
	if(self.ContentType != 0) {
		xmlAddChild(node, [self.ContentType xmlNodeForDoc:node->doc elementName:@"ContentType"]);
	}
	if(self.LocalAddress != 0) {
		xmlAddChild(node, [self.LocalAddress xmlNodeForDoc:node->doc elementName:@"LocalAddress"]);
	}
	if(self.ServerName != 0) {
		xmlAddChild(node, [self.ServerName xmlNodeForDoc:node->doc elementName:@"ServerName"]);
	}
	if(self.ServerPort != 0) {
		xmlAddChild(node, [self.ServerPort xmlNodeForDoc:node->doc elementName:@"ServerPort"]);
	}
	if(self.ServerProtocol != 0) {
		xmlAddChild(node, [self.ServerProtocol xmlNodeForDoc:node->doc elementName:@"ServerProtocol"]);
	}
	if(self.ServerSoftware != 0) {
		xmlAddChild(node, [self.ServerSoftware xmlNodeForDoc:node->doc elementName:@"ServerSoftware"]);
	}
	if(self.MachineName != 0) {
		xmlAddChild(node, [self.MachineName xmlNodeForDoc:node->doc elementName:@"MachineName"]);
	}
	if(self.Browser != 0) {
		xmlAddChild(node, [self.Browser xmlNodeForDoc:node->doc elementName:@"Browser"]);
	}
	if(self.UserAgent != 0) {
		xmlAddChild(node, [self.UserAgent xmlNodeForDoc:node->doc elementName:@"UserAgent"]);
	}
	if(self.UserHostAddress != 0) {
		xmlAddChild(node, [self.UserHostAddress xmlNodeForDoc:node->doc elementName:@"UserHostAddress"]);
	}
	if(self.UserHostName != 0) {
		xmlAddChild(node, [self.UserHostName xmlNodeForDoc:node->doc elementName:@"UserHostName"]);
	}
}
/* elements */
@synthesize RawUrl;
@synthesize Path;
@synthesize RequestType;
@synthesize ContentLength;
@synthesize ContentType;
@synthesize LocalAddress;
@synthesize ServerName;
@synthesize ServerPort;
@synthesize ServerProtocol;
@synthesize ServerSoftware;
@synthesize MachineName;
@synthesize Browser;
@synthesize UserAgent;
@synthesize UserHostAddress;
@synthesize UserHostName;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Environment *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Environment *newObject = [[ContentCafe_Environment new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "RawUrl")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.RawUrl = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Path")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Path = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "RequestType")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.RequestType = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentLength")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentLength = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentType")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentType = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "LocalAddress")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.LocalAddress = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ServerName")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ServerName = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ServerPort")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ServerPort = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ServerProtocol")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ServerProtocol = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ServerSoftware")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ServerSoftware = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MachineName")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MachineName = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Browser")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Browser = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "UserAgent")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.UserAgent = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "UserHostAddress")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.UserHostAddress = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "UserHostName")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.UserHostName = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ReviewPublicationItems
- (id)init
{
	if((self = [super init])) {
		ReviewPublicationItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(ReviewPublicationItem != nil) [ReviewPublicationItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ReviewPublicationItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ReviewPublicationItem != 0) {
		for(ContentCafe_CodeLiteral * child in self.ReviewPublicationItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ReviewPublicationItem"]);
		}
	}
}
/* elements */
@synthesize ReviewPublicationItem;
- (void)addReviewPublicationItem:(ContentCafe_CodeLiteral *)toAdd
{
	if(toAdd != nil) [ReviewPublicationItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ReviewPublicationItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ReviewPublicationItems *newObject = [[ContentCafe_ReviewPublicationItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewPublicationItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ReviewPublicationItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_InventoryAvailabilityItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventoryAvailabilityItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_InventoryAvailabilityItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventoryAvailabilityItem *newObject = [[ContentCafe_InventoryAvailabilityItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_InventoryAvailabilityItems
- (id)init
{
	if((self = [super init])) {
		InventoryAvailabilityItem = [[NSMutableArray alloc] init];
		Minimum = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(InventoryAvailabilityItem != nil) [InventoryAvailabilityItem release];
	if(Minimum != nil) [Minimum release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventoryAvailabilityItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Minimum != 0) {
		xmlSetProp(node, (const xmlChar*)"Minimum", (const xmlChar*)[[self.Minimum description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.InventoryAvailabilityItem != 0) {
		for(ContentCafe_InventoryAvailabilityItem * child in self.InventoryAvailabilityItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"InventoryAvailabilityItem"]);
		}
	}
}
/* elements */
@synthesize InventoryAvailabilityItem;
- (void)addInventoryAvailabilityItem:(ContentCafe_InventoryAvailabilityItem *)toAdd
{
	if(toAdd != nil) [InventoryAvailabilityItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.Minimum forKey:@"Minimum"];
	
	return attributes;
}
@synthesize Minimum;
+ (ContentCafe_InventoryAvailabilityItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventoryAvailabilityItems *newObject = [[ContentCafe_InventoryAvailabilityItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Minimum");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Minimum = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventoryAvailabilityItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventoryAvailabilityItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.InventoryAvailabilityItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_MemberLinkItem
- (id)init
{
	if((self = [super init])) {
		Description = 0;
		URL = 0;
		Active = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Description != nil) [Description release];
	if(URL != nil) [URL release];
	if(Active != nil) [Active release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MemberLinkItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Description != 0) {
		xmlAddChild(node, [self.Description xmlNodeForDoc:node->doc elementName:@"Description"]);
	}
	if(self.URL != 0) {
		xmlAddChild(node, [self.URL xmlNodeForDoc:node->doc elementName:@"URL"]);
	}
	if(self.Active != 0) {
		xmlAddChild(node, [self.Active xmlNodeForDoc:node->doc elementName:@"Active"]);
	}
}
/* elements */
@synthesize Description;
@synthesize URL;
@synthesize Active;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_MemberLinkItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MemberLinkItem *newObject = [[ContentCafe_MemberLinkItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Description")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Description = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "URL")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.URL = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Active")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Active = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_MemberLinkItems
- (id)init
{
	if((self = [super init])) {
		MemberLinkItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(MemberLinkItem != nil) [MemberLinkItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MemberLinkItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.MemberLinkItem != 0) {
		for(ContentCafe_MemberLinkItem * child in self.MemberLinkItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"MemberLinkItem"]);
		}
	}
}
/* elements */
@synthesize MemberLinkItem;
- (void)addMemberLinkItem:(ContentCafe_MemberLinkItem *)toAdd
{
	if(toAdd != nil) [MemberLinkItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_MemberLinkItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MemberLinkItems *newObject = [[ContentCafe_MemberLinkItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MemberLinkItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MemberLinkItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.MemberLinkItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_MemberItem
- (id)init
{
	if((self = [super init])) {
		UserID = 0;
		Password = 0;
		Active = 0;
		Admin = 0;
		Annotation = 0;
		Biography = 0;
		Excerpt = 0;
		Flap = 0;
		Inventory = 0;
		Demand = 0;
		DemandHistory = 0;
		Jacket = 0;
		Product = 0;
		Review = 0;
		TOC = 0;
		ReviewPublicationItems = 0;
		InventoryAvailabilityItems = 0;
		MemberLinkItems = 0;
		Search = 0;
		MuzeVideoRelease = 0;
		MuzeSimilarCinema = 0;
		MuzePopularMusic = 0;
		MuzeClassicalMusic = 0;
		MuzeEssentialArtists = 0;
		MuzeGames = 0;
		MuzeJacket = 0;
		MuzeTunes = 0;
		MuzeReels = 0;
		ReserveInventory = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(UserID != nil) [UserID release];
	if(Password != nil) [Password release];
	if(Active != nil) [Active release];
	if(Admin != nil) [Admin release];
	if(Annotation != nil) [Annotation release];
	if(Biography != nil) [Biography release];
	if(Excerpt != nil) [Excerpt release];
	if(Flap != nil) [Flap release];
	if(Inventory != nil) [Inventory release];
	if(Demand != nil) [Demand release];
	if(DemandHistory != nil) [DemandHistory release];
	if(Jacket != nil) [Jacket release];
	if(Product != nil) [Product release];
	if(Review != nil) [Review release];
	if(TOC != nil) [TOC release];
	if(ReviewPublicationItems != nil) [ReviewPublicationItems release];
	if(InventoryAvailabilityItems != nil) [InventoryAvailabilityItems release];
	if(MemberLinkItems != nil) [MemberLinkItems release];
	if(Search != nil) [Search release];
	if(MuzeVideoRelease != nil) [MuzeVideoRelease release];
	if(MuzeSimilarCinema != nil) [MuzeSimilarCinema release];
	if(MuzePopularMusic != nil) [MuzePopularMusic release];
	if(MuzeClassicalMusic != nil) [MuzeClassicalMusic release];
	if(MuzeEssentialArtists != nil) [MuzeEssentialArtists release];
	if(MuzeGames != nil) [MuzeGames release];
	if(MuzeJacket != nil) [MuzeJacket release];
	if(MuzeTunes != nil) [MuzeTunes release];
	if(MuzeReels != nil) [MuzeReels release];
	if(ReserveInventory != nil) [ReserveInventory release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MemberItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.UserID != 0) {
		xmlAddChild(node, [self.UserID xmlNodeForDoc:node->doc elementName:@"UserID"]);
	}
	if(self.Password != 0) {
		xmlAddChild(node, [self.Password xmlNodeForDoc:node->doc elementName:@"Password"]);
	}
	if(self.Active != 0) {
		xmlAddChild(node, [self.Active xmlNodeForDoc:node->doc elementName:@"Active"]);
	}
	if(self.Admin != 0) {
		xmlAddChild(node, [self.Admin xmlNodeForDoc:node->doc elementName:@"Admin"]);
	}
	if(self.Annotation != 0) {
		xmlAddChild(node, [self.Annotation xmlNodeForDoc:node->doc elementName:@"Annotation"]);
	}
	if(self.Biography != 0) {
		xmlAddChild(node, [self.Biography xmlNodeForDoc:node->doc elementName:@"Biography"]);
	}
	if(self.Excerpt != 0) {
		xmlAddChild(node, [self.Excerpt xmlNodeForDoc:node->doc elementName:@"Excerpt"]);
	}
	if(self.Flap != 0) {
		xmlAddChild(node, [self.Flap xmlNodeForDoc:node->doc elementName:@"Flap"]);
	}
	if(self.Inventory != 0) {
		xmlAddChild(node, [self.Inventory xmlNodeForDoc:node->doc elementName:@"Inventory"]);
	}
	if(self.Demand != 0) {
		xmlAddChild(node, [self.Demand xmlNodeForDoc:node->doc elementName:@"Demand"]);
	}
	if(self.DemandHistory != 0) {
		xmlAddChild(node, [self.DemandHistory xmlNodeForDoc:node->doc elementName:@"DemandHistory"]);
	}
	if(self.Jacket != 0) {
		xmlAddChild(node, [self.Jacket xmlNodeForDoc:node->doc elementName:@"Jacket"]);
	}
	if(self.Product != 0) {
		xmlAddChild(node, [self.Product xmlNodeForDoc:node->doc elementName:@"Product"]);
	}
	if(self.Review != 0) {
		xmlAddChild(node, [self.Review xmlNodeForDoc:node->doc elementName:@"Review"]);
	}
	if(self.TOC != 0) {
		xmlAddChild(node, [self.TOC xmlNodeForDoc:node->doc elementName:@"TOC"]);
	}
	if(self.ReviewPublicationItems != 0) {
		xmlAddChild(node, [self.ReviewPublicationItems xmlNodeForDoc:node->doc elementName:@"ReviewPublicationItems"]);
	}
	if(self.InventoryAvailabilityItems != 0) {
		xmlAddChild(node, [self.InventoryAvailabilityItems xmlNodeForDoc:node->doc elementName:@"InventoryAvailabilityItems"]);
	}
	if(self.MemberLinkItems != 0) {
		xmlAddChild(node, [self.MemberLinkItems xmlNodeForDoc:node->doc elementName:@"MemberLinkItems"]);
	}
	if(self.Search != 0) {
		xmlAddChild(node, [self.Search xmlNodeForDoc:node->doc elementName:@"Search"]);
	}
	if(self.MuzeVideoRelease != 0) {
		xmlAddChild(node, [self.MuzeVideoRelease xmlNodeForDoc:node->doc elementName:@"MuzeVideoRelease"]);
	}
	if(self.MuzeSimilarCinema != 0) {
		xmlAddChild(node, [self.MuzeSimilarCinema xmlNodeForDoc:node->doc elementName:@"MuzeSimilarCinema"]);
	}
	if(self.MuzePopularMusic != 0) {
		xmlAddChild(node, [self.MuzePopularMusic xmlNodeForDoc:node->doc elementName:@"MuzePopularMusic"]);
	}
	if(self.MuzeClassicalMusic != 0) {
		xmlAddChild(node, [self.MuzeClassicalMusic xmlNodeForDoc:node->doc elementName:@"MuzeClassicalMusic"]);
	}
	if(self.MuzeEssentialArtists != 0) {
		xmlAddChild(node, [self.MuzeEssentialArtists xmlNodeForDoc:node->doc elementName:@"MuzeEssentialArtists"]);
	}
	if(self.MuzeGames != 0) {
		xmlAddChild(node, [self.MuzeGames xmlNodeForDoc:node->doc elementName:@"MuzeGames"]);
	}
	if(self.MuzeJacket != 0) {
		xmlAddChild(node, [self.MuzeJacket xmlNodeForDoc:node->doc elementName:@"MuzeJacket"]);
	}
	if(self.MuzeTunes != 0) {
		xmlAddChild(node, [self.MuzeTunes xmlNodeForDoc:node->doc elementName:@"MuzeTunes"]);
	}
	if(self.MuzeReels != 0) {
		xmlAddChild(node, [self.MuzeReels xmlNodeForDoc:node->doc elementName:@"MuzeReels"]);
	}
	if(self.ReserveInventory != 0) {
		xmlAddChild(node, [self.ReserveInventory xmlNodeForDoc:node->doc elementName:@"ReserveInventory"]);
	}
}
/* elements */
@synthesize UserID;
@synthesize Password;
@synthesize Active;
@synthesize Admin;
@synthesize Annotation;
@synthesize Biography;
@synthesize Excerpt;
@synthesize Flap;
@synthesize Inventory;
@synthesize Demand;
@synthesize DemandHistory;
@synthesize Jacket;
@synthesize Product;
@synthesize Review;
@synthesize TOC;
@synthesize ReviewPublicationItems;
@synthesize InventoryAvailabilityItems;
@synthesize MemberLinkItems;
@synthesize Search;
@synthesize MuzeVideoRelease;
@synthesize MuzeSimilarCinema;
@synthesize MuzePopularMusic;
@synthesize MuzeClassicalMusic;
@synthesize MuzeEssentialArtists;
@synthesize MuzeGames;
@synthesize MuzeJacket;
@synthesize MuzeTunes;
@synthesize MuzeReels;
@synthesize ReserveInventory;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_MemberItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MemberItem *newObject = [[ContentCafe_MemberItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "UserID")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.UserID = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Password")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Password = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Active")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Active = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Admin")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Admin = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Annotation")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Annotation = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Biography")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Biography = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Excerpt")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Excerpt = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Flap")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Flap = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Inventory")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Inventory = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Demand")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Demand = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistory")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandHistory = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Jacket")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Jacket = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Product")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Product = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Review")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Review = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TOC")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.TOC = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewPublicationItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ReviewPublicationItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ReviewPublicationItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventoryAvailabilityItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventoryAvailabilityItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.InventoryAvailabilityItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MemberLinkItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MemberLinkItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MemberLinkItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Search")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Search = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeVideoRelease")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeVideoRelease = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeSimilarCinema")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeSimilarCinema = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzePopularMusic")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzePopularMusic = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeClassicalMusic")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeClassicalMusic = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeEssentialArtists")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeEssentialArtists = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeGames")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeGames = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeJacket")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeJacket = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeTunes")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeTunes = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeReels")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeReels = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReserveInventory")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ReserveInventory = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_MemberItems
- (id)init
{
	if((self = [super init])) {
		MemberItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(MemberItem != nil) [MemberItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MemberItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.MemberItem != 0) {
		for(ContentCafe_MemberItem * child in self.MemberItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"MemberItem"]);
		}
	}
}
/* elements */
@synthesize MemberItem;
- (void)addMemberItem:(ContentCafe_MemberItem *)toAdd
{
	if(toAdd != nil) [MemberItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_MemberItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MemberItems *newObject = [[ContentCafe_MemberItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MemberItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MemberItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.MemberItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_AvailableContent
- (id)init
{
	if((self = [super init])) {
		Annotation = 0;
		Biography = 0;
		Excerpt = 0;
		Flap = 0;
		Inventory = 0;
		Demand = 0;
		DemandHistory = 0;
		Jacket = 0;
		Product = 0;
		Review = 0;
		TOC = 0;
		MuzeVideoRelease = 0;
		MuzeSimilarCinema = 0;
		MuzePopularMusic = 0;
		MuzeClassicalMusic = 0;
		MuzeEssentialArtists = 0;
		MuzeGames = 0;
		MuzeJacket = 0;
		CPSIA_Warning = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Annotation != nil) [Annotation release];
	if(Biography != nil) [Biography release];
	if(Excerpt != nil) [Excerpt release];
	if(Flap != nil) [Flap release];
	if(Inventory != nil) [Inventory release];
	if(Demand != nil) [Demand release];
	if(DemandHistory != nil) [DemandHistory release];
	if(Jacket != nil) [Jacket release];
	if(Product != nil) [Product release];
	if(Review != nil) [Review release];
	if(TOC != nil) [TOC release];
	if(MuzeVideoRelease != nil) [MuzeVideoRelease release];
	if(MuzeSimilarCinema != nil) [MuzeSimilarCinema release];
	if(MuzePopularMusic != nil) [MuzePopularMusic release];
	if(MuzeClassicalMusic != nil) [MuzeClassicalMusic release];
	if(MuzeEssentialArtists != nil) [MuzeEssentialArtists release];
	if(MuzeGames != nil) [MuzeGames release];
	if(MuzeJacket != nil) [MuzeJacket release];
	if(CPSIA_Warning != nil) [CPSIA_Warning release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:AvailableContent");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Annotation != 0) {
		xmlAddChild(node, [self.Annotation xmlNodeForDoc:node->doc elementName:@"Annotation"]);
	}
	if(self.Biography != 0) {
		xmlAddChild(node, [self.Biography xmlNodeForDoc:node->doc elementName:@"Biography"]);
	}
	if(self.Excerpt != 0) {
		xmlAddChild(node, [self.Excerpt xmlNodeForDoc:node->doc elementName:@"Excerpt"]);
	}
	if(self.Flap != 0) {
		xmlAddChild(node, [self.Flap xmlNodeForDoc:node->doc elementName:@"Flap"]);
	}
	if(self.Inventory != 0) {
		xmlAddChild(node, [self.Inventory xmlNodeForDoc:node->doc elementName:@"Inventory"]);
	}
	if(self.Demand != 0) {
		xmlAddChild(node, [self.Demand xmlNodeForDoc:node->doc elementName:@"Demand"]);
	}
	if(self.DemandHistory != 0) {
		xmlAddChild(node, [self.DemandHistory xmlNodeForDoc:node->doc elementName:@"DemandHistory"]);
	}
	if(self.Jacket != 0) {
		xmlAddChild(node, [self.Jacket xmlNodeForDoc:node->doc elementName:@"Jacket"]);
	}
	if(self.Product != 0) {
		xmlAddChild(node, [self.Product xmlNodeForDoc:node->doc elementName:@"Product"]);
	}
	if(self.Review != 0) {
		xmlAddChild(node, [self.Review xmlNodeForDoc:node->doc elementName:@"Review"]);
	}
	if(self.TOC != 0) {
		xmlAddChild(node, [self.TOC xmlNodeForDoc:node->doc elementName:@"TOC"]);
	}
	if(self.MuzeVideoRelease != 0) {
		xmlAddChild(node, [self.MuzeVideoRelease xmlNodeForDoc:node->doc elementName:@"MuzeVideoRelease"]);
	}
	if(self.MuzeSimilarCinema != 0) {
		xmlAddChild(node, [self.MuzeSimilarCinema xmlNodeForDoc:node->doc elementName:@"MuzeSimilarCinema"]);
	}
	if(self.MuzePopularMusic != 0) {
		xmlAddChild(node, [self.MuzePopularMusic xmlNodeForDoc:node->doc elementName:@"MuzePopularMusic"]);
	}
	if(self.MuzeClassicalMusic != 0) {
		xmlAddChild(node, [self.MuzeClassicalMusic xmlNodeForDoc:node->doc elementName:@"MuzeClassicalMusic"]);
	}
	if(self.MuzeEssentialArtists != 0) {
		xmlAddChild(node, [self.MuzeEssentialArtists xmlNodeForDoc:node->doc elementName:@"MuzeEssentialArtists"]);
	}
	if(self.MuzeGames != 0) {
		xmlAddChild(node, [self.MuzeGames xmlNodeForDoc:node->doc elementName:@"MuzeGames"]);
	}
	if(self.MuzeJacket != 0) {
		xmlAddChild(node, [self.MuzeJacket xmlNodeForDoc:node->doc elementName:@"MuzeJacket"]);
	}
	if(self.CPSIA_Warning != 0) {
		xmlAddChild(node, [self.CPSIA_Warning xmlNodeForDoc:node->doc elementName:@"CPSIA_Warning"]);
	}
}
/* elements */
@synthesize Annotation;
@synthesize Biography;
@synthesize Excerpt;
@synthesize Flap;
@synthesize Inventory;
@synthesize Demand;
@synthesize DemandHistory;
@synthesize Jacket;
@synthesize Product;
@synthesize Review;
@synthesize TOC;
@synthesize MuzeVideoRelease;
@synthesize MuzeSimilarCinema;
@synthesize MuzePopularMusic;
@synthesize MuzeClassicalMusic;
@synthesize MuzeEssentialArtists;
@synthesize MuzeGames;
@synthesize MuzeJacket;
@synthesize CPSIA_Warning;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_AvailableContent *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_AvailableContent *newObject = [[ContentCafe_AvailableContent new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Annotation")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Annotation = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Biography")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Biography = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Excerpt")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Excerpt = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Flap")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Flap = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Inventory")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Inventory = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Demand")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Demand = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistory")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandHistory = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Jacket")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Jacket = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Product")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Product = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Review")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Review = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TOC")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.TOC = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeVideoRelease")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeVideoRelease = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeSimilarCinema")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeSimilarCinema = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzePopularMusic")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzePopularMusic = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeClassicalMusic")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeClassicalMusic = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeEssentialArtists")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeEssentialArtists = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeGames")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeGames = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeJacket")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeJacket = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "CPSIA_Warning")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [USBoolean  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.CPSIA_Warning = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_AnnotationSummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:AnnotationSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_AnnotationSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_AnnotationSummaryItem *newObject = [[ContentCafe_AnnotationSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_AnnotationSummaryItems
- (id)init
{
	if((self = [super init])) {
		AnnotationSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(AnnotationSummaryItem != nil) [AnnotationSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:AnnotationSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.AnnotationSummaryItem != 0) {
		for(ContentCafe_AnnotationSummaryItem * child in self.AnnotationSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"AnnotationSummaryItem"]);
		}
	}
}
/* elements */
@synthesize AnnotationSummaryItem;
- (void)addAnnotationSummaryItem:(ContentCafe_AnnotationSummaryItem *)toAdd
{
	if(toAdd != nil) [AnnotationSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_AnnotationSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_AnnotationSummaryItems *newObject = [[ContentCafe_AnnotationSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "AnnotationSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_AnnotationSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.AnnotationSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_AnnotationItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Annotation = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Annotation != nil) [Annotation release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:AnnotationItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Annotation != 0) {
		xmlAddChild(node, [self.Annotation xmlNodeForDoc:node->doc elementName:@"Annotation"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Annotation;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_AnnotationItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_AnnotationItem *newObject = [[ContentCafe_AnnotationItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Annotation")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Annotation = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_AnnotationItems
- (id)init
{
	if((self = [super init])) {
		AnnotationItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(AnnotationItem != nil) [AnnotationItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:AnnotationItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.AnnotationItem != 0) {
		for(ContentCafe_AnnotationItem * child in self.AnnotationItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"AnnotationItem"]);
		}
	}
}
/* elements */
@synthesize AnnotationItem;
- (void)addAnnotationItem:(ContentCafe_AnnotationItem *)toAdd
{
	if(toAdd != nil) [AnnotationItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_AnnotationItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_AnnotationItems *newObject = [[ContentCafe_AnnotationItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "AnnotationItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_AnnotationItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.AnnotationItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ReviewSummaryItem
- (id)init
{
	if((self = [super init])) {
		Publication = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Publication != nil) [Publication release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ReviewSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Publication != 0) {
		xmlAddChild(node, [self.Publication xmlNodeForDoc:node->doc elementName:@"Publication"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Publication;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ReviewSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ReviewSummaryItem *newObject = [[ContentCafe_ReviewSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Publication")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Publication = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ReviewSummaryItems
- (id)init
{
	if((self = [super init])) {
		ReviewSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(ReviewSummaryItem != nil) [ReviewSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ReviewSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ReviewSummaryItem != 0) {
		for(ContentCafe_ReviewSummaryItem * child in self.ReviewSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ReviewSummaryItem"]);
		}
	}
}
/* elements */
@synthesize ReviewSummaryItem;
- (void)addReviewSummaryItem:(ContentCafe_ReviewSummaryItem *)toAdd
{
	if(toAdd != nil) [ReviewSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_ReviewSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ReviewSummaryItems *newObject = [[ContentCafe_ReviewSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ReviewSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ReviewSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ReviewItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Publication = 0;
		Issue = 0;
		Review = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Publication != nil) [Publication release];
	if(Issue != nil) [Issue release];
	if(Review != nil) [Review release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ReviewItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Publication != 0) {
		xmlAddChild(node, [self.Publication xmlNodeForDoc:node->doc elementName:@"Publication"]);
	}
	if(self.Issue != 0) {
		xmlAddChild(node, [self.Issue xmlNodeForDoc:node->doc elementName:@"Issue"]);
	}
	if(self.Review != 0) {
		xmlAddChild(node, [self.Review xmlNodeForDoc:node->doc elementName:@"Review"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Publication;
@synthesize Issue;
@synthesize Review;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_ReviewItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ReviewItem *newObject = [[ContentCafe_ReviewItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Publication")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Publication = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Issue")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Issue = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Review")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Review = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ReviewItems
- (id)init
{
	if((self = [super init])) {
		ReviewItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(ReviewItem != nil) [ReviewItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ReviewItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ReviewItem != 0) {
		for(ContentCafe_ReviewItem * child in self.ReviewItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ReviewItem"]);
		}
	}
}
/* elements */
@synthesize ReviewItem;
- (void)addReviewItem:(ContentCafe_ReviewItem *)toAdd
{
	if(toAdd != nil) [ReviewItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ReviewItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ReviewItems *newObject = [[ContentCafe_ReviewItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ReviewItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ReviewItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_BiographySummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:BiographySummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_BiographySummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_BiographySummaryItem *newObject = [[ContentCafe_BiographySummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_BiographySummaryItems
- (id)init
{
	if((self = [super init])) {
		BiographySummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(BiographySummaryItem != nil) [BiographySummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:BiographySummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.BiographySummaryItem != 0) {
		for(ContentCafe_BiographySummaryItem * child in self.BiographySummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"BiographySummaryItem"]);
		}
	}
}
/* elements */
@synthesize BiographySummaryItem;
- (void)addBiographySummaryItem:(ContentCafe_BiographySummaryItem *)toAdd
{
	if(toAdd != nil) [BiographySummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_BiographySummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_BiographySummaryItems *newObject = [[ContentCafe_BiographySummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "BiographySummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_BiographySummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.BiographySummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_BiographyItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Biography = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Biography != nil) [Biography release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:BiographyItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Biography != 0) {
		xmlAddChild(node, [self.Biography xmlNodeForDoc:node->doc elementName:@"Biography"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Biography;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_BiographyItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_BiographyItem *newObject = [[ContentCafe_BiographyItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Biography")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Biography = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_BiographyItems
- (id)init
{
	if((self = [super init])) {
		BiographyItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(BiographyItem != nil) [BiographyItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:BiographyItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.BiographyItem != 0) {
		for(ContentCafe_BiographyItem * child in self.BiographyItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"BiographyItem"]);
		}
	}
}
/* elements */
@synthesize BiographyItem;
- (void)addBiographyItem:(ContentCafe_BiographyItem *)toAdd
{
	if(toAdd != nil) [BiographyItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_BiographyItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_BiographyItems *newObject = [[ContentCafe_BiographyItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "BiographyItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_BiographyItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.BiographyItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_FlapSummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:FlapSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_FlapSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_FlapSummaryItem *newObject = [[ContentCafe_FlapSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_FlapSummaryItems
- (id)init
{
	if((self = [super init])) {
		FlapSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(FlapSummaryItem != nil) [FlapSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:FlapSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.FlapSummaryItem != 0) {
		for(ContentCafe_FlapSummaryItem * child in self.FlapSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"FlapSummaryItem"]);
		}
	}
}
/* elements */
@synthesize FlapSummaryItem;
- (void)addFlapSummaryItem:(ContentCafe_FlapSummaryItem *)toAdd
{
	if(toAdd != nil) [FlapSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_FlapSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_FlapSummaryItems *newObject = [[ContentCafe_FlapSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "FlapSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_FlapSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.FlapSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_FlapItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Flap = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Flap != nil) [Flap release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:FlapItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Flap != 0) {
		xmlAddChild(node, [self.Flap xmlNodeForDoc:node->doc elementName:@"Flap"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Flap;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_FlapItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_FlapItem *newObject = [[ContentCafe_FlapItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Flap")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Flap = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_FlapItems
- (id)init
{
	if((self = [super init])) {
		FlapItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(FlapItem != nil) [FlapItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:FlapItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.FlapItem != 0) {
		for(ContentCafe_FlapItem * child in self.FlapItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"FlapItem"]);
		}
	}
}
/* elements */
@synthesize FlapItem;
- (void)addFlapItem:(ContentCafe_FlapItem *)toAdd
{
	if(toAdd != nil) [FlapItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_FlapItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_FlapItems *newObject = [[ContentCafe_FlapItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "FlapItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_FlapItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.FlapItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_InventorySummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventorySummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_InventorySummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventorySummaryItem *newObject = [[ContentCafe_InventorySummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_InventorySummaryItems
- (id)init
{
	if((self = [super init])) {
		InventorySummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(InventorySummaryItem != nil) [InventorySummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventorySummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.InventorySummaryItem != 0) {
		for(ContentCafe_InventorySummaryItem * child in self.InventorySummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"InventorySummaryItem"]);
		}
	}
}
/* elements */
@synthesize InventorySummaryItem;
- (void)addInventorySummaryItem:(ContentCafe_InventorySummaryItem *)toAdd
{
	if(toAdd != nil) [InventorySummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_InventorySummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventorySummaryItems *newObject = [[ContentCafe_InventorySummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventorySummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventorySummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.InventorySummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_InventoryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
		OnHand = 0;
		OnOrder = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(OnHand != nil) [OnHand release];
	if(OnOrder != nil) [OnOrder release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventoryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.OnHand != 0) {
		xmlAddChild(node, [self.OnHand xmlNodeForDoc:node->doc elementName:@"OnHand"]);
	}
	if(self.OnOrder != 0) {
		xmlAddChild(node, [self.OnOrder xmlNodeForDoc:node->doc elementName:@"OnOrder"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
@synthesize OnHand;
@synthesize OnOrder;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_InventoryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventoryItem *newObject = [[ContentCafe_InventoryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "OnHand")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.OnHand = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "OnOrder")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.OnOrder = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_InventoryItems
- (id)init
{
	if((self = [super init])) {
		InventoryItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(InventoryItem != nil) [InventoryItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:InventoryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.InventoryItem != 0) {
		for(ContentCafe_InventoryItem * child in self.InventoryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"InventoryItem"]);
		}
	}
}
/* elements */
@synthesize InventoryItem;
- (void)addInventoryItem:(ContentCafe_InventoryItem *)toAdd
{
	if(toAdd != nil) [InventoryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_InventoryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_InventoryItems *newObject = [[ContentCafe_InventoryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventoryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventoryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.InventoryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_DemandSummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_DemandSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandSummaryItem *newObject = [[ContentCafe_DemandSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_DemandSummaryItems
- (id)init
{
	if((self = [super init])) {
		DemandSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(DemandSummaryItem != nil) [DemandSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.DemandSummaryItem != 0) {
		for(ContentCafe_DemandSummaryItem * child in self.DemandSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"DemandSummaryItem"]);
		}
	}
}
/* elements */
@synthesize DemandSummaryItem;
- (void)addDemandSummaryItem:(ContentCafe_DemandSummaryItem *)toAdd
{
	if(toAdd != nil) [DemandSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_DemandSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandSummaryItems *newObject = [[ContentCafe_DemandSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.DemandSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_DemandItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
		Demand = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(Demand != nil) [Demand release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.Demand != 0) {
		xmlAddChild(node, [self.Demand xmlNodeForDoc:node->doc elementName:@"Demand"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
@synthesize Demand;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_DemandItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandItem *newObject = [[ContentCafe_DemandItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Demand")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Demand = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_DemandItems
- (id)init
{
	if((self = [super init])) {
		DemandItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(DemandItem != nil) [DemandItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.DemandItem != 0) {
		for(ContentCafe_DemandItem * child in self.DemandItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"DemandItem"]);
		}
	}
}
/* elements */
@synthesize DemandItem;
- (void)addDemandItem:(ContentCafe_DemandItem *)toAdd
{
	if(toAdd != nil) [DemandItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_DemandItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandItems *newObject = [[ContentCafe_DemandItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.DemandItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_DemandHistorySummaryItem
- (id)init
{
	if((self = [super init])) {
		Supplier = 0;
		Warehouse = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandHistorySummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Supplier;
@synthesize Warehouse;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_DemandHistorySummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandHistorySummaryItem *newObject = [[ContentCafe_DemandHistorySummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_DemandHistorySummaryItems
- (id)init
{
	if((self = [super init])) {
		DemandHistorySummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(DemandHistorySummaryItem != nil) [DemandHistorySummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandHistorySummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.DemandHistorySummaryItem != 0) {
		for(ContentCafe_DemandHistorySummaryItem * child in self.DemandHistorySummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"DemandHistorySummaryItem"]);
		}
	}
}
/* elements */
@synthesize DemandHistorySummaryItem;
- (void)addDemandHistorySummaryItem:(ContentCafe_DemandHistorySummaryItem *)toAdd
{
	if(toAdd != nil) [DemandHistorySummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_DemandHistorySummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandHistorySummaryItems *newObject = [[ContentCafe_DemandHistorySummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistorySummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandHistorySummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.DemandHistorySummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_DemandHistoryItem
- (id)init
{
	if((self = [super init])) {
		Year = 0;
		Month = 0;
		Supplier = 0;
		Warehouse = 0;
		Demand = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Year != nil) [Year release];
	if(Month != nil) [Month release];
	if(Supplier != nil) [Supplier release];
	if(Warehouse != nil) [Warehouse release];
	if(Demand != nil) [Demand release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandHistoryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Year != 0) {
		xmlAddChild(node, [self.Year xmlNodeForDoc:node->doc elementName:@"Year"]);
	}
	if(self.Month != 0) {
		xmlAddChild(node, [self.Month xmlNodeForDoc:node->doc elementName:@"Month"]);
	}
	if(self.Supplier != 0) {
		xmlAddChild(node, [self.Supplier xmlNodeForDoc:node->doc elementName:@"Supplier"]);
	}
	if(self.Warehouse != 0) {
		xmlAddChild(node, [self.Warehouse xmlNodeForDoc:node->doc elementName:@"Warehouse"]);
	}
	if(self.Demand != 0) {
		xmlAddChild(node, [self.Demand xmlNodeForDoc:node->doc elementName:@"Demand"]);
	}
}
/* elements */
@synthesize Year;
@synthesize Month;
@synthesize Supplier;
@synthesize Warehouse;
@synthesize Demand;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_DemandHistoryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandHistoryItem *newObject = [[ContentCafe_DemandHistoryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Year")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Year = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Month")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Month = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Supplier")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Supplier = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Warehouse")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Warehouse = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Demand")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Demand = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_DemandHistoryItems
- (id)init
{
	if((self = [super init])) {
		DemandHistoryItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(DemandHistoryItem != nil) [DemandHistoryItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:DemandHistoryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.DemandHistoryItem != 0) {
		for(ContentCafe_DemandHistoryItem * child in self.DemandHistoryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"DemandHistoryItem"]);
		}
	}
}
/* elements */
@synthesize DemandHistoryItem;
- (void)addDemandHistoryItem:(ContentCafe_DemandHistoryItem *)toAdd
{
	if(toAdd != nil) [DemandHistoryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_DemandHistoryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_DemandHistoryItems *newObject = [[ContentCafe_DemandHistoryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistoryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandHistoryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.DemandHistoryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_JacketSummaryItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:JacketSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_JacketSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_JacketSummaryItem *newObject = [[ContentCafe_JacketSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_JacketSummaryItems
- (id)init
{
	if((self = [super init])) {
		JacketSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(JacketSummaryItem != nil) [JacketSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:JacketSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.JacketSummaryItem != 0) {
		for(ContentCafe_JacketSummaryItem * child in self.JacketSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"JacketSummaryItem"]);
		}
	}
}
/* elements */
@synthesize JacketSummaryItem;
- (void)addJacketSummaryItem:(ContentCafe_JacketSummaryItem *)toAdd
{
	if(toAdd != nil) [JacketSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_JacketSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_JacketSummaryItems *newObject = [[ContentCafe_JacketSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "JacketSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_JacketSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.JacketSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_JacketElement
- (id)init
{
	if((self = [super init])) {
		Encoding = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Encoding != nil) [Encoding release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:JacketElement");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.Encoding != 0) {
		xmlSetProp(node, (const xmlChar*)"Encoding", (const xmlChar*)[[self.Encoding description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.Encoding forKey:@"Encoding"];
	
	return attributes;
}
@synthesize Encoding;
+ (ContentCafe_JacketElement *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_JacketElement *newObject = [[ContentCafe_JacketElement new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "Encoding");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Encoding = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_JacketItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Width = 0;
		Height = 0;
		Format = 0;
		Jacket = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Width != nil) [Width release];
	if(Height != nil) [Height release];
	if(Format != nil) [Format release];
	if(Jacket != nil) [Jacket release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:JacketItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Width != 0) {
		xmlAddChild(node, [self.Width xmlNodeForDoc:node->doc elementName:@"Width"]);
	}
	if(self.Height != 0) {
		xmlAddChild(node, [self.Height xmlNodeForDoc:node->doc elementName:@"Height"]);
	}
	if(self.Format != 0) {
		xmlAddChild(node, [self.Format xmlNodeForDoc:node->doc elementName:@"Format"]);
	}
	if(self.Jacket != 0) {
		xmlAddChild(node, [self.Jacket xmlNodeForDoc:node->doc elementName:@"Jacket"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Width;
@synthesize Height;
@synthesize Format;
@synthesize Jacket;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_JacketItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_JacketItem *newObject = [[ContentCafe_JacketItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Width")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Width = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Height")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Height = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Format")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Format = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Jacket")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_JacketElement class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Jacket = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_JacketItems
- (id)init
{
	if((self = [super init])) {
		JacketItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(JacketItem != nil) [JacketItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:JacketItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.JacketItem != 0) {
		for(ContentCafe_JacketItem * child in self.JacketItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"JacketItem"]);
		}
	}
}
/* elements */
@synthesize JacketItem;
- (void)addJacketItem:(ContentCafe_JacketItem *)toAdd
{
	if(toAdd != nil) [JacketItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_JacketItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_JacketItems *newObject = [[ContentCafe_JacketItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "JacketItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_JacketItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.JacketItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_TocSummaryItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:TocSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_TocSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_TocSummaryItem *newObject = [[ContentCafe_TocSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_TocSummaryItems
- (id)init
{
	if((self = [super init])) {
		TocSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(TocSummaryItem != nil) [TocSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:TocSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.TocSummaryItem != 0) {
		for(ContentCafe_TocSummaryItem * child in self.TocSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"TocSummaryItem"]);
		}
	}
}
/* elements */
@synthesize TocSummaryItem;
- (void)addTocSummaryItem:(ContentCafe_TocSummaryItem *)toAdd
{
	if(toAdd != nil) [TocSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_TocSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_TocSummaryItems *newObject = [[ContentCafe_TocSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TocSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_TocSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.TocSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_TocItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Toc = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Toc != nil) [Toc release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:TocItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Toc != 0) {
		xmlAddChild(node, [self.Toc xmlNodeForDoc:node->doc elementName:@"Toc"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Toc;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_TocItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_TocItem *newObject = [[ContentCafe_TocItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Toc")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Toc = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_TocItems
- (id)init
{
	if((self = [super init])) {
		TocItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(TocItem != nil) [TocItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:TocItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.TocItem != 0) {
		for(ContentCafe_TocItem * child in self.TocItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"TocItem"]);
		}
	}
}
/* elements */
@synthesize TocItem;
- (void)addTocItem:(ContentCafe_TocItem *)toAdd
{
	if(toAdd != nil) [TocItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_TocItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_TocItems *newObject = [[ContentCafe_TocItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TocItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_TocItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.TocItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ExcerptSummaryItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ExcerptSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ExcerptSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ExcerptSummaryItem *newObject = [[ContentCafe_ExcerptSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ExcerptSummaryItems
- (id)init
{
	if((self = [super init])) {
		ExcerptSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(ExcerptSummaryItem != nil) [ExcerptSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ExcerptSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ExcerptSummaryItem != 0) {
		for(ContentCafe_ExcerptSummaryItem * child in self.ExcerptSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ExcerptSummaryItem"]);
		}
	}
}
/* elements */
@synthesize ExcerptSummaryItem;
- (void)addExcerptSummaryItem:(ContentCafe_ExcerptSummaryItem *)toAdd
{
	if(toAdd != nil) [ExcerptSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_ExcerptSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ExcerptSummaryItems *newObject = [[ContentCafe_ExcerptSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ExcerptSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ExcerptSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ExcerptSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ExcerptItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Excerpt = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Excerpt != nil) [Excerpt release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ExcerptItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Excerpt != 0) {
		xmlAddChild(node, [self.Excerpt xmlNodeForDoc:node->doc elementName:@"Excerpt"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Excerpt;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_ExcerptItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ExcerptItem *newObject = [[ContentCafe_ExcerptItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Excerpt")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Excerpt = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ExcerptItems
- (id)init
{
	if((self = [super init])) {
		ExcerptItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(ExcerptItem != nil) [ExcerptItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ExcerptItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ExcerptItem != 0) {
		for(ContentCafe_ExcerptItem * child in self.ExcerptItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ExcerptItem"]);
		}
	}
}
/* elements */
@synthesize ExcerptItem;
- (void)addExcerptItem:(ContentCafe_ExcerptItem *)toAdd
{
	if(toAdd != nil) [ExcerptItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ExcerptItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ExcerptItems *newObject = [[ContentCafe_ExcerptItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ExcerptItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ExcerptItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ExcerptItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ProductSummaryItem
- (id)init
{
	if((self = [super init])) {
		Source = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Source != nil) [Source release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ProductSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Source != 0) {
		xmlAddChild(node, [self.Source xmlNodeForDoc:node->doc elementName:@"Source"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Source;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ProductSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ProductSummaryItem *newObject = [[ContentCafe_ProductSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Source")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Source = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_ProductSummaryItems
- (id)init
{
	if((self = [super init])) {
		ProductSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(ProductSummaryItem != nil) [ProductSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ProductSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ProductSummaryItem != 0) {
		for(ContentCafe_ProductSummaryItem * child in self.ProductSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ProductSummaryItem"]);
		}
	}
}
/* elements */
@synthesize ProductSummaryItem;
- (void)addProductSummaryItem:(ContentCafe_ProductSummaryItem *)toAdd
{
	if(toAdd != nil) [ProductSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_ProductSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ProductSummaryItems *newObject = [[ContentCafe_ProductSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ProductSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ProductSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ProductSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ProductItems
- (id)init
{
	if((self = [super init])) {
		ProductItem = [[NSMutableArray alloc] init];
	}
	
	return self;
}
- (void)dealloc
{
	if(ProductItem != nil) [ProductItem release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ProductItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ProductItem != 0) {
		for(ContentCafe_ProductItem * child in self.ProductItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"ProductItem"]);
		}
	}
}
/* elements */
@synthesize ProductItem;
- (void)addProductItem:(ContentCafe_ProductItem *)toAdd
{
	if(toAdd != nil) [ProductItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_ProductItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ProductItems *newObject = [[ContentCafe_ProductItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ProductItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ProductItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.ProductItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_MuzeSummaryItem
- (id)init
{
	if((self = [super init])) {
		Type = 0;
		Records = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Type != nil) [Type release];
	if(Records != nil) [Records release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MuzeSummaryItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Type != 0) {
		xmlAddChild(node, [self.Type xmlNodeForDoc:node->doc elementName:@"Type"]);
	}
	if(self.Records != 0) {
		xmlAddChild(node, [self.Records xmlNodeForDoc:node->doc elementName:@"Records"]);
	}
}
/* elements */
@synthesize Type;
@synthesize Records;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_MuzeSummaryItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MuzeSummaryItem *newObject = [[ContentCafe_MuzeSummaryItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Type")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_CodeLiteral class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Type = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Records")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSNumber  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Records = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_MuzeSummaryItems
- (id)init
{
	if((self = [super init])) {
		MuzeSummaryItem = [[NSMutableArray alloc] init];
		TotalRecords = 0;
		UniqueRecords = 0;
		LastUpdated = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(MuzeSummaryItem != nil) [MuzeSummaryItem release];
	if(TotalRecords != nil) [TotalRecords release];
	if(UniqueRecords != nil) [UniqueRecords release];
	if(LastUpdated != nil) [LastUpdated release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:MuzeSummaryItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.TotalRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"TotalRecords", (const xmlChar*)[[self.TotalRecords description] UTF8String]);
	}
	if(self.UniqueRecords != 0) {
		xmlSetProp(node, (const xmlChar*)"UniqueRecords", (const xmlChar*)[[self.UniqueRecords description] UTF8String]);
	}
	if(self.LastUpdated != 0) {
		xmlSetProp(node, (const xmlChar*)"LastUpdated", (const xmlChar*)[[self.LastUpdated description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.MuzeSummaryItem != 0) {
		for(ContentCafe_MuzeSummaryItem * child in self.MuzeSummaryItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"MuzeSummaryItem"]);
		}
	}
}
/* elements */
@synthesize MuzeSummaryItem;
- (void)addMuzeSummaryItem:(ContentCafe_MuzeSummaryItem *)toAdd
{
	if(toAdd != nil) [MuzeSummaryItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.TotalRecords forKey:@"TotalRecords"];
	[attributes setObject:self.UniqueRecords forKey:@"UniqueRecords"];
	[attributes setObject:self.LastUpdated forKey:@"LastUpdated"];
	
	return attributes;
}
@synthesize TotalRecords;
@synthesize UniqueRecords;
@synthesize LastUpdated;
+ (ContentCafe_MuzeSummaryItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_MuzeSummaryItems *newObject = [[ContentCafe_MuzeSummaryItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "TotalRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.TotalRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "UniqueRecords");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UniqueRecords = [NSNumber numberWithInt:[attrString intValue]];
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "LastUpdated");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.LastUpdated = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeSummaryItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MuzeSummaryItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.MuzeSummaryItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_Muze
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Muze");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Muze *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Muze *newObject = [[ContentCafe_Muze new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_RequestItem
- (id)init
{
	if((self = [super init])) {
		Key = 0;
		Content = [[NSMutableArray alloc] init];
		Environment = 0;
		MemberItem = 0;
		MemberItems = 0;
		AvailableContent = 0;
		AnnotationSummaryItems = 0;
		AnnotationItems = 0;
		ReviewSummaryItems = 0;
		ReviewItems = 0;
		BiographySummaryItems = 0;
		BiographyItems = 0;
		FlapSummaryItems = 0;
		FlapItems = 0;
		InventorySummaryItems = 0;
		InventoryItems = 0;
		DemandSummaryItems = 0;
		DemandItems = 0;
		DemandHistorySummaryItems = 0;
		DemandHistoryItems = 0;
		JacketSummaryItems = 0;
		JacketItems = 0;
		TocSummaryItems = 0;
		TocItems = 0;
		ExcerptSummaryItems = 0;
		ExcerptItems = 0;
		ProductSummaryItems = 0;
		ProductItems = 0;
		MuzeSummaryItems = 0;
		Muze = 0;
		ID_ = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Key != nil) [Key release];
	if(Content != nil) [Content release];
	if(Environment != nil) [Environment release];
	if(MemberItem != nil) [MemberItem release];
	if(MemberItems != nil) [MemberItems release];
	if(AvailableContent != nil) [AvailableContent release];
	if(AnnotationSummaryItems != nil) [AnnotationSummaryItems release];
	if(AnnotationItems != nil) [AnnotationItems release];
	if(ReviewSummaryItems != nil) [ReviewSummaryItems release];
	if(ReviewItems != nil) [ReviewItems release];
	if(BiographySummaryItems != nil) [BiographySummaryItems release];
	if(BiographyItems != nil) [BiographyItems release];
	if(FlapSummaryItems != nil) [FlapSummaryItems release];
	if(FlapItems != nil) [FlapItems release];
	if(InventorySummaryItems != nil) [InventorySummaryItems release];
	if(InventoryItems != nil) [InventoryItems release];
	if(DemandSummaryItems != nil) [DemandSummaryItems release];
	if(DemandItems != nil) [DemandItems release];
	if(DemandHistorySummaryItems != nil) [DemandHistorySummaryItems release];
	if(DemandHistoryItems != nil) [DemandHistoryItems release];
	if(JacketSummaryItems != nil) [JacketSummaryItems release];
	if(JacketItems != nil) [JacketItems release];
	if(TocSummaryItems != nil) [TocSummaryItems release];
	if(TocItems != nil) [TocItems release];
	if(ExcerptSummaryItems != nil) [ExcerptSummaryItems release];
	if(ExcerptItems != nil) [ExcerptItems release];
	if(ProductSummaryItems != nil) [ProductSummaryItems release];
	if(ProductItems != nil) [ProductItems release];
	if(MuzeSummaryItems != nil) [MuzeSummaryItems release];
	if(Muze != nil) [Muze release];
	if(ID_ != nil) [ID_ release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
//	xmlNodePtr root = xmlDocGetRootElement(doc);
	
//	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
//	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:RequestItem");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.ID_ != 0) {
		xmlSetProp(node, (const xmlChar*)"ID", (const xmlChar*)[[self.ID_ description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Key != 0) {
		xmlAddChild(node, [self.Key xmlNodeForDoc:node->doc elementName:@"Key"]);
	}
	if(self.Content != 0) {
		for(ContentCafe_Content * child in self.Content) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"Content"]);
		}
	}
	if(self.Environment != 0) {
		xmlAddChild(node, [self.Environment xmlNodeForDoc:node->doc elementName:@"Environment"]);
	}
	if(self.MemberItem != 0) {
		xmlAddChild(node, [self.MemberItem xmlNodeForDoc:node->doc elementName:@"MemberItem"]);
	}
	if(self.MemberItems != 0) {
		xmlAddChild(node, [self.MemberItems xmlNodeForDoc:node->doc elementName:@"MemberItems"]);
	}
	if(self.AvailableContent != 0) {
		xmlAddChild(node, [self.AvailableContent xmlNodeForDoc:node->doc elementName:@"AvailableContent"]);
	}
	if(self.AnnotationSummaryItems != 0) {
		xmlAddChild(node, [self.AnnotationSummaryItems xmlNodeForDoc:node->doc elementName:@"AnnotationSummaryItems"]);
	}
	if(self.AnnotationItems != 0) {
		xmlAddChild(node, [self.AnnotationItems xmlNodeForDoc:node->doc elementName:@"AnnotationItems"]);
	}
	if(self.ReviewSummaryItems != 0) {
		xmlAddChild(node, [self.ReviewSummaryItems xmlNodeForDoc:node->doc elementName:@"ReviewSummaryItems"]);
	}
	if(self.ReviewItems != 0) {
		xmlAddChild(node, [self.ReviewItems xmlNodeForDoc:node->doc elementName:@"ReviewItems"]);
	}
	if(self.BiographySummaryItems != 0) {
		xmlAddChild(node, [self.BiographySummaryItems xmlNodeForDoc:node->doc elementName:@"BiographySummaryItems"]);
	}
	if(self.BiographyItems != 0) {
		xmlAddChild(node, [self.BiographyItems xmlNodeForDoc:node->doc elementName:@"BiographyItems"]);
	}
	if(self.FlapSummaryItems != 0) {
		xmlAddChild(node, [self.FlapSummaryItems xmlNodeForDoc:node->doc elementName:@"FlapSummaryItems"]);
	}
	if(self.FlapItems != 0) {
		xmlAddChild(node, [self.FlapItems xmlNodeForDoc:node->doc elementName:@"FlapItems"]);
	}
	if(self.InventorySummaryItems != 0) {
		xmlAddChild(node, [self.InventorySummaryItems xmlNodeForDoc:node->doc elementName:@"InventorySummaryItems"]);
	}
	if(self.InventoryItems != 0) {
		xmlAddChild(node, [self.InventoryItems xmlNodeForDoc:node->doc elementName:@"InventoryItems"]);
	}
	if(self.DemandSummaryItems != 0) {
		xmlAddChild(node, [self.DemandSummaryItems xmlNodeForDoc:node->doc elementName:@"DemandSummaryItems"]);
	}
	if(self.DemandItems != 0) {
		xmlAddChild(node, [self.DemandItems xmlNodeForDoc:node->doc elementName:@"DemandItems"]);
	}
	if(self.DemandHistorySummaryItems != 0) {
		xmlAddChild(node, [self.DemandHistorySummaryItems xmlNodeForDoc:node->doc elementName:@"DemandHistorySummaryItems"]);
	}
	if(self.DemandHistoryItems != 0) {
		xmlAddChild(node, [self.DemandHistoryItems xmlNodeForDoc:node->doc elementName:@"DemandHistoryItems"]);
	}
	if(self.JacketSummaryItems != 0) {
		xmlAddChild(node, [self.JacketSummaryItems xmlNodeForDoc:node->doc elementName:@"JacketSummaryItems"]);
	}
	if(self.JacketItems != 0) {
		xmlAddChild(node, [self.JacketItems xmlNodeForDoc:node->doc elementName:@"JacketItems"]);
	}
	if(self.TocSummaryItems != 0) {
		xmlAddChild(node, [self.TocSummaryItems xmlNodeForDoc:node->doc elementName:@"TocSummaryItems"]);
	}
	if(self.TocItems != 0) {
		xmlAddChild(node, [self.TocItems xmlNodeForDoc:node->doc elementName:@"TocItems"]);
	}
	if(self.ExcerptSummaryItems != 0) {
		xmlAddChild(node, [self.ExcerptSummaryItems xmlNodeForDoc:node->doc elementName:@"ExcerptSummaryItems"]);
	}
	if(self.ExcerptItems != 0) {
		xmlAddChild(node, [self.ExcerptItems xmlNodeForDoc:node->doc elementName:@"ExcerptItems"]);
	}
	if(self.ProductSummaryItems != 0) {
		xmlAddChild(node, [self.ProductSummaryItems xmlNodeForDoc:node->doc elementName:@"ProductSummaryItems"]);
	}
	if(self.ProductItems != 0) {
		xmlAddChild(node, [self.ProductItems xmlNodeForDoc:node->doc elementName:@"ProductItems"]);
	}
	if(self.MuzeSummaryItems != 0) {
		xmlAddChild(node, [self.MuzeSummaryItems xmlNodeForDoc:node->doc elementName:@"MuzeSummaryItems"]);
	}
	if(self.Muze != 0) {
		xmlAddChild(node, [self.Muze xmlNodeForDoc:node->doc elementName:@"Muze"]);
	}
}
/* elements */
@synthesize Key;
@synthesize Content;
- (void)addContent:(ContentCafe_Content *)toAdd
{
	if(toAdd != nil) [Content addObject:toAdd];
}
@synthesize Environment;
@synthesize MemberItem;
@synthesize MemberItems;
@synthesize AvailableContent;
@synthesize AnnotationSummaryItems;
@synthesize AnnotationItems;
@synthesize ReviewSummaryItems;
@synthesize ReviewItems;
@synthesize BiographySummaryItems;
@synthesize BiographyItems;
@synthesize FlapSummaryItems;
@synthesize FlapItems;
@synthesize InventorySummaryItems;
@synthesize InventoryItems;
@synthesize DemandSummaryItems;
@synthesize DemandItems;
@synthesize DemandHistorySummaryItems;
@synthesize DemandHistoryItems;
@synthesize JacketSummaryItems;
@synthesize JacketItems;
@synthesize TocSummaryItems;
@synthesize TocItems;
@synthesize ExcerptSummaryItems;
@synthesize ExcerptItems;
@synthesize ProductSummaryItems;
@synthesize ProductItems;
@synthesize MuzeSummaryItems;
@synthesize Muze;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.ID_ forKey:@"ID"];
	
	return attributes;
}
@synthesize ID_;
+ (ContentCafe_RequestItem *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_RequestItem *newObject = [[ContentCafe_RequestItem new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "ID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.ID_ = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Key")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Key class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Key = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Content")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Content class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.Content addObject:newChild];
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Environment")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Environment class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Environment = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MemberItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MemberItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MemberItem = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MemberItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MemberItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MemberItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "AvailableContent")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_AvailableContent class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.AvailableContent = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "AnnotationSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_AnnotationSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.AnnotationSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "AnnotationItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_AnnotationItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.AnnotationItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ReviewSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ReviewSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ReviewItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ReviewItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ReviewItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "BiographySummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_BiographySummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.BiographySummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "BiographyItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_BiographyItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.BiographyItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "FlapSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_FlapSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.FlapSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "FlapItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_FlapItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.FlapItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventorySummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventorySummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.InventorySummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "InventoryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_InventoryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.InventoryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistorySummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandHistorySummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandHistorySummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "DemandHistoryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_DemandHistoryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.DemandHistoryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "JacketSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_JacketSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.JacketSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "JacketItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_JacketItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.JacketItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TocSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_TocSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.TocSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "TocItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_TocItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.TocItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ExcerptSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ExcerptSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ExcerptSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ExcerptItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ExcerptItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ExcerptItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ProductSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ProductSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ProductSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ProductItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ProductItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ProductItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "MuzeSummaryItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_MuzeSummaryItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.MuzeSummaryItems = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Muze")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Muze class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Muze = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_RequestItems
- (id)init
{
	if((self = [super init])) {
		RequestItem = [[NSMutableArray alloc] init];
		UserID = 0;
		Password = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(RequestItem != nil) [RequestItem release];
	if(UserID != nil) [UserID release];
	if(Password != nil) [Password release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
//	xmlNodePtr root = xmlDocGetRootElement(doc);
	
//	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
//	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:RequestItems");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.UserID != 0) {
		xmlSetProp(node, (const xmlChar*)"UserID", (const xmlChar*)[[self.UserID description] UTF8String]);
	}
	if(self.Password != 0) {
		xmlSetProp(node, (const xmlChar*)"Password", (const xmlChar*)[[self.Password description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.RequestItem != 0) {
		for(ContentCafe_RequestItem * child in self.RequestItem) {
			xmlAddChild(node, [child xmlNodeForDoc:node->doc elementName:@"RequestItem"]);
		}
	}
}
/* elements */
@synthesize RequestItem;
- (void)addRequestItem:(ContentCafe_RequestItem *)toAdd
{
	if(toAdd != nil) [RequestItem addObject:toAdd];
}
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.UserID forKey:@"UserID"];
	[attributes setObject:self.Password forKey:@"Password"];
	
	return attributes;
}
@synthesize UserID;
@synthesize Password;
+ (ContentCafe_RequestItems *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_RequestItems *newObject = [[ContentCafe_RequestItems new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "UserID");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.UserID = attrString;
		xmlFree(attrValue);
	}
	attrValue = xmlGetProp(cur, (const xmlChar *) "Password");
	if(attrValue != NULL) {
		attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		self.Password = attrString;
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "RequestItem")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_RequestItem class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				if(newChild != nil) [self.RequestItem addObject:newChild];
			}
		}
	}
}
@end
@implementation ContentCafe_ContentCafeXML
- (id)init
{
	if((self = [super init])) {
		Error = 0;
		Search = 0;
		RequestItems = 0;
		DateTime = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(Error != nil) [Error release];
	if(Search != nil) [Search release];
	if(RequestItems != nil) [RequestItems release];
	if(DateTime != nil) [DateTime release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
//	xmlNodePtr root = xmlDocGetRootElement(doc);
	
//	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
//	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:ContentCafeXML");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
	if(self.DateTime != 0) {
		xmlSetProp(node, (const xmlChar*)"DateTime", (const xmlChar*)[[self.DateTime description] UTF8String]);
	}
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.Error != 0) {
		xmlAddChild(node, [self.Error xmlNodeForDoc:node->doc elementName:@"Error"]);
	}
	if(self.Search != 0) {
		xmlAddChild(node, [self.Search xmlNodeForDoc:node->doc elementName:@"Search"]);
	}
	if(self.RequestItems != 0) {
		xmlAddChild(node, [self.RequestItems xmlNodeForDoc:node->doc elementName:@"RequestItems"]);
	}
}
/* elements */
@synthesize Error;
@synthesize Search;
@synthesize RequestItems;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:self.DateTime forKey:@"DateTime"];
	
	return attributes;
}
@synthesize DateTime;
+ (ContentCafe_ContentCafeXML *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_ContentCafeXML *newObject = [[ContentCafe_ContentCafeXML new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
	xmlChar *attrValue = NULL;
	//NSString *attrString;
	
	attrValue = xmlGetProp(cur, (const xmlChar *) "DateTime");
	if(attrValue != NULL) {
		//attrString = [NSString stringWithCString:(char*)attrValue encoding:NSUTF8StringEncoding];
		//self.DateTime = [NSDate dateWithString:attrString];
		xmlFree(attrValue);
	}
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Error")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Error = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "Search")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_Search class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.Search = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "RequestItems")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_RequestItems class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.RequestItems = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_Test1Response
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test1Response");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test1Response *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test1Response *newObject = [[ContentCafe_Test1Response new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_Test2
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test2");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test2 *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test2 *newObject = [[ContentCafe_Test2 new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_Test2Response
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test2Response");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test2Response *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test2Response *newObject = [[ContentCafe_Test2Response new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_Test3
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test3");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test3 *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test3 *newObject = [[ContentCafe_Test3 new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_Test3Response
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test3Response");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test3Response *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test3Response *newObject = [[ContentCafe_Test3Response new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_Test4
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test4");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test4 *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test4 *newObject = [[ContentCafe_Test4 new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_Test4Response
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Test4Response");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Test4Response *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Test4Response *newObject = [[ContentCafe_Test4Response new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_XmlPost
- (id)init
{
	if((self = [super init])) {
	}
	
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlPost");
	
	[self addAttributesToNode:node];
	
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
}
/* elements */
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlPost *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlPost *newObject = [[ContentCafe_XmlPost new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
}
@end
@implementation ContentCafe_XmlPostResponse
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlPostResponse");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlPostResponse *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlPostResponse *newObject = [[ContentCafe_XmlPostResponse new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_XmlString
- (id)init
{
	if((self = [super init])) {
		xmlRequest = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(xmlRequest != nil) [xmlRequest release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlString");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.xmlRequest != 0) {
		xmlAddChild(node, [self.xmlRequest xmlNodeForDoc:node->doc elementName:@"xmlRequest"]);
	}
}
/* elements */
@synthesize xmlRequest;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlString *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlString *newObject = [[ContentCafe_XmlString new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "xmlRequest")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.xmlRequest = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_XmlStringResponse
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlStringResponse");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlStringResponse *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlStringResponse *newObject = [[ContentCafe_XmlStringResponse new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_XmlClass
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
//	xmlNodePtr root = xmlDocGetRootElement(doc);
	
//	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
//	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlClass");
	xmlSetNsProp(node, nil, (const xmlChar*)"xmlns", (const xmlChar*)"http://ContentCafe2.btol.com");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlClass *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlClass *newObject = [[ContentCafe_XmlClass new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_XmlClassResponse
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:XmlClassResponse");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_XmlClassResponse *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_XmlClassResponse *newObject = [[ContentCafe_XmlClassResponse new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_Single
- (id)init
{
	if((self = [super init])) {
		userID = 0;
		password = 0;
		key = 0;
		content = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(userID != nil) [userID release];
	if(password != nil) [password release];
	if(key != nil) [key release];
	if(content != nil) [content release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	//xmlNodePtr root = xmlDocGetRootElement(doc);
	
	//xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	// originally:
	//xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:Single");
	xmlSetNsProp(node, nil, (const xmlChar*)"xmlns", (const xmlChar*)"http://ContentCafe2.btol.com");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.userID != 0) {
		xmlAddChild(node, [self.userID xmlNodeForDoc:node->doc elementName:@"userID"]);
	}
	if(self.password != 0) {
		xmlAddChild(node, [self.password xmlNodeForDoc:node->doc elementName:@"password"]);
	}
	if(self.key != 0) {
		xmlAddChild(node, [self.key xmlNodeForDoc:node->doc elementName:@"key"]);
	}
	if(self.content != 0) {
		xmlAddChild(node, [self.content xmlNodeForDoc:node->doc elementName:@"content"]);
	}
}
/* elements */
@synthesize userID;
@synthesize password;
@synthesize key;
@synthesize content;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_Single *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_Single *newObject = [[ContentCafe_Single new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "userID")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.userID = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "password")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.password = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "key")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.key = newChild;
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "content")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [NSString  class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.content = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe_SingleResponse
- (id)init
{
	if((self = [super init])) {
		self.ContentCafe = 0;
	}
	
	return self;
}
- (void)dealloc
{
	if(self.ContentCafe != nil) [self.ContentCafe release];
	
	[super dealloc];
}
- (NSString *)nsPrefix
{
	return @"ContentCafe";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	xmlNodePtr root = xmlDocGetRootElement(doc);
	
	xmlNsPtr xsi = xmlSearchNs(doc, root, (const xmlChar*)"xsi");
	
	xmlNodePtr node = xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], NULL);
	xmlSetNsProp(node, xsi, (const xmlChar*)"type", (const xmlChar*)"ContentCafe:SingleResponse");
	
	[self addAttributesToNode:node];
	
	[self addElementsToNode:node];
	
	return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node
{
	
}
- (void)addElementsToNode:(xmlNodePtr)node
{
	
	if(self.ContentCafe != 0) {
		xmlAddChild(node, [self.ContentCafe xmlNodeForDoc:node->doc elementName:@"ContentCafe"]);
	}
}
/* elements */
@synthesize ContentCafe;
/* attributes */
- (NSDictionary *)attributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	return attributes;
}
+ (ContentCafe_SingleResponse *)deserializeNode:(xmlNodePtr)cur
{
	ContentCafe_SingleResponse *newObject = [[ContentCafe_SingleResponse new] autorelease];
	
	[newObject deserializeAttributesFromNode:cur];
	[newObject deserializeElementsFromNode:cur];
	
	return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur
{
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur
{
	
	
	for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
		if(cur->type == XML_ELEMENT_NODE) {
			xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
			NSString *elementString = nil;
			
			if(elementText != NULL) {
				elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
				[elementString self]; // avoid compiler warning for unused var
				xmlFree(elementText);
			}
			if(xmlStrEqual(cur->name, (const xmlChar *) "ContentCafe")) {
				
				Class elementClass = nil;
				xmlChar *instanceType = xmlGetNsProp(cur, (const xmlChar *) "type", (const xmlChar *) "http://www.w3.org/2001/XMLSchema-instance");
				if(instanceType == NULL) {
					elementClass = [ContentCafe_ContentCafeXML class];
				} else {
					NSString *elementTypeString = [NSString stringWithCString:(char*)instanceType encoding:NSUTF8StringEncoding];
					
					NSArray *elementTypeArray = [elementTypeString componentsSeparatedByString:@":"];
					
					NSString *elementClassString = nil;
					if([elementTypeArray count] > 1) {
						NSString *prefix = [elementTypeArray objectAtIndex:0];
						NSString *localName = [elementTypeArray objectAtIndex:1];
						
						xmlNsPtr elementNamespace = xmlSearchNs(cur->doc, cur, (const xmlChar *)[prefix UTF8String]);
						
						NSString *standardPrefix = [[USGlobals sharedInstance].wsdlStandardNamespaces objectForKey:[NSString stringWithCString:(char*)elementNamespace->href encoding:NSUTF8StringEncoding]];
						
						elementClassString = [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
					} else {
						elementClassString = [elementTypeString stringByReplacingOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [elementTypeString length])];
					}
					
					elementClass = NSClassFromString(elementClassString);
					xmlFree(instanceType);
				}
				
				id newChild = [elementClass deserializeNode:cur];
				
				self.ContentCafe = newChild;
			}
		}
	}
}
@end
@implementation ContentCafe
+ (void)initialize
{
	[[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"xsd" forKey:@"http://www.w3.org/2001/XMLSchema"];
	[[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"ContentCafe" forKey:@"http://ContentCafe2.btol.com"];
}
+ (ContentCafeSoap *)ContentCafeSoap
{
	return [[[ContentCafeSoap alloc] initWithAddress:@"http://contentcafe2.btol.com/ContentCafe/ContentCafe.asmx"] autorelease];
}
+ (ContentCafeSoap12 *)ContentCafeSoap12
{
	return [[[ContentCafeSoap12 alloc] initWithAddress:@"http://contentcafe2.btol.com/ContentCafe/ContentCafe.asmx"] autorelease];
}
@end
@implementation ContentCafeSoap
@synthesize address;
@synthesize defaultTimeout;
@synthesize logXMLInOut;
@synthesize cookies;
@synthesize authUsername;
@synthesize authPassword;
- (id)init
{
	if((self = [super init])) {
		address = nil;
		cookies = nil;
		defaultTimeout = 10;//seconds
		logXMLInOut = NO;
		synchronousOperationComplete = NO;
	}
	
	return self;
}
- (id)initWithAddress:(NSString *)anAddress
{
	if((self = [self init])) {
		self.address = [NSURL URLWithString:anAddress];
	}
	
	return self;
}
- (void)addCookie:(NSHTTPCookie *)toAdd
{
	if(toAdd != nil) {
		if(cookies == nil) cookies = [[NSMutableArray alloc] init];
		[cookies addObject:toAdd];
	}
}
- (ContentCafeSoapResponse *)performSynchronousOperation:(ContentCafeSoapOperation *)operation
{
	synchronousOperationComplete = NO;
	[operation start];
	
	// Now wait for response
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
	
	while (!synchronousOperationComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	return operation.response;
}
- (void)performAsynchronousOperation:(ContentCafeSoapOperation *)operation
{
	[operation start];
}
- (void) operation:(ContentCafeSoapOperation *)operation completedWithResponse:(ContentCafeSoapResponse *)response
{
	synchronousOperationComplete = YES;
}
- (ContentCafeSoapResponse *)Test1UsingParameters:(ContentCafe_Test1 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_Test1*)[ContentCafeSoap_Test1 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test1AsyncUsingParameters:(ContentCafe_Test1 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_Test1*)[ContentCafeSoap_Test1 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)Test2UsingParameters:(ContentCafe_Test2 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_Test2*)[ContentCafeSoap_Test2 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test2AsyncUsingParameters:(ContentCafe_Test2 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_Test2*)[ContentCafeSoap_Test2 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)Test3UsingParameters:(ContentCafe_Test3 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_Test3*)[ContentCafeSoap_Test3 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test3AsyncUsingParameters:(ContentCafe_Test3 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_Test3*)[ContentCafeSoap_Test3 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)Test4UsingParameters:(ContentCafe_Test4 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_Test4*)[ContentCafeSoap_Test4 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test4AsyncUsingParameters:(ContentCafe_Test4 *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_Test4*)[ContentCafeSoap_Test4 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)XmlPostUsingParameters:(ContentCafe_XmlPost *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_XmlPost*)[ContentCafeSoap_XmlPost alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlPostAsyncUsingParameters:(ContentCafe_XmlPost *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_XmlPost*)[ContentCafeSoap_XmlPost alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)XmlStringUsingParameters:(ContentCafe_XmlString *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_XmlString*)[ContentCafeSoap_XmlString alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlStringAsyncUsingParameters:(ContentCafe_XmlString *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_XmlString*)[ContentCafeSoap_XmlString alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)XmlClassUsingParameters:(ContentCafe_XmlClass *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_XmlClass*)[ContentCafeSoap_XmlClass alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlClassAsyncUsingParameters:(ContentCafe_XmlClass *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_XmlClass*)[ContentCafeSoap_XmlClass alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoapResponse *)SingleUsingParameters:(ContentCafe_Single *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap_Single*)[ContentCafeSoap_Single alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)SingleAsyncUsingParameters:(ContentCafe_Single *)aParameters  delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap_Single*)[ContentCafeSoap_Single alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (void)sendHTTPCallUsingBody:(NSString *)outputBody soapAction:(NSString *)soapAction forOperation:(ContentCafeSoapOperation *)operation
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.address 
																												 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
																										 timeoutInterval:self.defaultTimeout];
	NSData *bodyData = [outputBody dataUsingEncoding:NSUTF8StringEncoding];
	
	if(cookies != nil) {
		[request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
	}
	[request setValue:@"wsdl2objc" forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	[request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
	// originally:
	//[request setValue:@"application/soap+xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%u", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
	[request setValue:self.address.host forHTTPHeaderField:@"Host"];
	[request setHTTPMethod: @"POST"];
	// set version 1.1 - how?
	[request setHTTPBody: bodyData];
		
#ifdef SERVICE_DEBUG
	if(self.logXMLInOut) {
		NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
		NSLog(@"OutputBody:\n%@", outputBody);
	}
#endif
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:operation];
	
	operation.urlConnection = connection;
	[connection release];
}
- (void) dealloc
{
	[address release];
	[cookies release];
	[super dealloc];
}
@end
@implementation ContentCafeSoapOperation
@synthesize binding;
@synthesize response;
@synthesize delegate;
@synthesize responseData;
@synthesize urlConnection;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)aDelegate
{
	if ((self = [super init])) {
		self.binding = aBinding;
		response = nil;
		self.delegate = aDelegate;
		self.responseData = nil;
		self.urlConnection = nil;
	}
	
	return self;
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
		newCredential=[NSURLCredential credentialWithUser:self.binding.authUsername
												 password:self.binding.authPassword
											  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:newCredential
			   forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Authentication Error" forKey:NSLocalizedDescriptionKey];
		NSError *authError = [NSError errorWithDomain:@"Connection Authentication" code:0 userInfo:userInfo];
		[self connection:connection didFailWithError:authError];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
	NSHTTPURLResponse *httpResponse;
	if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		httpResponse = (NSHTTPURLResponse *) urlResponse;
	} else {
		httpResponse = nil;
	}
	
	if(binding.logXMLInOut) {
		NSLog(@"ResponseStatus: %u\n", [httpResponse statusCode]);
		NSLog(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);
	}
	
	NSMutableArray *cookies = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:binding.address] mutableCopy];
	
	binding.cookies = cookies;
	[cookies release];
//	if ([urlResponse.MIMEType rangeOfString:@"application/soap+xml"].length == 0) {
	if ([urlResponse.MIMEType rangeOfString:@"text/xml"].length == 0) { // the baker-taylor's service responds with text/xml.
		NSError *error = nil;
		[connection cancel];
		if ([httpResponse statusCode] >= 400) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]] forKey:NSLocalizedDescriptionKey];
				
			error = [NSError errorWithDomain:@"ContentCafeSoapResponseHTTP" code:[httpResponse statusCode] userInfo:userInfo];
		} else {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
																[NSString stringWithFormat: @"Unexpected response MIME type to SOAP call:%@", urlResponse.MIMEType]
																													 forKey:NSLocalizedDescriptionKey];
			error = [NSError errorWithDomain:@"ContentCafeSoapResponseHTTP" code:1 userInfo:userInfo];
		}
				
		[self connection:connection didFailWithError:error];
  }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  if (responseData == nil) {
		responseData = [data mutableCopy];
	} else {
		[responseData appendData:data];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (binding.logXMLInOut) {
		NSLog(@"ResponseError:\n%@\n%@", error,[error userInfo]);
	}
	response.error = error;
	[delegate operation:self completedWithResponse:response];
}
- (void)dealloc
{
	[binding release];
	[response release];
	delegate = nil;
	[responseData release];
	[urlConnection release];
	
	[super dealloc];
}
@end
@implementation ContentCafeSoap_Test1
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test1 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test1"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test1" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test1Response")) {
									ContentCafe_Test1Response *bodyObject = [ContentCafe_Test1Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_Test2
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test2 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test2"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test2" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test2Response")) {
									ContentCafe_Test2Response *bodyObject = [ContentCafe_Test2Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_Test3
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test3 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test3"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test3" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test3Response")) {
									ContentCafe_Test3Response *bodyObject = [ContentCafe_Test3Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_Test4
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test4 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test4"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test4" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test4Response")) {
									ContentCafe_Test4Response *bodyObject = [ContentCafe_Test4Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_XmlPost
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlPost *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlPost"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlPost" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlPostResponse")) {
									ContentCafe_XmlPostResponse *bodyObject = [ContentCafe_XmlPostResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_XmlString
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlString *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlString"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlString" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlStringResponse")) {
									ContentCafe_XmlStringResponse *bodyObject = [ContentCafe_XmlStringResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_XmlClass
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlClass *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlClass"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlClass" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlClassResponse")) {
									ContentCafe_XmlClassResponse *bodyObject = [ContentCafe_XmlClassResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap_Single
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap *)aBinding delegate:(id<ContentCafeSoapResponseDelegate>)responseDelegate
parameters:(ContentCafe_Single *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoapResponse new];
	
	ContentCafeSoap_envelope *envelope = [ContentCafeSoap_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Single"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Single" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoapResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "SingleResponse")) {
									ContentCafe_SingleResponse *bodyObject = [ContentCafe_SingleResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
static ContentCafeSoap_envelope *ContentCafeSoapSharedEnvelopeInstance = nil;
@implementation ContentCafeSoap_envelope
+ (ContentCafeSoap_envelope *)sharedInstance
{
	if(ContentCafeSoapSharedEnvelopeInstance == nil) {
		ContentCafeSoapSharedEnvelopeInstance = [ContentCafeSoap_envelope new];
	}
	
	return ContentCafeSoapSharedEnvelopeInstance;
}
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements
{
    xmlDocPtr doc;
	
	doc = xmlNewDoc((const xmlChar*)XML_DEFAULT_VERSION);
	if (doc == NULL) {
		NSLog(@"Error creating the xml document tree");
		return @"";
	}
	
	xmlNodePtr root = xmlNewDocNode(doc, NULL, (const xmlChar*)"Envelope", NULL);
	xmlDocSetRootElement(doc, root);
	
//	xmlNsPtr soapEnvelopeNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2003/05/soap-envelope", (const xmlChar*)"soap");
	xmlNsPtr soapEnvelopeNs = xmlNewNs(root, (const xmlChar*)"http://schemas.xmlsoap.org/soap/envelope/", (const xmlChar*)"soap");
	xmlSetNs(root, soapEnvelopeNs);
	
	xmlNsPtr xslNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/1999/XSL/Transform", (const xmlChar*)"xsl");
	xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema-instance", (const xmlChar*)"xsi");
	
	xmlNewNsProp(root, xslNs, (const xmlChar*)"version", (const xmlChar*)"1.0");
	
	xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema", (const xmlChar*)"xsd");
	// originally
	//xmlNewNs(root, (const xmlChar*)"http://ContentCafe2.btol.com", (const xmlChar*)"ContentCafe");
	
	if((headerElements != nil) && ([headerElements count] > 0)) {
		xmlNodePtr headerNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Header", NULL);
		xmlAddChild(root, headerNode);
		
		for(NSString *key in [headerElements allKeys]) {
			id header = [headerElements objectForKey:key];
			xmlAddChild(headerNode, [header xmlNodeForDoc:doc elementName:key]);
		}
	}
	
	if((bodyElements != nil) && ([bodyElements count] > 0)) {
		xmlNodePtr bodyNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Body", NULL);
		xmlAddChild(root, bodyNode);
		
		for(NSString *key in [bodyElements allKeys]) {
			id body = [bodyElements objectForKey:key];
			xmlAddChild(bodyNode, [body xmlNodeForDoc:doc elementName:key]);
		}
	}
	
	xmlChar *buf;
	int size;
	xmlDocDumpFormatMemory(doc, &buf, &size, 1);
	
	NSString *serializedForm = [NSString stringWithCString:(const char*)buf encoding:NSUTF8StringEncoding];
	xmlFree(buf);
	
	xmlFreeDoc(doc);	
	return serializedForm;
}
@end
@implementation ContentCafeSoapResponse
@synthesize headers;
@synthesize bodyParts;
@synthesize error;
- (id)init
{
	if((self = [super init])) {
		headers = nil;
		bodyParts = nil;
		error = nil;
	}
	
	return self;
}
-(void)dealloc {
    self.headers = nil;
    self.bodyParts = nil;
    self.error = nil;	
    [super dealloc];
}
@end
@implementation ContentCafeSoap12
@synthesize address;
@synthesize defaultTimeout;
@synthesize logXMLInOut;
@synthesize cookies;
@synthesize authUsername;
@synthesize authPassword;
- (id)init
{
	if((self = [super init])) {
		address = nil;
		cookies = nil;
		defaultTimeout = 10;//seconds
		logXMLInOut = NO;
		synchronousOperationComplete = NO;
	}
	
	return self;
}
- (id)initWithAddress:(NSString *)anAddress
{
	if((self = [self init])) {
		self.address = [NSURL URLWithString:anAddress];
	}
	
	return self;
}
- (void)addCookie:(NSHTTPCookie *)toAdd
{
	if(toAdd != nil) {
		if(cookies == nil) cookies = [[NSMutableArray alloc] init];
		[cookies addObject:toAdd];
	}
}
- (ContentCafeSoap12Response *)performSynchronousOperation:(ContentCafeSoap12Operation *)operation
{
	synchronousOperationComplete = NO;
	[operation start];
	
	// Now wait for response
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
	
	while (!synchronousOperationComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	return operation.response;
}
- (void)performAsynchronousOperation:(ContentCafeSoap12Operation *)operation
{
	[operation start];
}
- (void) operation:(ContentCafeSoap12Operation *)operation completedWithResponse:(ContentCafeSoap12Response *)response
{
	synchronousOperationComplete = YES;
}
- (ContentCafeSoap12Response *)Test1UsingParameters:(ContentCafe_Test1 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_Test1*)[ContentCafeSoap12_Test1 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test1AsyncUsingParameters:(ContentCafe_Test1 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_Test1*)[ContentCafeSoap12_Test1 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)Test2UsingParameters:(ContentCafe_Test2 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_Test2*)[ContentCafeSoap12_Test2 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test2AsyncUsingParameters:(ContentCafe_Test2 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_Test2*)[ContentCafeSoap12_Test2 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)Test3UsingParameters:(ContentCafe_Test3 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_Test3*)[ContentCafeSoap12_Test3 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test3AsyncUsingParameters:(ContentCafe_Test3 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_Test3*)[ContentCafeSoap12_Test3 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)Test4UsingParameters:(ContentCafe_Test4 *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_Test4*)[ContentCafeSoap12_Test4 alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)Test4AsyncUsingParameters:(ContentCafe_Test4 *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_Test4*)[ContentCafeSoap12_Test4 alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)XmlPostUsingParameters:(ContentCafe_XmlPost *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_XmlPost*)[ContentCafeSoap12_XmlPost alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlPostAsyncUsingParameters:(ContentCafe_XmlPost *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_XmlPost*)[ContentCafeSoap12_XmlPost alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)XmlStringUsingParameters:(ContentCafe_XmlString *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_XmlString*)[ContentCafeSoap12_XmlString alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlStringAsyncUsingParameters:(ContentCafe_XmlString *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_XmlString*)[ContentCafeSoap12_XmlString alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)XmlClassUsingParameters:(ContentCafe_XmlClass *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_XmlClass*)[ContentCafeSoap12_XmlClass alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)XmlClassAsyncUsingParameters:(ContentCafe_XmlClass *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_XmlClass*)[ContentCafeSoap12_XmlClass alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (ContentCafeSoap12Response *)SingleUsingParameters:(ContentCafe_Single *)aParameters 
{
	return [self performSynchronousOperation:[[(ContentCafeSoap12_Single*)[ContentCafeSoap12_Single alloc] initWithBinding:self delegate:self
																							parameters:aParameters
																							] autorelease]];
}
- (void)SingleAsyncUsingParameters:(ContentCafe_Single *)aParameters  delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
{
	[self performAsynchronousOperation: [[(ContentCafeSoap12_Single*)[ContentCafeSoap12_Single alloc] initWithBinding:self delegate:responseDelegate
																							 parameters:aParameters
																							 ] autorelease]];
}
- (void)sendHTTPCallUsingBody:(NSString *)outputBody soapAction:(NSString *)soapAction forOperation:(ContentCafeSoap12Operation *)operation
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.address 
																												 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
																										 timeoutInterval:self.defaultTimeout];
	NSData *bodyData = [outputBody dataUsingEncoding:NSUTF8StringEncoding];
	
	if(cookies != nil) {
		[request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
	}

	[request setValue:@"wsdl2objc" forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	[request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
	// originally:
	//[request setValue:@"application/soap+xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%u", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
	[request setValue:self.address.host forHTTPHeaderField:@"Host"];
	[request setHTTPMethod: @"POST"];
	// set version 1.1 - how?
	[request setHTTPBody: bodyData];
		
#ifdef SERVICE_DEBUG
	if(self.logXMLInOut) {
		NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
		NSLog(@"OutputBody:\n%@", outputBody);
	}
#endif
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:operation];
	
	operation.urlConnection = connection;
	[connection release];
}
- (void) dealloc
{
	[address release];
	[cookies release];
	[super dealloc];
}
@end
@implementation ContentCafeSoap12Operation
@synthesize binding;
@synthesize response;
@synthesize delegate;
@synthesize responseData;
@synthesize urlConnection;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)aDelegate
{
	if ((self = [super init])) {
		self.binding = aBinding;
		response = nil;
		self.delegate = aDelegate;
		self.responseData = nil;
		self.urlConnection = nil;
	}
	
	return self;
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
		newCredential=[NSURLCredential credentialWithUser:self.binding.authUsername
												 password:self.binding.authPassword
											  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:newCredential
			   forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Authentication Error" forKey:NSLocalizedDescriptionKey];
		NSError *authError = [NSError errorWithDomain:@"Connection Authentication" code:0 userInfo:userInfo];
		[self connection:connection didFailWithError:authError];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
	NSHTTPURLResponse *httpResponse;
	if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		httpResponse = (NSHTTPURLResponse *) urlResponse;
	} else {
		httpResponse = nil;
	}
	
	if(binding.logXMLInOut) {
		NSLog(@"ResponseStatus: %u\n", [httpResponse statusCode]);
		NSLog(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);
	}
	
	NSMutableArray *cookies = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:binding.address] mutableCopy];
	
	binding.cookies = cookies;
	[cookies release];
  if ([urlResponse.MIMEType rangeOfString:@"application/soap+xml"].length == 0) {
		NSError *error = nil;
		[connection cancel];
		if ([httpResponse statusCode] >= 400) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]] forKey:NSLocalizedDescriptionKey];
				
			error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseHTTP" code:[httpResponse statusCode] userInfo:userInfo];
		} else {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
																[NSString stringWithFormat: @"Unexpected response MIME type to SOAP call:%@", urlResponse.MIMEType]
																													 forKey:NSLocalizedDescriptionKey];
			error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseHTTP" code:1 userInfo:userInfo];
		}
				
		[self connection:connection didFailWithError:error];
  }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  if (responseData == nil) {
		responseData = [data mutableCopy];
	} else {
		[responseData appendData:data];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (binding.logXMLInOut) {
		NSLog(@"ResponseError:\n%@", error);
	}
	response.error = error;
	[delegate operation:self completedWithResponse:response];
}
- (void)dealloc
{
	[binding release];
	[response release];
	delegate = nil;
	[responseData release];
	[urlConnection release];
	
	[super dealloc];
}
@end
@implementation ContentCafeSoap12_Test1
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test1 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test1"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test1" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test1Response")) {
									ContentCafe_Test1Response *bodyObject = [ContentCafe_Test1Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_Test2
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test2 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test2"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test2" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test2Response")) {
									ContentCafe_Test2Response *bodyObject = [ContentCafe_Test2Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_Test3
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test3 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test3"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test3" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test3Response")) {
									ContentCafe_Test3Response *bodyObject = [ContentCafe_Test3Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_Test4
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_Test4 *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Test4"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Test4" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "Test4Response")) {
									ContentCafe_Test4Response *bodyObject = [ContentCafe_Test4Response deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_XmlPost
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlPost *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlPost"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlPost" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlPostResponse")) {
									ContentCafe_XmlPostResponse *bodyObject = [ContentCafe_XmlPostResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_XmlString
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlString *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlString"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlString" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlStringResponse")) {
									ContentCafe_XmlStringResponse *bodyObject = [ContentCafe_XmlStringResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_XmlClass
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_XmlClass *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"XmlClass"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/XmlClass" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "XmlClassResponse")) {
									ContentCafe_XmlClassResponse *bodyObject = [ContentCafe_XmlClassResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
@implementation ContentCafeSoap12_Single
@synthesize parameters;
- (id)initWithBinding:(ContentCafeSoap12 *)aBinding delegate:(id<ContentCafeSoap12ResponseDelegate>)responseDelegate
parameters:(ContentCafe_Single *)aParameters
{
	if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
		self.parameters = aParameters;
	}
	
	return self;
}
- (void)dealloc
{
	if(parameters != nil) [parameters release];
	
	[super dealloc];
}
- (void)main
{
	[response autorelease];
	response = [ContentCafeSoap12Response new];
	
	ContentCafeSoap12_envelope *envelope = [ContentCafeSoap12_envelope sharedInstance];
	
	NSMutableDictionary *headerElements = nil;
	headerElements = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *bodyElements = nil;
	bodyElements = [NSMutableDictionary dictionary];
	if(parameters != nil) [bodyElements setObject:parameters forKey:@"Single"];
	
	NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
	
	[binding sendHTTPCallUsingBody:operationXMLString soapAction:@"http://ContentCafe2.btol.com/Single" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (responseData != nil && delegate != nil)
	{
		xmlDocPtr doc;
		xmlNodePtr cur;
		
		if (binding.logXMLInOut) {
			NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
		}
		
		doc = xmlParseMemory([responseData bytes], [responseData length]);
		
		if (doc == NULL) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
			
			response.error = [NSError errorWithDomain:@"ContentCafeSoap12ResponseXML" code:1 userInfo:userInfo];
			[delegate operation:self completedWithResponse:response];
		} else {
			cur = xmlDocGetRootElement(doc);
			cur = cur->children;
			
			for( ; cur != NULL ; cur = cur->next) {
				if(cur->type == XML_ELEMENT_NODE) {
					
					if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
						NSMutableArray *responseBodyParts = [NSMutableArray array];
						
						xmlNodePtr bodyNode;
						for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
							if(cur->type == XML_ELEMENT_NODE) {
								if(xmlStrEqual(bodyNode->name, (const xmlChar *) "SingleResponse")) {
									ContentCafe_SingleResponse *bodyObject = [ContentCafe_SingleResponse deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
								}
                                                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") && 
                                                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
									SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
									//NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
									if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                                                }
							}
						}
						
						response.bodyParts = responseBodyParts;
					}
				}
			}
			
			xmlFreeDoc(doc);
		}
		
		xmlCleanupParser();
		[delegate operation:self completedWithResponse:response];
	}
}
@end
static ContentCafeSoap12_envelope *ContentCafeSoap12SharedEnvelopeInstance = nil;
@implementation ContentCafeSoap12_envelope
+ (ContentCafeSoap12_envelope *)sharedInstance
{
	if(ContentCafeSoap12SharedEnvelopeInstance == nil) {
		ContentCafeSoap12SharedEnvelopeInstance = [ContentCafeSoap12_envelope new];
	}
	
	return ContentCafeSoap12SharedEnvelopeInstance;
}
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements
{
    xmlDocPtr doc;
	
	doc = xmlNewDoc((const xmlChar*)XML_DEFAULT_VERSION);
	if (doc == NULL) {
		NSLog(@"Error creating the xml document tree");
		return @"";
	}
	
	xmlNodePtr root = xmlNewDocNode(doc, NULL, (const xmlChar*)"Envelope", NULL);
	xmlDocSetRootElement(doc, root);
	
	xmlNsPtr soapEnvelopeNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2003/05/soap-envelope", (const xmlChar*)"soap");
	xmlSetNs(root, soapEnvelopeNs);
	
	xmlNsPtr xslNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/1999/XSL/Transform", (const xmlChar*)"xsl");
	xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema-instance", (const xmlChar*)"xsi");
	
	xmlNewNsProp(root, xslNs, (const xmlChar*)"version", (const xmlChar*)"1.0");
	
	xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema", (const xmlChar*)"xsd");
	xmlNewNs(root, (const xmlChar*)"http://ContentCafe2.btol.com", (const xmlChar*)"ContentCafe");
	
	if((headerElements != nil) && ([headerElements count] > 0)) {
		xmlNodePtr headerNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Header", NULL);
		xmlAddChild(root, headerNode);
		
		for(NSString *key in [headerElements allKeys]) {
			id header = [headerElements objectForKey:key];
			xmlAddChild(headerNode, [header xmlNodeForDoc:doc elementName:key]);
		}
	}
	
	if((bodyElements != nil) && ([bodyElements count] > 0)) {
		xmlNodePtr bodyNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Body", NULL);
		xmlAddChild(root, bodyNode);
		
		for(NSString *key in [bodyElements allKeys]) {
			id body = [bodyElements objectForKey:key];
			xmlAddChild(bodyNode, [body xmlNodeForDoc:doc elementName:key]);
		}
	}
	
	xmlChar *buf;
	int size;
	xmlDocDumpFormatMemory(doc, &buf, &size, 1);
	
	NSString *serializedForm = [NSString stringWithCString:(const char*)buf encoding:NSUTF8StringEncoding];
	xmlFree(buf);
	
	xmlFreeDoc(doc);	
	return serializedForm;
}
@end
@implementation ContentCafeSoap12Response
@synthesize headers;
@synthesize bodyParts;
@synthesize error;
- (id)init
{
	if((self = [super init])) {
		headers = nil;
		bodyParts = nil;
		error = nil;
	}
	
	return self;
}
-(void)dealloc {
    self.headers = nil;
    self.bodyParts = nil;
    self.error = nil;	
    [super dealloc];
}
@end
