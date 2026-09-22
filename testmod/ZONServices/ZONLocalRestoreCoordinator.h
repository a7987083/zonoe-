#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONLocalRestoreSelectionHandler)(NSURL *selectedURL);

/// Presentation/orchestration boundary for local restore.
///
/// This coordinator owns document-picker presentation, local archive path
/// normalization, restore HUD/result presentation and the call into
/// ZONRestoreAPI. The restore engine and post-success lifecycle remain behind
/// ZONRestoreAPI / ZONRestoreService.
@interface ZONLocalRestoreCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)presentLocalRestoreFromViewController:(UIViewController *)hostViewController;

/// Compatibility hook for legacy YYYPicker UI that needs to refresh its file
/// list after a document has been selected. The handler is notification-only;
/// restore execution remains owned by this coordinator.
- (void)presentLocalRestoreFromViewController:(UIViewController *)hostViewController
                             selectionHandler:(nullable ZONLocalRestoreSelectionHandler)selectionHandler;

/// Restore an already-prepared staging tree through the same public restore API.
- (void)restorePreparedArchiveStaging;

@end

NS_ASSUME_NONNULL_END
