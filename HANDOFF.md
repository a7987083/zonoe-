# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8i Secretless Auth v3 Cutover
- VERSION: `v1_p79_8i`.
- Build HEAD: `03a81ac810c849a10b90a76b06aea3ee9b81db3d`.
- CI Run `36831060055` / #70: success.
- Artifact ID `11146139879`, digest `sha256:d1c1ca3bc161edf027953c2e5b68274d57318556b0c2598dec23b74d0edd19fe`.
- Dylib SHA256: `df8470f296d6d62e0196aea040175e16deab3f78077564b2403dbe2f940a44ad`.
- Dylib size: 3,322,560 bytes.
- Architectures: arm64 + arm64e PAC00.
- Status: CI PASSED / DEVICE PENDING.
- P79.8g remains the latest device-passed baseline.

## P79.8i authentication contract
- The old long-lived shared Verify Secret/HMAC path is removed from active client code; there is no compatibility fallback.
- CI no longer reads or injects `ZON_VERIFY_SECRET`, `VERIFY_SECRET`, or `DYLIB_VERIFY_SECRET`.
- Runtime Config must pass RSA-2048/SHA-256 verification using the embedded server public key and expected key id.
- Each device owns a persistent ECDSA P-256 private key in Keychain using `AfterFirstUnlockThisDeviceOnly`; only its public key is sent to the server.
- Challenge request sends `udid`, `dylib_key`, and `device_public_key`.
- Verify proof uses protocol v3 canonical prefix `zonoe-dylib-auth-v3` and signs challenge + UDID + app identity + dylib identity with ECDSA/SHA-256.
- Verify response short-lived token is stored session-only in `ZONAuthV2Storage`; token/Verify responses are not persisted across process exit.
- `/index/index/apiface?udid=...` and `/appstore` authorization semantics are unchanged.

## Upgrade behavior for already-active UDIDs
- Existing active UDIDs still enter Runtime Config + Verify without the legacy activation prompt.
- If v3 challenge returns `enrollment_required=true` and no current session card exists, the client presents a one-time `设备安全升级` card prompt.
- That card is used only as `license_code` for the device-public-key enrollment request; the client does **not** re-run `/appstore` activation.
- After successful enrollment, subsequent launches should reuse the same Keychain P-256 key and should not request the card again unless the server explicitly requires re-enrollment.

## Preserved architecture / behavior
- `ZONFeatureAccessProvider`, `ZONRuntimeCapabilityService`, `ZONFeatureDispatcher`, and `ZONFeatureRegistry` remain the active boundaries.
- Feature identifiers, legacy tags, section ordering, renderer behavior, and current server permission model are unchanged by P79.8i.
- `base.cloud-save` still uses `extra_menu` for visibility and `extra_features` for action.
- `runtime.iap-noads` still writes the existing runtime preferences and delegates passive activation to `ZONRuntimeCapabilityService`.
- Satella names/RVAs/signatures/mapped-range/PAC/one-shot/no-host-dlopen contract remains unchanged.
- R4 typed descriptors and R5 AuthV2Flow decomposition remain paused.

## Test / CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- `p79.8i-secretless-auth-v3-contract: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Final binary string evidence: `ZON_VERIFY_SECRET=0`, placeholder `=0`, `zonoe-dylib-auth-v3=2`, `device_signature=4`, `/challenge=2`, `rsa-2048-sha256=2`.
- Raw CI candidate is the release candidate; the old `*_secret_configured.dylib` post-build patch workflow is retired.

## P79.8i device gate
1. Already-active UDID upgrades to v3 and completes one-time device-key enrollment when the server requests it.
2. Fresh card activation reaches v3 Verify using the current session card for first enrollment.
3. Second launch reuses the device P-256 Keychain key without card re-entry.
4. Signed Runtime Config validates and Verify returns the expected `access_level`, `permissions`, token, notice/update payloads.
5. Menu opens with the expected feature ordering/visibility.
6. Cancelled/invalid enrollment fails closed.
7. `runtime.iap-noads` / passive Satella path remains normal.

## Remaining separate regressions
- P79.8c VIP cloud permission matrix remains independently pending.
- P79.8b full persistence regression remains independently pending beyond the P0 reset boundary.

## Deferred work
- The second/source-controlled external dylib exported interface and standalone button remain deferred.
- Business APIs may consume the short-lived token later; P79.8i only establishes/retains the token in session and replaces the old Verify authentication root.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Never reintroduce a long-lived shared Verify Secret into a public client.
- Server private signing material stays server-side; the client contains only the server verification public key plus its own per-device private key.
