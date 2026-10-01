# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.8i Secretless Auth v3 Cutover — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8i`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `03a81ac810c849a10b90a76b06aea3ee9b81db3d`.
- CI Run `36831060055` / #70: success.
- Artifact ID `11146139879`, digest `sha256:d1c1ca3bc161edf027953c2e5b68274d57318556b0c2598dec23b74d0edd19fe`.
- Dylib SHA256: `df8470f296d6d62e0196aea040175e16deab3f78077564b2403dbe2f940a44ad`.
- Universal `arm64 + arm64e (PAC00)`.
- Public client no longer contains or receives a long-lived shared Verify Secret.

### P79.8i delivered
1. Hard-cut old Verify Secret/HMAC protocol; no backward compatibility path remains in active Verify.
2. Runtime Config is accepted only after RSA-2048/SHA-256 verification against the embedded server public key/key id.
3. Per-device ECDSA P-256 private key is generated/reused from Keychain with `AfterFirstUnlockThisDeviceOnly` accessibility.
4. Challenge request sends `udid + dylib_key + device_public_key`.
5. Verify proof uses protocol v3 canonical prefix `zonoe-dylib-auth-v3` plus challenge/app/dylib identity fields.
6. `device_signature` uses `SecKeyCreateSignature(...ECDSASignatureMessageX962SHA256...)`.
7. Verify response short-lived token is stored session-only in `ZONAuthV2Storage`; it is not persisted to Keychain/UserDefaults.
8. `/index/index/apiface?udid=...` and `/appstore` authorization semantics remain unchanged.
9. Existing active UDIDs that receive `enrollment_required=true` get a one-time license-code prompt solely for device-key enrollment; it does not re-run `/appstore` activation.
10. Existing menu/R3/Satella/runtime-capability architecture is unchanged.
11. CI no longer reads `ZON_VERIFY_SECRET`, `VERIFY_SECRET`, or `DYLIB_VERIFY_SECRET`, and no post-build Secret injection exists.
12. Release candidate is the raw CI dylib; `*_secret_configured.dylib` is retired.

### P79.8i verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- `p79.8i-secretless-auth-v3-contract: PASS`.
- Xcode 16.4 `arm64 + arm64e` build: PASS.
- Binary string evidence: `ZON_VERIFY_SECRET=0`, placeholder `=0`, `zonoe-dylib-auth-v3=2`, `device_signature=4`, `/challenge=2`.

## Latest device-passed baselines
- P79.8f: closed P0 startup/reset/runtime-safety baseline — DEVICE PASSED.
- P79.8g: R2 Runtime Capability extraction — DEVICE PASSED and still the latest device-verified baseline.
- P79.8h: CI passed but was not separately promoted before the P79.8i auth cutover.
- P79.8i: CI PASSED / DEVICE PENDING.

## P79.8i device gate
1. Already-active UDID reaches v3 challenge/verify and, when requested, completes the one-time device-key enrollment prompt.
2. Fresh card activation reaches v3 Verify using the current session card for first enrollment.
3. Second launch reuses the same P-256 Keychain key and does not request the card again.
4. Signed Runtime Config validates and the v3 Verify returns `access_level`, `permissions`, token, notice/update data as expected.
5. Menu opens with unchanged feature ordering/visibility for the current authorization.
6. Invalid/cancelled enrollment fails closed.
7. `runtime.iap-noads` / passive Satella path remains normal.

## Remaining separate regression gates
- P79.8c cloud permission matrix remains independently pending: `basic` hides `VIP云存档`; `app_plus/global_plus` expose it; actual action still requires fresh Verify.
- P79.8b full persistence regression remains independently pending beyond the P0 protected-key reset boundary.

## Deferred external-dylib integration
- The source-controlled external dylib exported interface and standalone button remain intentionally deferred.
- `ZONFeatureAccessProvider` + `ZONRuntimeCapabilityService` remain the prepared integration boundary.

## Architecture policy after P79.8i
- Keep `ZONRuntimeCapabilityService`, `ZONFeatureAccessProvider`, `ZONFeatureDispatcher`, `ZONFeatureRegistry` as current boundaries.
- R4 typed feature descriptors and R5 God Object decomposition remain paused until product work requires them.
- Do not introduce Protocol/Adapter/Factory/DI layers only for architectural symmetry.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never put a long-lived shared Verify Secret back into a public client.
6. Server private signing material must remain server-side; the client may contain only verification public keys and its own per-device private key.

# Next Task
Run the P79.8i Secretless Auth v3 device gate against the deployed server. P79.8g remains the device-passed fallback baseline until P79.8i is explicitly reported normal.
