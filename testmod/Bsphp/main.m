//static __attribute__((constructor)) void _logosLocalInit(void) {
//    NSLog(@"load1111111111");
//    [[WX_NongShiFu123 alloc] BSPHP];
//}
#import "WX_NongShiFu123.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "daochucd.h"
#import "getKeychain.h"

#import <UIKit/UIKit.h>
#import "JDStatusBarNotification.h"
#import "NSObject+UI.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "../category/wyURLProtocol.h"
#import "../ZONBootstrap/ZONBootstrap.h"
#import "../ZONServices/ZonoeUDIDAPI.h"

#ifndef ZON_BUILD_VARIANT_DEBUG
#define ZON_BUILD_VARIANT_DEBUG 0
#endif

#pragma mark - v1_p33 hot-update URL capture (B_debug only)

static NSString * const ZONHotUpdateHandledKey = @"zonoe.hotupdate.handled";
static const NSUInteger ZONHotUpdateBodyCaptureLimit = 512 * 1024;

static dispatch_queue_t ZONHotUpdateLogQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.zonoe.hotupdate.capture", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSMutableSet<NSString *> *ZONHotUpdateSeenKeys(void)
{
    static NSMutableSet<NSString *> *seen;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        seen = [NSMutableSet set];
    });
    return seen;
}

static NSString *ZONHotUpdateLogPath(void)
{
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                   NSUserDomainMask,
                                                                   YES).firstObject;
        if (documents.length == 0) {
            documents = NSTemporaryDirectory();
        }
        NSString *directory = [documents stringByAppendingPathComponent:@"ZONHotUpdate"];
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        path = [directory stringByAppendingPathComponent:@"urls.log"];
    });
    return path;
}

static BOOL ZONLooksLikeHotUpdateURL(NSURL *url)
{
    NSString *value = url.absoluteString.lowercaseString;
    if (value.length == 0) return NO;

    NSArray<NSString *> *tokens = @[
        @"hotupdate", @"hot_update", @"res_update", @"update", @"patch",
        @"version", @"manifest", @"assetbundle", @"bundle", @"bundlesbuild",
        @"resource", @"/res/", @"cdn", @"download",
        @".zip", @".json", @".cfg", @".plist", @".bytes", @".dat"
    ];
    for (NSString *token in tokens) {
        if ([value containsString:token]) return YES;
    }
    return NO;
}

static void ZONAppendHotUpdateLine(NSString *line)
{
    NSString *path = ZONHotUpdateLogPath();
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (path.length == 0 || data.length == 0) return;

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [data writeToFile:path atomically:YES];
        return;
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) return;
    [handle seekToEndOfFile];
    [handle writeData:data];
    [handle closeFile];
}

static void ZONRecordHotUpdateURL(NSString *kind, NSURL *url, NSString *extra)
{
    NSString *value = url.absoluteString;
    if (value.length == 0) return;

    BOOL hot = ZONLooksLikeHotUpdateURL(url);
    NSString *key = [NSString stringWithFormat:@"%@|%@|%@", kind ?: @"", value, extra ?: @""];

    dispatch_async(ZONHotUpdateLogQueue(), ^{
        NSMutableSet<NSString *> *seen = ZONHotUpdateSeenKeys();
        if ([seen containsObject:key]) return;
        [seen addObject:key];

        NSString *tag = hot ? @"HOT" : @"NET";
        NSString *line = [NSString stringWithFormat:@"%@ [%@] [%@] %@%@%@\n",
                          [NSDate date],
                          tag,
                          kind ?: @"URL",
                          value,
                          extra.length ? @" | " : @"",
                          extra ?: @""];
        ZONAppendHotUpdateLine(line);

        if (hot || [kind isEqualToString:@"BODY_URL"] || [kind isEqualToString:@"REDIRECT"]) {
            NSLog(@"[zonoemenu][hotupdate][%@][%@] %@%@%@",
                  tag,
                  kind ?: @"URL",
                  value,
                  extra.length ? @" | " : @"",
                  extra ?: @"");
        }
    });
}

static void ZONExtractURLsFromResponseBody(NSData *data)
{
    if (data.length == 0) return;

    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (text.length == 0) return;

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"https?://[^\\s\\\"'<>]+"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (!regex || error) return;

    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:text
                                                               options:0
                                                                 range:NSMakeRange(0, text.length)];
    NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@",;)]}>\\\""];
    for (NSTextCheckingResult *match in matches) {
        NSString *candidate = [text substringWithRange:match.range];
        candidate = [candidate stringByTrimmingCharactersInSet:trimSet];
        NSURL *url = [NSURL URLWithString:candidate];
        if (url) {
            ZONRecordHotUpdateURL(@"BODY_URL", url, nil);
        }
    }
}

@interface wyURLProtocol () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) BOOL stopped;
@end

@implementation wyURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:ZONHotUpdateHandledKey inRequest:request]) {
        return NO;
    }

    NSString *scheme = request.URL.scheme.lowercaseString;
    return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    self.stopped = NO;
    self.data = [NSMutableData data];

    NSMutableURLRequest *request = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:ZONHotUpdateHandledKey inRequest:request];

    NSString *method = request.HTTPMethod.length ? request.HTTPMethod : @"GET";
    ZONRecordHotUpdateURL([NSString stringWithFormat:@"REQ %@", method], request.URL, nil);

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    // The internal forwarding session must not recurse back through wyURLProtocol.
    configuration.protocolClasses = @[];

    self.session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:nil];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

- (void)stopLoading
{
    self.stopped = YES;
    [self.task cancel];
    [self.session invalidateAndCancel];
    self.task = nil;
    self.session = nil;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if (self.stopped) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }

    NSString *extra = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger status = ((NSHTTPURLResponse *)response).statusCode;
        extra = [NSString stringWithFormat:@"HTTP %ld", (long)status];
    }
    ZONRecordHotUpdateURL(@"RESP", response.URL ?: dataTask.currentRequest.URL, extra);

    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if (self.stopped) return;

    if (self.data.length < ZONHotUpdateBodyCaptureLimit) {
        NSUInteger remaining = ZONHotUpdateBodyCaptureLimit - self.data.length;
        if (data.length <= remaining) {
            [self.data appendData:data];
        } else if (remaining > 0) {
            [self.data appendData:[data subdataWithRange:NSMakeRange(0, remaining)]];
        }
    }

    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSString *extra = [NSString stringWithFormat:@"HTTP %ld", (long)response.statusCode];
    ZONRecordHotUpdateURL(@"REDIRECT", request.URL, extra);
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 didCompleteWithError:(NSError *)error
{
    if (self.stopped) return;

    ZONExtractURLsFromResponseBody(self.data);

    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }

    [self.session finishTasksAndInvalidate];
    self.task = nil;
    self.session = nil;
}

@end

static void ZONInjectHotUpdateProtocol(NSURLSessionConfiguration *configuration)
{
    if (!configuration) return;

    NSMutableArray *classes = [configuration.protocolClasses mutableCopy];
    if (!classes) classes = [NSMutableArray array];
    if (![classes containsObject:[wyURLProtocol class]]) {
        [classes insertObject:[wyURLProtocol class] atIndex:0];
    }
    configuration.protocolClasses = classes;
}

@interface NSURLSessionConfiguration (ZONHotUpdateCapture)
+ (NSURLSessionConfiguration *)zon_hot_defaultSessionConfiguration;
+ (NSURLSessionConfiguration *)zon_hot_ephemeralSessionConfiguration;
@end

@implementation NSURLSessionConfiguration (ZONHotUpdateCapture)

+ (NSURLSessionConfiguration *)zon_hot_defaultSessionConfiguration
{
    NSURLSessionConfiguration *configuration = [self zon_hot_defaultSessionConfiguration];
    ZONInjectHotUpdateProtocol(configuration);
    return configuration;
}

+ (NSURLSessionConfiguration *)zon_hot_ephemeralSessionConfiguration
{
    NSURLSessionConfiguration *configuration = [self zon_hot_ephemeralSessionConfiguration];
    ZONInjectHotUpdateProtocol(configuration);
    return configuration;
}

@end

static void ZONInstallHotUpdateCapture(void)
{
#if ZON_BUILD_VARIANT_DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLProtocol registerClass:[wyURLProtocol class]];

        Method defaultOriginal = class_getClassMethod([NSURLSessionConfiguration class],
                                                      @selector(defaultSessionConfiguration));
        Method defaultReplacement = class_getClassMethod([NSURLSessionConfiguration class],
                                                         @selector(zon_hot_defaultSessionConfiguration));
        if (defaultOriginal && defaultReplacement) {
            method_exchangeImplementations(defaultOriginal, defaultReplacement);
        }

        Method ephemeralOriginal = class_getClassMethod([NSURLSessionConfiguration class],
                                                        @selector(ephemeralSessionConfiguration));
        Method ephemeralReplacement = class_getClassMethod([NSURLSessionConfiguration class],
                                                           @selector(zon_hot_ephemeralSessionConfiguration));
        if (ephemeralOriginal && ephemeralReplacement) {
            method_exchangeImplementations(ephemeralOriginal, ephemeralReplacement);
        }

        NSString *path = ZONHotUpdateLogPath();
        NSLog(@"[zonoemenu][hotupdate] capture enabled; log=%@", path);
        dispatch_async(ZONHotUpdateLogQueue(), ^{
            NSString *header = [NSString stringWithFormat:@"\n===== ZON hot-update capture %@ =====\n", [NSDate date]];
            ZONAppendHotUpdateLine(header);
        });
    });
#endif
}

#pragma mark - Authorization reset compatibility

static IMP gZONOriginalDeleteKM = NULL;

static void ZONClearStoredUDIDState(void)
{
    // loada / cloud-save legacy machine-code cache.
    [getKeychain removeKeychainDataForKey:@"DZUDID"];

    // C1/v1_p3+ zonoe bridge cache. If these are left behind, A_customer would
    // simply restore DZUDID from the bridge cache on the next launch and would
    // not exercise the first-activation UDID flow again.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:@"zonoe.udid.bridge.value"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.scheme"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.requestTimestamp"];
    [defaults removeObjectForKey:@"zonoe.udid.bridge.requestNonce"];
    [defaults synchronize];

    NSLog(@"[zonoemenu][INFO][auth] authorization reset also cleared UDID state");
}

static void ZONDeleteKMAndUDID(id self, SEL _cmd)
{
    if (gZONOriginalDeleteKM) {
        ((void (*)(id, SEL))gZONOriginalDeleteKM)(self, _cmd);
    }
    ZONClearStoredUDIDState();
}

static void ZONInstallAuthorizationResetExtension(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class authClass = NSClassFromString(@"WX_NongShiFu123");
        Method method = class_getInstanceMethod(authClass, @selector(deletekm));
        if (!method) {
            NSLog(@"[zonoemenu][WARN][auth] deletekm not found; UDID reset extension unavailable");
            return;
        }

        gZONOriginalDeleteKM = method_setImplementation(method, (IMP)ZONDeleteKMAndUDID);
        NSLog(@"[zonoemenu][INFO][auth] authorization reset now includes UDID state");
    });
}

static void ZONShowCustomerStatus(NSString *text,
                                  JDStatusBarNotificationIncludedStyle style,
                                  NSTimeInterval delay)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter dismissAnimated:YES];
        [presenter presentWithText:text dismissAfterDelay:delay includedStyle:style];
    });
}

static void ZONContinueCustomerAuthorization(WX_NongShiFu123 *auth, NSString *udid, BOOL newlyFetched)
{
    if (udid.length < 5) return;

    [getKeychain addKeychainData:udid forKey:@"DZUDID"];
    NSString *verified = [getKeychain getKeychainDataForKey:@"DZUDID"];

    if (verified.length < 5 || ![verified isEqualToString:udid]) {
        ZONShowCustomerStatus(@"UDID 写入失败\n请重新启动后再试",
                              JDStatusBarNotificationIncludedStyleError,
                              5.0);
        return;
    }

    if (newlyFetched) {
        NSString *status = [NSString stringWithFormat:
                            @"UDID 获取成功\n%@\n已写入 DZUDID\n正在继续授权",
                            verified];
        ZONShowCustomerStatus(status,
                              JDStatusBarNotificationIncludedStyleSuccess,
                              5.0);
    }

    [auth loada];
}

static void ZONStartCustomerAuthorization(void)
{
    WX_NongShiFu123 *auth = [WX_NongShiFu123 new];

    // Existing valid customer keychain data wins. This avoids unnecessary zonoe jumps
    // for already activated customers.
    NSString *existing = [getKeychain getKeychainDataForKey:@"DZUDID"];
    if (existing.length >= 5) {
        [auth loada];
        return;
    }

    // Reuse the C1/v1_p3 bridge cache when available.
    NSString *cached = ZonoeCurrentUDID();
    if (cached.length >= 5) {
        ZONContinueCustomerAuthorization(auth, cached, NO);
        return;
    }

    ZONShowCustomerStatus(@"正在获取设备 UDID...",
                          JDStatusBarNotificationIncludedStyleLight,
                          5.0);

    // First customer activation: authorization is the only owner of UDID acquisition.
    // No menu/icon action requests UDID anymore.
    ZonoeSetUDIDCallback(^(NSString *udid) {
        ZONContinueCustomerAuthorization(auth, udid, YES);
    });
    ZonoeRequestUDIDIfNeeded();
}
 
@implementation NSObject (mian)

#pragma mark - 强制加载 AppLovin SDK（如果存在）

// 核心通用加载逻辑
+ (void)loadDynamicFrameworkNamed:(NSString *)frameworkName {
    NSString *frameworkPath = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 1. 优先尝试 PrivateFrameworks 路径
    NSString *privatePath = [[NSBundle mainBundle] privateFrameworksPath];
    if (privatePath) {
        frameworkPath = [privatePath stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@.framework/%@", frameworkName, frameworkName]];
    }

    // 2. 兜底尝试标准 Frameworks 路径
    if (!frameworkPath || ![fileManager fileExistsAtPath:frameworkPath]) {
        frameworkPath = [[[NSBundle mainBundle] bundlePath]
                         stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"Frameworks/%@.framework/%@", frameworkName, frameworkName]];
    }

    // 3. 最终检查文件是否存在
    if (![fileManager fileExistsAtPath:frameworkPath]) {
        NSLog(@"[%@] SDK not found at path: %@", frameworkName, frameworkPath);
        return;
    }

    // 4. 执行 dlopen
    void *handle = dlopen([frameworkPath UTF8String], RTLD_NOW);
    if (!handle) {
        NSLog(@"[%@] dlopen failed: %s", frameworkName, dlerror());
        return;
    }

    // 5. 执行后续初始化逻辑
    if ([NSObject respondsToSelector:@selector(sdkload)]) {
        [NSObject sdkload];
    }
    
    NSLog(@"[%@] SDK loaded successfully from: %@", frameworkName, frameworkPath);
}

+ (void)tryLoadAppLovinSDK {
    [self loadDynamicFrameworkNamed:@"AppLovinSDK"];
}

+ (void)UnityFramework {
    [self loadDynamicFrameworkNamed:@"UnityFramework"];
}

+(void)load
{
    ZONInstallAuthorizationResetExtension();
    ZONInstallHotUpdateCapture();

    ZONBootstrapStart(^{
        // Preserve the verified legacy framework preflight timing/order.
        [self tryLoadAppLovinSDK];
        [self UnityFramework];
    }, ^{
#if ZON_BUILD_VARIANT_DEBUG
        // B_debug: developer entry. No customer authorization and no UDID request.
        [NSObject 显示图标];
#else
        // A_customer: formal customer entry. UDID is acquired only when loada needs it.
        NSObject *statusHost = [NSObject new];
        [statusHost showProgressNotificationAndAnimate];
        ZONStartCustomerAuthorization();
#endif
    });
}

- (void)showProgressNotificationAndAnimate {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"🎉加载插件中...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];
    });
}

- (void)sdkload{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        JDStatusBarNotificationPresenter *presenter = [JDStatusBarNotificationPresenter sharedPresenter];
        [presenter presentWithText:@"🎉检测完成...." dismissAfterDelay:3 includedStyle:JDStatusBarNotificationIncludedStyleLight];
    });
}

@end
