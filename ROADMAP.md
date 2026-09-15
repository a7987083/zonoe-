# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p39`.
- Runtime/source commit: `613882da7068795533c530d45775f7ae5f79ed56`.
- Verification Run `34891852090`: success.
- Real-device regression: passed and explicitly reported by user.
- Active PBX Sources: **75**.
- All nine active product features remain verified.

## P40 completed — zero-behavior source/dependency hygiene
- Source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`.
- Test branch: `test/zonoemenu-v1-p40-zero-behavior-refactor`.
- Successful CI head: `8eeb3212f9236bea9eeb6be2f8ca88d71c2a0e5b`.
- CI Run `34915266733`: **success**.
- Active Sources remained **75**.
- Localized `ZONFeatureDispatcher` implementation-only imports from `.h` into `.m`.
- Removed the uncompiled JDStatusBar `NotificationPresenter.swift` wrapper.
- Removed the proven-stale JDStatus umbrella import from `PreferenceManager.m`.
- A_customer and B_debug dylibs were byte-identical to promoted P39 artifacts.
- P40 was an architectural cleanup candidate and was not separately promoted by a real-device report.

## P41 implemented — UDID bridge compilation boundary
Status: **CI verified / real-device pending**.

Source:
- Work branch: `work/zonoemenu-v1-p41-udidbridge-boundary`.
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- Test branch: `test/zonoemenu-v1-p41-udidbridge-boundary-build`.
- CI trigger/head: `925cd9b11364278e1927f300cc46e13dace2a239`.
- CI Run `34959813770`: **success**.

Change:
- `testmod/ZONServices/ZONUDIDBridge.h` is now declaration-only.
- The exact P40 callback/nonce/storage/socket/request implementation was mechanically moved into `testmod/ZONServices/ZONUDIDBridge.m`.
- The bridge symbols are explicitly hidden from the dylib export surface.
- No `main.m`, `NSObject+UI.m`, authorization, menu, cloud-save, backup/restore, hook, or other protected runtime implementation was changed.

Source-count rule:
- P39/P40: 75 active Sources.
- P41: **76 active Sources**.
- The only addition is `ZONUDIDBridge.m`; none of the existing 75 sources was removed.
- This increase is intentional because formerly header-owned executable code now has an explicit translation-unit owner.

Verification:
- P41 mechanical body-equivalence contract: passed.
- `ZONUDIDBridge.m` independent iPhoneOS compile with `-Wall -Wextra -Werror`: passed.
- A_customer arm64 + arm64e full build: passed.
- B_debug arm64 + arm64e full build: passed.
- Exported symbol set versus P40: identical.
- `ZONUDIDBridge*` symbols do not leak into the dylib export surface.
- Linked load-library set versus P40: identical.
- A_customer artifact: `10392947122`, digest `sha256:8b5ed743e7d9c958fa695fce7cdb4f0cf48984dc94a2162b539a75698392a336`.
- B_debug artifact: `10393041635`, digest `sha256:4d9123c5df4554e71c4d33ba11ddcec15fb3adcc3c5470daaf21505ed6f4afd0`.

## Protected behavior
Keep unchanged until an explicit, isolated phase proves otherwise:
- `main.m +load` timing and Bootstrap/authorization sequencing.
- Zonoe callback scheme, nonce generation/validation, callback URL parsing and storage keys.
- Localhost bridge port/timeouts/retry count and pending-request age limits.
- `zonoe://udid` preferred path and legacy web/profile fallback.
- Floating entry/menu stack and all nine active features.
- Cloud save, local files, backup/restore, clear-data and clear-auth paths.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime paths.

## Next task
Perform **P41 real-device regression**, using A_customer as the promotion gate. Required checks:
1. normal startup with an already cached valid UDID;
2. first/forced acquisition through `zonoe://udid` callback + nonce;
3. localhost bridge result acceptance;
4. fallback to the existing web/profile flow when Zonoe cannot open;
5. authorization continues normally after UDID acquisition;
6. menu and core features still open and operate normally.

Do not promote P41 until the real-device result is explicitly reported. P39 remains the fallback/device baseline. After P41 promotion, the next architecture candidate is moving the stable `ZonoeUDIDAPI` implementation out of `NSObject+UI.m` into its own translation unit.
