#import <UIKit/UIKit.h>

@interface UIDevice (blioAdditions)
- (NSString *)blioDevicePlatform;
- (CGFloat)blioDeviceMaximumLayoutZoom;
- (NSInteger)blioDeviceMaximumTileSize;
@end