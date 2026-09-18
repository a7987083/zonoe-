from pathlib import Path

src = Path('testmod/ZONServices/ZONUDIDBridge.m').read_text()
version = Path('VERSION').read_text().strip()

assert version == 'v1_p59', version

required = [
    'static const NSTimeInterval ZONUDIDBridgeOpenRetryDelay = 3.0;',
    'static void ZONUDIDBridgeOpenRequestAttempt',
    'BOOL allowRetry',
    'NSString *nonce = ZONUDIDBridgeNewNonce();',
    'NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);',
    '[defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];',
    '[UIApplication.sharedApplication openURL:requestURL',
    'if (success) return;',
    'if (![currentNonce isEqualToString:nonce])',
    'ZONUDIDBridgeClearPendingRequest();',
    'if (!allowRetry)',
    'zonoe://udid retry failed; using web fallback',
    'scheduling one retry',
    'dispatch_after(dispatch_time(DISPATCH_TIME_NOW,',
    'if (ZONUDIDBridgeCurrentUDID().length > 0) return;',
    'if (ZONUDIDBridgeIsPlausibleNonce(pendingNonce))',
    'retry skipped because a newer request is pending',
    'ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, NO);',
    'ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, YES);',
    'ZONUDIDBridgeFetchPendingResult();',
    'BOOL ZONUDIDBridgeHandleURL(NSURL *url)',
]
for token in required:
    assert token in src, token

# Retry must be strictly bounded: one initial invocation and one retry invocation.
assert src.count('ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, NO);') == 1
assert src.count('ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, YES);') == 1

# Existing request throttle remains on initial requests only.
assert 'if (previous > 0 && now - previous < 10.0) return;' in src

# First open failure must not immediately fall back; fallback is in the non-retry branch.
helper_start = src.index('static void ZONUDIDBridgeOpenRequestAttempt')
public_start = src.index('void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler')
helper = src[helper_start:public_start]
assert helper.index('if (!allowRetry)') < helper.index('scheduling one retry')
assert helper.count('if (unavailableHandler) unavailableHandler();') == 2  # URL construction failure + second-open failure

print('P59 UDID open retry contract PASS')
