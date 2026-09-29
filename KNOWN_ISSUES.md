# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_8a`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Rebuilt from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- BindingProbe removal: `dce8c905960256d6e73dcdb62d42060f56660558`.
- CI Run `36572203902` / #32: success.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `188e25b8c8d76653baffb01e01cd8931302d2ca6d0e67a07d18fee1bd80a894a`.
- Controlled final SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Real-device validation: pending.
- Last promoted/device baseline remains P64a / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### Fresh-App UDID-first behavior still needs device confirmation
- P79.8a now queries `/apiface` immediately after the UDID is available.
- The startup decision no longer depends on a locally saved card.
- Expected active response is the legacy-proven device contract: `code=1`, `msg=ok`, `expire>now`.
- Device test must confirm that a freshly installed App on an already-activated UDID enters Runtime Config + Verify without showing the card prompt.

### `/apiface` and Verify have different responsibilities
- `/apiface` determines whether the UDID currently has an active card authorization.
- It is not required to return `access_level` or `permissions`.
- Verify owns current-App applicability and returns server-authoritative `access_level` / `permissions`.
- Do not reintroduce the P79.10 assumption that startup must see `access_level` from `/apiface`.

### Unknown server payloads must not be treated as “no activation”
- Network failures, HTTP errors, and unrecognized JSON do not open the card prompt.
- Only explicit missing/expired authorization states may lead to card input.
- If production `/apiface` uses a new no-record wording, update the classifier from captured real JSON rather than defaulting unknown data to activation.

### First activation state-change gate remains important
- A card prompt may also appear after an App-specific Verify mismatch so a different unused card can add authorization to the same UDID.
- Therefore `activateCard` must still compare `/apiface` before/after state and require a real authorization change before entering Verify.
- Do not short-circuit an entered replacement card just because the UDID already has some other active authorization.

### App mismatch prompt routing requires device confirmation
- `app_not_authorized` / `Authorization does not apply to this App` now lives directly in `ZONAuthV2Flow`, not in a swizzled compatibility layer.
- Verify that the user returns to the same card input and can submit a replacement card.

### Cross-App authorization clearing remains an entitlement boundary
- Current reset can only remove Keychain records visible to the current process/access groups.
- True cross-App local clearing requires a shared Keychain access group; server records require a real reset/revoke contract.

### Raw CI artifact has no Verify Secret
- CI Run `36572203902` reported `verify_secret_configured=0`.
- Controlled artifact uses equal-length post-build injection into both architecture slices.
- Placeholder remaining `0`; Secret occurrences `2`.
- Public source remains placeholder-only.

## Corrected / removed

### P79.8 BindingProbe runtime path — removed in P79.8a
- `ZONAuthV2Storage.m` no longer imports `ZONAuthV2BindingProbe.m`.
- Final binary marker counts: `P79.8_BINDING_GATE=0`, `P79.8_LICENSE_PROBE=0`.

### Saved-card-first startup — corrected in P79.8a
- Previous P79.8 startup opened card input immediately on a fresh App because no local card existed.
- P79.8a checks server authorization by UDID first.

### P79.9/P79.10 startup experiments — not inherited
- P79.8a intentionally rebuilds from P79.8 and uses the verified legacy UDID-first contract instead of stacking later compatibility patches.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Verify acceptance testing must use the Secret-configured controlled artifact.
