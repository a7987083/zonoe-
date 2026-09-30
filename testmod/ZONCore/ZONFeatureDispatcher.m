#import "ZONFeatureDispatcher.h"
#import "ZONFeatureRegistry.h"
#import "ImgTool.h"
#import "../ZONAuthV2/ZONAuthV2Storage.h"
#import "../ZONServices/ZONSixButtonActionService.h"
#import "../ZONServices/ZONRuntimeDirectoryService.h"
#import "../ZONServices/ZONResetCoordinator.h"
#import "../ZONServices/ZONLocalFilesCoordinator.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/vm_prot.h>
#import <stdint.h>
#import <string.h>
#if __has_include(<ptrauth.h>)
#import <ptrauth.h>
#endif

typedef BOOL (^ZONFeatureActionHandler)(UIViewController *hostViewController);
typedef BOOL (^ZONFeatureToggleHandler)(BOOL on);
typedef void (^ZONRuntimeToggleSideEffect)(BOOL on);

#pragma mark - Compatibility C surface

NSString *ZONTmpDirectoryPath(void)
{
    return [ZONRuntimeDirectoryService temporaryDirectoryPath];
}

BOOL ZONEnsureTmpDirectory(void)
{
    return [ZONRuntimeDirectoryService ensureTemporaryDirectory];
}

void ZONClearGameDataPreservingTmp(void)
{
    [[ZONResetCoordinator sharedCoordinator] resetGameDataWithoutConfirmation];
}

void ZONPresentClearGameDataConfirmation(UIViewController *hostViewController)
{
    [[ZONResetCoordinator sharedCoordinator] presentClearGameDataFromViewController:hostViewController];
}

void ZONPresentClearAuthorizationConfirmation(UIViewController *hostViewController)
{
    [[ZONResetCoordinator sharedCoordinator] presentClearAuthorizationFromViewController:hostViewController];
}

#pragma mark - Permission helpers

static NSDictionary<NSString *, id> *ZONCurrentServerPermissions(void)
{
    NSDictionary *verify = [ZONAuthV2Storage lastVerify];
    NSDictionary *permissions = [verify[@"permissions"] isKindOfClass:NSDictionary.class] ? verify[@"permissions"] : nil;
    return permissions ?: @{};
}

static void ZONPresentPermissionDenied(UIViewController *hostViewController, NSString *featureTitle)
{
    if (!hostViewController) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"当前授权不包含%@权限。", featureTitle.length ? featureTitle : @"该功能"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"权限不足"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [hostViewController presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Injected passive Satella trigger

static const uintptr_t kZONPassiveSatellaCtorRVA = 0x847C;
static const uintptr_t kZONPassiveSatellaInitRVA = 0x888C;

static const uint8_t kZONPassiveSatellaCtorBytes[4] = {
    0xC0, 0x03, 0x5F, 0xD6
};

static const uint8_t kZONPassiveSatellaInitPrologue[16] = {
    0xFC, 0x6F, 0xBA, 0xA9,
    0xFA, 0x67, 0x01, 0xA9,
    0xF8, 0x5F, 0x02, 0xA9,
    0xF6, 0x57, 0x03, 0xA9
};

static BOOL gZONPassiveSatellaStarted = NO;

static BOOL ZONPathEndsWith(const char *path, const char *name)
{
    if (!path || !name) return NO;
    size_t pathLength = strlen(path);
    size_t nameLength = strlen(name);
    if (pathLength < nameLength) return NO;
    return strcmp(path + pathLength - nameLength, name) == 0;
}

/// P79.8f P0 hardening: validate the supplied RVA against the mapped executable
/// __TEXT segment before dereferencing base + RVA. The target contract still
/// intentionally requires __TEXT vmaddr == 0, preserving P79.8d address semantics.
static BOOL ZONPassiveSatellaTextCoversRange(const struct mach_header_64 *header,
                                             uintptr_t rva,
                                             size_t length)
{
    if (!header || header->magic != MH_MAGIC_64 || length == 0) return NO;
    if (rva > UINTPTR_MAX - length) return NO;

    uintptr_t cursor = (uintptr_t)(header + 1);
    if ((uintptr_t)header->sizeofcmds > UINTPTR_MAX - cursor) return NO;
    uintptr_t commandsEnd = cursor + (uintptr_t)header->sizeofcmds;

    for (uint32_t index = 0; index < header->ncmds; index++) {
        if (cursor > commandsEnd || commandsEnd - cursor < sizeof(struct load_command)) return NO;

        const struct load_command *command = (const struct load_command *)cursor;
        if (command->cmdsize < sizeof(struct load_command) ||
            (uintptr_t)command->cmdsize > commandsEnd - cursor) {
            return NO;
        }

        if (command->cmd == LC_SEGMENT_64) {
            if (command->cmdsize < sizeof(struct segment_command_64)) return NO;
            const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
            if (strncmp(segment->segname, "__TEXT", sizeof(segment->segname)) == 0) {
                if (segment->vmaddr != 0) return NO;
                if ((segment->initprot & VM_PROT_READ) == 0 ||
                    (segment->initprot & VM_PROT_EXECUTE) == 0) {
                    return NO;
                }
                if (rva > segment->vmsize) return NO;
                return length <= (size_t)(segment->vmsize - rva);
            }
        }

        cursor += (uintptr_t)command->cmdsize;
    }

    return NO;
}

static uintptr_t ZONFindInjectedPassiveSatellaBase(void)
{
    uint32_t count = _dyld_image_count();
    for (uint32_t index = 0; index < count; index++) {
        const char *path = _dyld_get_image_name(index);
        const struct mach_header *header = _dyld_get_image_header(index);
        if (!path || !header) continue;

        if (!ZONPathEndsWith(path, "1_passive.dylib") &&
            !ZONPathEndsWith(path, "1_passive_zh.dylib") &&
            !ZONPathEndsWith(path, "SatellaJailed_passive.dylib")) {
            continue;
        }

        if (header->magic != MH_MAGIC_64) {
            NSLog(@"[zonoemenu][P79.8D_SATELLA] unsupported Mach-O header path=%s magic=0x%x", path, header->magic);
            continue;
        }

        const struct mach_header_64 *header64 = (const struct mach_header_64 *)header;
        BOOL ctorMapped = ZONPassiveSatellaTextCoversRange(header64,
                                                           kZONPassiveSatellaCtorRVA,
                                                           sizeof(kZONPassiveSatellaCtorBytes));
        BOOL initMapped = ZONPassiveSatellaTextCoversRange(header64,
                                                           kZONPassiveSatellaInitRVA,
                                                           sizeof(kZONPassiveSatellaInitPrologue));
        if (!ctorMapped || !initMapped) {
            NSLog(@"[zonoemenu][P79.8F_P0_SATELLA] text_range_mismatch path=%s ctor=%d init=%d",
                  path, ctorMapped, initMapped);
            continue;
        }

        uintptr_t base = (uintptr_t)header;
        if (memcmp((const void *)(base + kZONPassiveSatellaCtorRVA),
                   kZONPassiveSatellaCtorBytes,
                   sizeof(kZONPassiveSatellaCtorBytes)) != 0) {
            NSLog(@"[zonoemenu][P79.8D_SATELLA] passive_ctor_mismatch path=%s base=0x%llx", path, (unsigned long long)base);
            continue;
        }

        if (memcmp((const void *)(base + kZONPassiveSatellaInitRVA),
                   kZONPassiveSatellaInitPrologue,
                   sizeof(kZONPassiveSatellaInitPrologue)) != 0) {
            NSLog(@"[zonoemenu][P79.8D_SATELLA] init_prologue_mismatch path=%s base=0x%llx", path, (unsigned long long)base);
            continue;
        }

        NSLog(@"[zonoemenu][P79.8D_SATELLA] validated path=%s base=0x%llx", path, (unsigned long long)base);
        return base;
    }

    return 0;
}

static BOOL ZONStartInjectedPassiveSatella(void)
{
    @synchronized ([NSBundle class]) {
        if (gZONPassiveSatellaStarted) {
            NSLog(@"[zonoemenu][P79.8D_SATELLA] already_started");
            return YES;
        }

        uintptr_t base = ZONFindInjectedPassiveSatellaBase();
        if (!base) {
            NSLog(@"[zonoemenu][P79.8D_SATELLA] image_not_loaded_or_invalid");
            return NO;
        }

        uintptr_t address = base + kZONPassiveSatellaInitRVA;
        void *rawFunction = (void *)address;
#if __has_feature(ptrauth_calls)
        rawFunction = ptrauth_sign_unauthenticated(rawFunction,
                                                   ptrauth_key_function_pointer,
                                                   0);
#endif
        void (*startFunction)(void) = (void (*)(void))rawFunction;
        NSLog(@"[zonoemenu][P79.8D_SATELLA] init=0x%llx", (unsigned long long)address);

        if ([NSThread isMainThread]) {
            startFunction();
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                startFunction();
            });
        }

        gZONPassiveSatellaStarted = YES;
        NSLog(@"[zonoemenu][P79.8D_SATELLA] started");
        return YES;
    }
}

#pragma mark - Runtime toggles

static void ZONApplyRuntimeToggle(NSUserDefaults *defaults,
                                  NSString *integerKey,
                                  NSString *booleanKey,
                                  BOOL on,
                                  ZONRuntimeToggleSideEffect sideEffect)
{
    [defaults setInteger:on forKey:integerKey];
    [defaults setBool:on forKey:booleanKey];
    [defaults synchronize];
    if (sideEffect) sideEffect(on);
}

#pragma mark - Action routes

static NSDictionary<NSString *, ZONFeatureActionHandler> *ZONActionRoutes(void)
{
    static NSDictionary<NSString *, ZONFeatureActionHandler> *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            @"base.remote-download": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performRemoteDownloadFromViewController:host];
            },
            @"base.cloud-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performCloudSaveFromViewController:host];
            },
            @"base.local-files": ^BOOL(UIViewController *host) {
                return [[ZONLocalFilesCoordinator sharedCoordinator] presentLocalFilesFromViewController:host];
            },
            @"data.backup-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performBackupSaveFromViewController:host];
            },
            @"data.restore-save": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performRestoreSaveFromViewController:host];
            },
            @"data.clear-game-data": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performClearGameDataFromViewController:host];
            },
            @"auth.clear-records": ^BOOL(UIViewController *host) {
                return [ZONSixButtonActionService performClearAuthorizationFromViewController:host];
            },
        };
    });
    return routes;
}

static NSDictionary<NSString *, ZONFeatureToggleHandler> *ZONToggleRoutes(void)
{
    static NSDictionary<NSString *, ZONFeatureToggleHandler> *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            @"runtime.iap-noads": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"NNGG", @"NNGGNNGG", on,
                                      ^(BOOL enabled) { [ImgTool share].NeiGou = enabled; });
                if (on) {
                    BOOL started = ZONStartInjectedPassiveSatella();
                    NSLog(@"[zonoemenu][P79.8D_SATELLA] toggle_on started=%d", started);
                }
                return YES;
            },
            @"runtime.ad-speed": ^BOOL(BOOL on) {
                ZONApplyRuntimeToggle(NSUserDefaults.standardUserDefaults,
                                      @"AADD", @"AADDAADD", on,
                                      ^(BOOL enabled) { [ImgTool share].ADSpeed = enabled; });
                return YES;
            },
        };
    });
    return routes;
}

/// Routes registry-owned actions. Registry metadata remains the source of truth;
/// route tables only map a registered identifier to its service boundary.
BOOL ZONDispatchMigratedActionForLegacyTag(NSInteger legacyTag,
                                            UIViewController *hostViewController)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSDictionary *permissions = ZONCurrentServerPermissions();
    if (!ZONFeatureIsActionAllowedWithPermissions(feature, permissions)) {
        NSLog(@"[zonoemenu][P79.8C_ACTION_PERMISSION] denied feature=%@ required=%@",
              feature[ZONFeatureIdentifierKey] ?: @"",
              feature[ZONFeatureRequiredActionPermissionKey] ?: @"");
        ZONPresentPermissionDenied(hostViewController, feature[ZONFeatureTitleKey]);
        // The route is handled even when denied, preventing any legacy fallback
        // from reaching the protected action by tag.
        return YES;
    }

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureActionHandler handler = ZONActionRoutes()[identifier];
    return handler ? handler(hostViewController) : NO;
}

/// Toggle dispatch preserves the exact UserDefaults keys, synchronize call and
/// ImgTool side effects used by the promoted runtime.
BOOL ZONDispatchMigratedToggleForLegacyTag(NSInteger legacyTag, BOOL on)
{
    NSDictionary<NSString *, id> *feature = ZONFeatureMetadataForLegacyTag(legacyTag);
    if (!feature || ![feature[ZONFeatureMigratedKey] boolValue]) return NO;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    ZONFeatureToggleHandler handler = ZONToggleRoutes()[identifier];
    return handler ? handler(on) : NO;
}
