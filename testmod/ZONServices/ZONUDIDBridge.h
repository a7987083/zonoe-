#ifndef ZONUDIDBridge_h
#define ZONUDIDBridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN

#define ZONUDID_BRIDGE_HIDDEN __attribute__((visibility("hidden")))

FOUNDATION_EXPORT NSString * const ZONUDIDBridgeValueKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeSchemeKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeRequestTimestampKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeRequestNonceKey ZONUDID_BRIDGE_HIDDEN;
FOUNDATION_EXPORT NSString * const ZONUDIDBridgeDidUpdateNotification ZONUDID_BRIDGE_HIDDEN;
extern const uint16_t ZONUDIDBridgePort ZONUDID_BRIDGE_HIDDEN;

NSString * _Nullable ZONUDIDBridgeCallbackScheme(void) ZONUDID_BRIDGE_HIDDEN;
NSString *ZONUDIDBridgeCallbackHost(void) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeCallbackURL(void) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeIsPlausibleNonce(NSString *value) ZONUDID_BRIDGE_HIDDEN;
NSString *ZONUDIDBridgeNewNonce(void) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeRequestURLForNonce(NSString *nonce) ZONUDID_BRIDGE_HIDDEN;
NSURL * _Nullable ZONUDIDBridgeRequestURL(void) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeIsPlausibleUDID(NSString *value) ZONUDID_BRIDGE_HIDDEN;
NSString * _Nullable ZONUDIDBridgeCurrentUDID(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeClearPendingRequest(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeStoreUDID(NSString *udid) ZONUDID_BRIDGE_HIDDEN;
BOOL ZONUDIDBridgeHandleURL(NSURL *url) ZONUDID_BRIDGE_HIDDEN;
NSDictionary * _Nullable ZONUDIDBridgeFetchLocalResultOnce(NSString *nonce) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeFetchPendingResult(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeStart(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeRequestIfNeeded(void) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeForceRefreshWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler) ZONUDID_BRIDGE_HIDDEN;
void ZONUDIDBridgeForceRefresh(void) ZONUDID_BRIDGE_HIDDEN;

#undef ZONUDID_BRIDGE_HIDDEN

NS_ASSUME_NONNULL_END

#endif /* ZONUDIDBridge_h */
