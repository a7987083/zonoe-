#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Presentation boundary for the local sandbox browser action.
/// Keeps ZONFeatureDispatcher limited to registry lookup and route dispatch.
@interface ZONLocalFilesCoordinator : NSObject

+ (instancetype)sharedCoordinator;
- (BOOL)presentLocalFilesFromViewController:(UIViewController *)hostViewController;

@end

NS_ASSUME_NONNULL_END
