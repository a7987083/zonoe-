# KNOWN_ISSUES

## Current state
- Active version: `v1_p79_8h`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `b62e6ac71c6d58db48b75e8f3064b012b836571f`.
- CI Run `36734106358` / #62: success.
- Artifact ID: `11106496611`.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `ae3a3eee1fc53b0009f7c25ad4b37d9713ab2ef2f0fd34d1ad17dc78fd3c3457`.
- Controlled final SHA256: `8ac866a22d2bae372adb62f9cdcc67c1bfadf6b3a71fe7e8e2b927d8687caa26`.
- P79.8h device validation: pending.
- Latest device-passed runtime/architecture baseline: P79.8g.
- Closed P0 safety baseline: P79.8f.

## R3 risk reduced in P79.8h

### Renderer and Dispatcher no longer parse AuthV2 permission schema independently
- `ZONFeatureAccessProvider` now owns `lastVerify → permissions/access_level` parsing.
- `ZONSectionRenderer` calls `isFeatureVisible:`.
- `ZONFeatureDispatcher` calls `isFeatureActionAllowed:` for protected actions.
- This removes duplicated permission-schema knowledge from two consumer layers.

### Local runtime capability can now participate in the same access decision
- Registry defines optional metadata `requiredRuntimeCapability`.
- When set, both visibility and action access require `ZONRuntimeCapabilityService.isCapabilityAvailable:`.
- No existing P79.8h feature sets the key, so this version intentionally does not hide or block any additional existing feature.

### Visibility is not the only guard
- Protected action routing uses the same provider as menu rendering.
- Future runtime-capability-dependent actions can therefore fail closed even if reached outside normal UI rendering.

## Device-equivalence risk still open for P79.8h
- R3 changes where permission decisions are made, so CI/source-contract success is not promoted as device equivalence automatically.
- Verify the current menu still renders normally for the current authorization, existing feature ordering/count does not unexpectedly change, protected action behavior remains normal, and the passive runtime path still works.
- Until that check passes, P79.8g remains the latest device-passed baseline.

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

### Feature registry remains weakly typed
- Feature/section descriptors are dictionaries keyed by strings.
- P79.8h added one optional key safely, but compile-time safety remains limited.
- R4 should introduce typed descriptors incrementally while preserving identifiers, tags, ordering and renderer behavior.

### `ZONAuthV2Flow` still owns too many responsibilities
- It parses server payloads, classifies state, orchestrates activation/config/Verify, maps errors, presents card UI, notices/updates, and opens the floating entry.
- R5 should begin with a pure authorization-decision parser, not a one-shot rewrite.

### Duplicate Runtime Config parsing helpers
- `ZONAuthV2API.m` and `ZONAuthV2Verify.m` still implement similar nested config lookup semantics.
- Extract later with tests; do not mix with R4.

### External source-controlled dylib integration is deferred
- Do not add exported-symbol probing or a standalone button yet.
- The R3 access-provider path is ready for future `requiredRuntimeCapability` usage when that work resumes.

## P79.8h verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- `p79.8g-runtime-capability: PASS`.
- `p79.8h-feature-access: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final placeholder remaining: `0`.
- Controlled final Verify Secret occurrences: `2`.
- Raw-to-final changed bytes: `128`, limited to the two equal-length Verify Secret placeholder regions.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
