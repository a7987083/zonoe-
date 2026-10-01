#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONAuthV2Storage : NSObject

/// P79.8b: removes persistence left by older AuthV2 / legacy authorization builds.
/// Menu/runtime preference keys are intentionally not touched.
+ (void)purgeLegacyPersistentState;

/// Session-only values. DZUDID in the legacy Keychain remains the sole long-lived
/// device identifier used by the authorization coordinator. P79.8i adds v3
/// short-lived values here; none are persisted.
+ (nullable NSString *)udid;
+ (void)setUDID:(NSString *)udid;
+ (nullable NSString *)token;
+ (void)setToken:(nullable NSString *)token;
+ (nullable NSString *)authProof;
+ (void)setAuthProof:(nullable NSString *)authProof;
+ (void)clearAuthorizationSession;
+ (void)clearAll;

/// Session-only response/config caches. They deliberately do not survive process exit.
+ (nullable NSDictionary *)lastLicense;
+ (void)setLastLicense:(nullable NSDictionary *)value;
+ (nullable NSDictionary *)lastVerify;
+ (void)setLastVerify:(nullable NSDictionary *)value;
+ (nullable NSDictionary *)lastRuntimeConfig;
+ (void)setLastRuntimeConfig:(nullable NSDictionary *)value;

/// The only AuthV2 NSUserDefaults value intentionally kept across launches: it
/// records which notice has already been presented so the same notice is not repeated.
+ (nullable NSString *)lastNoticeFingerprint;
+ (void)setLastNoticeFingerprint:(nullable NSString *)value;
@end

NS_ASSUME_NONNULL_END
