# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.8b Persistence Cleanup — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8b`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Functional baseline: device-passed P79.8a UDID-first flow.
- Storage contract commits: `78da327ef11946d8502e77b023d1f8b823c2fad1`, `1b099d83da7ae00a5773279f755110f0c441b4d3`.
- Authorization cleanup integration: `d97e78c8bdedbf8efa0b87b77a0c18bf8b9266ea`.
- Reset-service cleanup integration: `4a5888613f7c2c5b76e5191d2c42a9a60e491890`.
- VERSION/build HEAD: `19d5d1e0204c84f56fc2ee330bb2371d3511d367`.
- CI Run `36585791709` / run #36: success.
- Artifact ID `11041556869`, digest `sha256:18b44f1ff221d9a2582291c30a5b145166f4e954e831158bd82bf0a41716a82a`.
- Raw CI dylib SHA256: `b6c3333cbce0b0ff508a11ac31a6d81ce180db4c1afd3360e86d0ed5a9ce7045`.
- Controlled final test dylib SHA256: `e363256b06e7842090103f95cc5edd14066b7eb50f144768fcd38882255bd62c`.
- Raw CI reports placeholder Secret; controlled final artifact has placeholder `0` and Secret occurrences `2`.

### P79.8b persistence contract
1. `DZUDID` remains the sole long-lived device identity used by authorization.
2. AuthV2 `udid` and `card` are session-only and are not persisted in the AuthV2 Keychain service.
3. `lastVerify`, `lastActivation`, `lastRuntimeConfig`, and `lastBootstrap` are session-only memory caches.
4. `zonoe.auth.v2.lastNoticeFingerprint` is the only AuthV2 `NSUserDefaults` value intentionally retained across launches, solely to suppress repeat display of the same notice.
5. Completed UDID bridge residue (`value`, `scheme`, nonce, timestamp) is purged after `DZUDID` is durably confirmed.
6. Legacy authorization defaults (`到期时间`, `卡密`, `公告`, `zonoeudid`, `解锁码到期时间`, `到期弹窗`) are migrated away.
7. Existing menu/runtime `NSUserDefaults` keys are intentionally untouched.
8. P79.8a authorization semantics are unchanged: UDID-first `/apiface` lookup, then Runtime Config + Verify when active; card prompt only for explicit missing/expired authorization.

### Device gates for P79.8b
- Upgrade from P79.8a or older and confirm old authorization/defaults residue is removed.
- Confirm menu fold states, IAP/ad toggles, and ad-speed preference still persist exactly as before.
- Confirm an already-activated UDID still skips card input and reaches Verify.
- Confirm a fresh activation still succeeds, then leaves no card/Verify/RuntimeConfig/Bootstrap persistence in Preferences.
- Confirm one notice is shown once and the same notice is not repeated after relaunch.

## Device-passed baseline — P79.8a
- VERSION: `v1_p79_8a`.
- Rebuilt directly from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36572203902` / #32: success.
- Controlled final dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Real-device validation: PASS — user confirmed fresh-App UDID-first activation behavior works correctly.

## Protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API base: `https://app3.zonoeios.xyz`
- UDID authorization path: `/index/index/apiface`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_8b`; verify persistence cleanup while confirming P79.8a UDID-first authorization and all menu persistence remain unchanged.
