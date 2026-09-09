#ifndef ZonoeUDIDAPI_h
#define ZonoeUDIDAPI_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZonoeUDIDCallback)(NSString *udid);

/// 返回当前已缓存且与宿主 callback scheme 匹配的 UDID；没有则返回 nil。
FOUNDATION_EXPORT NSString * _Nullable ZonoeCurrentUDID(void);

/// 普通请求入口。已有有效 UDID 时不会重复请求 zonoe。
FOUNDATION_EXPORT void ZonoeRequestUDID(void);

/// 推荐入口。仅在当前没有有效 UDID 时才发起 zonoe 请求。
FOUNDATION_EXPORT void ZonoeRequestUDIDIfNeeded(void);

/// 显式清除当前缓存并重新获取。仅用于用户/业务主动刷新。
FOUNDATION_EXPORT void ZonoeForceRefreshUDID(void);

/// 设置一次性成功回调。拿到有效 UDID 后调用一次并自动清空回调。
/// 如果设置时已经有有效缓存，会在主线程立即异步回调该缓存值。
FOUNDATION_EXPORT void ZonoeSetUDIDCallback(ZonoeUDIDCallback _Nullable callback);

NS_ASSUME_NONNULL_END

#endif /* ZonoeUDIDAPI_h */
