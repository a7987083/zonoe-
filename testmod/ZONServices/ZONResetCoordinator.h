#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONResetCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)presentClearGameDataFromViewController:(UIViewController *)hostViewController;
- (void)presentClearAuthorizationFromViewController:(UIViewController *)hostViewController;

/// Compatibility entry for historical callers that expect immediate game-data reset without confirmation UI.
- (void)resetGameDataWithoutConfirmation;

@end

NS_ASSUME_NONNULL_END
