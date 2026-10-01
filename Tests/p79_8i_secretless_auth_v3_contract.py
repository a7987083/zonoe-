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

# Required v3.1 proof chain. The existing UDID-first /apiface gate supplies a
# short-lived auth_proof. The exact same proof must be sent to Challenge and
# Verify and must be covered by the device signature canonical text.
for required in (
    "zonoe-dylib-auth-v3",
    'payload[@"protocol_version"] = @3',
    'device_public_key',
    'device_signature',
    'challenge_id',
    'auth_proof',
    'auth_proof_unavailable',
    '[ZONAuthV2Storage authProof]',
    'payload[@"auth_proof"] = authProof;',
    'SecKeyCreateRandomKey',
    'kSecAttrKeyTypeECSECPrimeRandom',
    'kSecKeyAlgorithmECDSASignatureMessageX962SHA256',
    'SecKeyCreateSignature',
    'SecKeyVerifySignature',
    'rsa-2048-sha256',
):
    assert required in verify, required

# Challenge carries auth_proof.
challenge_method = verify.split('NSDictionary *challengePayload = @{', 1)[1].split('};', 1)[0]
assert '@"auth_proof": authProof' in challenge_method

# Verify carries the same auth_proof and it is assigned before signing.
verify_flow = verify.split('NSMutableDictionary *payload = [context mutableCopy];', 1)[1].split('- (void)submitVerifyPayload:', 1)[0]
assert 'payload[@"auth_proof"] = authProof;' in verify_flow
assert verify_flow.index('payload[@"auth_proof"] = authProof;') < verify_flow.index('canonicalProof:payload')

# v3.1 canonical ordering is fixed by the generated API package:
# challenge_id, challenge, auth_proof, udid, bundle_id, ...
canonical = verify.split('- (NSString *)canonicalProof:', 1)[1].split('- (SecKeyRef)devicePrivateKey', 1)[0]
ordered = [
    'payload[@"challenge_id"]',
    'payload[@"challenge"]',
    'payload[@"auth_proof"]',
    'payload[@"udid"]',
    'payload[@"bundle_id"]',
    'payload[@"dylib_key"]',
    'payload[@"dylib_version"]',
    'payload[@"dylib_build"]',
    'payload[@"dylib_sha256"]',
    'payload[@"app_executable"]',
    'payload[@"app_macho_uuid"]',
    'payload[@"app_version"]',
    'payload[@"app_build"]',
]
positions = [canonical.index(item) for item in ordered]
assert positions == sorted(positions), positions

# Do not consume auth_proof after Challenge. Clear it only when the Verify HTTP
# request completes, so the exact same proof remains available for /verify.
challenge_to_submit = verify.split('[self postJSON:challengePayload', 1)[1].split('- (void)submitVerifyPayload:', 1)[0]
assert '[ZONAuthV2Storage setAuthProof:nil]' not in challenge_to_submit
submit_method = verify.split('- (void)submitVerifyPayload:', 1)[1].split('#pragma mark - Runtime Config signature', 1)[0]
assert '[ZONAuthV2Storage setAuthProof:nil]' in submit_method

# /apiface is the source of the authorization proof. Every fresh license lookup
# refreshes or clears the session-only proof without changing UDID-first semantics.
license_method = api.split('- (void)fetchLicenseForUDID:', 1)[1].split('- (void)activateUDID:', 1)[0]
assert 'json[@"auth_proof"]' in license_method
assert '[ZONAuthV2Storage setAuthProof:' in license_method
assert 'AUTH_PROOF' in license_method

# The GitHub bootstrap remains the signed runtime config in this product client.
# Do not reintroduce the previously removed second /config hop as part of v3.1.
runtime_method = api.split('- (void)fetchRuntimeConfigWithCompletion:', 1)[1].split('\n@end', 1)[0]
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

print("P79.8i Secretless Auth v3.1 auth-proof contract: OK")

# P79.8j proven-dead auth residue must not return.
assert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.m").exists()
assert not (root / "testmod/ZONAuthV2/ZONAuthV2BindingProbe.h").exists()
assert "postVerifyBody" not in api
assert "verifyURLForRuntimeConfig" not in api
assert "lastBootstrap" not in storage_h
assert "lastActivation" not in storage_h
assert "+ (nullable NSString *)card;" not in storage_h
assert "lastRuntimeConfig" in storage_h  # still consumed by cloud-save fresh Verify
assert "clearAuthorizationSession" in storage_h
