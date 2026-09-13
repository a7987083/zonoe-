#ifndef ZONBootstrap_h
#define ZONBootstrap_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONBootstrapPreflightBlock)(void);
typedef void (^ZONBootstrapReadyBlock)(void);

/// Production bootstrap shared by customer/debug variants.
///
/// Order is deliberately stable:
/// 1. Run legacy framework preflight synchronously at +load timing.
/// 2. Hop to the main queue for the variant-specific entry path.
/// 3. Load explicitly bundled ZONModules after the entry path has been started.
FOUNDATION_EXPORT void ZONBootstrapStart(ZONBootstrapPreflightBlock _Nullable preflight,
                                         ZONBootstrapReadyBlock _Nullable ready);

NS_ASSUME_NONNULL_END

#endif /* ZONBootstrap_h */
