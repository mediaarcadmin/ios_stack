#import <UIKit/UIKit.h>

@interface UIDevice (blioAdditions)
- (NSString *)blioDevicePlatform;
- (CGFloat)blioDeviceMaximumLayoutZoom;
- (NSInteger)blioDeviceMaximumTileSize;
- (BOOL)blioDevicePerCharacterSearchEnabled;
- (NSTimeInterval)blioDeviceSearchInterval;
+(NSString *) IPAddress;
@end