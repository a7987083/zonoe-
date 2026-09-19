from pathlib import Path

p = Path('testmod/Bsphp/WX_NongShiFu123.mm')
s = p.read_text()

anchor = '- (void)zon_presentAuthorizationNetworkRetry\n{'
assert anchor in s
helper = r'''- (NSDate *)zon_localAuthorizationExpiryForKey:(NSString *)key
{
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (raw.length == 0) return nil;
    NSArray<NSString *> *formats = @[@"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd#HH:mm:ss", @"yyyy-MM-dd HH:mm", @"yyyy-MM-dd"];
    for (NSString *format in formats) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:raw];
        if (date) return date;
    }
    return nil;
}

- (BOOL)zon_hasValidOfflineAuthorizationForMode:(ZONAuthorizationRetryMode)mode
{
    NSString *deviceID = [getKeychain getKeychainDataForKey:@"DZUDID"];
    if (deviceID.length <= 16) return NO;

    NSString *expiryKey = nil;
    if (mode == ZONAuthorizationRetryModeSoftwareSource) {
        NSString *localState = [getKeychain getKeychainDataForKey:@"rjyyz"];
        if (![localState isEqualToString:@"ok"]) return NO;
        expiryKey = @"解锁码到期时间";
    } else if (mode == ZONAuthorizationRetryModeAdSpeed) {
        NSString *card = [getKeychain getKeychainDataForKey:@"ShiSanGeDZKM"];
        if (card.length <= 34) return NO;
        expiryKey = @"到期时间";
    } else {
        return NO;
    }

    NSDate *expiry = [self zon_localAuthorizationExpiryForKey:expiryKey];
    return expiry && [expiry timeIntervalSinceNow] > 0;
}

- (ZONAuthorizationRetryMode)zon_validOfflineAuthorizationMode
{
    // Prefer software-source entitlement when both legacy records exist.
    if ([self zon_hasValidOfflineAuthorizationForMode:ZONAuthorizationRetryModeSoftwareSource]) {
        return ZONAuthorizationRetryModeSoftwareSource;
    }
    if ([self zon_hasValidOfflineAuthorizationForMode:ZONAuthorizationRetryModeAdSpeed]) {
        return ZONAuthorizationRetryModeAdSpeed;
    }
    return ZONAuthorizationRetryModeUnknown;
}

- (void)zon_activateOfflineAuthorizationForMode:(ZONAuthorizationRetryMode)mode
{
    验证状态 = YES;
    gZONAuthorizationRetryMode = mode;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];
        NSString *text = (mode == ZONAuthorizationRetryModeSoftwareSource) ? @"离线模式\n软件源授权有效" : @"离线模式\n秒过广告授权有效";
        [presenter presentWithText:text dismissAfterDelay:5 includedStyle:JDStatusBarNotificationIncludedStyleSuccess];
        [NSObject 显示图标];
    });
}

'''
s = s.replace(anchor, helper + anchor, 1)

# Critical fix over P63: resolve offline entitlement before legacy kmm/rjyyz routing.
needle = '''    设备特征码=[getKeychain getKeychainDataForKey:@"DZUDID"];\n'''
insert = needle + '''\n    if (![self getNet]) {\n        ZONAuthorizationRetryMode offlineMode = [self zon_validOfflineAuthorizationMode];\n        if (offlineMode != ZONAuthorizationRetryModeUnknown) {\n            [self zon_activateOfflineAuthorizationForMode:offlineMode];\n            return;\n        }\n    }\n'''
assert s.count(needle) >= 1
s = s.replace(needle, insert, 1)

p.write_text(s)
