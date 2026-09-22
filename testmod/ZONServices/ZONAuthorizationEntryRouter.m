#import "ZONAuthorizationEntryRouter.h"
#import "../category/getKeychain.h"

@implementation ZONAuthorizationEntrySnapshot
@end

@implementation ZONAuthorizationEntryRouter

+ (ZONAuthorizationEntrySnapshot *)currentSnapshot
{
    ZONAuthorizationEntrySnapshot *snapshot = [ZONAuthorizationEntrySnapshot new];
    snapshot.unlockStatus = [getKeychain getKeychainDataForKey:@"rjyyz"];
    snapshot.activationCode = [getKeychain getKeychainDataForKey:@"ShiSanGeDZKM"];
    snapshot.deviceIdentifier = [getKeychain getKeychainDataForKey:@"DZUDID"];

    NSString *deviceIdentifier = snapshot.deviceIdentifier;
    NSString *activationCode = snapshot.activationCode;
    NSString *unlockStatus = snapshot.unlockStatus;

    if (deviceIdentifier.length < 5) {
        snapshot.mode = ZONAuthorizationEntryModeFirstActivation;
    } else if ([activationCode containsString:@"mg"] ||
               [unlockStatus containsString:@"未查到解锁记录"]) {
        snapshot.mode = ZONAuthorizationEntryModeAdSpeed;
    } else if (deviceIdentifier.length > 16 &&
               [unlockStatus containsString:@"ok"]) {
        snapshot.mode = ZONAuthorizationEntryModeSoftwareSource;
    } else {
        snapshot.mode = ZONAuthorizationEntryModeChooseMethod;
    }

    return snapshot;
}

@end
