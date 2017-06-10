
#import <UIKit/UIKit.h>

@interface UIColor (Tools)

+ (UIColor *)randomColor;
+ (UIColor *)colorWithHexString:(NSString *)hex;
+ (UIColor *)colorWithHexString:(NSString *)hex alp:(CGFloat)alp;

- (CGColorSpaceModel) colorSpaceModel ;
- (NSString *) colorSpaceString;
- (CGFloat) red;
- (CGFloat) green;
- (CGFloat) blue;
- (CGFloat) alpha;
@end
