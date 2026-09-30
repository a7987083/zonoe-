# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use suffixes.

## Current active stage — P79.8f P0 Runtime/Authorization Safety Hardening — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8f`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Build HEAD: `67fbf755cf00623f3d0136668e103461d5189dae`.
- CI Run `36723643520` / #44: success.
- Artifact ID `11101797212`, digest `sha256:e16aa4bb55eb9e776c283d02da67eef78010f7f07df012c764e7a452a029ba6e`.
- Raw CI dylib SHA256: `b124e544b32674844bf7e9be9a35e0259e512063ce7b0113e5450c3a61535970`.
- Controlled final dylib SHA256: `18c443fb67440e7030b1b85fb82813c6d5aad52347cbf4aa3358313e00a84a6a`.
- Controlled final ZIP SHA256: `1e6ba1e2b3576673e645e787b83cadde1b6833f200dc621d527273ab6fbe0778`.
- Universal `arm64 + arm64e (PAC00)`.

### P0 hardening delivered in P79.8f
1. **Injected passive dylib memory safety**
   - Before any `memcmp(base + RVA)`, parse `LC_SEGMENT_64` and locate `__TEXT`.
   - Preserve the P79.8d contract `__TEXT vmaddr == 0`.
   - Require `VM_PROT_READ | VM_PROT_EXECUTE` and ensure both `0x847C` ctor signature and `0x888C` init signature ranges fit the mapped segment.
   - Invalid/malformed/mismatched images fail closed with `[P79.8F_P0_SATELLA] text_range_mismatch` before dereference or call.
2. **Authorization-reset boundary protection**
   - Snapshot menu/runtime keys before authorization cleanup: `fold_base`, `fold_draw`, `fold_role`, `NNGG`, `NNGGNNGG`, `AADD`, `AADDAADD`, `AADDssppeedd`.
   - Verify the snapshot is unchanged after authorization reset.
   - If authorization cleanup crosses that boundary, restore the menu/runtime snapshot, log `[P79.8F_P0_RESET]`, and return failure.
3. **P0 acceptance contracts**
   - `Tests/p79_8f_p0_safety_contract.py` locks network-error-before-card-prompt behavior, unknown-payload card-prompt suppression, current game-data reset scope, authorization reset boundary, and passive mapped-range gating.
   - Active P79 workflow runs Dispatcher, P79.8d passive, and P79.8f P0 contracts before Xcode build.

### P79.8f CI evidence
- `dispatcher-contract: PASS`.
- `p79.8d-passive-contract: PASS`.
- `p79.8f-p0-safety: PASS`.
- Xcode 16.4 `arm64 + arm64e` build: PASS.
- Raw CI artifact contains no real/test Verify Secret.
- Controlled final injection changed exactly 128 bytes across the two placeholder regions; placeholder remaining `0`, Secret occurrences `2`.

### P0 real-device acceptance required
1. Existing activated UDID starts without card prompt and reaches Verify/menu.
2. Offline startup shows network failure and does **not** open card prompt.
3. Clear authorization removes authorization state while preserving the protected menu/runtime keys.
4. Clear game data remains scoped to the current App container `Documents/Library/tmp` and current bundle defaults.
5. Matching injected passive dylib still logs `validated → init → started` and activates exactly once.
6. No injected passive dylib does not crash and does not roll back the existing IAP/iGameGod toggle.
7. Same-name incompatible/truncated passive image fails closed before signature read/call.
8. Real arm64e hardware validates PAC-signed indirect invocation.

## Functional baseline inherited
- P79.8a: UDID-first authorization — DEVICE PASSED.
- P79.8b: AuthV2 persistence cleanup — DEVICE PENDING.
- P79.8c: server-driven menu permissions — DEVICE PENDING.
- P79.8d: injected passive Satella trigger — DEVICE PENDING.
- P79.8e: CI/test architecture hardening; product bytes unchanged from P79.8d.

## Refactor sequence after P0 device acceptance
1. R2 — extract passive injected-image probing/invocation from `ZONFeatureDispatcher` into a dedicated runtime-capability boundary without changing behavior.
2. R3 — introduce one feature-access provider combining server permissions and local runtime capabilities; this is the clean basis for “external dylib loaded → show new button”.
3. R4 — migrate weak dictionary feature metadata toward typed descriptors while preserving identifiers/tags/order.
4. R5 — decompose `ZONAuthV2Flow`, starting from pure authorization-decision parsing.
5. R6 — measure startup/preflight/module-load timing before optimization or reordering.
6. R7 — classify historical tests/workflows/generated artifacts before cleanup.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Run the P79.8f P0 device matrix. Only after P0 is device-accepted should R2 Runtime Capability extraction begin.
