# KNOWN_ISSUES

## Current state
- Active version: `v1_p79_8i`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional auth-proof HEAD before documentation sync: `980bc43656c8f609ea1c1c8f596d6128c5ae623e`.
- CI Run `36856203863` / #84: success.
- Artifact ID: `11157763459`.
- Artifact digest: `sha256:18fd793a2d930f63774e244e8c88d75849702e0542f6791b89f5d7033acdc35f`.
- Architectures: `arm64 + arm64e`.
- CI dylib SHA256: `a30afd52caf5640ab27aa907b5da70b4450c8b336b115a43ae0a3cf0184525af`.
- Client status: CI PASSED.
- Server status: auth-proof contract still must be deployed.
- P79.8i device validation: pending.
- Latest device-passed runtime/architecture baseline: P79.8g.

## Current blocking issue — deployed server does not yet satisfy the new auth-proof contract
The client intentionally no longer uses `license_code` for device-key enrollment. It now requires `/apiface` to return a short-lived `auth_proof` and sends that proof to `/challenge`.

Until the server is updated:
- the new client will fail closed with `auth_proof_unavailable` before `/challenge` if `/apiface` does not return the field;
- or `/challenge` will reject the request if the server does not validate/accept `auth_proof`;
- this is expected and must not be "fixed" by restoring the old secondary card prompt or `license_code` Verify path.

Required server changes:
- active `/apiface` response: add `auth_proof`, `auth_proof_expires_at`;
- proof: short-lived, server-verifiable, bound to UDID + `dylib_key` + active authorization + expiry + unique jti/nonce;
- `/challenge`: validate proof and bind challenge to submitted public-key fingerprint/device_key_id;
- `/verify`: stop requiring `license_code` for first-key enrollment;
- first key enrollment: only from a valid proof-created challenge;
- same active UDID may enroll different App P-256 keys without card re-entry.

## Authorization-model invariant
Do not redesign this as App-level card authorization:
- authorization root is UDID;
- card is only needed when the UDID has no valid authorization or is expired;
- `/appstore` is only the business activation path;
- after a UDID is active, later Apps must inherit that UDID authorization without asking for the card again;
- P-256 keys are App/device proof-of-possession keys layered after authorization.

## Client risks reduced in current P79.8i
- Long-lived shared Verify Secret/HMAC path is removed.
- Runtime Config comes directly from signed GitHub bootstrap and is RSA-2048/SHA-256 verified.
- The accidental second `/index/dylib_verify/config` hop is removed.
- The secondary `设备安全升级` enrollment UI is removed.
- `/verify` no longer receives `license_code` from local card storage.
- `auth_proof` and Verify token are session-only.
- Proof is cleared locally once challenge creation succeeds.
- Contract test forbids regression back to card-backed Verify enrollment.

## Device-equivalence risk still open for P79.8i
CI proves source/build contracts, not the deployed server interaction. After server deployment verify:
- already-active UDID obtains proof and reaches challenge without card UI;
- fresh activation still uses the existing `/appstore` + second `/apiface` confirmation flow;
- second App on same active UDID enrolls its own key without card entry;
- registered App reuses its Keychain key on next launch;
- invalid/expired/replayed proof fails closed;
- Verify permissions/access/token/menu and passive runtime behavior remain normal.

## Remaining functional regression gates

### P79.8c cloud permission matrix
- Still separately pending.
- `basic` must hide `VIP云存档`.
- `app_plus/global_plus` must expose it.
- Actual cloud action must still pass fresh Verify.

### P79.8b full persistence regression
- Still separately tracked beyond the P0 authorization-reset protected-key boundary.
- AuthV2 response/config/card/proof/token session-only behavior should be rechecked when storage/persistence code changes.

## Open architecture risks — deferred
- Feature registry remains weakly typed; R4 typed descriptors are paused.
- `ZONAuthV2Flow` remains large; R5 decomposition is paused.
- Runtime Config helper duplication remains; do not mix cleanup with the current server-contract rollout.
- External source-controlled dylib integration remains deferred.

## Verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- `p79.8i-secretless-auth-v3-contract: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Never commit or print long-lived server secrets/private signing material.
