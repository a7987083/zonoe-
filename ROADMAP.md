# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.8i Secretless Auth v3 / UDID auth-proof enrollment — CI PASSED / SERVER PENDING / DEVICE PENDING
- VERSION: `v1_p79_8i`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional auth-proof HEAD before documentation sync: `980bc43656c8f609ea1c1c8f596d6128c5ae623e`.
- CI Run `36856203863` / #84: success.
- Artifact ID `11157763459`, digest `sha256:18fd793a2d930f63774e244e8c88d75849702e0542f6791b89f5d7033acdc35f`.
- Dylib SHA256: `a30afd52caf5640ab27aa907b5da70b4450c8b336b115a43ae0a3cf0184525af`, size 3,321,952 bytes.
- Universal `arm64 + arm64e (PAC00)`.
- Latest device-passed baseline remains P79.8g.

### Frozen authorization model
1. Startup identity is DZUDID / UDID-first.
2. `/index/index/apiface?udid=...` determines whether the UDID is already authorized.
3. Card input and `/appstore` are used only when the UDID has no valid authorization or the authorization is expired.
4. Once a UDID is active, later Apps on the same UDID must not require the card again.
5. App-specific P-256 keys are proof-of-possession keys, not the business authorization root.

### P79.8i client contract now delivered
1. Old long-lived Verify Secret/HMAC path remains fully removed.
2. Signed GitHub bootstrap is used directly as Runtime Config after RSA-2048/SHA-256 verification; no second `/index/dylib_verify/config` hop.
3. Per-App ECDSA P-256 private key remains in Keychain with `AfterFirstUnlockThisDeviceOnly`.
4. Every successful `/apiface` lookup refreshes session-only `auth_proof`; failed lookups clear it.
5. Verify refuses to create a challenge if `auth_proof` is missing (`auth_proof_unavailable`).
6. `/challenge` now sends `udid + dylib_key + device_public_key + auth_proof`.
7. Client clears the local short-lived proof after the server accepts the challenge.
8. `/verify` no longer sends `license_code` for device-key enrollment.
9. The removed secondary `设备安全升级` / card-enrollment UI remains removed.
10. Existing `ZONAuthV2Flow` UDID-first state machine and `/appstore` business semantics are unchanged.
11. Verify token and `auth_proof` are session-only and are not persisted to UserDefaults or the AuthV2 Keychain namespace.
12. R3 feature access, runtime capability, passive Satella and current menu behavior are untouched.

### Matching server contract required before device test
The deployed server must be updated before this client can pass the device gate:
- Active `/apiface` response must include `auth_proof` and `auth_proof_expires_at`.
- `auth_proof` must be a short-lived server-verifiable authorization proof bound at least to UDID, `dylib_key`, current authorization and expiry/jti.
- `/challenge` must accept and validate `auth_proof`, bind the resulting challenge to the submitted public-key fingerprint, and reject stale/replayed/mismatched proofs.
- `/verify` must no longer require `license_code` for first-key enrollment.
- First public-key registration is allowed only from a challenge created with a valid authorization proof.
- Multiple Apps on the same active UDID may register separate P-256 keys without re-entering the card.

### CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- `p79.8i-secretless-auth-v3-contract: PASS`.
- Xcode 16.4 `arm64 + arm64e` build: PASS.

## P79.8i device gate after server deployment
1. Already-active UDID receives `auth_proof`, reaches `/challenge`, and never sees a card prompt.
2. Fresh card activation runs `/appstore` once, the post-activation `/apiface` returns `auth_proof`, and Verify succeeds.
3. A second App on the same active UDID gets a new proof and can enroll its own P-256 key without card re-entry.
4. Subsequent launches reuse that App's Keychain P-256 key.
5. Verify returns expected `access_level`, `permissions`, token, notice/update data and the menu opens normally.
6. Missing/expired/replayed/mismatched `auth_proof` fails closed.
7. `runtime.iap-noads` / passive Satella path remains normal.

## Remaining separate regression gates
- P79.8c cloud permission matrix remains independently pending: `basic` hides `VIP云存档`; `app_plus/global_plus` expose it; actual action still requires fresh Verify.
- P79.8b full persistence regression remains independently pending beyond the P0 protected-key reset boundary.

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
6. Server private signing material must remain server-side.

# Next Task
Deploy the matching server `auth_proof` contract, then run the P79.8i device gate. P79.8g remains the device-passed fallback baseline until P79.8i is explicitly reported normal.
