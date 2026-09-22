# P76 Device Validation

## Candidate
- Version: `v1_p76`
- Branch: `work/p76-authorization-entry-routing`
- Device baseline: `v1_p74`
- Device-baseline build SHA: `47840ad17fb4780dff4294adf162cb08a02bb6dc`
- P75: intentionally skipped; runtime toggle boundary was left unchanged
- P76 actual migrated/build SHA: `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`
- CI Run: `35698122018`
- CI status: `success`
- Device status: `pending`
- Promotion status: `not_promoted`

## Artifacts
### A_customer
- Artifact ID: `10681262598`
- Artifact digest: `sha256:a4f3da4c43104c8058a34daf2e6c78a9ce098bba449e30dc5a4f7e6239c4c752`
- dylib SHA256: `9e7310cc52ac44bcd34e31fcd20df28474c46f79bea675be5ae60b7306af5e2e`

### B_debug
- Artifact ID: `10681337287`
- Artifact digest: `sha256:659a8a5320f9afd037263b0225bfe49276beea3ce07676386a7490a3836ad74e`
- dylib SHA256: `ac336bad7cd75b6e197a6aa1dee65c1475adfca459f998cf5a29a5a0911d6456`

## Scope
P76 extracts authorization-entry decision policy from `WX_NongShiFu123::loada` into the UIKit-free `ZONAuthorizationEntryRouter`.

The router reads the existing Keychain values and preserves the established priority:

1. `DZUDID.length < 5` -> first activation
2. activation code contains `mg` OR `rjyyz` contains `未查到解锁记录` -> ad-speed authorization (`BSPHP`)
3. `DZUDID.length > 16` AND `rjyyz` contains `ok` -> software-source authorization (`BSPHPy`)
4. otherwise -> existing authorization-method chooser

P76 intentionally does **not** rewrite BSPHP/BSPHPy protocol requests, heartbeat, activation-code verification, blacklist logic, runtime toggles, reset, backup or restore behavior.

## Required real-device validation
Use A_customer first.

1. Launch and normal already-authorized startup remain normal.
2. Existing ad-speed authorization path still enters `秒过广告激活中` and completes normally.
3. Existing software-source authorization path still enters `软件源激活中` and completes normally.
4. Fresh/cleared authorization state still enters `首次激活` and can choose an authorization method.
5. If DZUDID is absent/invalid, the existing UDID acquisition path still works and reaches the authorization chooser.
6. Network-failure retry behavior remains the same for both authorization modes.
7. Existing activation-code reuse / activation-code prompt behavior remains normal.
8. Authorization reset still works and relaunch returns to the expected activation flow.
9. Menu, local-files, backup, local restore, remote ZIP and cloud-save basic regression remain normal.
10. No false authorization success, route inversion, crash or unexpected early exit is observed.

P76 must not be promoted until the user explicitly confirms the scoped real-device validation passes.
