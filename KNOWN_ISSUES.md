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
- Current-device validation: pending.
- Last device-passed baseline: P79.8a / controlled SHA256 `1601c8aaf55643918d4d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.

## P0 risks still requiring device validation

### Startup / authorization behavior
- P79.8f contract tests prove source ordering: startup transport errors are handled before missing-activation/card-prompt routing, and ambiguous payloads suppress the card prompt.
- CI cannot prove real network/UI timing. Verify on device that offline startup shows a network error and does not open card input.
- P79.8a remains the last real-device-confirmed UDID-first authorization baseline.

### Authorization reset boundary
- P79.8f now snapshots and verifies menu/runtime preferences around authorization cleanup.
- Protected keys: `fold_base`, `fold_draw`, `fold_role`, `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`, `AADDssppeedd`.
- If cleanup crosses that boundary, P79.8f restores the snapshot and reports failure.
- Device validation must confirm authorization data is actually cleared while those protected keys retain their previous values.

### Game-data reset scope
- Current implementation derives reset roots from `NSHomeDirectory()` and targets only `Documents`, `Library`, `tmp`, plus the current Bundle ID's NSUserDefaults persistent domain.
- P79.8f locks this scope with a contract test but does not change the destructive implementation itself.
- Real-device validation is still required because destructive filesystem behavior cannot be fully proven by static CI.

### Passive dylib call still requires exact target contract
- Accepted names remain `1_passive.dylib`, `1_passive_zh.dylib`, `SatellaJailed_passive.dylib`.
- Target contract remains `__TEXT vmaddr=0`, ctor RVA `0x847C`, init RVA `0x888C`, exact ctor/prologue signatures.
- P79.8f adds a mapped-`__TEXT` range/protection check before reading either signature. Bad/malformed images fail closed with `text_range_mismatch` before `memcmp` or call.
- Device testing must confirm a valid target still initializes successfully and a bad same-name target does not crash.

### arm64e PAC still needs real hardware
- CI compiles arm64 and arm64e successfully.
- Real arm64e hardware is still required to prove the PAC-signed indirect call works with the target passive dylib.

### P79.8c cloud permission and P79.8b persistence remain device-pending
- basic must hide `VIP云存档`; app/global Plus must expose it and fresh Verify must gate download.
- AuthV2 response/config/card state is memory-only while menu/runtime preferences remain unchanged.

## Open architecture risks after P0

### Dispatcher still mixes routing with runtime capability implementation
- P79.8f makes the passive call safer but intentionally leaves ownership in `ZONFeatureDispatcher`.
- After P0 device acceptance, R2 should extract only the passive capability probe/invocation into a dedicated runtime-capability boundary without changing the contract.

### `ZONAuthV2Flow` still owns too many responsibilities
- It parses server payloads, classifies state, orchestrates activation/config/Verify, maps errors, presents card UI, notices/updates, and opens the floating entry.
- Future work should begin with a pure authorization-decision parser, not a one-shot rewrite.

### Renderer reads raw AuthV2 session schema
- `ZONSectionRenderer` directly consumes `lastVerify/permissions/access_level`.
- R3 should introduce one feature-access provider before adding the future external-dylib-dependent button.

### Feature registry remains weakly typed
- Feature/section descriptors are dictionaries keyed by strings.
- Move toward typed descriptors only after the runtime-capability and access-provider boundaries stabilize.

### Duplicate Runtime Config parsing helpers
- `ZONAuthV2API.m` and `ZONAuthV2Verify.m` still implement similar nested config lookup semantics.
- Extract later with tests; do not mix with P0 work.

## P79.8f verification evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- Xcode 16.4 arm64 + arm64e build: PASS.
- Controlled final placeholder remaining: `0`.
- Controlled final Verify Secret occurrences: `2`.
- Raw-to-final changed bytes: `128`, limited to the two equal-length Secret placeholder regions.

## Tracking rule
- CI success alone does not equal device promotion.
- Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
- Real/test Verify Secret must not be committed or printed.
