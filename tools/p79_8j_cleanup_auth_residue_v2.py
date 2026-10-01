#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel): return (ROOT / rel).read_text(encoding='utf-8')
def write(rel, s): (ROOT / rel).write_text(s, encoding='utf-8')
def must(s, old, new, label):
    if old not in s: raise SystemExit(f'missing expected block: {label}')
    return s.replace(old, new, 1)

def refs(needle, excluded):
    out=[]
    for p in ROOT.rglob('*'):
        if not p.is_file() or '.git' in p.parts: continue
        rel=p.relative_to(ROOT).as_posix()
        if rel in excluded: continue
        try: data=p.read_text(encoding='utf-8')
        except Exception: continue
        if needle in data: out.append(rel)
    return out

# Proven dead: detached BindingProbe compatibility/swizzle source.
for rel in ('testmod/ZONAuthV2/ZONAuthV2BindingProbe.h','testmod/ZONAuthV2/ZONAuthV2BindingProbe.m'):
    p=ROOT/rel
    if p.exists(): p.unlink()

# Proven dead: duplicate Verify transport in ZONAuthV2API.
api_h_rel='testmod/ZONAuthV2/ZONAuthV2API.h'
api_h=read(api_h_rel)
api_h=must(api_h,
'''- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion;
- (void)postVerifyBody:(NSDictionary *)body
         runtimeConfig:(NSDictionary *)runtimeConfig
            completion:(ZONAuthV2JSONCompletion)completion;
''',
'''- (void)fetchRuntimeConfigWithCompletion:(ZONAuthV2JSONCompletion)completion;
''','API header old Verify transport')
write(api_h_rel,api_h)

api_m_rel='testmod/ZONAuthV2/ZONAuthV2API.m'
api_m=read(api_m_rel)
api_m=must(api_m,
'''            self.sessionBootstrap = normalized;
            [ZONAuthV2Storage setLastBootstrap:normalized];
            if (completion) completion(normalized, nil);
''',
'''            self.sessionBootstrap = normalized;
            if (completion) completion(normalized, nil);
''','duplicate bootstrap cache write')
api_m=must(api_m,
'''
        NSDictionary *lastKnownGood = [ZONAuthV2Storage lastBootstrap];
        if ([self isUsableBootstrap:lastKnownGood]) {
            self.sessionBootstrap = lastKnownGood;
            if (completion) completion(lastKnownGood, nil);
            return;
        }
''','\n','duplicate bootstrap fallback')
start=api_m.find('- (NSString *)verifyURLForRuntimeConfig:')
end=api_m.find('\n@end',start)
if start<0 or end<0: raise SystemExit('old API Verify methods not found')
api_m=api_m[:start]+api_m[end:]
write(api_m_rel,api_m)

# Flow cleanup. Keep lastRuntimeConfig because cloud-save fresh Verify consumes it.
flow_rel='testmod/ZONAuthV2/ZONAuthV2Flow.m'
flow=read(flow_rel)
flow=must(flow,
'''static BOOL ZONLicenseIsAuthorized(NSDictionary *license) {
    return ZONUDIDAuthorizationStateFromPayload(license) == ZONUDIDAuthorizationStateActive;
}

''','', 'unused license helper')
flow=must(flow,
'''        if (state == ZONUDIDAuthorizationStateActive) {
            NSString *savedCard = [ZONAuthV2Storage card] ?: @"";
            NSLog(@"[zonoemenu][auth-v2][P79.8A_UDID_GATE] active UDID authorization; entering runtime-config + Verify without card prompt");
            [self fetchConfigAndVerifyUDID:udid card:savedCard license:snapshot host:nil isNewActivation:NO];
            return;
        }
''',
'''        if (state == ZONUDIDAuthorizationStateActive) {
            NSLog(@"[zonoemenu][auth-v3][UDID_GATE] active UDID authorization; entering signed Runtime Config + Verify");
            [self fetchConfigAndVerifyUDID:udid license:snapshot isNewActivation:NO];
            return;
        }
''','active branch card forwarding')
flow=must(flow,'            [ZONAuthV2Storage setLastActivation:activationResponse];\n','', 'write-only lastActivation')
flow=must(flow,
'                [self fetchConfigAndVerifyUDID:udid card:card license:afterLicense host:nil isNewActivation:YES];\n',
'                [self fetchConfigAndVerifyUDID:udid license:afterLicense isNewActivation:YES];\n','activation card forwarding')
flow=must(flow,
'''- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                            card:(NSString *)card
                         license:(NSDictionary *)license
                            host:(UIViewController *)host
                 isNewActivation:(BOOL)isNewActivation {
''',
'''- (void)fetchConfigAndVerifyUDID:(NSString *)udid
                         license:(NSDictionary *)license
                 isNewActivation:(BOOL)isNewActivation {
''','Verify orchestration signature')
flow=must(flow,
'''                [ZONAuthV2Storage setLastVerify:response];
                if (card.length) [ZONAuthV2Storage setCard:card];
                [self handleVerifySuccess:response license:license ?: @{} isNewActivation:isNewActivation];
''',
'''                [ZONAuthV2Storage setLastVerify:response];
                [self handleVerifySuccess:response license:license ?: @{} isNewActivation:isNewActivation];
''','Verify success card storage')

# clearCard is only an AuthV2Flow/Storage artifact; rename it to what it actually clears.
extra=refs('clearCard', {flow_rel,'testmod/ZONAuthV2/ZONAuthV2Storage.h','testmod/ZONAuthV2/ZONAuthV2Storage.m','tools/p79_8j_cleanup_auth_residue.py','tools/p79_8j_cleanup_auth_residue_v2.py'})
if extra: raise SystemExit(f'clearCard has external consumers: {extra}')
flow=flow.replace('[ZONAuthV2Storage clearCard];','[ZONAuthV2Storage clearAuthorizationSession];')

# Private host arguments are unused: ZONPresentationCoordinator owns presentation.
flow=flow.replace('presentCardPromptForUDID:udid host:hostViewController message:nil','presentCardPromptForUDID:udid message:nil')
flow=flow.replace('presentCardPromptForUDID:udid host:hostViewController message:@"当前设备授权已到期，请输入新的有效卡密。"','presentCardPromptForUDID:udid message:@"当前设备授权已到期，请输入新的有效卡密。"')
flow=flow.replace('presentCardPromptForUDID:udid host:nil message:','presentCardPromptForUDID:udid message:')
flow=flow.replace('activateCard:card udid:udid host:nil','activateCard:card udid:udid')
flow=flow.replace('- (void)presentCardPromptForUDID:(NSString *)udid host:(UIViewController *)host message:(NSString *)message','- (void)presentCardPromptForUDID:(NSString *)udid message:(NSString *)message')
flow=flow.replace('- (void)activateCard:(NSString *)card udid:(NSString *)udid host:(UIViewController *)host','- (void)activateCard:(NSString *)card udid:(NSString *)udid')

old='''static NSString *ZONUserMessage(NSString *code, NSString *raw) {
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
new='''static NSString *ZONUserMessage(NSString *code, NSString *raw) {
    NSString *lower = raw.lowercaseString ?: @"";
    if ([lower containsString:@"authorization does not apply to this app"] || [code isEqualToString:@"app_not_authorized"]) return @"当前授权不适用于此应用。";
    if ([code isEqualToString:@"license_invalid"]) {
        if ([lower containsString:@"expired"] || [lower containsString:@"expire"]) return @"卡密已到期，请重新输入有效卡密。";
        return @"卡密无效、已失效或不适用于当前应用，请重新输入有效卡密。";
    }
    if ([code isEqualToString:@"license_expired"] || [code isEqualToString:@"authorization_expired"]) return @"授权已到期，请重新输入有效卡密。";
    if ([code hasPrefix:@"auth_proof_"]) return @"设备授权凭证已失效，请重新验证。";
    if ([code hasPrefix:@"challenge_"]) return @"验证请求已失效，请重试。";
    if ([code hasPrefix:@"device_key_"] || [code hasPrefix:@"device_signature_"]) return @"设备身份验证失败。";
    if ([code isEqualToString:@"runtime_config_invalid"] || [code isEqualToString:@"client_config_invalid"]) return @"验证配置无效，请稍后重试。";
    if (!raw.length) return @"授权验证失败，请稍后重试。";
    for (NSUInteger i = 0; i < raw.length; i++) if ([raw characterAtIndex:i] > 127) return raw;
    return @"授权验证失败，请稍后重试。";
}
'''
flow=must(flow,old,new,'protocol-aware error mapping')
write(flow_rel,flow)

# Storage: remove only proven-unused card, lastActivation and duplicate lastBootstrap.
storage_h_rel='testmod/ZONAuthV2/ZONAuthV2Storage.h'
h=read(storage_h_rel)
h=must(h,'+ (nullable NSString *)card;\n+ (void)setCard:(NSString *)card;\n','', 'card declarations')
h=h.replace('+ (void)clearCard;','+ (void)clearAuthorizationSession;')
h=must(h,'+ (nullable NSDictionary *)lastActivation;\n+ (void)setLastActivation:(nullable NSDictionary *)value;\n','', 'lastActivation declarations')
h=must(h,'+ (nullable NSDictionary *)lastBootstrap;\n+ (void)setLastBootstrap:(nullable NSDictionary *)value;\n','', 'lastBootstrap declarations')
write(storage_h_rel,h)

storage_m_rel='testmod/ZONAuthV2/ZONAuthV2Storage.m'
m=read(storage_m_rel)
m=m.replace('static NSString *gZONAuthV2SessionCard = nil;\n','')
m=m.replace('static NSDictionary *gZONAuthV2SessionLastActivation = nil;\n','')
m=m.replace('static NSDictionary *gZONAuthV2SessionLastBootstrap = nil;\n','')
a=m.find('+ (NSString *)card {'); b=m.find('+ (NSString *)token {',a)
if a<0 or b<0: raise SystemExit('card accessor block missing')
m=m[:a]+m[b:]
m=m.replace('+ (void)clearCard {','+ (void)clearAuthorizationSession {')
m=m.replace('        gZONAuthV2SessionCard = nil;\n','')
m=m.replace('        gZONAuthV2SessionLastActivation = nil;\n','')
m=m.replace('        gZONAuthV2SessionLastBootstrap = nil;\n','')
# Remove lastActivation methods only.
a=m.find('+ (NSDictionary *)lastActivation {'); b=m.find('+ (NSDictionary *)lastRuntimeConfig {',a)
if a<0 or b<0: raise SystemExit('lastActivation method block missing')
m=m[:a]+m[b:]
# Remove lastBootstrap methods only, retaining lastRuntimeConfig for cloud save.
a=m.find('+ (NSDictionary *)lastBootstrap {'); b=m.find('+ (NSString *)lastNoticeFingerprint {',a)
if a<0 or b<0: raise SystemExit('lastBootstrap method block missing')
m=m[:a]+m[b:]
write(storage_m_rel,m)

# Remove stale WX import only from main.m: runtime WX fallback remains alive elsewhere,
# so the BSPHP source itself is intentionally retained.
main_rel='testmod/Bsphp/main.m'
main=read(main_rel)
main=main.replace('//static __attribute__((constructor)) void _logosLocalInit(void) {\n//    NSLog(@"load1111111111");\n//    [[WX_NongShiFu123 alloc] BSPHP];\n//}\n','')
main=main.replace('#import "WX_NongShiFu123.h"\n','')
write(main_rel,main)

coord_rel='testmod/ZONServices/ZONAuthorizationCoordinator.m'
coord=read(coord_rel)
coord=coord.replace('// Kept as a compatibility startup hook. Legacy Bsphp remains in-tree for reference,\n    // but P79 authorization no longer calls WX_NongShiFu123/BSPHP/BSPHPy/loada.\n','// Compatibility startup hook retained for the authorization reset service.\n    // The primary P79 authorization engine is ZONAuthV2Flow.\n')
write(coord_rel,coord)

# Contract adapts to API boundary and asserts the deleted residue stays deleted.
test_rel='Tests/p79_8i_secretless_auth_v3_contract.py'
t=read(test_rel)
t=must(t,"runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('- (NSString *)verifyURLForRuntimeConfig:', 1)[0]\n","runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('\\n@end', 1)[0]\n",'contract API boundary')
if 'P79.8j proven-dead auth residue' not in t:
    t += '''\n# P79.8j proven-dead auth residue must not return.\nassert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.m").exists()\nassert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.h").exists()\nassert "postVerifyBody" not in api\nassert "verifyURLForRuntimeConfig" not in api\nassert "lastBootstrap" not in storage_h\nassert "lastActivation" not in storage_h\nassert "+ (nullable NSString *)card;" not in storage_h\nassert "lastRuntimeConfig" in storage_h  # still consumed by cloud-save fresh Verify\nassert "clearAuthorizationSession" in storage_h\n'''
write(test_rel,t)

write('VERSION','v1_p79_8j\n')
chg=read('CHANGELOG_DEV.md')
entry='''\n## v1_p79_8j — Auth Verification Residue Cleanup\n- Removed detached `ZONAuthV2BindingProbe` compatibility/swizzle source.\n- Removed duplicate `ZONAuthV2API` Verify transport; `ZONAuthV2Verify` exclusively owns `/challenge` and `/verify`.\n- Removed card propagation/storage from Verify; card remains activation-only.\n- Removed write-only `lastActivation` and duplicate `lastBootstrap` session caches.\n- Kept `lastRuntimeConfig` because cloud-save fresh Verify still consumes it.\n- Kept legacy `WX_NongShiFu123`/Config source because the live legacy-UDID fallback and cloud-save purchase/config paths still reference it; it is not dead code yet.\n- Replaced card-centric generic Verify errors with v3 protocol-aware messages.\n'''
if '## v1_p79_8j — Auth Verification Residue Cleanup' not in chg: write('CHANGELOG_DEV.md',entry+chg)

old=ROOT/'tools/p79_8j_cleanup_auth_residue.py'
if old.exists(): old.unlink()
print('P79.8j safe auth cleanup applied')
