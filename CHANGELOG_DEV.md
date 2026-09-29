# CHANGELOG_DEV

## 2026-09-29 — v1_p79_9 UDID-First Authorization Gate — CI PASSED / DEVICE PENDING
- Branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `675621f8264e228fc1d578301b17f49e9101a16b`.
- Build/version commit: `77db45077f6e22e54b7fa9e8c5a0a3924a65747a`.
- CI Run `36564346565` / #29: success.
- Artifact ID `11031705119`, digest `sha256:05393223053e999500028f64d8143c84191666016a4441adf4b4cf5f35b5bd23`.
- Raw CI dylib SHA256: `57a81062e35556b7092fbabaa6d98a8a90ea3796a3cbe8c3c27a3cc39f9e06c7`.
- Requirement corrected from P79.8: startup must authenticate by UDID first; card input is only for a UDID that has no active authorization.
- Added startup swizzle/gate that stores the acquired UDID and immediately calls `/apiface`.
- Added explicit authorization priority: **scope 1 Plus/全软件源 → scope 3 指定 App → scope 2 仅验证**.
- Any supported active authorization bypasses `/appstore` and proceeds directly to Runtime Config + Verify, even in a freshly installed App with no locally saved card.
- Specified-App mappings are not guessed client-side because `/apiface` summaries do not include app IDs; current-App applicability remains a Verify responsibility.
- Network/5xx lookup failure does not mean “unactivated”; it shows an error and does not open the card prompt.
- Only a real no-active-authorization result clears stale local card state and opens the card activation prompt.
- Legacy active authorization without `authorizations[]` is treated as source/Plus for backward compatibility.
- P79.6 first-activation before/after state-change gate remains the fallback after the user actually enters a new card.
- Raw CI again reported `verify_secret_configured=0`; source stays placeholder-only.
- Controlled final dylib was patched by equal-length Secret injection in both arm64/arm64e slices: placeholder `0`, Secret occurrences `2`, size unchanged, 128 changed bytes.
- Controlled final test dylib SHA256: `75b28c007ee6171fe506af68a76ccfd008f1dd07226deab7c227a54c3dec721b`.

## 2026-09-29 — v1_p79_8 Same-Card/Same-UDID License Query — CI PASSED / SUPERSEDED BEFORE DEVICE
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- Build commit: `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36560746520` / #27: success.
- Controlled final SHA256: `12cac6f3a9b7ce9da1ad5f27f9364606c42f52eb3311dd36e2308c5cd8a8f723`.
- Replaced the retired `/authorization` probe with exact `AuthorizationLicense::query(code, udid)`.
- Superseded after requirement clarification: fresh App startup should not require card+UDID probing at all when the UDID already has active authorization.

## 2026-09-29 — v1_p79_7 Auth Semantics + Reset Scope — CI PASSED / DEVICE FAILED
- CI Run `36531465809` / #25: success.
- Controlled final SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- Device failure: same card + same UDID still reached `/appstore` and returned `解锁码已使用` because the compatibility `/authorization` probe did not prove the binding.
- App mismatch routing back to card prompt and broader current-process-visible Keychain reset were introduced here and carried forward.

## 2026-09-29 — v1_p79_6 Server-Driven Auth Activation Gate — CI PASSED
- Restored `/apiface before → /appstore → /apiface after → authorization + state-change gate → Runtime Config → Verify v2` for true first activation.
- Saved-card `/apiface` must contain valid authorization before Verify.
- Transient network/server failures preserve authorization state.
- Build commit: `ac948369ceba488ece11deb8730d8a9510687f44`; CI Run `36523256192` / #24 success.

## 2026-09-21 — v1_p64a Runtime Directory Cleanup Fix — DEVICE PASSED / PROMOTED
- Source commit: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- User reported full real-device regression normal.
- P64a remains the last promoted/device-verified rollback baseline.

## Operating rules
- New stage increments numeric version; same-stage fixes use suffixes.
- CI success does not equal device promotion.
- Real/test Verify Secret is never committed to public source or printed in logs.
