#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONAuthV2Flow : NSObject
+ (instancetype)sharedFlow;
- (void)startFromViewController:(nullable UIViewController *)hostViewController
                          udid:(NSString *)udid;
@end

NS_ASSUME_NONNULL_END
