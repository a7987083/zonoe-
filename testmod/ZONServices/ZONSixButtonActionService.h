#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Stable action boundary for the six menu buttons covered by the P63 program.
/// P63A intentionally preserves the existing engines and user-visible behavior.
@interface ZONSixButtonActionService : NSObject

+ (BOOL)performRemoteDownloadFromViewController:(UIViewController *)hostViewController;
+ (BOOL)performCloudSaveFromViewController:(UIViewController *)hostViewController;
+ (BOOL)performBackupSaveFromViewController:(UIViewController *)hostViewController;
+ (BOOL)performRestoreSaveFromViewController:(UIViewController *)hostViewController;
+ (BOOL)performClearGameDataFromViewController:(UIViewController *)hostViewController;
+ (BOOL)performClearAuthorizationFromViewController:(UIViewController *)hostViewController;

/// Compatibility surface retained for the historical C dispatcher helpers.
+ (NSString *)temporaryDirectoryPath;
+ (BOOL)ensureTemporaryDirectory;
+ (void)clearGameDataPreservingTemporaryDirectory;

@end

NS_ASSUME_NONNULL_END
