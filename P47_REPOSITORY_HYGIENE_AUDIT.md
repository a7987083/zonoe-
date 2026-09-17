# P47 Repository Hygiene Audit

## Baseline
- Runtime predecessor: `v1_p46`.
- P46 runtime commit: `83a49f46c1d0e4eecf5a52a485ebc35442786f67`.
- P46 CI Run: `35167182449` (success).
- Canonical product surface: `testmod/` + `testmod.xcodeproj`.
- P47 intent: repository hygiene only; no runtime behavior/refactor work.

## Audit result

### Removed
`Packages/com.leizi.www..testmod_0.1-1_iphoneos-arm.zip`

Evidence before removal:
- It was the only tracked entry under `Packages/`.
- Repository code search returned no references to the exact filename.
- Repository code search returned no references to `Packages/` as a runtime, PBX, script, workflow, or documentation input.
- It is a reproducible package artifact, not canonical source.

### Ignore rule added
`Packages/*.zip`

The rule is intentionally narrow. It prevents re-committing generated package ZIPs without globally blocking legitimate source archives elsewhere in the repository.

### Already protected by `.gitignore`
- `xcuserdata/`
- `*.xcuserstate`
- `build/`
- `DerivedData/`
- `*.dSYM/`
- `*.dylib`
- `*.deb`
- `.DS_Store`
- local config/secrets overrides

No tracked `xcuserdata` entry was present in the P46 tree inventory.

### Retained deliberately
Historical phase scripts, tests, audit documents, and P34-P46 workflows are retained in P47.

Reason: they are reproducibility/evidence material, not generated package outputs. P47 does not equate age with dead code. Removal of historical CI/test inputs requires separate reachability and policy evidence and is outside this phase.

## Product invariants — final result
1. `testmod/` tree SHA identical to P46: **PASS**.
2. `testmod.xcodeproj/` tree SHA identical to P46: **PASS**.
3. Active PBX Sources remains 79: **PASS**.
4. No new runtime source added or removed: **PASS**.
5. A_customer and B_debug build for arm64 + arm64e: **PASS**.
6. Exported symbols and load libraries remain identical to P46: **PASS**.
7. Inherited P46 launch contract: **PASS**.

## CI evidence
- Work branch: `work/zonoemenu-v1-p47-repository-hygiene`.
- Repository candidate commit: `64f8575966d62695123b9f8444f89dbc98e796df`.
- Test branch: `test/zonoemenu-v1-p47-repository-hygiene-build`.
- Successful CI head: `eed8c8aca74a8c6e6985848a11c76d5a52cc2f40`.
- CI Run `35169166129`: **success**.
- A_customer artifact ID `10476362290`, digest `sha256:f913b210dd80e2438af1bfc13b8b8b3aafe3ab3837c8d4507935abb10adfdfe5`.
- A_customer dylib SHA256 `0a02a4eae98c6e18801320e2558c63769683697caf5faf557f38d553cbc729a2`.
- B_debug artifact ID `10476157646`, digest `sha256:d2f57b2f041b533a40dcfdec43e691c274822b97214deeeb5acaac3e115a7bcd`.
- P47 A_customer SHA256 equals P46 A_customer SHA256 exactly, so the produced A_customer dylib is **byte-identical to P46**.

## Device gate
P47 changes no product runtime source. P46 had not yet been explicitly device-promoted when P47 work began, and P45 was not separately promoted. Because P47 A_customer is byte-identical to P46 A_customer, one explicit real-device PASS using the P47 candidate can satisfy the inherited P45/P46 combined gate and permit direct P47 promotion.

Required inherited device coverage:
- existing `DZUDID` startup/auth;
- fresh Zonoe acquisition/return;
- legacy fallback where practical, with no duplicate loop and valid `DZUDID` continuation;
- launch trace presence/order without visible stall;
- floating entry/menu smoke.

## Rollback
Until the inherited combined device validation explicitly passes, `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561` remains the last device-verified rollback baseline.
