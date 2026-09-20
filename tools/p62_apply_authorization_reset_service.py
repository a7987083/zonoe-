#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WX = ROOT / 'testmod/Bsphp/WX_NongShiFu123.mm'
COORD = ROOT / 'testmod/ZONServices/ZONAuthorizationCoordinator.m'
PBX = ROOT / 'testmod.xcodeproj/project.pbxproj'
SERVICE_H = ROOT / 'testmod/ZONServices/ZONAuthorizationResetService.h'
SERVICE_M = ROOT / 'testmod/ZONServices/ZONAuthorizationResetService.m'

HEADER = '''#import <Foundation/Foundation.h>\n\nNS_ASSUME_NONNULL_BEGIN\n\n@interface ZONAuthorizationResetService : NSObject\n\n/// Clears the complete authorization state used by the P62 runtime.\n/// Missing items are treated as success.\n+ (BOOL)clearAuthorizationData:(NSError * _Nullable * _Nullable)error;\n\n@end\n\nNS_ASSUME_NONNULL_END\n'''

IMPLEMENTATION = '''#import "ZONAuthorizationResetService.h"\n#import "../category/getKeychain.h"\n#import "../菜单/ZONKeychain.h"\n\n@implementation ZONAuthorizationResetService\n\n+ (BOOL)clearAuthorizationData:(NSError **)error\n{\n    if (error) *error = nil;\n\n    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;\n\n    // Preserve the exact P62 deletekm UserDefaults clear set.\n    NSArray<NSString *> *userDefaultsKeys = @[\n        @"zonoeudid",\n        @"卡密",\n        @"已选择开启秒过广告",\n        @"到期时间",\n    ];\n    for (NSString *key in userDefaultsKeys) {\n        [defaults removeObjectForKey:key];\n    }\n\n    // Preserve the exact P62 deletekm getKeychain clear set.\n    NSArray<NSString *> *legacyKeychainKeys = @[\n        @"SJUSERID",\n        @"ShiSanGeDZKM",\n        @"rjyyz",\n    ];\n    for (NSString *key in legacyKeychainKeys) {\n        [getKeychain removeKeychainDataForKey:key];\n    }\n\n    // P62 coordinator reset extension: clear the machine-code cache as part\n    // of the same atomic reset API instead of relying on runtime swizzling.\n    [getKeychain removeKeychainDataForKey:@"DZUDID"];\n\n    NSArray<NSString *> *bridgeKeys = @[\n        @"zonoe.udid.bridge.value",\n        @"zonoe.udid.bridge.scheme",\n        @"zonoe.udid.bridge.requestTimestamp",\n        @"zonoe.udid.bridge.requestNonce",\n    ];\n    for (NSString *key in bridgeKeys) {\n        [defaults removeObjectForKey:key];\n    }\n\n    NSError *keychainError = nil;\n    BOOL keychainOK = [ZONKeychain removeItemForAccount:@"UDID"\n                                                service:@"com.china.TestKeyChain"\n                                                  error:&keychainError];\n\n    // The old coordinator called synchronize after its bridge-cache cleanup.\n    // Keep that effective P62 behavior here.\n    [defaults synchronize];\n\n    if (!keychainOK) {\n        if (error) *error = keychainError;\n        return NO;\n    }\n\n    return YES;\n}\n\n@end\n'''


def replace_objc_method(source: str, signature: str, replacement: str) -> str:
    start = source.find(signature)
    if start < 0:
        raise SystemExit(f'method signature not found: {signature}')
    brace = source.find('{', start)
    if brace < 0:
        raise SystemExit(f'method opening brace not found: {signature}')
    depth = 0
    end = None
    for i in range(brace, len(source)):
        c = source[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end is None:
        raise SystemExit(f'method closing brace not found: {signature}')
    return source[:start] + replacement + source[end:]


SERVICE_H.write_text(HEADER, encoding='utf-8')
SERVICE_M.write_text(IMPLEMENTATION, encoding='utf-8')

wx = WX.read_text(encoding='utf-8')
import_line = '#import "../ZONServices/ZONAuthorizationResetService.h"\n'
if import_line not in wx:
    anchor = '#import "ZONKeychain.h"\n'
    if wx.count(anchor) != 1:
        raise SystemExit(f'expected exactly one ZONKeychain import, found {wx.count(anchor)}')
    wx = wx.replace(anchor, anchor + import_line, 1)

replacement = '''- (void)deletekm {\n    NSError *error = nil;\n    BOOL cleared = [ZONAuthorizationResetService clearAuthorizationData:&error];\n    if (!cleared) {\n        ConfigLog(@"❌清除授权信息失败：%@", error);\n    } else {\n        ConfigLog(@"✅清除授权信息成功");\n    }\n}\n'''
wx = replace_objc_method(wx, '- (void)deletekm {', replacement)
WX.write_text(wx, encoding='utf-8')

coord = COORD.read_text(encoding='utf-8')
status_marker = 'static void ZONShowCustomerStatus'
pos = coord.find(status_marker)
if pos < 0:
    raise SystemExit('ZONShowCustomerStatus marker not found')
new_prefix = '''#import "ZONAuthorizationCoordinator.h"\n#import "../Bsphp/WX_NongShiFu123.h"\n#import "../category/getKeychain.h"\n#import "JDStatusBarNotification.h"\n#import "ZonoeUDIDAPI.h"\n#import "ZONLaunchTrace.h"\n\n#pragma mark - Authorization reset compatibility\n\nvoid ZONInstallAuthorizationResetExtension(void)\n{\n    // Kept as a compatibility startup hook. Reset ownership now lives in\n    // ZONAuthorizationResetService and WX_NongShiFu123::deletekm forwards to it.\n    static dispatch_once_t onceToken;\n    dispatch_once(&onceToken, ^{\n        NSLog(@"[zonoemenu][INFO][auth] authorization reset service installed");\n    });\n}\n\n'''
coord = new_prefix + coord[pos:]
COORD.write_text(coord, encoding='utf-8')

pbx = PBX.read_text(encoding='utf-8')
BUILD_ID = 'A17D0E012F7B100100C0FFEE'
FILE_ID = 'A17D0E022F7B100100C0FFEE'

build_line = f'\t\t{BUILD_ID} /* ZONAuthorizationResetService.m in Sources */ = {{isa = PBXBuildFile; fileRef = {FILE_ID} /* ZONAuthorizationResetService.m */; }};\n'
file_line = f'\t\t{FILE_ID} /* ZONAuthorizationResetService.m */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONAuthorizationResetService.m"; sourceTree = SOURCE_ROOT; }};\n'
source_line = f'\t\t\t\t{BUILD_ID} /* ZONAuthorizationResetService.m in Sources */,\n'

# Check the actual declarations, not whether the IDs appear anywhere. BUILD_ID and
# FILE_ID are also referenced from other PBX records, so global ID presence is not
# sufficient to prove the declaration exists.
if build_line not in pbx:
    anchor = '\t\t7ECBD4432F3A614B00C56F1C /* ZONAuthorizationCoordinator.m in Sources */ = {isa = PBXBuildFile; fileRef = 7ECBD4422F3A614B00C56F1C /* ZONAuthorizationCoordinator.m */; };\n'
    if pbx.count(anchor) != 1:
        raise SystemExit(f'PBX build anchor count: {pbx.count(anchor)}')
    pbx = pbx.replace(anchor, anchor + build_line, 1)

if file_line not in pbx:
    anchor = '\t\t7ECBD4422F3A614B00C56F1C /* ZONAuthorizationCoordinator.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = "testmod/ZONServices/ZONAuthorizationCoordinator.m"; sourceTree = SOURCE_ROOT; };\n'
    if pbx.count(anchor) != 1:
        raise SystemExit(f'PBX file anchor count: {pbx.count(anchor)}')
    pbx = pbx.replace(anchor, anchor + file_line, 1)

if source_line not in pbx:
    anchor = '\t\t\t\t7ECBD4432F3A614B00C56F1C /* ZONAuthorizationCoordinator.m in Sources */,\n'
    if pbx.count(anchor) != 1:
        raise SystemExit(f'PBX sources anchor count: {pbx.count(anchor)}')
    pbx = pbx.replace(anchor, anchor + source_line, 1)

PBX.write_text(pbx, encoding='utf-8')

# Contract checks: service owns every key cleared by effective P62 reset.
service = SERVICE_M.read_text(encoding='utf-8')
required = [
    'zonoeudid', '卡密', '已选择开启秒过广告', '到期时间',
    'SJUSERID', 'ShiSanGeDZKM', 'rjyyz', 'DZUDID',
    'zonoe.udid.bridge.value', 'zonoe.udid.bridge.scheme',
    'zonoe.udid.bridge.requestTimestamp', 'zonoe.udid.bridge.requestNonce',
    'com.china.TestKeyChain',
]
for token in required:
    if token not in service:
        raise SystemExit(f'missing reset token: {token}')

if 'method_setImplementation' in COORD.read_text(encoding='utf-8'):
    raise SystemExit('runtime deletekm swizzle still present')
if '[ZONAuthorizationResetService clearAuthorizationData:&error]' not in WX.read_text(encoding='utf-8'):
    raise SystemExit('WX deletekm is not forwarding to reset service')

final_pbx = PBX.read_text(encoding='utf-8')
if final_pbx.count('ZONAuthorizationResetService.m in Sources') != 2:
    raise SystemExit('unexpected PBX service source references')
if build_line not in final_pbx:
    raise SystemExit('reset service PBXBuildFile declaration missing')
if file_line not in final_pbx:
    raise SystemExit('reset service PBXFileReference declaration missing')
if source_line not in final_pbx:
    raise SystemExit('reset service PBXSourcesBuildPhase membership missing')

print('authorization reset service migration applied')
