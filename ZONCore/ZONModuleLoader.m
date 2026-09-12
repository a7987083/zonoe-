#import "ZONModuleLoader.h"
#import <dlfcn.h>

void ZONCoreLog(ZONLogLevel level, const char *moduleID, const char *message) {
    NSString *module = moduleID ? [NSString stringWithUTF8String:moduleID] : @"core";
    NSString *text = message ? [NSString stringWithUTF8String:message] : @"";
    NSString *levelText = @"INFO";
    switch (level) {
        case ZONLogLevelDebug: levelText = @"DEBUG"; break;
        case ZONLogLevelWarn:  levelText = @"WARN"; break;
        case ZONLogLevelError: levelText = @"ERROR"; break;
        case ZONLogLevelInfo:
        default: break;
    }
    NSLog(@"[zonoemenu][%@][%@] %@", levelText, module ?: @"core", text ?: @"");
}

const ZONHostAPI *ZONGetHostAPI(void) {
    static const ZONHostAPI api = {
        .struct_size = sizeof(ZONHostAPI),
        .abi_version = ZON_MODULE_ABI_VERSION,
        .log = ZONCoreLog,
    };
    return &api;
}

NSArray<NSString *> *ZONBundledModuleDirectories(void) {
    NSMutableArray<NSString *> *directories = [NSMutableArray array];
    NSBundle *bundle = [NSBundle mainBundle];

    NSString *frameworks = bundle.privateFrameworksPath;
    if (frameworks.length > 0) {
        [directories addObject:[frameworks stringByAppendingPathComponent:@"ZONModules"]];
    }

    NSString *bundleModules = [bundle.bundlePath stringByAppendingPathComponent:@"ZONModules"];
    [directories addObject:bundleModules];

    return directories.copy;
}

BOOL ZONPathIsInsideDirectory(NSString *path, NSString *directory) {
    NSString *resolvedPath = [[path stringByStandardizingPath] stringByResolvingSymlinksInPath];
    NSString *resolvedDirectory = [[[directory stringByStandardizingPath] stringByResolvingSymlinksInPath]
                                   stringByAppendingString:@"/"];
    return [resolvedPath hasPrefix:resolvedDirectory];
}

BOOL ZONLoadModuleAtPath(NSString *path, NSMutableSet<NSString *> *loadedIdentifiers) {
    if (![path.pathExtension.lowercaseString isEqualToString:@"dylib"]) {
        return NO;
    }

    void *handle = dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        ZONCoreLog(ZONLogLevelError, "loader", dlerror());
        return NO;
    }

    dlerror();
    ZONModuleABIVersionFn abiFn = (ZONModuleABIVersionFn)dlsym(handle, "zonoe_module_abi_version");
    ZONModuleIdentifierFn identifierFn = (ZONModuleIdentifierFn)dlsym(handle, "zonoe_module_identifier");
    ZONModuleInitializeFn initializeFn = (ZONModuleInitializeFn)dlsym(handle, "zonoe_module_initialize");

    if (!abiFn || !identifierFn || !initializeFn) {
        ZONCoreLog(ZONLogLevelError, "loader", "required module export is missing");
        dlclose(handle);
        return NO;
    }

    if (abiFn() != ZON_MODULE_ABI_VERSION) {
        ZONCoreLog(ZONLogLevelWarn, "loader", "module ABI version mismatch");
        dlclose(handle);
        return NO;
    }

    const char *identifierCString = identifierFn();
    if (!identifierCString || identifierCString[0] == '\0') {
        ZONCoreLog(ZONLogLevelError, "loader", "module identifier is empty");
        dlclose(handle);
        return NO;
    }

    NSString *identifier = [NSString stringWithUTF8String:identifierCString];
    if (identifier.length == 0 || [loadedIdentifiers containsObject:identifier]) {
        ZONCoreLog(ZONLogLevelWarn, "loader", "duplicate or invalid module identifier");
        dlclose(handle);
        return NO;
    }

    if (!initializeFn(ZONGetHostAPI())) {
        ZONCoreLog(ZONLogLevelError, identifierCString, "module initialization failed");
        dlclose(handle);
        return NO;
    }

    // Successful modules intentionally remain loaded for the host process lifetime.
    [loadedIdentifiers addObject:identifier];
    ZONCoreLog(ZONLogLevelInfo, identifierCString, "module loaded");
    return YES;
}

void ZONLoadBundledModules(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        NSMutableSet<NSString *> *loadedIdentifiers = [NSMutableSet set];

        for (NSString *directory in ZONBundledModuleDirectories()) {
            BOOL isDirectory = NO;
            if (![fm fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory) {
                continue;
            }

            NSError *error = nil;
            NSArray<NSString *> *entries = [fm contentsOfDirectoryAtPath:directory error:&error];
            if (!entries) {
                ZONCoreLog(ZONLogLevelWarn, "loader", error.localizedDescription.UTF8String);
                continue;
            }

            entries = [entries sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            for (NSString *entry in entries) {
                if (![entry.pathExtension.lowercaseString isEqualToString:@"dylib"]) {
                    continue;
                }

                NSString *path = [directory stringByAppendingPathComponent:entry];
                if (!ZONPathIsInsideDirectory(path, directory)) {
                    ZONCoreLog(ZONLogLevelWarn, "loader", "module path escaped allowed directory");
                    continue;
                }

                ZONLoadModuleAtPath(path, loadedIdentifiers);
            }
        }
    });
}
