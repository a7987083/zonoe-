# zonoemenu HANDOFF

## Repository / baselines
- Repository: `a7987083/zonoe-`.
- Current work branch: `work/zonoemenu-v1-p41-udidbridge-boundary`.
- Current test branch: `test/zonoemenu-v1-p41-udidbridge-boundary-build`.
- Current candidate version: `v1_p41`.
- **Promoted/device baseline remains `v1_p39` / `613882da7068795533c530d45775f7ae5f79ed56`.**
- User explicitly reported P39 real-device validation passed.
- P39 active PBX Sources: **75**.
- P41 candidate active PBX Sources: **76**, solely because `ZONUDIDBridge.m` is now an explicit translation unit.

## P40 zero-behavior precursor
- Source commit: `09aa9f27fe0b0491ac17f92ed9ed20d496bf8f33`.
- Successful CI head: `8eeb3212f9236bea9eeb6be2f8ca88d71c2a0e5b`.
- Run `34915266733`: success.
- Kept 75 Sources.
- Localized Dispatcher implementation imports, removed uncompiled JDStatus Swift wrapper, removed stale PreferenceManager import.
- A_customer and B_debug dylibs were byte-identical to P39.
- Not separately promoted by a real-device report.

## P41 UDID Bridge Boundary
### Source state
- Product source commit: `ffa6e2a7c380ca34ec1add72d488eb96c1f60bfe`.
- CI trigger/head: `925cd9b11364278e1927f300cc46e13dace2a239`.
- CI Run `34959813770`: **success**.
- `testmod/ZONServices/ZONUDIDBridge.h` is declaration-only.
- `testmod/ZONServices/ZONUDIDBridge.m` owns the implementation.
- PBX source delta from P40 is exactly one source: `ZONUDIDBridge.m`.
- Existing 75 active sources remain present.

### Behavior-preservation evidence
- `Tests/p41_udidbridge_boundary_contract.py` mechanically reconstructs the expected `.m` from the P40 implementation-heavy Header and requires exact equality.
- Protected runtime files are tree-identical to P40, including `main.m`, `NSObject+UI.m`, Bootstrap, ModuleLoader, Registry, Dispatcher, menu, cloud-save, file, backup/restore and hook paths.
- Callback scheme/host logic, nonce rules, NSUserDefaults keys, localhost port `14302`, socket timeout `700000µs`, 6 attempts, 250ms retry delay, 90s pending age and 10s request throttle are unchanged.
- `ZONUDIDBridge.m` independently compiles with `-Wall -Wextra -Werror` against the iPhoneOS SDK.
- A_customer and B_debug both fully build for arm64 + arm64e.
- Dynamic exported symbol set is identical to P40; bridge symbols remain hidden.
- Linked load-library set is identical to P40.

### Artifacts
- A_customer: artifact `10392947122`, digest `sha256:8b5ed743e7d9c958fa695fce7cdb4f0cf48984dc94a2162b539a75698392a336`.
- B_debug: artifact `10393041635`, digest `sha256:4d9123c5df4554e71c4d33ba11ddcec15fb3adcc3c5470daaf21505ed6f4afd0`.

## Runtime call chain that must remain stable
```text
dyld
  -> testmod/Bsphp/main.m +load
     -> authorization reset compatibility hook
     -> ZONBootstrapStart(...)
        -> A_customer authorization startup
           -> ZonoeUDIDAPI (still implemented in NSObject+UI.m)
              -> ZONUDIDBridge.h declarations
                 -> ZONUDIDBridge.m implementation
                    -> zonoe://udid callback + nonce
                    -> localhost bridge polling
                    -> NSUserDefaults bridge cache
                 -> legacy WX_NongShiFu123 web/profile fallback when needed
           -> authorization continuation
        -> B_debug floating entry
        -> ZONLoadBundledModules()
```

## Important non-change
P41 does **not** move `ZonoeUDIDAPI` out of `NSObject+UI.m`. That is a later phase. Mixing stable identity/auth API implementation with UI ownership remains architectural debt, but it must not be combined with the bridge-boundary migration.

## Promotion gate
P41 is **CI verified, not device verified**. Do not describe it as promoted until the user explicitly reports a real-device pass.

Required A_customer real-device checks:
1. startup with cached valid UDID;
2. first/forced `zonoe://udid` request and callback nonce path;
3. localhost bridge result path;
4. legacy web/profile fallback when Zonoe `openURL` fails;
5. authorization proceeds after UDID is received;
6. floating menu and core features remain operational.

## Next task after P41 device pass
Only after P41 is promoted, start a separate phase to move the stable `ZonoeUDIDAPI` implementation from `NSObject+UI.m` into `ZonoeUDIDAPI.m`, again with exact body-equivalence and customer authorization/UDID real-device gates.
