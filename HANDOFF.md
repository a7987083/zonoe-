# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current work target — P79.8
- Main P79 branch: `work/p79-server-driven-auth-isolation-v1`.
- VERSION: `v1_p79_8`.
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- Build/version commit: `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36560746520` / run #27: success.
- Artifact ID `11028839445`.
- Raw CI dylib SHA256: `590f6a67e5e4faf9d6c9a2c6f6910884cbff4a15e5cf6c205fe3536be20fb9cc`.
- Raw CI artifact reports `verify_secret_configured=0`.
- Controlled final test dylib has the test Verify Secret injected into both arm64/arm64e slices with equal-length replacement; placeholder remaining `0`, Secret occurrences `2`.
- Controlled final test dylib SHA256: `12cac6f3a9b7ce9da1ad5f27f9364606c42f52eb3311dd36e2308c5cd8a8f723`.
- Do not commit the test/real Verify Secret to public Git history.

## Why P79.7 failed
- Real-device result: entering a card already bound to the current UDID still displayed `解锁码已使用`.
- P79.7 used the legacy `/authorization` compatibility surface as a binding probe.
- That path is not the formal server-driven authorization contract and did not yield the structured Bound result expected by the client.
- The client therefore fell back to `/appstore`; current `/appstore` intentionally treats an already activated `jh=1` card as a one-time credential and returns `解锁码已使用`.
- Do not restore `/authorization` as the binding decision source.

## P79.8 same-card/same-UDID contract
1. Existing UDID authorization is read through `/apiface`.
2. Before reactivation, the client POSTs `code + udid` to `/index/index/license`.
3. That server controller uses `AuthorizationLicense::query(code, udid)`, which requires exact `kami + udid + jh=1` before returning a matching authorization.
4. The client only treats the result as Bound when that exact binding is active (`授权有效`).
5. Bound result skips `/appstore` and proceeds to Runtime Config + Verify.
6. New/unused/mismatched/expired results fall back to the canonical P79.6 activation path.
7. A generic `解锁码已使用` response is never sufficient to authorize.

## Other P79.7 behavior carried forward
- Verify `app_not_authorized` / `Authorization does not apply to this App` clears the saved card and returns to the original card prompt rather than ending in a separate alert.
- Authorization reset deletes complete authorization-related Keychain services visible to the current process, not only selected accounts.
- Cross-App deletion still depends on Keychain access-group visibility; Apps with isolated access groups cannot be cleared by another App's process without shared entitlements or a server-side revoke/reset API.

## Verify protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key`: `zonoe.main`
- `dylib_version`: `1`
- `dylib_build`: empty string
- Protocol version: `2`

## Required device checks
1. Same valid card + same UDID reaches Verify without `/appstore` used-card rejection.
2. Different used card does not pass as the existing authorization.
3. Unused valid card still activates through `/appstore`.
4. Invalid/nonexistent card remains in the card input flow.
5. Card for another App returns to the same card input flow with the App-mismatch message.
6. Valid current-App card reaches success → notice → update → icon.
7. Clear authorization behavior is rechecked across two Apps and actual Keychain access-group entitlements are recorded.

## Last promoted/device baseline
- P64a / `v1_p64a`.
- Source `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI `35524126925`: success.
- Device: passed.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
