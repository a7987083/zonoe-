#ifndef ZONBootstrap_h
#define ZONBootstrap_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONBootstrapPreflightBlock)(void);
typedef void (^ZONBootstrapReadyBlock)(void);

/// Production bootstrap shared by customer/debug variants.
///
/// Startup is intentionally host-driven:
/// 1. Return quickly from dylib/+load timing without touching host frameworks/UI.
/// 2. After a short delay, wait on the main queue until a usable host UIWindow exists.
/// 3. Run the legacy framework preflight only after UIKit/window readiness.
/// 4. Start the variant-specific entry path, then load explicitly bundled ZONModules.
FOUNDATION_EXPORT void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
                                         ZONBootstrapReadyBlock _Nullable ready);

NS_ASSUME_NONNULL_END

#endif /* ZONBootstrap_h */
