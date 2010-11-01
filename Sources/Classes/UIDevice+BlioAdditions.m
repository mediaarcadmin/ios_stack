#import "UIDevice+BlioAdditions.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation UIDevice (BlioAdditions)

/*
 Platforms
 iPhone1,1 = iPhone 1G
 iPhone1,2 = iPhone 3G
 iPhone2,1 = iPhone 3GS
 iPod1,1   = iPod touch 1G
 iPod2,1   = iPod touch 2G
 */

- (NSString *) blioDevicePlatform {
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);
	return platform;
}

- (CGFloat)blioDeviceMaximumLayoutZoom {
  
    NSRange iPhoneFamilyRange = {6,1};
    NSRange iPodFamilyRange = {4,1};  
    NSRange iPodModelRange = {6,1};
  
    NSString *platformString = [self blioDevicePlatform];
    
    CGFloat layoutZoom = 2;
    CGFloat highLayoutZoom = 4;
  
    // Devices newer than iPhone 3G or iPod 2G will be able to handle higher zoom levels
    if ([[self model] isEqualToString:@"iPhone"]) {
        if ([[platformString substringWithRange:iPhoneFamilyRange] floatValue] >= 2) layoutZoom = highLayoutZoom;
    } else if ([[self model] isEqualToString:@"iPod"]) {
        if ([[platformString substringWithRange:iPodFamilyRange] floatValue] == 2) {
            if ([[platformString substringWithRange:iPodModelRange] floatValue] >= 2) layoutZoom = highLayoutZoom;
        } else if ([[platformString substringWithRange:iPodFamilyRange] floatValue] > 2) {
            layoutZoom = highLayoutZoom;
        }
    } else {
        layoutZoom = highLayoutZoom;
    }
  
    return layoutZoom;
}

- (NSInteger)blioDeviceMaximumTileSize {
    
    NSRange iPhoneFamilyRange = {6,1};
    NSRange iPodFamilyRange = {4,1};  
    NSRange iPodModelRange = {6,1};
    
    NSString *platformString = [self blioDevicePlatform];
    
    NSInteger tileSize = 1024;
    NSInteger largeTileSize = 2048;
        
    // Devices older than iPhone 3G or iPod 2G will be able to handle higher tile sizes
    if ([[self model] isEqualToString:@"iPhone"]) {
        if ([[platformString substringWithRange:iPhoneFamilyRange] floatValue] >= 2) tileSize = largeTileSize;
    } else if ([[self model] isEqualToString:@"iPod"]) {
        if ([[platformString substringWithRange:iPodFamilyRange] floatValue] == 2) {
            if ([[platformString substringWithRange:iPodModelRange] floatValue] >= 2) tileSize = largeTileSize;
        } else if ([[platformString substringWithRange:iPodFamilyRange] floatValue] > 2) {
            tileSize = largeTileSize;
        }
    } else {
        tileSize = largeTileSize;
    }
    
    return tileSize;
}

- (BOOL)blioDevicePerCharacterSearchEnabled {
    
    NSRange iPhoneFamilyRange = {6,1};
    NSRange iPodFamilyRange = {4,1};  
    NSRange iPodModelRange = {6,1};
    
    NSString *platformString = [self blioDevicePlatform];
    
    BOOL perCharacterSearchEnabled = NO;
    
    // Devices older than iPhone 3G or iPod 2G will be able to handle per character search
    if ([[self model] isEqualToString:@"iPhone"]) {
        if ([[platformString substringWithRange:iPhoneFamilyRange] floatValue] >= 2) perCharacterSearchEnabled = YES;
    } else if ([[self model] isEqualToString:@"iPod"]) {
        if ([[platformString substringWithRange:iPodFamilyRange] floatValue] == 2) {
            if ([[platformString substringWithRange:iPodModelRange] floatValue] >= 2) perCharacterSearchEnabled = YES;
        } else if ([[platformString substringWithRange:iPodFamilyRange] floatValue] > 2) {
            perCharacterSearchEnabled = YES;
        }
    } else {
        perCharacterSearchEnabled = YES;
    }
    
    return perCharacterSearchEnabled;
}

- (NSTimeInterval)blioDeviceSearchInterval {
    
    NSRange iPhoneFamilyRange = {6,1};
    NSRange iPodFamilyRange = {4,1};  
    NSRange iPodModelRange = {6,1};
    
    NSString *platformString = [self blioDevicePlatform];
    
    NSTimeInterval timeInterval = 0.1f;
    NSTimeInterval shortInterval = 0.01f;
    
    // Devices older than iPhone 3G or iPod 2G will be able to handle per character search
    if ([[self model] isEqualToString:@"iPhone"]) {
        if ([[platformString substringWithRange:iPhoneFamilyRange] floatValue] >= 2) timeInterval = shortInterval;
    } else if ([[self model] isEqualToString:@"iPod"]) {
        if ([[platformString substringWithRange:iPodFamilyRange] floatValue] == 2) {
            if ([[platformString substringWithRange:iPodModelRange] floatValue] >= 2) timeInterval = shortInterval;
        } else if ([[platformString substringWithRange:iPodFamilyRange] floatValue] > 2) {
            timeInterval = shortInterval;
        }
    } else {
        timeInterval = shortInterval;
    }
    
    return timeInterval;
}

// obtained from Zach Waugh's blog: http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone
// modified to support cellular interface
+(NSString *) IPAddress {
	NSString * wifiAddress = nil;
	NSString * cellAddress = nil;
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				NSLog(@"[NSString stringWithUTF8String:temp_addr->ifa_name]: %@, %@",[NSString stringWithUTF8String:temp_addr->ifa_name],[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					wifiAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
				else if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"])
				{
					// Get NSString from C String
					cellAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
				
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	if (wifiAddress) return wifiAddress;
	else if (cellAddress) return cellAddress;
	return @"error";
}


@end