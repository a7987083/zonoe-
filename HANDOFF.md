# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p42-zonoe-udid-api-boundary`.
- Current test branch: `test/zonoemenu-v1-p42-zonoe-udid-api-boundary-build`.
- Current version: `v1_p42`.
- **Promoted/device baseline: `v1_p42` / `e87b683a9c868e00d13582c8145bb9368878fee3`.**
- User explicitly reported P42 real-device validation normal.
- P42 active PBX Sources: **77**.

## P41 — UDID Bridge Boundary
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI Run `34959813770`: success.
- User explicitly reported P41 real-device validation normal before P42 development.
- `ZONUDIDBridge.h` is declaration-only; `ZONUDIDBridge.m` owns implementation.
- Active Sources: 75 → 76.
- P41 is superseded by the later P42 device pass.

## P42 — Zonoe UDID API Boundary
### Source state
- Product source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Contract unicode-path fix commit: `698bd84d676107f65ae14d6b2041805948001674` (test-only; product runtime unchanged).
- CI Run `34995566144`: **success**.
- `testmod/ZONServices/ZonoeUDIDAPI.m` now owns the stable public Zonoe UDID API implementation.
- `testmod/视图菜单/NSObject+UI.m` no longer owns UDID callback/fallback state and remains UI-focused.
- PBX source delta from P41 is exactly one source: `ZonoeUDIDAPI.m`.
- Active Sources: **76 → 77**.

### Behavior-preservation evidence
- `Tests/p42_zonoe_udid_api_boundary_contract.py` requires exact mechanical migration of the P41 API block.
- Callback state, notification observer, `DZUDID` keychain lookup, `WX_NongShiFu123` legacy fallback, bridge calls and dispatch behavior remain unchanged.
- `ZonoeUDIDAPI.m` independently compiles against the iPhoneOS SDK with `-Wall -Wextra -Werror`.
- A_customer and B_debug both fully build for arm64 + arm64e.
- Dynamic exported symbol set is identical to P41.
- Linked load-library set is identical to P41.

### Artifacts
- A_customer artifact: `10407391591`, digest `sha256:ac8ec9dc629993d33f24ef646133497cc257babcc7ab1b3186cf879c1bd1c819`.
- A_customer dylib SHA256: `9174bed40c8297a3927348d61cc0959a02f42391741d249edab2dcdfbcc63ad6`.
- B_debug artifact: `10406554164`, digest `sha256:ef422950b514da765c7da3504f8ab961b9415c65d63158dbac2fdf8a15884d06`.

## Runtime call chain that must remain stable
```text
dyld
  -> testmod/Bsphp/main.m +load
     -> authorization reset compatibility hook
     -> ZONBootstrapStart(...)
        -> A_customer authorization startup
           -> ZonoeUDIDAPI.h
              -> ZonoeUDIDAPI.m
                 -> ZONUDIDBridge.h
                    -> ZONUDIDBridge.m
                       -> zonoe://udid callback + nonce
                       -> localhost bridge polling
                       -> NSUserDefaults bridge cache
                 -> legacy WX_NongShiFu123 web/profile fallback when needed
           -> authorization continuation
        -> B_debug floating entry
        -> ZONLoadBundledModules()
```

## Promotion state
P42 is **CI verified and device verified**. It is the current promoted fallback/device baseline for subsequent work.

## Next task
Before defining P43, inspect `REFACTOR_REVIEW.md`, current PBX membership, and live call chains. Select the next smallest zero-behavior ownership split. Do not combine structural movement with timing/threading or behavior changes. Preserve P42 as the rollback baseline until a later candidate is explicitly device-passed.
