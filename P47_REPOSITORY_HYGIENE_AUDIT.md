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

## Product invariants
P47 must prove:
1. `testmod/` tree SHA is identical to P46.
2. `testmod.xcodeproj/` tree SHA is identical to P46.
3. Active PBX Sources remains 79.
4. No new runtime source is added or removed.
5. A_customer and B_debug still build for arm64 + arm64e.
6. Exported symbols and load libraries remain identical to P46.

## Device gate
Because P47 changes no product runtime source, P47 itself does not add a new behavioral device surface. However, P46 had not yet been explicitly device-promoted when P47 work began. Therefore P47 cannot become the promoted baseline until the inherited P46 combined device gate has passed.

## Rollback
Until inherited P46 device validation passes, `v1_p44` / `aee574d180da7cc82db54be7ab5aeaa9d072c561` remains the last explicitly device-verified rollback baseline.
