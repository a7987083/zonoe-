from pathlib import Path

bridge = Path('testmod/ZONServices/ZONUDIDBridge.m')
s = bridge.read_text()

old = r'''#pragma mark - Request

void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;
    if (ZONUDIDBridgeCallbackScheme().length == 0) {
        NSLog(@"[zonoemenu][WARN][udid] zonoe callback scheme unavailable; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    NSString *nonce = ZONUDIDBridgeNewNonce();
    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);
    if (!requestURL) {
        NSLog(@"[zonoemenu][WARN][udid] unable to construct zonoe://udid request; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    ZONUDIDBridgeStart();
    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];
    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];

    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce");
    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (!success) {
            ZONUDIDBridgeClearPendingRequest();
            NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid; using web fallback");
            if (unavailableHandler) unavailableHandler();
        }
    }];
}
'''

new = r'''#pragma mark - Request

static const NSTimeInterval ZONUDIDBridgeOpenRetryDelay = 3.0;

static void ZONUDIDBridgeOpenRequestAttempt(dispatch_block_t _Nullable unavailableHandler,
                                             BOOL allowRetry)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;

    NSString *nonce = ZONUDIDBridgeNewNonce();
    NSURL *requestURL = ZONUDIDBridgeRequestURLForNonce(nonce);
    if (!requestURL) {
        NSLog(@"[zonoemenu][WARN][udid] unable to construct zonoe://udid request; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    [defaults setObject:nonce forKey:ZONUDIDBridgeRequestNonceKey];
    [defaults setDouble:now forKey:ZONUDIDBridgeRequestTimestampKey];

    NSLog(@"[zonoemenu][INFO][udid] requesting UDID through zonoe callback + nonce%@",
          allowRetry ? @"" : @" (retry)");
    [UIApplication.sharedApplication openURL:requestURL
                                     options:@{}
                           completionHandler:^(BOOL success) {
        if (success) return;

        NSString *currentNonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
        if (![currentNonce isEqualToString:nonce]) {
            NSLog(@"[zonoemenu][INFO][udid] ignoring stale zonoe open failure");
            return;
        }

        ZONUDIDBridgeClearPendingRequest();
        if (!allowRetry) {
            NSLog(@"[zonoemenu][WARN][udid] zonoe://udid retry failed; using web fallback");
            if (unavailableHandler) unavailableHandler();
            return;
        }

        NSLog(@"[zonoemenu][WARN][udid] unable to open zonoe://udid; scheduling one retry");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(ZONUDIDBridgeOpenRetryDelay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (ZONUDIDBridgeCurrentUDID().length > 0) return;

            NSString *pendingNonce = [NSUserDefaults.standardUserDefaults stringForKey:ZONUDIDBridgeRequestNonceKey];
            if (ZONUDIDBridgeIsPlausibleNonce(pendingNonce)) {
                NSLog(@"[zonoemenu][INFO][udid] retry skipped because a newer request is pending");
                return;
            }

            ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, NO);
        });
    }];
}

void ZONUDIDBridgeRequestIfNeededWithUnavailableHandler(dispatch_block_t _Nullable unavailableHandler)
{
    if (ZONUDIDBridgeCurrentUDID().length > 0) return;
    if (ZONUDIDBridgeCallbackScheme().length == 0) {
        NSLog(@"[zonoemenu][WARN][udid] zonoe callback scheme unavailable; using fallback");
        if (unavailableHandler) unavailableHandler();
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSTimeInterval previous = [defaults doubleForKey:ZONUDIDBridgeRequestTimestampKey];
    if (previous > 0 && now - previous < 10.0) return;

    ZONUDIDBridgeStart();
    ZONUDIDBridgeOpenRequestAttempt(unavailableHandler, YES);
}
'''

if s.count(old) != 1:
    raise SystemExit(f'P59 request block mismatch: {s.count(old)}')
s = s.replace(old, new, 1)
bridge.write_text(s)

version = Path('VERSION')
v = version.read_text().strip()
if v != 'v1_p58':
    raise SystemExit(f'expected VERSION v1_p58, got {v!r}')
version.write_text('v1_p59\n')

print('P59 transform applied')
