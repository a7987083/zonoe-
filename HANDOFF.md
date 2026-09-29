# zonoemenu HANDOFF

## Repository / source of truth
- Repository: `a7987083/zonoe-`.
- Canonical runtime/product surface: `testmod/` + `testmod.xcodeproj`.
- Read in this order: `PROJECT_STATE.json` → `ROADMAP.md` → `KNOWN_ISSUES.md` → `CHANGELOG_DEV.md`.

## Current work target — P79.7
- Branch: `work/p79.7-auth-semantics-reset-scope`.
- Main P79 branch: `work/p79-server-driven-auth-isolation-v1`.
- VERSION: `v1_p79_7`.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809` / run #25: success.
- Artifact ID `11016299418`.
- Raw CI dylib SHA256: `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- Raw CI artifact reports `verify_secret_configured=0`.
- Controlled final test dylib has the user-provided test Verify Secret injected into both arm64/arm64e slices with equal-length replacement.
- Placeholder remaining: `0`.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- Do not commit the test/real Verify Secret to public Git history.

## P79.7 behavior
- Same card + same UDID: query the compatibility binding endpoint first; a confirmed same binding proceeds to Runtime Config + Verify without re-running activation.
- Unknown/not-bound result keeps the P79.6 activation path.
- App mismatch Verify result returns to the original card input prompt instead of ending in a separate alert.
- Authorization reset deletes complete authorization-related Keychain services visible to the current process, not only selected accounts.
- Cross-App deletion still depends on Keychain access-group visibility; Apps with isolated access groups cannot be cleared by another App's process.

## Verify protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key`: `zonoe.main`
- `dylib_version`: `1`
- `dylib_build`: empty string
- Protocol version: `2`

## Required device checks
1. Same valid card + same UDID authenticates successfully.
2. Different used card does not pass as the existing authorization.
3. Invalid/nonexistent card remains in the card input flow.
4. Card for another App returns to the same card input flow with the App-mismatch message.
5. Valid current-App card reaches success → notice → update → icon.
6. Clear authorization removes current-App visible AuthV2/legacy state.
7. Test App B after clearing from App A and record whether both Apps share a Keychain access group.

## Last promoted/device baseline
- P64a / `v1_p64a`.
- Source `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI `35524126925`: success.
- Device: passed.

## Long-project rules
- Preserve commit history.
- CI success is not device promotion.
- Keep all five long-project state files synchronized.
