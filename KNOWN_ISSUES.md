# KNOWN_ISSUES

## Current state
- Active version: `v1_p79_8f`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `67fbf755cf00623f3d0136668e103461d5189dae`.
- CI Run `36723643520` / #44: success.
- Artifact ID: `11101797212`.
- Architectures: `arm64 + arm64e`.
- Raw CI SHA256: `b124e544b32674844bf7e9be9a35e0259e512063ce7b0113e5450c3a61535970`.
- Controlled final SHA256: `18c443fb67440e7030b1b85fb82813c6d5aad52347cbf4aa3358313e00a84a6a`.
- P0 device validation: PASSED by user report on 2026-09-30.
- Current P0 device baseline: P79.8f.

## P0 risks closed in P79.8f

### Startup / authorization transport-vs-activation routing
- Source contracts lock transport errors before missing-activation/card-prompt routing and suppress card prompt for ambiguous payloads.
- User reported device testing normal; no P79.8f startup/authorization regression was reported.

### Authorization reset boundary
- P79.8f snapshots `fold_base`, `fold_draw`, `fold_role`, `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`, `AADDssppeedd` around authorization cleanup.
- Boundary crossing restores the protected snapshot and returns failure.
- Device testing was reported normal; this P0 boundary is accepted for the current baseline.

### Game-data reset scope
- Reset roots remain current `NSHomeDirectory()` → `Documents`, `Library`, `tmp`, plus current Bundle ID defaults.
- P0 device testing was reported normal; no sandbox-scope regression was reported.

### Passive dylib mapped-range safety
- Accepted names remain `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Contract remains `__TEXT vmaddr=0`, ctor RVA `0x847C`, init RVA `0x888C`, exact ctor/prologue signatures.
- P79.8f validates mapped `__TEXT` bounds/protections before either signature read or indirect call.
- Device testing was reported normal; current P0 passive-runtime baseline is accepted.

## Remaining functional regression gates

### P79.8c cloud permission matrix
- Still separately pending; the P79.8f P0 acceptance does not by itself prove every cloud permission scenario.
- `basic` must hide `VIP云存档`.
- `app_plus/global_plus` must expose it.
- Actual cloud action must still pass fresh Verify.

### P79.8b full persistence regression
- Still separately tracked beyond the P0 authorization-reset protected-key boundary.
- AuthV2 session-only response/config/card semantics should be rechecked when a later change touches persistence/storage.

## Open architecture risks — P1+

### Dispatcher still mixes routing with runtime capability implementation
- P79.8f makes the passive call safe but intentionally leaves the implementation inside `ZONFeatureDispatcher`.
- R2 should now extract only probe/validation/invocation into a dedicated runtime-capability boundary while preserving the device-passed P79.8f contract.

### `ZONAuthV2Flow` still owns too many responsibilities
- It parses server payloads, classifies state, orchestrates activation/config/Verify, maps errors, presents card UI, notices/updates, and opens the floating entry.
- Future work should begin with a pure authorization-decision parser, not a one-shot rewrite.

### Renderer reads raw AuthV2 session schema
- `ZONSectionRenderer` directly consumes `lastVerify/permissions/access_level`.
- R3 should introduce one feature-access provider before adding the future external-dylib-dependent button.

### Feature registry remains weakly typed
- Feature/section descriptors are dictionaries keyed by strings.
- Move toward typed descriptors only after runtime capability and access-provider boundaries stabilize.

### Duplicate Runtime Config parsing helpers
- `ZONAuthV2API.m` and `ZONAuthV2Verify.m` still implement similar nested config lookup semantics.
- Extract later with tests; do not mix with R2.

## P79.8f verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final placeholder remaining: `0`.
- Controlled final Verify Secret occurrences: `2`.
- Raw-to-final changed bytes: `128`, limited to the two equal-length Secret placeholder regions.
- Device test: reported normal; P79.8f promoted to current P0 device baseline.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
