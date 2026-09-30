# KNOWN_ISSUES

## Current state
- Active version: `v1_p79_8g`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `9702183f97304e62939d528f7bec64c46417510a`.
- CI Run `36727105080` / #53: success.
- Artifact ID: `11103866499`.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `e5a7f07ed4a5bf980113382f72eca11782fc163b80f64a05754843b0b3a3bede`.
- Controlled final SHA256: `4172ac0881f6885b1ac620a486ba9b8eadd153c9b11f26a3647607737c028863`.
- P79.8g device validation: pending.
- Current device-passed baseline: P79.8f.

## R2 risk reduced in P79.8g

### Dispatcher no longer owns passive runtime internals
- `ZONFeatureDispatcher` now delegates passive activation through `ZONRuntimeCapabilityService`.
- `_dyld_*`, Mach-O parsing, mapped-`__TEXT` validation, passive RVAs/signatures, ptrauth and one-shot state now live behind the capability boundary.
- `Tests/p79_8g_runtime_capability_boundary.py` explicitly rejects those low-level details if they reappear in Dispatcher.

### Runtime capability service is intentionally narrow
- Current registered capability is only `passive.satella`.
- Public API is `isCapabilityAvailable:` + `activateCapability:`.
- The service does not load or unload external modules; targets remain externally injected/preloaded.
- This is sufficient for R2 and for future button visibility checks, but it is not yet the R3 menu-access integration.

## P79.8g device-equivalence risk
- R2 moves code across compilation units, so CI/source-contract success is not treated as real-device equivalence automatically.
- Verify on device that the existing `runtime.iap-noads` path still preserves `NNGG`, `NNGGNNGG`, `ImgTool.NeiGou`, valid passive startup, one-shot semantics, no-target behavior and arm64e invocation.
- Until that passes, P79.8f remains the promotion baseline.

## P0 risks remain closed by P79.8f baseline
- Startup transport failure is not treated as missing activation/card prompt.
- Authorization reset preserves protected menu/runtime keys.
- Game-data reset remains scoped to the current App container roots/defaults.
- Passive mapped-range validation executes before signature dereference/call.
- P79.8g tests continue to lock these P79.8f contracts after implementation migration.

## Remaining functional regression gates

### P79.8c cloud permission matrix
- Still separately pending.
- `basic` must hide `VIP云存档`.
- `app_plus/global_plus` must expose it.
- Actual cloud action must still pass fresh Verify.

### P79.8b full persistence regression
- Still separately tracked beyond the P0 authorization-reset protected-key boundary.
- AuthV2 response/config/card session-only behavior should be rechecked when storage/persistence code changes.

## Open architecture risks — next stages

### Renderer still reads raw AuthV2 session schema
- `ZONSectionRenderer` directly consumes `lastVerify/permissions/access_level`.
- R3 should introduce a feature-access provider combining server permissions with `ZONRuntimeCapabilityService.isCapabilityAvailable:` before the future standalone external-dylib button is added.

### Feature registry remains weakly typed
- Feature/section descriptors are dictionaries keyed by strings.
- Add optional runtime-capability metadata during R3 carefully; migrate to typed descriptors only after the access boundary is stable.

### `ZONAuthV2Flow` still owns too many responsibilities
- It parses server payloads, classifies state, orchestrates activation/config/Verify, maps errors, presents card UI, notices/updates, and opens the floating entry.
- R5 should begin with a pure authorization-decision parser, not a one-shot rewrite.

### Duplicate Runtime Config parsing helpers
- `ZONAuthV2API.m` and `ZONAuthV2Verify.m` still implement similar nested config lookup semantics.
- Extract later with tests; do not mix with R3.

## P79.8g verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final placeholder remaining: `0`.
- Controlled final Verify Secret occurrences: `2`.
- Raw-to-final changed bytes: `128`, limited to the two equal-length Verify Secret placeholder regions.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
