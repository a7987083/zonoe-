#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONAuthorizationEntryMode) {
    ZONAuthorizationEntryModeFirstActivation = 0,
    ZONAuthorizationEntryModeAdSpeed = 1,
    ZONAuthorizationEntryModeSoftwareSource = 2,
    ZONAuthorizationEntryModeChooseMethod = 3,
};

@interface ZONAuthorizationEntrySnapshot : NSObject
@property (nonatomic, copy, nullable) NSString *unlockStatus;
@property (nonatomic, copy, nullable) NSString *activationCode;
@property (nonatomic, copy, nullable) NSString *deviceIdentifier;
@property (nonatomic, assign) ZONAuthorizationEntryMode mode;
@end

@interface ZONAuthorizationEntryRouter : NSObject
+ (ZONAuthorizationEntrySnapshot *)currentSnapshot;
@end

NS_ASSUME_NONNULL_END
