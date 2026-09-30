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
- P79.8g device validation: PASSED by user report on 2026-09-30.
- Current latest device-passed runtime/architecture baseline: P79.8g.
- Closed P0 safety baseline remains P79.8f and is inherited by P79.8g.

## R2 risk closed in P79.8g

### Dispatcher no longer owns passive runtime internals
- `ZONFeatureDispatcher` delegates passive activation through `ZONRuntimeCapabilityService`.
- `_dyld_*`, Mach-O parsing, mapped-`__TEXT` validation, passive RVAs/signatures, ptrauth and one-shot state live behind the capability boundary.
- `Tests/p79_8g_runtime_capability_boundary.py` rejects those low-level details if they reappear in Dispatcher.

### Runtime capability service is device-accepted
- Current registered capability is `passive.satella`.
- Public API is `isCapabilityAvailable:` + `activateCapability:`.
- The service does not load/unload external modules; targets remain externally injected/preloaded.
- User reported P79.8g testing normal after the extraction, so the code-move/device-equivalence risk is closed for this baseline.

## P0 risks remain closed through inherited P79.8f contracts
- Startup transport failure is not treated as missing activation/card prompt.
- Authorization reset preserves protected menu/runtime keys.
- Game-data reset remains scoped to the current App container roots/defaults.
- Passive mapped-range validation executes before signature dereference/call.
- P79.8g tests continue to lock these contracts after implementation migration.

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
- P79.8h / R3 should introduce one feature-access provider combining server permissions with `ZONRuntimeCapabilityService.isCapabilityAvailable:` before adding the standalone external-dylib button.

### Visibility alone must not become the security boundary
- When runtime-capability metadata is added, Dispatcher/action execution must enforce the same capability requirement used by rendering.
- A hidden button must not remain reachable through legacy tags or direct dispatch.

### Feature registry remains weakly typed
- Feature/section descriptors are dictionaries keyed by strings.
- R3 may add an optional runtime-capability key, but full typed-descriptor migration belongs to R4 after the access boundary is stable.

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
- Device test: reported normal; P79.8g promoted to current runtime/architecture baseline.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
