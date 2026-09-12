# CHANGELOG_DEV

## 2026-09-12 — v1_p30 EventBridge Boundary Cleanup
- Development base: p29 source/CI commit `506a22c01a2b46dbea0d4299418fcb702b6cb80e`; device fallback remains p28 because p29 hardware verification was not explicitly confirmed.
- Bumped `VERSION` to `v1_p30`.
- Converted `ZONMenuEventBridge` from header-only `static inline` implementation to declaration header + independent `.m` translation unit.
- Moved EventBridge-only imports and constants into `ZONMenuEventBridge.m`; preserved function bodies, UserDefaults keys and dispatch flow.
- Registered `ZONMenuEventBridge.m` in the Xcode target Sources phase.
- Did not modify `ZONFeatureDispatcher.h`, Registry data, ModuleLoader, authorization, UDID, cloud save, clear-game-data, UI behavior, `WX_NongShiFu123.mm`, `main.m`, or keyboard/presentation logic.
- Source split commit: `760f03f511005f639f9a7a1de8aaad6f02f85c9a`.
- Integrated p30 source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`.
- Successful CI run `34672196947`: A_customer and B_debug both passed compile/link/package and arm64+arm64e verification.
- A dylib SHA256: `383fdab525bbdb1cdfced50288c1ac5b8acfbfdbe8419802fdc29b735095133a`.
- B dylib SHA256: `2eb3c8693b6836feb926dbbf587b54125892b025c17fdb026c6b32c7e371accf`.
- Device/runtime regression remains pending.
- First p30 CI attempt failed only because a shallow checkout could not resolve the p29 comparison commit; CI was corrected without changing p30 source.

## 2026-09-12 — v1_p29 Rendering Boundary Cleanup
- Converted Panel/Chrome/FeatureRenderer/SectionRenderer helpers to independent `.m` translation units.
- Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- A/B CI passed; explicit hardware confirmation is still pending.

## 2026-09-12 — v1_p28 ZONCore Build Integration
- Registered `ZONMenuCoordinator.m` as a normal Xcode target source and removed the temporary direct `.m` import bridge.
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- A/B CI and hardware regression passed; p28 remains the current device-verified baseline.
