# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Current branch: `work/p79.8-udid-first-rebuild`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md` → `ARCHITECTURE.md` → `REFACTOR_REVIEW.md`.

## Current target — P79.8i Secretless Auth v3 / UDID auth-proof enrollment
- VERSION: `v1_p79_8i`.
- Functional auth-proof HEAD before documentation sync: `980bc43656c8f609ea1c1c8f596d6128c5ae623e`.
- CI Run `36856203863` / #84: success.
- Artifact ID `11157763459`.
- Artifact digest: `sha256:18fd793a2d930f63774e244e8c88d75849702e0542f6791b89f5d7033acdc35f`.
- Dylib SHA256: `a30afd52caf5640ab27aa907b5da70b4450c8b336b115a43ae0a3cf0184525af`.
- Dylib size: 3,321,952 bytes.
- Architectures: arm64 + arm64e PAC00.
- Status: CLIENT CI PASSED / SERVER CONTRACT PENDING / DEVICE PENDING.
- P79.8g remains the latest device-passed baseline.

## Actual business authorization model — do not reinterpret
- Authorization is **UDID-level**, not App-level.
- Startup first acquires/reuses DZUDID, then calls `/index/index/apiface?udid=<UDID>`.
- If the UDID is already active, the client does not ask for a card and does not call `/appstore`.
- If the UDID has no activation record, or is expired, the user enters a card and the client calls `/appstore`, then calls `/apiface` again to prove the authorization state actually became active.
- Once a UDID is active, installing later Apps on that same UDID must not require the card again.
- P-256 device/App keys are proof-of-possession keys layered after business authorization; they must not replace the UDID-first authorization model.

## Current Secretless v3 client contract
- Old long-lived shared Verify Secret/HMAC is removed; no compatibility fallback exists.
- Signed GitHub bootstrap is the Runtime Config and is verified with RSA-2048/SHA-256 using the embedded server public key/key id.
- No second `/index/dylib_verify/config` request exists.
- Each App generates/reuses an ECDSA P-256 private key in Keychain using `AfterFirstUnlockThisDeviceOnly`; only the public key is sent to the server.
- `ZONAuthV2API.fetchLicenseForUDID` captures top-level `/apiface` `auth_proof` into `ZONAuthV2Storage` as session-only state.
- Missing proof causes Verify to fail closed with `auth_proof_unavailable` before `/challenge`.
- `/challenge` sends `udid`, `dylib_key`, `device_public_key`, `auth_proof`.
- Once challenge creation succeeds, the client clears the local proof to prevent reuse.
- Verify proof still signs `zonoe-dylib-auth-v3` canonical challenge/app/dylib identity fields with ECDSA/SHA-256.
- `/verify` no longer attaches `license_code` for first-key enrollment.
- The secondary enrollment/card UI remains removed.
- Short-lived Verify token remains session-only.

## Required matching server behavior
Before this client can be promoted on device, server must:
1. Return `auth_proof` plus `auth_proof_expires_at` on active `/apiface` responses.
2. Make the proof short-lived and server-verifiable, bound at least to UDID, `dylib_key`, authorization, issue/expiry time and unique jti/nonce.
3. Accept `auth_proof` in `/index/dylib_verify/challenge` and verify signature/authenticity, expiry, UDID match, `dylib_key` match and current active authorization.
4. Bind challenge to the submitted public-key fingerprint/device_key_id.
5. Allow first public-key registration only for a challenge created from a valid proof.
6. Stop requiring `license_code` in `/verify` for first-key enrollment.
7. Permit a new App on the same active UDID to register its own P-256 key from a fresh `/apiface` proof without card re-entry.
8. Reject replayed/expired/mismatched proofs and consumed challenges.

## Preserved architecture / behavior
- `ZONFeatureAccessProvider`, `ZONRuntimeCapabilityService`, `ZONFeatureDispatcher`, and `ZONFeatureRegistry` remain active boundaries.
- Feature identifiers, legacy tags, section ordering, renderer behavior and current permission model are unchanged by this auth-proof cutover.
- `base.cloud-save` still uses `extra_menu` for visibility and `extra_features` for action.
- `runtime.iap-noads` and passive Satella contract remain unchanged.
- R4 typed descriptors and R5 AuthV2Flow decomposition remain paused.

## CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- `p79.8i-secretless-auth-v3-contract: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.

## Device gate after server deployment
1. Already-active UDID reaches `/challenge` with `auth_proof` and no card prompt.
2. Fresh card activation runs `/appstore` only once, post-activation `/apiface` supplies proof, then Verify succeeds.
3. Second App on same UDID gets a fresh proof, registers its own P-256 key, and never asks for the card.
4. Subsequent launches reuse the App Keychain key.
5. Verify returns expected access/permissions/token and menu opens normally.
6. Missing/expired/replayed/mismatched proof fails closed.
7. Passive runtime path remains normal.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five project-state files synchronized after development/build/validation.
- Never reintroduce a long-lived shared Verify Secret into a public client.
- Server private signing material stays server-side; the client contains only server verification public material plus its own P-256 private key.
