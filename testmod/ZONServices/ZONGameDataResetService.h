#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONGameDataResetStage) {
    ZONGameDataResetStagePreparing = 0,
    ZONGameDataResetStageDocuments,
    ZONGameDataResetStageLibrary,
    ZONGameDataResetStageTemporary,
    ZONGameDataResetStagePreferences,
    ZONGameDataResetStageVerification,
    ZONGameDataResetStageCompleted,
};

typedef void (^ZONGameDataResetProgressHandler)(ZONGameDataResetStage stage);

/// Resets the primary app data container toward a first-launch state.
///
/// Scope:
/// - clears Documents contents
/// - clears Library contents
/// - clears tmp contents
/// - clears the app NSUserDefaults persistent domain
///
/// Explicitly out of scope:
/// - Keychain / authorization storage
/// - App Group containers
/// - iCloud / CloudKit remote data
///
/// The operation is synchronous. Call it from a background queue.
@interface ZONGameDataResetService : NSObject

+ (BOOL)resetGameDataWithProgress:(nullable ZONGameDataResetProgressHandler)progress
                            error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
