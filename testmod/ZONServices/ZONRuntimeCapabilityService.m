#import "ZONRuntimeCapabilityService.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/vm_prot.h>
#import <stdint.h>
#import <string.h>
#if __has_include(<ptrauth.h>)
#import <ptrauth.h>
#endif

NSString * const ZONRuntimeCapabilityPassiveSatella = @"passive.satella";

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

@implementation ZONRuntimeCapabilityService

+ (BOOL)isCapabilityAvailable:(NSString *)identifier
{
    if ([identifier isEqualToString:ZONRuntimeCapabilityPassiveSatella]) {
        return ZONFindInjectedPassiveSatellaBase() != 0;
    }
    return NO;
}

+ (BOOL)activateCapability:(NSString *)identifier
{
    if ([identifier isEqualToString:ZONRuntimeCapabilityPassiveSatella]) {
        return ZONStartInjectedPassiveSatella();
    }
    return NO;
}

@end
