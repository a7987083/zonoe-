#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def write(rel, text):
    (ROOT / rel).write_text(text, encoding="utf-8")


def must_replace(text, old, new, label):
    if old not in text:
        raise SystemExit(f"missing expected block: {label}")
    return text.replace(old, new, 1)


def grep_refs(needle, excluded=()):
    hits = []
    for p in ROOT.rglob("*"):
        if not p.is_file() or ".git" in p.parts:
            continue
        rel = p.relative_to(ROOT).as_posix()
        if any(rel == x or rel.startswith(x.rstrip("/") + "/") for x in excluded):
            continue
        try:
            data = p.read_text(encoding="utf-8")
        except Exception:
            continue
        if needle in data:
            hits.append(rel)
    return hits

# 1) Delete the detached P79.7 BindingProbe swizzle/compatibility implementation.
for rel in (
    "testmod/ZONAuthV2/ZONAuthV2BindingProbe.h",
    "testmod/ZONAuthV2/ZONAuthV2BindingProbe.m",
):
    p = ROOT / rel
    if p.exists():
        p.unlink()

# 2) Remove the obsolete ZONAuthV2API Verify posting layer. Verify v3 owns
#    /challenge and /verify directly in ZONAuthV2Verify.
api_h_rel = "testmod/ZONAuthV2/ZONAuthV2API.h"
api_h = read(api_h_rel)
api_h = must_replace(
    api_h,
    "- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion;\n- (void)postVerifyBody:(NSDictionary *)body\n         runtimeConfig:(NSDictionary *)runtimeConfig\n            completion:(ZONAuthV2JSONCompletion)completion;\n",
    "- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion;\n",
    "API header legacy verify method",
)
write(api_h_rel, api_h)

api_m_rel = "testmod/ZONAuthV2/ZONAuthV2API.m"
api_m = read(api_m_rel)
api_m = must_replace(
    api_m,
    "            self.sessionBootstrap = normalized;\n            [ZONAuthV2Storage setLastBootstrap:normalized];\n            if (completion) completion(normalized, nil);\n",
    "            self.sessionBootstrap = normalized;\n            if (completion) completion(normalized, nil);\n",
    "API bootstrap duplicate cache write",
)
api_m = must_replace(
    api_m,
    "\n        NSDictionary *lastKnownGood = [ZONAuthV2Storage lastBootstrap];\n        if ([self isUsableBootstrap:lastKnownGood]) {\n            self.sessionBootstrap = lastKnownGood;\n            if (completion) completion(lastKnownGood, nil);\n            return;\n        }\n",
    "\n",
    "API duplicate bootstrap fallback",
)
start = api_m.find("- (NSString *)verifyURLForRuntimeConfig:")
if start == -1:
    raise SystemExit("legacy verifyURLForRuntimeConfig method not found")
end = api_m.find("\n@end", start)
if end == -1:
    raise SystemExit("API @end not found")
api_m = api_m[:start] + api_m[end:]
write(api_m_rel, api_m)

# 3) Tighten Flow ownership: card is activation-only; Runtime Config and Verify
#    no longer carry card/host/cached-config residue.
flow_rel = "testmod/ZONAuthV2/ZONAuthV2Flow.m"
flow = read(flow_rel)
flow = must_replace(
    flow,
    "static BOOL ZONLicenseIsAuthorized(NSDictionary *license) {\n    return ZONUDIDAuthorizationStateFromPayload(license) == ZONUDIDAuthorizationStateActive;\n}\n\n",
    "",
    "unused ZONLicenseIsAuthorized",
)
flow = must_replace(
    flow,
    "        if (state == ZONUDIDAuthorizationStateActive) {\n            NSString *savedCard = [ZONAuthV2Storage card] ?: @\"\";\n            NSLog(@\"[zonoemenu][auth-v2][P79.8A_UDID_GATE] active UDID authorization; entering runtime-config + Verify without card prompt\");\n            [self fetchConfigAndVerifyUDID:udid card:savedCard license:snapshot host:nil isNewActivation:NO];\n            return;\n        }\n",
    "        if (state == ZONUDIDAuthorizationStateActive) {\n            NSLog(@\"[zonoemenu][auth-v3][UDID_GATE] active UDID authorization; entering signed Runtime Config + Verify\");\n            [self fetchConfigAndVerifyUDID:udid license:snapshot isNewActivation:NO];\n            return;\n        }\n",
    "active branch card residue",
)
flow = flow.replace("[ZONAuthV2Storage clearCard];", "[ZONAuthV2Storage clearAuthorizationSession];")
flow = must_replace(
    flow,
    "            [ZONAuthV2Storage setLastActivation:activationResponse];\n",
    "",
    "write-only lastActivation",
)
flow = must_replace(
    flow,
    "                [self fetchConfigAndVerifyUDID:udid card:card license:afterLicense host:nil isNewActivation:YES];\n",
    "                [self fetchConfigAndVerifyUDID:udid license:afterLicense isNewActivation:YES];\n",
    "post activation card forwarding",
)
old_method = '''- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                            card:(NSString *)card
                         license:(NSDictionary *)license
                            host:(UIViewController *)host
                 isNewActivation:(BOOL)isNewActivation {
    [[ZONAuthV2API sharedAPI] fetchRuntimeConfigWithCompletion:^(NSDictionary *config, NSError *configError) {
        NSDictionary *effectiveConfig = config;
        if (config && !configError) {
            [ZONAuthV2Storage setLastRuntimeConfig:config];
        } else {
            effectiveConfig = [ZONAuthV2Storage lastRuntimeConfig];
        }
        if (!effectiveConfig) {
            [self handleVerifyFailureResponse:config error:configError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-30 userInfo:@{NSLocalizedDescriptionKey:@"Runtime Config 不可用"}] udid:udid];
            return;
        }

        NSLog(@"[zonoemenu][auth-v2][VERIFY_CONFIG] ready dylib_key=%@", ZONString(ZONFirstValueForKeys(effectiveConfig, @[@"dylib_key"])));
        [[ZONAuthV2Verify sharedVerifier] verifyUDID:udid runtimeConfig:effectiveConfig completion:^(NSDictionary *response, NSError *verifyError) {
'''
new_method = '''- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                         license:(NSDictionary *)license
                 isNewActivation:(BOOL)isNewActivation {
    [[ZONAuthV2API sharedAPI] fetchRuntimeConfigWithCompletion:^(NSDictionary *config, NSError *configError) {
        if (!config || configError) {
            [self handleVerifyFailureResponse:config error:configError ?: [NSError errorWithDomain:@"ZONAuthV2" code:-30 userInfo:@{NSLocalizedDescriptionKey:@"Runtime Config 不可用"}] udid:udid];
            return;
        }

        NSLog(@"[zonoemenu][auth-v3][VERIFY_CONFIG] signed config ready version=%@ key_id=%@",
              ZONString(config[@"config_version"]), ZONString(config[@"key_id"]));
        [[ZONAuthV2Verify sharedVerifier] verifyUDID:udid runtimeConfig:config completion:^(NSDictionary *response, NSError *verifyError) {
'''
flow = must_replace(flow, old_method, new_method, "verify orchestration legacy params/cache")
flow = must_replace(
    flow,
    "                [ZONAuthV2Storage setLastVerify:response];\n                if (card.length) [ZONAuthV2Storage setCard:card];\n                [self handleVerifySuccess:response license:license ?: @{} isNewActivation:isNewActivation];\n",
    "                [ZONAuthV2Storage setLastVerify:response];\n                [self handleVerifySuccess:response license:license ?: @{} isNewActivation:isNewActivation];\n",
    "verify success card persistence",
)
# Remove private host parameters; presentation is owned by ZONPresentationCoordinator.
flow = flow.replace("presentCardPromptForUDID:udid host:hostViewController message:nil", "presentCardPromptForUDID:udid message:nil")
flow = flow.replace("presentCardPromptForUDID:udid host:hostViewController message:@\"当前设备授权已到期，请输入新的有效卡密。\"", "presentCardPromptForUDID:udid message:@\"当前设备授权已到期，请输入新的有效卡密。\"")
flow = flow.replace("presentCardPromptForUDID:udid host:nil message:", "presentCardPromptForUDID:udid message:")
flow = flow.replace("activateCard:card udid:udid host:nil", "activateCard:card udid:udid")
flow = flow.replace("- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message", "- (void)presentCardPromptForUDID:(NSString *)udid message:(NSString *)message")
flow = flow.replace("- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host", "- (void)activateCard:(NSString *)card udid:(NSString *)udid")
# Replace legacy card-centric generic failure mapping with protocol-aware messages.
old_user_message = '''static NSString *ZONUserMessage(NSString *code, NSString *raw) {
    NSString *lower = raw.lowercaseString ?: @"";
    if ([lower containsString:@"authorization does not apply to this app"]) {
        return @"当前卡密不适用于此应用，请更换有效卡密。";
    }
    if ([code isEqualToString:@"license_invalid"]) {
        if ([lower containsString:@"expired"] || [lower containsString:@"expire"]) return @"卡密已到期，请重新输入有效卡密。";
        return @"卡密无效、已失效或不适用于当前应用，请重新输入有效卡密。";
    }
    if ([code isEqualToString:@"license_expired"] || [code isEqualToString:@"authorization_expired"]) {
        return @"卡密已到期，请重新输入有效卡密。";
    }
    if (!raw.length) return @"授权验证失败，请稍后重试。";

    NSCharacterSet *letters = NSCharacterSet.letterCharacterSet;
    NSUInteger letterCount = 0, nonASCII = 0;
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ([letters characterIsMember:c]) letterCount++;
        if (c > 127) nonASCII++;
    }
    if (letterCount > 6 && nonASCII == 0) return @"授权状态异常，请检查卡密是否有效并重试。";
    return raw;
}
'''
new_user_message = '''static NSString *ZONUserMessage(NSString *code, NSString *raw) {
    NSString *lower = raw.lowercaseString ?: @"";
    if ([lower containsString:@"authorization does not apply to this app"] || [code isEqualToString:@"app_not_authorized"]) {
        return @"当前授权不适用于此应用。";
    }
    if ([code isEqualToString:@"license_invalid"]) {
        if ([lower containsString:@"expired"] || [lower containsString:@"expire"]) return @"卡密已到期，请重新输入有效卡密。";
        return @"卡密无效、已失效或不适用于当前应用，请重新输入有效卡密。";
    }
    if ([code isEqualToString:@"license_expired"] || [code isEqualToString:@"authorization_expired"]) {
        return @"授权已到期，请重新输入有效卡密。";
    }
    if ([code hasPrefix:@"auth_proof_"]) return @"设备授权凭证已失效，请重新验证。";
    if ([code hasPrefix:@"challenge_"]) return @"验证请求已失效，请重试。";
    if ([code hasPrefix:@"device_key_"] || [code hasPrefix:@"device_signature_"]) return @"设备身份验证失败。";
    if ([code isEqualToString:@"runtime_config_invalid"] || [code isEqualToString:@"client_config_invalid"]) return @"验证配置无效，请稍后重试。";
    if (!raw.length) return @"授权验证失败，请稍后重试。";

    BOOL hasNonASCII = NO;
    for (NSUInteger i = 0; i < raw.length; i++) {
        if ([raw characterAtIndex:i] > 127) { hasNonASCII = YES; break; }
    }
    return hasNonASCII ? raw : @"授权验证失败，请稍后重试。";
}
'''
flow = must_replace(flow, old_user_message, new_user_message, "card-centric generic error mapping")
write(flow_rel, flow)

# 4) Collapse AuthV2 storage to values that have real consumers.
storage_h_rel = "testmod/ZONAuthV2/ZONAuthV2Storage.h"
storage_h = read(storage_h_rel)
storage_h = must_replace(storage_h, "+ (nullable NSString *)card;\n+ (void)setCard:(NSString *)card;\n", "", "storage card declarations")
storage_h = storage_h.replace("+ (void)clearCard;", "+ (void)clearAuthorizationSession;")
for block in (
    "+ (nullable NSDictionary *)lastActivation;\n+ (void)setLastActivation:(nullable NSDictionary *)value;\n",
    "+ (nullable NSDictionary *)lastRuntimeConfig;\n+ (void)setLastRuntimeConfig:(nullable NSDictionary *)value;\n",
    "+ (nullable NSDictionary *)lastBootstrap;\n+ (void)setLastBootstrap:(nullable NSDictionary *)value;\n",
):
    storage_h = must_replace(storage_h, block, "", "storage duplicate/write-only cache declaration")
storage_h = storage_h.replace("/// Session-only response/config caches. They deliberately do not survive process exit.\n", "/// Session-only Verify response used by the access layer.\n")
write(storage_h_rel, storage_h)

storage_m_rel = "testmod/ZONAuthV2/ZONAuthV2Storage.m"
storage_m = read(storage_m_rel)
storage_m = storage_m.replace("static NSString *gZONAuthV2SessionCard = nil;\n", "")
storage_m = storage_m.replace("static NSDictionary *gZONAuthV2SessionLastActivation = nil;\n", "")
storage_m = storage_m.replace("static NSDictionary *gZONAuthV2SessionLastRuntimeConfig = nil;\n", "")
storage_m = storage_m.replace("static NSDictionary *gZONAuthV2SessionLastBootstrap = nil;\n", "")
# Remove card accessors.
card_start = storage_m.find("+ (NSString *)card {")
card_end = storage_m.find("+ (NSString *)token {", card_start)
if card_start == -1 or card_end == -1:
    raise SystemExit("storage card accessor block not found")
storage_m = storage_m[:card_start] + storage_m[card_end:]
storage_m = storage_m.replace("+ (void)clearCard {", "+ (void)clearAuthorizationSession {")
storage_m = storage_m.replace("        gZONAuthV2SessionCard = nil;\n", "")
storage_m = storage_m.replace("        gZONAuthV2SessionLastActivation = nil;\n", "")
storage_m = storage_m.replace("        gZONAuthV2SessionLastRuntimeConfig = nil;\n", "")
storage_m = storage_m.replace("        gZONAuthV2SessionLastBootstrap = nil;\n", "")
# Remove write-only/duplicate cache methods between lastVerify and lastNoticeFingerprint.
cache_start = storage_m.find("+ (NSDictionary *)lastActivation {")
cache_end = storage_m.find("+ (NSString *)lastNoticeFingerprint {", cache_start)
if cache_start == -1 or cache_end == -1:
    raise SystemExit("storage obsolete cache method block not found")
storage_m = storage_m[:cache_start] + storage_m[cache_end:]
write(storage_m_rel, storage_m)

# 5) Remove the old BSPHP validation implementation if no runtime code outside
#    that implementation references its exported API/globals.
wx_excluded = (
    "testmod/Bsphp/WX_NongShiFu123.h",
    "testmod/Bsphp/WX_NongShiFu123.mm",
    "testmod/Bsphp/main.m",
    "testmod.xcodeproj/project.pbxproj",
    ".github/workflows",
    "Tests",
    "tools/p79_8j_cleanup_auth_residue.py",
    "ROADMAP.md", "CHANGELOG_DEV.md", "HANDOFF.md", "PROJECT_STATE.json", "KNOWN_ISSUES.md",
)
for symbol in ("WX_NongShiFu123", "软件版本号", "软件公告", "软件描述", "逻辑A", "逻辑B", "解绑扣除时间", "试用模式", "验证状态", "设备特征码", "软件信息"):
    refs = grep_refs(symbol, wx_excluded)
    if refs:
        raise SystemExit(f"refusing to delete legacy BSPHP validation; external {symbol} refs: {refs}")
main_rel = "testmod/Bsphp/main.m"
main = read(main_rel)
main = main.replace('//static __attribute__((constructor)) void _logosLocalInit(void) {\n//    NSLog(@"load1111111111");\n//    [[WX_NongShiFu123 alloc] BSPHP];\n//}\n', '')
main = main.replace('#import "WX_NongShiFu123.h"\n', '')
write(main_rel, main)
for rel in ("testmod/Bsphp/WX_NongShiFu123.h", "testmod/Bsphp/WX_NongShiFu123.mm"):
    p = ROOT / rel
    if p.exists(): p.unlink()

# Config/NetTool is the companion encrypted BSPHP transport. Remove it only if
# no code outside the legacy validation stack consumes NetTool/Config.
legacy_net_candidates = (
    "testmod/Bsphp/Config.h", "testmod/Bsphp/Config.m",
    "testmod/category/NetWorkingApiClient.h", "testmod/category/NetWorkingApiClient.m",
    "testmod/category/DES3Util.h", "testmod/category/DES3Util.m",
    "testmod/category/NSDictionary+StichingStringkeyValue.h", "testmod/category/NSDictionary+StichingStringkeyValue.m",
    "testmod/category/NSString+MD5.h", "testmod/category/NSString+MD5.m",
    "testmod/category/NSString+URLCode.h", "testmod/category/NSString+URLCode.m",
)
net_excluded = legacy_net_candidates + (
    "testmod.xcodeproj/project.pbxproj", ".github/workflows", "Tests", "tools/p79_8j_cleanup_auth_residue.py",
    "ROADMAP.md", "CHANGELOG_DEV.md", "HANDOFF.md", "PROJECT_STATE.json", "KNOWN_ISSUES.md",
)
external_net_refs = []
for symbol in ("NetTool", "NetWorkingApiClient", "DES3Util", "stitchingStringFromDictionary", "BSPHP_PASSWORD", "BSPHP_INSGIN", "BSPHP_TOSGIN"):
    refs = grep_refs(symbol, net_excluded)
    if refs: external_net_refs.extend((symbol, r) for r in refs)
if not external_net_refs:
    for rel in legacy_net_candidates:
        p = ROOT / rel
        if p.exists(): p.unlink()
else:
    print("keeping legacy crypto/network helper set due external refs:", external_net_refs)

# Strip project entries for files we actually removed. Removing every PBX line
# containing the exact basename safely removes build-file, file-ref, group and phase rows.
pbx_rel = "testmod.xcodeproj/project.pbxproj"
pbx = read(pbx_rel)
removed_basenames = [
    "WX_NongShiFu123.h", "WX_NongShiFu123.mm",
]
for rel in legacy_net_candidates:
    if not (ROOT / rel).exists():
        removed_basenames.append(Path(rel).name)
lines = pbx.splitlines(True)
lines = [line for line in lines if not any(f"/* {name}" in line for name in removed_basenames)]
pbx = "".join(lines)
write(pbx_rel, pbx)

# 6) Update v3.1 contract for the cleaned API boundary and add cleanup assertions.
test_rel = "Tests/p79_8i_secretless_auth_v3_contract.py"
test = read(test_rel)
test = must_replace(
    test,
    "runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('- (NSString *)verifyURLForRuntimeConfig:', 1)[0]\n",
    "runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('\\n@end', 1)[0]\n",
    "contract runtime method boundary",
)
test += '''\n# P79.8j auth-residue cleanup: old compatibility/swizzle and duplicate Verify transport are gone.\nassert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.m").exists()\nassert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.h").exists()\nassert "postVerifyBody" not in api\nassert "verifyURLForRuntimeConfig" not in api\nassert "lastBootstrap" not in storage_h\nassert "lastRuntimeConfig" not in storage_h\nassert "lastActivation" not in storage_h\nassert "+ (nullable NSString *)card;" not in storage_h\nassert "clearAuthorizationSession" in storage_h\n'''
write(test_rel, test)

# 7) Version and lightweight project records. Exact CI/artifact IDs are filled
#    after the resulting build succeeds.
write("VERSION", "v1_p79_8j\n")

changelog = read("CHANGELOG_DEV.md")
entry = '''\n## v1_p79_8j — Auth Residue Cleanup\n- Removed detached `ZONAuthV2BindingProbe` swizzle/compatibility source.\n- Removed the obsolete `ZONAuthV2API.postVerifyBody` / Verify URL builder; `ZONAuthV2Verify` is the only Challenge/Verify owner.\n- Removed card propagation/storage from Verify. Card remains activation-only.\n- Removed write-only/duplicate AuthV2 caches (`lastActivation`, `lastRuntimeConfig`, `lastBootstrap`).\n- Replaced card-centric generic Verify errors with protocol-aware v3 messages.\n- Removed legacy BSPHP validation source and its encrypted transport helpers when no external references remain.\n- Preserved UDID-first `/apiface` → optional `/appstore` → signed bootstrap → `/challenge` → `/verify` semantics.\n'''
if "## v1_p79_8j — Auth Residue Cleanup" not in changelog:
    write("CHANGELOG_DEV.md", entry + changelog)

print("P79.8j auth cleanup applied")
