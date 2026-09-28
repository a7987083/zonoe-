#import "ZONAuthV2Verify.h"
#import "ZONAuthV2API.h"
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <dlfcn.h>

#ifndef ZON_VERIFY_SECRET
#define ZON_VERIFY_SECRET "ZON_VERIFY_SECRET_PLACEHOLDER_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#endif
#ifndef ZON_DYLIB_VERSION
#define ZON_DYLIB_VERSION ""
#endif
#ifndef ZON_DYLIB_BUILD
#define ZON_DYLIB_BUILD ""
#endif
#ifndef ZON_AUTH_BOOTSTRAP_DYLIB_KEY
#define ZON_AUTH_BOOTSTRAP_DYLIB_KEY "zonoe.main"
#endif

static NSError *ZONV2Error(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"ZONAuthV2" code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"验证错误"}];
}

static NSString *ZONStringValue(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value isKindOfClass:NSNumber.class]) return [(NSNumber *)value stringValue];
    return @"";
}

static id ZONConfigValue(NSDictionary *config, NSString *key) {
    id v = config[key];
    if (v && v != NSNull.null) return v;
    for (NSString *containerKey in @[@"data", @"config", @"runtime", @"result"]) {
        NSDictionary *nested = [config[containerKey] isKindOfClass:NSDictionary.class] ? config[containerKey] : nil;
        v = nested[key];
        if (v && v != NSNull.null) return v;
    }
    return nil;
}

static NSString *ZONMainMachOUUID(void) {
    const struct mach_header *header = _dyld_get_image_header(0);
    if (!header) return @"";
    BOOL is64 = (header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64);
    uintptr_t cursor = (uintptr_t)header + (is64 ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command *cmd = (const struct load_command *)cursor;
        if (cmd->cmd == LC_UUID && cmd->cmdsize >= sizeof(struct uuid_command)) {
            const struct uuid_command *uuidCmd = (const struct uuid_command *)cmd;
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:uuidCmd->uuid];
            return uuid.UUIDString ?: @"";
        }
        cursor += cmd->cmdsize;
    }
    return @"";
}

static NSString *ZONDylibPath(void) {
    Dl_info info = {0};
    if (dladdr((const void *)&ZONDylibPath, &info) != 0 && info.dli_fname) {
        return [NSString stringWithUTF8String:info.dli_fname] ?: @"";
    }
    return @"";
}

static NSString *ZONSHA256ForFile(NSString *path) {
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
    if (!stream) return @"";
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    [stream open];
    uint8_t buffer[64 * 1024];
    NSInteger n = 0;
    while ((n = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
        CC_SHA256_Update(&ctx, buffer, (CC_LONG)n);
    }
    [stream close];
    if (n < 0) return @"";
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    return hex;
}

static NSString *ZONNonce(void) {
    uint8_t bytes[24];
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof(bytes), bytes) != errSecSuccess) {
        return NSUUID.UUID.UUIDString.lowercaseString;
    }
    NSMutableString *s = [NSMutableString stringWithCapacity:sizeof(bytes) * 2];
    for (NSUInteger i = 0; i < sizeof(bytes); i++) [s appendFormat:@"%02x", bytes[i]];
    return s;
}

static NSString *ZONHMAC(NSString *canonical, NSString *secret) {
    NSData *keyData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [canonical dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, data.bytes, data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    return hex;
}

@implementation ZONAuthV2Verify

+ (instancetype)sharedVerifier {
    static ZONAuthV2Verify *v;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ v = [ZONAuthV2Verify new]; });
    return v;
}

- (void)verifyUDID:(NSString *)udid runtimeConfig:(NSDictionary *)runtimeConfig completion:(ZONAuthV2VerifyCompletion)completion {
    NSString *secret = @ZON_VERIFY_SECRET;
    if (!secret.length || [secret containsString:@"PLACEHOLDER"]) {
        if (completion) completion(nil, ZONV2Error(-20, @"Verify Secret 未配置"));
        return;
    }

    NSBundle *bundle = NSBundle.mainBundle;
    NSString *bundleID = bundle.bundleIdentifier ?: @"";
    NSString *appExecutable = ZONStringValue([bundle objectForInfoDictionaryKey:@"CFBundleExecutable"]);
    NSString *appVersion = ZONStringValue([bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
    NSString *appBuild = ZONStringValue([bundle objectForInfoDictionaryKey:@"CFBundleVersion"]);
    NSString *appUUID = ZONMainMachOUUID();

    NSString *dylibKey = ZONStringValue(ZONConfigValue(runtimeConfig, @"dylib_key"));
    if (!dylibKey.length) dylibKey = @ZON_AUTH_BOOTSTRAP_DYLIB_KEY;
    NSString *dylibVersion = ZONStringValue(ZONConfigValue(runtimeConfig, @"dylib_version"));
    if (!dylibVersion.length) dylibVersion = @ZON_DYLIB_VERSION;
    NSString *dylibBuild = ZONStringValue(ZONConfigValue(runtimeConfig, @"dylib_build"));
    if (!dylibBuild.length) dylibBuild = @ZON_DYLIB_BUILD;
    if (!dylibVersion.length) {
        if (completion) completion(nil, ZONV2Error(-21, @"服务器未返回 dylib_version，且构建未注入版本"));
        return;
    }

    NSString *dylibSHA = ZONSHA256ForFile(ZONDylibPath());
    NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)NSDate.date.timeIntervalSince1970];
    NSString *nonce = ZONNonce();
    NSString *protocolVersion = @"2";

    NSArray<NSString *> *canonicalFields = @[
        udid ?: @"", bundleID, dylibKey, dylibVersion, dylibBuild ?: @"", dylibSHA ?: @"",
        timestamp, nonce, protocolVersion, appExecutable, appUUID, appVersion, appBuild
    ];
    NSString *canonical = [canonicalFields componentsJoinedByString:@"\n"];
    NSString *signature = ZONHMAC(canonical, secret);

    NSDictionary *body = @{
        @"udid": udid ?: @"",
        @"bundle_id": bundleID,
        @"dylib_key": dylibKey,
        @"dylib_version": dylibVersion,
        @"dylib_build": dylibBuild ?: @"",
        @"dylib_sha256": dylibSHA ?: @"",
        @"timestamp": @([timestamp longLongValue]),
        @"nonce": nonce,
        @"signature": signature,
        @"protocol_version": @2,
        @"app_executable": appExecutable,
        @"app_macho_uuid": appUUID,
        @"app_version": appVersion,
        @"app_build": appBuild
    };

    [[ZONAuthV2API sharedAPI] postVerifyBody:body runtimeConfig:runtimeConfig completion:completion];
}

@end
