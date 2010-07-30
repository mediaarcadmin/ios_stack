//
//  USAdditions.m
//  WSDLParser
//
//  Created by John Ogle on 9/5/08.
//  Copyright 2008 LightSPEED Technologies. All rights reserved.
//  Modified by Matthew Faupel on 2009-05-06 to use NSDate instead of NSCalendarDate (for iPhone compatibility).
//  Modifications copyright (c) 2009 Micropraxis Ltd.
//  Modified by Henri Asseily on 2009-09-04 for SOAP 1.2 faults
//

#import "USAdditions.h"
#import "NSDate+ISO8601Parsing.h"
#import "NSDate+ISO8601Unparsing.h"

@implementation NSString (USAdditions)

- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	return xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], (const xmlChar*)[self UTF8String]);
}

+ (NSString *)deserializeNode:(xmlNodePtr)cur
{
	xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
	NSString *elementString = nil;
	
	if(elementText != NULL) {
		elementString = [NSString stringWithCString:(char*)elementText encoding:NSUTF8StringEncoding];
		xmlFree(elementText);
	}
	
	return elementString;
}

@end

@implementation NSNumber (USAdditions)

- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	return xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], (const xmlChar*)[[self stringValue] UTF8String]);
}

+ (NSNumber *)deserializeNode:(xmlNodePtr)cur
{
	NSString *stringValue = [NSString deserializeNode:cur];
	return [NSNumber numberWithDouble:[stringValue doubleValue]];
}

@end

@implementation NSDate (USAdditions)

- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	return xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], (const xmlChar*)[[self ISO8601DateString] UTF8String]);
}

+ (NSDate *)deserializeNode:(xmlNodePtr)cur
{
	return [NSDate dateWithString:[NSString deserializeNode:cur]];
}

@end

@implementation NSData (USAdditions)

- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	return xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], (const xmlChar*)[[self base64Encoding] UTF8String]);
}

+ (NSData *)deserializeNode:(xmlNodePtr)cur
{
	return [NSData dataWithBase64EncodedString:[NSString deserializeNode:cur]];
}

@end

@implementation USBoolean

@synthesize boolValue=value;

- (id)initWithBool:(BOOL)aValue
{
	self = [super init];
	if(self != nil) {
		value = aValue;
	}
	
	return self;
}

- (NSString *)stringValue
{
	return value ? @"true" : @"false";
}

- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName
{
	return xmlNewDocNode(doc, NULL, (const xmlChar*)[elName UTF8String], (const xmlChar*)[[self stringValue] UTF8String]);
}

+ (USBoolean *)deserializeNode:(xmlNodePtr)cur
{
	NSString *stringValue = [NSString deserializeNode:cur];
	
	if([stringValue isEqualToString:@"true"]) {
		return [[[USBoolean alloc] initWithBool:YES] autorelease];
	} else if([stringValue isEqualToString:@"false"]) {
		return [[[USBoolean alloc] initWithBool:NO] autorelease];
	}
	
	return nil;
}

@end

@implementation SOAPFault

@synthesize faultcode, faultstring, faultactor, detail;

+ (SOAPFault *)deserializeNode:(xmlNodePtr)cur
{
	SOAPFault *soapFault = [[SOAPFault new] autorelease];
	NSString *ns = [NSString stringWithCString:(char*)cur->ns->href encoding:NSUTF8StringEncoding];
	if (! ns) return soapFault;
	if ([ns isEqualToString:@"http://schemas.xmlsoap.org/soap/envelope/"]) {
		// soap 1.1
		for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
			if(cur->type == XML_ELEMENT_NODE) {
				if(xmlStrEqual(cur->name, (const xmlChar *) "faultcode")) {
					soapFault.faultcode = [NSString deserializeNode:cur];
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "faultstring")) {
					soapFault.faultstring = [NSString deserializeNode:cur];
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "faultactor")) {
					soapFault.faultactor = [NSString deserializeNode:cur];
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "detail")) {
					soapFault.detail = [NSString deserializeNode:cur];
				}
			}
		}
	} else if ([ns isEqualToString:@"http://www.w3.org/2003/05/soap-envelope"]) {
		// soap 1.2
				
		for( cur = cur->children ; cur != NULL ; cur = cur->next ) {
			if(cur->type == XML_ELEMENT_NODE) {
				if(xmlStrEqual(cur->name, (const xmlChar *) "Code")) {
					xmlNodePtr newcur = cur;
					for ( newcur = newcur->children; newcur != NULL ; newcur = newcur->next ) {
						if(xmlStrEqual(newcur->name, (const xmlChar *) "Value")) {
							soapFault.faultcode = [NSString deserializeNode:newcur];
							break;
						}
					}
					// TODO: Add Subcode handling
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "Reason")) {
					xmlChar *theReason = xmlNodeGetContent(cur);
					if (theReason != NULL) {
						soapFault.faultstring = [NSString stringWithCString:(char*)theReason encoding:NSUTF8StringEncoding];
						xmlFree(theReason);
					}
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "Node")) {
					soapFault.faultactor = [NSString deserializeNode:cur];
				}
				if(xmlStrEqual(cur->name, (const xmlChar *) "Detail")) {
					soapFault.detail = [NSString deserializeNode:cur];
				}
				// TODO: Add "Role" ivar
			}
		}
	}
  
	return soapFault;
}

- (NSString *)simpleFaultString
{
        NSString *simpleString = [faultstring stringByReplacingOccurrencesOfString: @"System.Web.Services.Protocols.SoapException: " withString: @""];
        NSRange suffixRange = [simpleString rangeOfString: @"\n   at "];
        
        if (suffixRange.length > 0)
                simpleString = [simpleString substringToIndex: suffixRange.location];
                
        return simpleString;
}

- (void)dealloc
{
        [faultcode release];
        [faultstring release];
        [faultactor release];
        [detail release];
        [super dealloc];
}

@end
