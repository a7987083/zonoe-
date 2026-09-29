# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_9`.
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `675621f8264e228fc1d578301b17f49e9101a16b`.
- Build commit: `77db45077f6e22e54b7fa9e8c5a0a3924a65747a`.
- CI Run `36564346565` / #29: success.
- Architectures: `arm64 + arm64e`.
- Controlled final test dylib SHA256: `75b28c007ee6171fe506af68a76ccfd008f1dd07226deab7c227a54c3dec721b`.
- Real-device validation: pending.
- Last promoted/device baseline remains P64a / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### UDID-first behavior requires real-device confirmation
- P79.9 queries `/apiface` immediately after UDID acquisition, before using local card state or presenting an activation prompt.
- Active scope priority is source/Plus (1) → specified App (3) → verify-only (2).
- If any supported active scope exists, the client enters Runtime Config + Verify without `/appstore`.
- Verify on a freshly installed App that no card prompt appears for an already-authorized UDID.

### Specified-App applicability is server/Verify-owned
- `/apiface` authorization summaries contain scope/type/expire but not the mapped App IDs.
- Therefore the client only prioritizes scope 3 and enters Verify; Verify must decide whether the current App is included.
- If scope 3 does not include the current App and another valid scope exists, backend Verify behavior must be checked to ensure it selects the next applicable authorization rather than stopping on the first non-applicable scope.

### Lookup failure must not look like no authorization
- Network errors and HTTP 5xx are shown as validation/server errors and must not open the card prompt.
- Device regression should include airplane-mode or controlled endpoint failure.

### App mismatch prompt routing requires confirmation
- `app_not_authorized` / `Authorization does not apply to this App` returns to the existing card prompt.
- Verify no separate terminal alert remains.

### Cross-App authorization clearing remains bounded by Keychain visibility
- Local reset deletes authorization-related Generic Password services visible to the current process.
- Apps using separate/default Keychain access groups cannot clear each other's private entries.
- True cross-App local reset requires shared access groups; server records require a real revoke/reset API.
- `/unbind` remains a transfer operation, not a global revoke API.

### Raw CI artifact has no Verify Secret
- CI Run `36564346565` reported `verify_secret_configured=0`.
- Raw CI dylib SHA256: `57a81062e35556b7092fbabaa6d98a8a90ea3796a3cbe8c3c27a3cc39f9e06c7`.
- Controlled artifact uses equal-length post-build injection into both architecture slices; placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ.
- Public source must retain only the placeholder.

## Corrected / superseded
- P79.8 exact card+UDID reuse is superseded by the clarified startup contract: UDID authorization must be queried first; card input is only for a UDID without active authorization.
- P79.7 `/authorization` probe is retired.
- P79.6 first-activation state-change gate remains active for actual new activation.

## Tracking rule
- CI success alone does not equal promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Verify acceptance testing must use the Secret-configured controlled artifact.
