#import "UIDevice+BlioAdditions.h"
#include <sys/types.h>
#include <sys/sysctl.h>

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
  
    // Devices newer than iPhone 3G or iPod 2G will be able to handle higher zoom levels
    if ([[self model] isEqualToString:@"iPhone"]) {
        if ([[platformString substringWithRange:iPhoneFamilyRange] floatValue] >= 2) layoutZoom = 4;
    } else if ([[self model] isEqualToString:@"iPod"]) {
        if ([[platformString substringWithRange:iPodFamilyRange] floatValue] == 2) {
            if ([[platformString substringWithRange:iPodModelRange] floatValue] >= 2) layoutZoom = 4;
        } else if ([[platformString substringWithRange:iPodFamilyRange] floatValue] > 2) {
            layoutZoom = 4;
        }
    } else if ([[self model] isEqualToString:@"iPhone Simulator"]) {
        layoutZoom = 4;
    }
  
    return layoutZoom;
}

@end