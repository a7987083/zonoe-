from pathlib import Path

root = Path(__file__).resolve().parents[1]
verify = (root / "testmod/ZONAuthV2/ZONAuthV2Verify.m").read_text()
api = (root / "testmod/ZONAuthV2/ZONAuthV2API.m").read_text()
storage_h = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.h").read_text()
storage_m = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.m").read_text()
workflow = (root / ".github/workflows/p79-server-driven-auth-build.yml").read_text()

# P79.8i is an intentional hard cutover: the old shared-secret/HMAC Verify path
# must not remain reachable or injected by CI.
for forbidden in (
    "ZON_VERIFY_SECRET",
    "ZON_VERIFY_SECRET_PLACEHOLDER",
    "CCHmac(",
    "kCCHmacAlgSHA256",
    'protocol_version\"] = @2',
    "requestEnrollmentLicenseCode",
    "设备安全升级",
    "首次升级到新版安全验证",
):
    assert forbidden not in verify, forbidden

for forbidden in (
    "SECRET_PRIMARY",
    "SECRET_FALLBACK_1",
    "SECRET_FALLBACK_2",
    "VERIFY_SECRET_CONFIGURED",
    "ZON_VERIFY_SECRET_PLACEHOLDER",
):
    assert forbidden not in workflow, forbidden

# Required v3 proof chain. Enrollment is server-owned. If the normal UDID-first
# activation flow already has a session card, Verify may attach it; otherwise the
# client still submits the signed proof without opening a second activation UI.
for required in (
    "zonoe-dylib-auth-v3",
    'payload[@"protocol_version"] = @3',
    'device_public_key',
    'device_signature',
    'challenge_id',
    'enrollment_required',
    'license_code',
    'SecKeyCreateRandomKey',
    'kSecAttrKeyTypeECSECPrimeRandom',
    'kSecKeyAlgorithmECDSASignatureMessageX962SHA256',
    'SecKeyCreateSignature',
    'SecKeyVerifySignature',
    'rsa-2048-sha256',
):
    assert required in verify, required

assert 'if (card.length) payload[@"license_code"] = card;' in verify

# The GitHub bootstrap is itself the signed v3 runtime config. The runtime-config
# method must return that object directly and must not make any additional HTTP GET.
runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('- (NSString *)verifyURLForRuntimeConfig:', 1)[0]
assert 'completion(bootstrap, nil)' in runtime_method
assert 'GETAbsoluteURL' not in runtime_method
assert 'using signed bootstrap directly' in runtime_method

# The short-lived token is session-only; no token Keychain/UserDefaults storage.
assert "+ (nullable NSString *)token;" in storage_h
assert "+ (void)setToken:(nullable NSString *)token;" in storage_h
assert "gZONAuthV2SessionToken" in storage_m
assert "setToken:token" in verify
assert "ZONAuthV2SessionToken" not in workflow

print("P79.8i Secretless Auth v3 contract: OK")
