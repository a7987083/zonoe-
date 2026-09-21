#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONSaveTransferCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)presentRemoteDownloadFromViewController:(UIViewController *)hostViewController;
- (void)presentCloudSaveFromViewController:(UIViewController *)hostViewController;

@end

NS_ASSUME_NONNULL_END
