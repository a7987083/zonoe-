#import <Foundation/Foundation.h>
#import "ZONRestoreService.h"

NS_ASSUME_NONNULL_BEGIN

/// Public restore facade.
///
/// ZONRestoreService owns archive extraction and filesystem apply semantics.
/// ZONRestoreAPI owns the complete user-facing restore transaction, including
/// the legacy P66 post-success preference reload / cleanup / process-exit tail.
@interface ZONRestoreAPI : NSObject

+ (instancetype)sharedAPI;

/// Restore a ZIP archive and run the complete post-restore lifecycle on success.
- (void)restoreArchiveAtPath:(NSString *)archivePath
                   inboxPath:(nullable NSString *)inboxPath
                  completion:(ZONRestoreCompletion)completion;

/// Restore an already-prepared staging directory and run the same post-restore lifecycle.
- (void)restorePreparedStagingAtPath:(NSString *)stagingRoot
                          completion:(ZONRestoreCompletion)completion;

/// Standard staging path retained for legacy callers such as yidongwenjian.
- (NSString *)restoreStagingRootPath;

/// Inbox helper retained for document-picker imports.
- (NSString *)restoreInboxPathForBundleIdentifier:(NSString *)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
