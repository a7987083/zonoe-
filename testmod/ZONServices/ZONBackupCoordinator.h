#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Owns backup presentation/orchestration while ZONBackupService remains the pure engine.
@interface ZONBackupCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)presentBackupFromViewController:(UIViewController *)hostViewController;

@end

NS_ASSUME_NONNULL_END
