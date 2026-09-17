# P51-D PubgLoad Refactor Plan

Baseline: promoted P51-C runtime (`5154a75a8cd88980387080e6c191b03a8f92a81e`).

## Scope
- Refactor only the remote-download / VIP cloud-save execution inside `testmod/菜单/PubgLoad.mm`.
- Keep `yuanchengdwon`, `xiazaidz:`, `checkCloudSaveStatus`, cloud JSON presentation, purchase validation, archive download delegate, unzip and `YYYPicker yidongwenjian` compatibility behavior.
- Centralize archive `NSURLSession` / `NSURLSessionDownloadTask` creation behind one helper.
- Extract purchase-validity evaluation (`code == 1`, `msg == ok`, `expire > now`, plus existing B_debug testMode override) behind one helper.

## Frozen behavior
- Manual remote URL still uses the user-entered URL without changing encoding rules.
- Cloud archive URL still uses percent encoding and retains nil/default, empty/deny, explicit JSON-address branches.
- Purchase endpoint remains `https://app.zonoeios.xyz/index/index/apiface?udid=%@`.
- Keychain key remains `DZUDID`.
- Cloud JSON continues to use `homeurl + bundleID + .json`.
- Default archive continues to use `homezip + bundleID + .zip`.
- Download delegate, progress UI, `/tmp` staging, ZIP-only gate, unzip destination `tmp/zonoe/`, archive deletion and `YYYPicker yidongwenjian` call remain unchanged.
- Existing `cleanupTemporaryFiles` behavior is intentionally unchanged in P51-D.

## Non-goals
- No endpoint migration.
- No change from synchronous purchase validation to another transport in this version.
- No `/tmp` cleanup narrowing in this version.
- No change to backup/restore implementation, auth, startup, UI, hooks, module loader, PBX membership or frameworks.

## Verification
- Exact runtime delta: only `testmod/菜单/PubgLoad.mm` may differ under the product surface.
- Static contract locks endpoints, key names, URL-selection branches, test-mode marker, progress/unzip/migration behavior and helper usage.
- Active Sources remain 78.
- A_customer + B_debug build for arm64 + arm64e.
- Exports and linked libraries must match P51-C artifacts.
- Real-device remote-download and VIP-cloud-save validation required before promotion.
