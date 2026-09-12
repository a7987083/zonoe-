# CHANGELOG_DEV

## 2026-09-12 — v1_p31 Feature Registry Boundary Cleanup
- Development base: p30 source `8e88b63611d19af6c42d9172c0f5741b34f51809`; device fallback remains p28 because p29/p30 hardware verification was not explicitly confirmed.
- Bumped `VERSION` to `v1_p31`.
- Converted `ZONFeatureRegistry` from header-only implementation to declaration header + independent `.m` translation unit.
- Converted Registry string keys from per-translation-unit `static` definitions to `FOUNDATION_EXPORT` declarations with one `.m` definition; names and values are unchanged.
- Registered `ZONFeatureRegistry.m` in the Xcode target Sources phase.
- Updated permanent `module-abi.yml` so `feature_registry_smoke.m` explicitly links `ZONFeatureRegistry.m`.
- Did not modify the 10 feature records or 3 section records: tags, identifiers, titles, kind/risk/migrated values, section order, feature order, state keys and renderer values remain unchanged.
- Did not modify Dispatcher/EventBridge business behavior, authorization, UDID, cloud save, clear-game-data, `WX_NongShiFu123.mm`, actual `testmod/Bsphp/main.m`, UI behavior, or keyboard/presentation logic.
- Registry split commit: `b6e43f11103f00381a90fe4ef42110a595d41bce`.
- Registry constants commit: `0f4f8fab9131bd5e73f7fcf15919fb5ece44e6b7`.
- Integrated p31 source commit: `5c0e5afddfecc9e9ed4b89f7ad42780cd652847f`.
- CI run `34673034214`: Registry data equivalence, Registry smoke, Module ABI smoke, A_customer and B_debug all passed.
- A dylib SHA256: `579d721b6f2cfcb89b711ad676632851c84173d65f872259d26553bf180b6b68`.
- B dylib SHA256: `ffe787f48c0ed5e6e3862692ccf279879831257ccdd7a8946af239d405927743`.
- Device/runtime regression is pending; the p31 hardware checklist cumulatively covers p29+p30+p31.
- ModuleLoader was audited but is not used by the actual target runtime path, so no inactive Loader implementation was forced into the product target.

## 2026-09-12 — v1_p30 EventBridge Boundary Cleanup
- Converted `ZONMenuEventBridge` to declaration header + independent `.m` translation unit.
- Source commit: `8e88b63611d19af6c42d9172c0f5741b34f51809`.
- A/B CI passed; explicit hardware confirmation is pending.

## 2026-09-12 — v1_p29 Rendering Boundary Cleanup
- Converted Panel/Chrome/FeatureRenderer/SectionRenderer helpers to independent `.m` translation units.
- Source commit: `506a22c01a2b46dbea0d4299418fcb702b6cb80e`.
- A/B CI passed; explicit hardware confirmation is pending.

## 2026-09-12 — v1_p28 ZONCore Build Integration
- Registered `ZONMenuCoordinator.m` as a normal Xcode target source and removed the temporary direct `.m` import bridge.
- Source commit: `350a46deb089a05fc599e641bd1eeb419c36c0d5`.
- A/B CI and hardware regression passed; p28 remains the current device-verified baseline.
