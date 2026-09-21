#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONRestoreErrorCode) {
    ZONRestoreErrorAlreadyRunning = 2000,
    ZONRestoreErrorInvalidInput = 2001,
    ZONRestoreErrorStagingPrepareFailed = 2002,
    ZONRestoreErrorArchiveExtractFailed = 2003,
    ZONRestoreErrorBackupRootNotFound = 2004,
    ZONRestoreErrorPreflightFailed = 2005,
    ZONRestoreErrorDocumentsApplyFailed = 2006,
    ZONRestoreErrorLibraryApplyFailed = 2007,
    ZONRestoreErrorCleanupFailed = 2008,
};

FOUNDATION_EXPORT NSErrorDomain const ZONRestoreErrorDomain;

typedef void (^ZONRestoreCompletion)(BOOL success, NSError * _Nullable error);

@interface ZONRestoreService : NSObject

+ (instancetype)sharedService;

- (NSString *)restoreStagingRootPath;
- (NSString *)restoreInboxPathForBundleIdentifier:(NSString *)bundleIdentifier;

/// Local/imported archive path. Extraction, validation, merge-restore and cleanup run off the main thread.
- (void)restoreArchiveAtPath:(NSString *)archivePath
                   inboxPath:(nullable NSString *)inboxPath
                  completion:(ZONRestoreCompletion)completion;

/// Compatibility entry for cloud/download flows which have already extracted into /tmp/zonoe.
- (void)restorePreparedStagingAtPath:(NSString *)stagingRoot
                          completion:(ZONRestoreCompletion)completion;

@end

NS_ASSUME_NONNULL_END
