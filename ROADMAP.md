# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Version naming rule
- New stage: `P63 → P64 → P65 → P66 → ...`
- Same-stage fix: `P64a → P64b → P64c ...`
- Historical strings `v1_p63a` and `v1_p63b` remain in history; canonical mapping is P63/P64.

## Current promoted runtime baseline — P65 / DEVICE PASSED
- Version: `v1_p65`.
- Branch: `work/p65-backup-engine-refactor`.
- Runtime/build source: `60db9885c1c69ff7e658bd99949274884d898b32`.
- CI Run `35562076044`: success.
- A_customer artifact `10622392644`, dylib SHA256 `83ab3e382d27e8c168a7428453e6b6da0f2acf0f5921877cb304e03485bde51e`.
- B_debug artifact `10622696370`, dylib SHA256 `849760004323c613d63c58c1b516141a732ece72603f2e19927327bebcaf8839`.
- Architectures: `arm64 + arm64e`.
- User explicitly reported the complete P65 real-device regression normal.
- P65 backup creation succeeded on device.
- A P65-produced backup restored successfully through the existing pre-P66 restore path.
- Startup/menu and existing six-button regression were normal.
- **P65 is promoted and is the rollback/device baseline for P66.**

## P64 / P64a history
### P64 — Clear Game Data Dedicated Service — CI PASSED / DEVICE FAILED
- Historical built VERSION string: `v1_p63b`; canonical stage is P64.
- Runtime source: `203b9f93d88a20f820ba35d0e3f65f16f296ce5d`.
- Device failure: runtime `Library/Caches` directory behavior was incorrectly treated as fatal.

### P64a — Runtime Directory Cleanup Fix — DEVICE PASSED / SUPERSEDED
- Version: `v1_p64a`.
- Runtime source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Real-device validation passed.
- Superseded as promoted baseline by P65.

## P65 — Backup Engine Refactor — COMPLETED / DEVICE PASSED
### Delivered architecture
`ZONFeatureRegistry → ZONFeatureDispatcher → ZONSixButtonActionService → ZONBackupService → filesystem/archive engine`

### Completed verification gates
- Backup button route preserved.
- Existing six-button boundary preserved.
- Backup service/API contract passes.
- A_customer `arm64 + arm64e`: PASS.
- B_debug `arm64 + arm64e`: PASS.
- Real-device launch/injection: PASS.
- Real-device backup creation: PASS.
- Backup output/share behavior: PASS.
- P65-produced backup restored through the existing restore path: PASS.
- Post-restore game/data behavior: PASS.

## P66 — Restore Engine Extraction — NEXT
### Goal
Extract restore execution from `YYYPicker` behind a dedicated restore service without changing the now device-proven P65 backup format or restore semantics.

### P66 guardrails
- P65 runtime/build source `60db9885c1c69ff7e658bd99949274884d898b32` is the rollback baseline.
- Preserve compatibility with P65-generated backups.
- Lock current restore behavior before moving implementation.
- Keep picker/presentation concerns outside the pure restore engine where practical.
- Build both A_customer and B_debug for `arm64 + arm64e`.
- Require real-device restore regression before promotion.

## Follow-on stages
- P67 — Remote Download engine extraction from `PubgLoad`.
- P68 — Cloud Save engine extraction from `PubgLoad`.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history.
3. New functional stages increment the numeric version; suffix letters are same-stage fixes only.
4. CI success does not equal device promotion.
5. Keep the five long-project state files synchronized.
6. Every successful CI delivery includes dylib delivery plus explicit real-device verification scope.

# Next Task
Open P66 from the promoted P65 runtime baseline and audit/extract the existing restore path from `YYYPicker` without changing observable restore behavior.
