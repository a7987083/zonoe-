# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_8b`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline: device-passed P79.8a UDID-first flow.
- Storage cleanup implementation: `78da327ef11946d8502e77b023d1f8b823c2fad1`, `1b099d83da7ae00a5773279f755110f0c441b4d3`.
- Cleanup integration: `d97e78c8bdedbf8efa0b87b77a0c18bf8b9266ea`.
- Reset integration: `4a5888613f7c2c5b76e5191d2c42a9a60e491890`.
- Build HEAD: `19d5d1e0204c84f56fc2ee330bb2371d3511d367`.
- CI Run `36585791709` / #36: success.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `b6c3333cbce0b0ff508a11ac31a6d81ce180db4c1afd3360e86d0ed5a9ce7045`.
- Controlled final SHA256: `e363256b06e7842090103f95cc5edd14066b7eb50f144768fcd38882255bd62c`.
- Current-device validation: pending.
- Last device-passed baseline: P79.8a / controlled SHA256 `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.

## Open risks

### Persistence cleanup needs device confirmation
- P79.8b intentionally changes storage only; authorization routing should remain identical to P79.8a.
- Device validation must confirm old defaults are removed without disturbing `DZUDID` or menu/runtime preferences.
- The expected long-lived AuthV2 `NSUserDefaults` surface after normal startup is only `zonoe.auth.v2.lastNoticeFingerprint` when a notice has actually been shown.
- UDID bridge nonce/timestamp are temporary transaction values and should be absent after successful completion.

### Menu persistence is deliberately out of cleanup scope
- Fold-state and runtime menu preferences remain untouched.
- Do not broaden the cleanup list to menu/runtime keys during future storage work.

### Notice de-duplication remains persistent by design
- `zonoe.auth.v2.lastNoticeFingerprint` is retained so the same notice is not shown every launch.
- Notice content itself is not otherwise stored by P79.8b AuthV2 state caches.

### `/apiface` and Verify responsibilities remain unchanged
- `/apiface` determines whether the UDID currently has an active card authorization.
- Verify owns current-App applicability and returns server-authoritative `access_level` / `permissions`.
- Do not reintroduce saved-card-first startup or require `/apiface` to return Verify permissions.

### First activation state-change gate remains important
- Activation still requires `/apiface before → /appstore → /apiface after → active + stateChanged → Runtime Config → Verify`.
- Generic `解锁码已使用` is never converted into success.

### Cross-App authorization clearing remains an entitlement boundary
- Local reset can only remove Keychain records visible to the current process/access groups.
- Server authorization state requires the server-side reset/revoke contract.

### Raw CI artifact has no Verify Secret
- CI Run `36585791709` produced the placeholder build.
- Controlled final artifact uses equal-length post-build injection into both architecture slices.
- Placeholder remaining `0`; Secret occurrences `2`.
- Public source remains placeholder-only.

## Corrected / removed

### Excess AuthV2 persistence — corrected in P79.8b
- `udid` and `card` in `com.zonoe.auth.v2` are no longer long-lived storage.
- `lastVerify`, `lastActivation`, `lastRuntimeConfig`, and `lastBootstrap` are session-memory only.
- Old persistent copies are removed during migration cleanup after `DZUDID` is confirmed.
- Completed bridge value/scheme/nonce/timestamp residue is also removed.

### P79.8 saved-card-first startup — corrected in P79.8a
- Startup checks server authorization by UDID first.
- User confirmed the P79.8a real-device scenario works correctly.

### P79.8 BindingProbe runtime path — removed in P79.8a
- BindingProbe swizzle is not compiled into the runtime path.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Verify acceptance testing must use the Secret-configured controlled artifact.
