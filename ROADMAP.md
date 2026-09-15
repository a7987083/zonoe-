# ROADMAP

## Current promoted baseline
- Device-verified version: `v1_p42`.
- Runtime/source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- CI Run `34995566144`: **success**.
- Real-device regression: **passed and explicitly reported by user**.
- Active PBX Sources: **77**.
- Architectures: arm64 + arm64e.
- P42/P41 exported symbol sets and linked load-library sets are identical.

## P41 completed — UDID bridge compilation boundary
- Work branch: `work/zonoemenu-v1-p41-udidbridge-boundary`.
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI Run `34959813770`: success.
- Real-device validation: passed.
- `ZONUDIDBridge.h` became declaration-only and `ZONUDIDBridge.m` became the explicit implementation owner.
- Active Sources: 75 → 76.

## P42 completed — Zonoe UDID API service boundary
- Work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Product source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- CI Run `34995566144`: **success**.
- Real-device validation: **passed**.
- Existing `ZonoeUDIDAPI` implementation moved mechanically from `testmod/视图菜单/NSObject+UI.m` to `testmod/ZONServices/ZonoeUDIDAPI.m`.
- `NSObject+UI.m` now keeps UI ownership only for this concern.
- Active Sources: 76 → 77; sole addition `ZonoeUDIDAPI.m`.
- Exact migration contract passed.
- Independent iPhoneOS compile with `-Wall -Wextra -Werror` passed.
- A_customer and B_debug full builds passed for arm64 + arm64e.
- A_customer artifact: `10407391591`, digest `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- B_debug artifact: `10406554164`, digest `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.

## Protected behavior
Keep unchanged unless a later isolated phase explicitly proves otherwise:
- `main.m +load` timing and Bootstrap/authorization sequencing.
- Zonoe callback scheme, nonce generation/validation, callback URL parsing and storage keys.
- Localhost bridge port/timeouts/retry count and pending-request age limits.
- `zonoe://udid` preferred path and legacy web/profile fallback.
- Floating entry/menu stack and all active features.
- Cloud save, local files, backup/restore, clear-data and clear-auth paths.
- `JiangHuHook`, `HookClass`, `ImgTool`, fishhook/rebind runtime paths.

## Next task
Before defining P43, review the remaining architecture hotspots in `REFACTOR_REVIEW.md` and current runtime call chains. Prefer the next smallest zero-behavior ownership split; do not combine timing/threading changes with structural cleanup. P42 is the fallback/device baseline for the next candidate.
