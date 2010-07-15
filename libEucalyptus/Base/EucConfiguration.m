//
//  EucConfiguration.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucConfiguration.h"
#import "THLog.h"

@implementation EucConfiguration

NSString * const EucConfigurationFontSizesKey = @"EucFontSizes";
NSString * const EucConfigurationDefaultFontSizeKey = @"EucDefaultFontSize";
NSString * const EucConfigurationDefaultFontFamilyKey = @"EucDefaultFontFamily";
NSString * const EucConfigurationSerifFontFamilyKey = @"EucSerifFontFamily";
NSString * const EucConfigurationSansSerifFontFamilyKey = @"EucSansSerifFontFamily";
NSString * const EucConfigurationMonospaceFontFamilyKey = @"EucMonospaceFontFamily";
NSString * const EucConfigurationCursiveFontFamilyKey = @"EucCursiveFontFamily";
NSString * const EucConfigurationFantasyFontFamilyKey = @"EucFantasyFontFamily";

static const char sDefaultConfigurationPlist[] = "                                                             \
<?xml version=\"1.0\" encoding=\"UTF-8\"?>                                                                     \
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">     \
<plist version=\"1.0\">                                                                                        \
<dict>                                                                                                         \
    <key>EucFontSizes</key>                                                                                    \
    <array>                                                                                                    \
        <integer>14</integer>                                                                                  \
        <integer>16</integer>                                                                                  \
        <integer>18</integer>                                                                                  \
        <integer>20</integer>                                                                                  \
        <integer>22</integer>                                                                                  \
    </array>                                                                                                   \
    <key>EucDefaultFontSize</key>                                                                              \
    <string>18</string>                                                                                        \
    <key>EucDefaultFontFamily</key>                                                                            \
    <string>Georgia</string>                                                                                   \
    <key>EucSerifFontFamily</key>                                                                              \
    <string>Georgia</string>                                                                                   \
    <key>EucSansSerifFontFamily</key>                                                                          \
    <string>Helvetica</string>                                                                                 \
    <key>EucMonospaceFontFamily</key>                                                                          \
    <string>Courier</string>                                                                                   \
    <key>EucCursiveFontFamily</key>                                                                            \
    <string>MarkerFelt</string>                                                                                \
    <key>EucFantasyFontFamily</key>                                                                            \
    <string>Zapfino</string>                                                                                   \
</dict>                                                                                                        \
</plist>                                                                                                       \
";

static NSDictionary *sEucConfigurationDictionary = nil;

+ (void)initialize
{
    if(self == [EucConfiguration class]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"EucConfiguration" ofType:@"plist"];
        if(path) {
            sEucConfigurationDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        } else {
            THWarn(@"Cannot find EucConfiguration.plist in bundle.");
        }

        if(!sEucConfigurationDictionary) {
            THWarn(@"Using defaults for EucConfiguration.plist.");            
            CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)sDefaultConfigurationPlist, sizeof(sDefaultConfigurationPlist), kCFAllocatorNull);
            NSError *error = NULL;
            sEucConfigurationDictionary = (NSDictionary *)CFPropertyListCreateWithData(kCFAllocatorDefault, data, 0, NULL, (CFErrorRef *)&error);
            CFRelease(data);
        }    
        
        NSAssert([sEucConfigurationDictionary isKindOfClass:[NSDictionary class]], path);
    }
}

+ (id)objectForKey:(NSString *)key
{
    return [sEucConfigurationDictionary objectForKey:key];
}

@end
