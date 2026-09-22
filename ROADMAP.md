# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current promoted runtime baseline — P69 / DEVICE PASSED
- Version: `v1_p69`.
- Branch: `work/p69-save-transfer-coordinator`.
- Runtime/build source: `1e8240e66ddf95fcfeebe970417a5b8721908cd8`.
- CI Run `35668507458`: success.
- Architectures: `arm64 + arm64e`.
- Real-device validation: PASS, explicitly reported by user (`全部正常`).
- Previous rollback baseline: P68 / `57492160450673f9ea17e69b9d4776668db32773`.

## Completed stages
- P65 — Backup Engine Refactor — device passed / promoted.
- P66 — Restore Engine Audit/Extraction — device passed / promoted.
- P67 — Remote Download Engine Extraction — CI passed, device regression, not promoted.
- P67a — Restore compatibility hotfix — device passed / promoted.
- P68 — Cloud Save Engine Extraction — device passed / promoted.
- P69 — Save Transfer Coordinator Extraction — device passed / promoted.

## P69 architecture
`ZONFeatureDispatcher -> ZONSixButtonActionService -> ZONSaveTransferCoordinator -> ZONCloudSaveService / ZONRemoteDownloadService -> ZONRestoreAPI`

P69 removes the active save-transfer orchestration from `PubgLoad`. `PubgLoad` remains only as a compatibility shim for legacy selectors.

## P70 planning rule
Do not define P70 by phase number alone. Start from the promoted P69 runtime and audit remaining mixed responsibilities first. Prefer the next extraction only when it has:
- a clear ownership boundary,
- measurable maintenance or regression-risk reduction,
- behavior that can be locked by contract tests,
- a narrow real-device validation scope.

Potential candidates must be verified from current source before selection; do not revive stale P64/P65 planning assumptions.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not rewrite historical commits.
3. New functional stages increment the numeric version; suffix letters are same-stage fixes only.
4. CI success does not equal device promotion.
5. Keep `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json`, and `KNOWN_ISSUES.md` synchronized at each stage transition.
6. Build the exact migrated source SHA and verify A_customer + B_debug artifacts before device testing.
7. Preserve the last real-device-passed source as rollback baseline until the next stage is explicitly device-passed.

# Next Task
Use P69 (`1e8240e66ddf95fcfeebe970417a5b8721908cd8`) as the development baseline, audit the remaining active runtime responsibilities, and select P70 only after source/data-flow review.
