from pathlib import Path

root = Path(__file__).resolve().parents[1]
verify = (root / "testmod/ZONAuthV2/ZONAuthV2Verify.m").read_text()
api = (root / "testmod/ZONAuthV2/ZONAuthV2API.m").read_text()
storage_h = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.h").read_text()
storage_m = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.m").read_text()
workflow = (root / ".github/workflows/p79-server-driven-auth-build.yml").read_text()

# P79.8i is an intentional hard cutover: the old shared-secret/HMAC Verify path
# and card-backed Verify enrollment must not remain reachable or injected by CI.
for forbidden in (
    "ZON_VERIFY_SECRET",
    "ZON_VERIFY_SECRET_PLACEHOLDER",
    "CCHmac(",
    "kCCHmacAlgSHA256",
    'protocol_version\"] = @2',
    "requestEnrollmentLicenseCode",
    "设备安全升级",
    "首次升级到新版安全验证",
    'payload[@"license_code"]',
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

# Required v3 proof chain. The existing UDID-first /apiface gate supplies a
# short-lived auth_proof. Verify must require it before challenge creation and
# attach it to the challenge request. No second card prompt/enrollment path exists.
for required in (
    "zonoe-dylib-auth-v3",
    'payload[@"protocol_version"] = @3',
    'device_public_key',
    'device_signature',
    'challenge_id',
    'auth_proof',
    'auth_proof_unavailable',
    '[ZONAuthV2Storage authProof]',
    '[ZONAuthV2Storage setAuthProof:nil]',
    'SecKeyCreateRandomKey',
    'kSecAttrKeyTypeECSECPrimeRandom',
    'kSecKeyAlgorithmECDSASignatureMessageX962SHA256',
    'SecKeyCreateSignature',
    'SecKeyVerifySignature',
    'rsa-2048-sha256',
):
    assert required in verify, required

# /apiface is the only source of the enrollment authorization proof. Every fresh
# license lookup refreshes or clears the session-only proof.
license_method = api.split('- (void)fetchLicenseForUDID:', 1)[1].split('- (void)activateUDID:', 1)[0]
assert 'json[@"auth_proof"]' in license_method
assert '[ZONAuthV2Storage setAuthProof:' in license_method
assert 'AUTH_PROOF' in license_method

# The GitHub bootstrap is itself the signed v3 runtime config. The runtime-config
# method must return that object directly and must not make any additional HTTP GET.
runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('- (NSString *)verifyURLForRuntimeConfig:', 1)[0]
assert 'completion(bootstrap, nil)' in runtime_method
assert 'GETAbsoluteURL' not in runtime_method
assert 'using signed bootstrap directly' in runtime_method

# Short-lived token and auth_proof are session-only; neither is persisted.
assert "+ (nullable NSString *)token;" in storage_h
assert "+ (void)setToken:(nullable NSString *)token;" in storage_h
assert "+ (nullable NSString *)authProof;" in storage_h
assert "+ (void)setAuthProof:(nullable NSString *)authProof;" in storage_h
assert "gZONAuthV2SessionToken" in storage_m
assert "gZONAuthV2SessionAuthProof" in storage_m
assert "setToken:token" in verify
assert "ZONAuthV2SessionToken" not in workflow
assert "ZONAuthV2SessionAuthProof" not in workflow

print("P79.8i Secretless Auth v3 auth-proof contract: OK")
