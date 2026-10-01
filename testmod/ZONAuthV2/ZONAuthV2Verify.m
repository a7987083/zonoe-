#import "ZONAuthV2Verify.h"
#import "ZONAuthV2Storage.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#ifndef ZON_DYLIB_VERSION
#define ZON_DYLIB_VERSION "1"
#endif
#ifndef ZON_DYLIB_BUILD
#define ZON_DYLIB_BUILD ""
#endif
#ifndef ZON_AUTH_BOOTSTRAP_DYLIB_KEY
#define ZON_AUTH_BOOTSTRAP_DYLIB_KEY "zonoe.main"
#endif

static NSString * const ZONVerifyServerKeyID = @"2ccbccb450ac8ee98c240dee77ce075e";
static NSString * const ZONVerifyServerPublicKeyPEM = @"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArTZEp5LgTmnwihvhlpqr\ny9W1ahmt0eQD3b6oQCM+Dq+cDmvO92APQzr3GBRxh4xBpK4JJOluWXs7xfCMLXkb\nUsukmePqe/kOb4VDhEGiGqojKOfp4DMP/kdYmZ5TIL/RcvnvqInyiCWf9R4ifMnI\nkOQFmWqHPxjoxaLfxDd93NPZwEeX5fcP/w2xze2Y1v4B+ITw8zHwL9pHjhZ2J/9s\nAfNoB5u3Bm+HGqtao9NrORU1ooXsV6YLhTP48we+ZkEF52C79Spf3prlSWnwl6mi\n/mtT8e1O6XEzIKaSd33KoODSDgwPUYhjRX5wsX9bbgmFOXdvQr+TNnMtMsJHYbl4\njwIDAQAB\n-----END PUBLIC KEY-----\n";

static void ZONVerifyImageAnchor(void) {}

static NSString *ZONString(id value) {
    return [value isKindOfClass:NSString.class] ? value : @"";
}

static NSError *ZONVerifyError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"ZONAuthV3" code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"Verify v3 failed"}];
}

static BOOL ZONReadDERLength(NSData *data, NSUInteger *offset, NSUInteger *length) {
    if (!data || !offset || !length || *offset >= data.length) return NO;
    const uint8_t *bytes = data.bytes;
    uint8_t first = bytes[(*offset)++];
    if ((first & 0x80) == 0) {
        *length = first;
        return *offset + *length <= data.length;
    }
    NSUInteger count = first & 0x7f;
    if (count == 0 || count > sizeof(NSUInteger) || *offset + count > data.length) return NO;
    NSUInteger value = 0;
    for (NSUInteger i = 0; i < count; i++) value = (value << 8) | bytes[(*offset)++];
    *length = value;
    return *offset + *length <= data.length;
}

@interface ZONAuthV2Verify ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation ZONAuthV2Verify

+ (instancetype)sharedVerifier {
    static ZONAuthV2Verify *verifier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        verifier = [ZONAuthV2Verify new];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.timeoutIntervalForRequest = 10.0;
        configuration.timeoutIntervalForResource = 15.0;
        verifier.session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return verifier;
}

- (void)verifyUDID:(NSString *)udid
     runtimeConfig:(NSDictionary *)runtimeConfig
        completion:(ZONAuthV2VerifyCompletion)completion {
    if (!completion) return;
    if (udid.length < 5) {
        completion(nil, ZONVerifyError(-100, @"UDID unavailable"));
        return;
    }

    NSDictionary *config = [runtimeConfig[@"config"] isKindOfClass:NSDictionary.class] ? runtimeConfig[@"config"] : runtimeConfig;
    if (![self validateRuntimeConfig:config]) {
        completion(@{@"ok": @NO, @"code": @"runtime_config_invalid", @"action": @"disable_feature", @"message": @"Runtime Config signature validation failed"}, nil);
        return;
    }

    NSURL *verifyURL = [self verifyURLFromRuntimeConfig:config];
    NSURL *challengeURL = [self challengeURLFromVerifyURL:verifyURL];
    if (!verifyURL || !challengeURL) {
        completion(@{@"ok": @NO, @"code": @"client_config_invalid", @"action": @"disable_feature", @"message": @"Verify endpoint unavailable"}, nil);
        return;
    }

    NSString *authProof = [ZONAuthV2Storage authProof] ?: @"";
    if (!authProof.length) {
        completion(@{@"ok": @NO, @"code": @"auth_proof_unavailable", @"action": @"block", @"message": @"Authorization proof unavailable"}, nil);
        return;
    }

    SecKeyRef privateKey = [self devicePrivateKey];
    if (!privateKey) {
        completion(@{@"ok": @NO, @"code": @"device_key_unavailable", @"action": @"block", @"message": @"Unable to create device key"}, nil);
        return;
    }
    NSString *publicPEM = [self publicKeyPEMForPrivateKey:privateKey];
    CFRelease(privateKey);
    if (!publicPEM.length) {
        completion(@{@"ok": @NO, @"code": @"device_key_unavailable", @"action": @"block", @"message": @"Unable to export device public key"}, nil);
        return;
    }

    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier ?: @"";
    NSString *executable = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] ?: @"";
    NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *appBuild = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"";
    NSString *appUUID = [self currentAppMachOUUID];
    if (!bundleID.length || !executable.length || !appUUID.length) {
        completion(@{@"ok": @NO, @"code": @"app_identity_unavailable", @"action": @"block", @"message": @"App identity unavailable"}, nil);
        return;
    }

    NSDictionary *context = @{
        @"udid": udid,
        @"bundle_id": bundleID,
        @"dylib_key": @ZON_AUTH_BOOTSTRAP_DYLIB_KEY,
        @"dylib_version": @ZON_DYLIB_VERSION,
        @"dylib_build": @ZON_DYLIB_BUILD,
        @"dylib_sha256": [self currentDylibSHA256] ?: @"",
        @"app_executable": executable,
        @"app_macho_uuid": appUUID,
        @"app_version": appVersion,
        @"app_build": appBuild,
        @"device_public_key": publicPEM,
    };

    NSDictionary *challengePayload = @{
        @"udid": udid,
        @"dylib_key": @ZON_AUTH_BOOTSTRAP_DYLIB_KEY,
        @"device_public_key": publicPEM,
        @"auth_proof": authProof,
    };

    __weak typeof(self) weakSelf = self;
    [self postJSON:challengePayload URL:challengeURL completion:^(NSDictionary *challengeJSON, NSError *challengeError) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (challengeError || !challengeJSON) {
            completion(nil, challengeError ?: ZONVerifyError(-101, @"Challenge unavailable"));
            return;
        }
        if (![challengeJSON[@"ok"] boolValue]) {
            completion(challengeJSON, nil);
            return;
        }

        NSString *challengeID = ZONString(challengeJSON[@"challenge_id"]);
        NSString *challenge = ZONString(challengeJSON[@"challenge"]);
        if (!challengeID.length || !challenge.length) {
            completion(@{@"ok": @NO, @"code": @"challenge_invalid", @"action": @"block", @"message": @"Invalid challenge response"}, nil);
            return;
        }

        // auth_proof is short-lived and only authorizes creation of this challenge.
        // Once the server accepted the challenge request, never reuse the proof locally.
        [ZONAuthV2Storage setAuthProof:nil];

        NSMutableDictionary *payload = [context mutableCopy];
        payload[@"protocol_version"] = @3;
        payload[@"challenge_id"] = challengeID;
        payload[@"challenge"] = challenge;

        SecKeyRef signingKey = [self devicePrivateKey];
        if (!signingKey) {
            completion(@{@"ok": @NO, @"code": @"device_key_unavailable", @"action": @"block", @"message": @"Device key unavailable"}, nil);
            return;
        }
        NSData *signature = [self signatureForString:[self canonicalProof:payload] privateKey:signingKey];
        CFRelease(signingKey);
        if (!signature.length) {
            completion(@{@"ok": @NO, @"code": @"device_signature_failed", @"action": @"block", @"message": @"Unable to sign challenge"}, nil);
            return;
        }
        payload[@"device_signature"] = [signature base64EncodedStringWithOptions:0];

        [self submitVerifyPayload:payload URL:verifyURL completion:completion];
    }];
}

- (void)submitVerifyPayload:(NSDictionary *)payload URL:(NSURL *)verifyURL completion:(ZONAuthV2VerifyCompletion)completion {
    [self postJSON:payload URL:verifyURL completion:^(NSDictionary *response, NSError *verifyError) {
        if (verifyError || !response) {
            completion(nil, verifyError ?: ZONVerifyError(-102, @"Verify service unavailable"));
            return;
        }
        NSString *token = ZONString(response[@"token"]);
        if ([response[@"ok"] boolValue] && token.length) {
            [ZONAuthV2Storage setToken:token];
        } else if (![response[@"ok"] boolValue]) {
            [ZONAuthV2Storage setToken:nil];
        }
        completion(response, nil);
    }];
}

#pragma mark - Runtime Config signature

- (NSURL *)verifyURLFromRuntimeConfig:(NSDictionary *)config {
    NSArray *endpoints = [config[@"api_endpoints"] isKindOfClass:NSArray.class] ? config[@"api_endpoints"] : @[];
    NSString *path = ZONString(config[@"verify_path"]);
    if (!path.length) path = @"/index/dylib_verify/verify";
    NSString *base = [endpoints.firstObject isKindOfClass:NSString.class] ? endpoints.firstObject : @"";
    if (!base.length) return [NSURL URLWithString:@"https://app3.zonoeios.xyz/index/dylib_verify/verify"];
    while ([base hasSuffix:@"/"]) base = [base substringToIndex:base.length - 1];
    NSString *normalizedPath = [path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path];
    return [NSURL URLWithString:[base stringByAppendingString:normalizedPath]];
}

- (NSURL *)challengeURLFromVerifyURL:(NSURL *)verifyURL {
    NSString *absolute = verifyURL.absoluteString ?: @"";
    NSRange range = [absolute rangeOfString:@"/verify" options:NSBackwardsSearch];
    if (range.location == NSNotFound) return nil;
    return [NSURL URLWithString:[absolute stringByReplacingCharactersInRange:range withString:@"/challenge"]];
}

- (BOOL)validateRuntimeConfig:(NSDictionary *)config {
    if (![config isKindOfClass:NSDictionary.class] || ![config[@"ok"] boolValue]) return NO;
    NSArray *apis = [config[@"api_endpoints"] isKindOfClass:NSArray.class] ? config[@"api_endpoints"] : nil;
    NSArray *bootstraps = [config[@"bootstrap_urls"] isKindOfClass:NSArray.class] ? config[@"bootstrap_urls"] : nil;
    NSString *path = ZONString(config[@"verify_path"]);
    NSString *signature = ZONString(config[@"signature"]);
    NSString *algorithm = ZONString(config[@"signature_alg"]);
    NSString *keyID = ZONString(config[@"key_id"]);
    NSInteger version = [config[@"config_version"] integerValue];
    NSTimeInterval expires = [config[@"expires_at"] doubleValue];
    if (!apis || !bootstraps || !path.length || !signature.length || version < 3 || expires <= NSDate.date.timeIntervalSince1970) return NO;
    if (![algorithm isEqualToString:@"rsa-2048-sha256"] || ![keyID isEqualToString:ZONVerifyServerKeyID]) return NO;

    NSString *canonical = [@[ [NSString stringWithFormat:@"%ld", (long)version],
                               [apis componentsJoinedByString:@","],
                               [bootstraps componentsJoinedByString:@","],
                               path,
                               [NSString stringWithFormat:@"%ld", (long)((NSInteger)expires)] ] componentsJoinedByString:@"\n"];
    NSData *signatureData = [[NSData alloc] initWithBase64EncodedString:signature options:0];
    SecKeyRef key = [self serverPublicKey];
    if (!signatureData.length || !key) {
        if (key) CFRelease(key);
        return NO;
    }
    NSData *message = [canonical dataUsingEncoding:NSUTF8StringEncoding];
    BOOL valid = SecKeyVerifySignature(key,
                                       kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256,
                                       (__bridge CFDataRef)message,
                                       (__bridge CFDataRef)signatureData,
                                       NULL);
    CFRelease(key);
    return valid;
}

- (NSData *)rsaPKCS1FromSPKI:(NSData *)spki {
    if (spki.length < 16) return nil;
    const uint8_t *bytes = spki.bytes;
    NSUInteger offset = 0, length = 0;
    if (bytes[offset++] != 0x30 || !ZONReadDERLength(spki, &offset, &length)) return nil;
    if (offset >= spki.length || bytes[offset++] != 0x30 || !ZONReadDERLength(spki, &offset, &length) || offset + length > spki.length) return nil;
    offset += length;
    if (offset >= spki.length || bytes[offset++] != 0x03 || !ZONReadDERLength(spki, &offset, &length) || length < 2 || offset + length > spki.length) return nil;
    if (bytes[offset] != 0x00) return nil;
    offset++;
    length--;
    if (offset + length > spki.length) return nil;
    return [spki subdataWithRange:NSMakeRange(offset, length)];
}

- (SecKeyRef)serverPublicKey {
    NSString *body = [ZONVerifyServerPublicKeyPEM stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
    body = [body stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
    body = [[body componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
    NSData *spki = [[NSData alloc] initWithBase64EncodedString:body options:0];
    NSData *pkcs1 = [self rsaPKCS1FromSPKI:spki];
    if (!pkcs1.length) return NULL;
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic,
        (__bridge id)kSecAttrKeySizeInBits:@2048,
    };
    return SecKeyCreateWithData((__bridge CFDataRef)pkcs1, (__bridge CFDictionaryRef)attributes, NULL);
}

#pragma mark - Device proof

- (NSString *)canonicalProof:(NSDictionary *)payload {
    return [@[ @"zonoe-dylib-auth-v3",
               payload[@"challenge_id"] ?: @"",
               payload[@"challenge"] ?: @"",
               payload[@"udid"] ?: @"",
               payload[@"bundle_id"] ?: @"",
               payload[@"dylib_key"] ?: @"",
               payload[@"dylib_version"] ?: @"",
               payload[@"dylib_build"] ?: @"",
               [payload[@"dylib_sha256"] lowercaseString] ?: @"",
               payload[@"app_executable"] ?: @"",
               [payload[@"app_macho_uuid"] uppercaseString] ?: @"",
               payload[@"app_version"] ?: @"",
               payload[@"app_build"] ?: @"" ] componentsJoinedByString:@"\n"];
}

- (SecKeyRef)devicePrivateKey {
    NSData *tag = [@"xyz.zonoe.dylib-auth.zonoe.main" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass:(__bridge id)kSecClassKey,
        (__bridge id)kSecAttrApplicationTag:tag,
        (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecReturnRef:@YES,
    };
    SecKeyRef key = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&key);
    if (status == errSecSuccess && key) return key;

    NSDictionary *privateAttributes = @{
        (__bridge id)kSecAttrIsPermanent:@YES,
        (__bridge id)kSecAttrApplicationTag:tag,
        (__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    };
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeySizeInBits:@256,
        (__bridge id)kSecPrivateKeyAttrs:privateAttributes,
    };
    return SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, NULL);
}

- (NSString *)publicKeyPEMForPrivateKey:(SecKeyRef)privateKey {
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
    if (!publicKey) return @"";
    CFErrorRef error = NULL;
    CFDataRef rawRef = SecKeyCopyExternalRepresentation(publicKey, &error);
    CFRelease(publicKey);
    if (!rawRef) {
        if (error) CFRelease(error);
        return @"";
    }
    NSData *raw = CFBridgingRelease(rawRef);
    const unsigned char prefixBytes[] = {
        0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,
        0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00
    };
    NSMutableData *spki = [NSMutableData dataWithBytes:prefixBytes length:sizeof(prefixBytes)];
    [spki appendData:raw];
    NSString *base64 = [spki base64EncodedStringWithOptions:0];
    NSMutableString *lines = [NSMutableString string];
    for (NSUInteger i = 0; i < base64.length; i += 64) {
        [lines appendFormat:@"%@\n", [base64 substringWithRange:NSMakeRange(i, MIN((NSUInteger)64, base64.length - i))]];
    }
    return [NSString stringWithFormat:@"-----BEGIN PUBLIC KEY-----\n%@-----END PUBLIC KEY-----\n", lines];
}

- (NSData *)signatureForString:(NSString *)string privateKey:(SecKeyRef)privateKey {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    CFErrorRef error = NULL;
    CFDataRef signature = SecKeyCreateSignature(privateKey,
                                                kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                                (__bridge CFDataRef)data,
                                                &error);
    if (!signature) {
        if (error) CFRelease(error);
        return nil;
    }
    return CFBridgingRelease(signature);
}

#pragma mark - Identity / integrity

- (NSString *)currentDylibSHA256 {
    Dl_info info;
    if (dladdr((const void *)&ZONVerifyImageAnchor, &info) == 0 || !info.dli_fname) return @"";
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[NSString stringWithUTF8String:info.dli_fname]];
    [stream open];
    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    uint8_t buffer[64 * 1024];
    NSInteger read = 0;
    while ((read = [stream read:buffer maxLength:sizeof(buffer)]) > 0) CC_SHA256_Update(&context, buffer, (CC_LONG)read);
    [stream close];
    if (read < 0) return @"";
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &context);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    return hex;
}

- (NSString *)currentAppMachOUUID {
    const struct mach_header *header = _dyld_get_image_header(0);
    if (!header) return @"";
    BOOL is64 = (header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64);
    uintptr_t cursor = (uintptr_t)header + (is64 ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command *command = (const struct load_command *)cursor;
        if (!command || command->cmdsize < sizeof(struct load_command)) break;
        if ((command->cmd & 0x7fffffff) == LC_UUID && command->cmdsize >= sizeof(struct uuid_command)) {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)command;
            const uint8_t *u = uuidCommand->uuid;
            return [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                    u[0],u[1],u[2],u[3],u[4],u[5],u[6],u[7],u[8],u[9],u[10],u[11],u[12],u[13],u[14],u[15]];
        }
        cursor += command->cmdsize;
    }
    return @"";
}

#pragma mark - HTTP

- (void)postJSON:(NSDictionary *)json URL:(NSURL *)url completion:(void (^)(NSDictionary *response, NSError *error))completion {
    NSError *encodeError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:0 error:&encodeError];
    if (!body) {
        completion(nil, encodeError);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        NSError *jsonError = nil;
        id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError] : nil;
        NSDictionary *decoded = [object isKindOfClass:NSDictionary.class] ? object : nil;
        if (error) {
            completion(decoded, error);
            return;
        }
        if (!decoded) {
            completion(nil, jsonError ?: ZONVerifyError(http.statusCode ?: -103, @"Server returned invalid JSON"));
            return;
        }
        if (http.statusCode < 200 || http.statusCode >= 300) {
            NSString *message = ZONString(decoded[@"message"]);
            completion(decoded, ZONVerifyError(http.statusCode, message.length ? message : @"Verify HTTP failure"));
            return;
        }
        completion(decoded, nil);
    }] resume];
}

@end
