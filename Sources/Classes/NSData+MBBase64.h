//
//  NSData (MBBase64) category taken from "MiloBird" at http://www.cocoadev.com/index.pl?BaseSixtyFour
//

@interface NSData (MBBase64)

+ (id)dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
- (NSString *)base64Encoding;

@end

