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
- Device status: `passed`
- Device reported by user: `true`
- Promotion status: `promoted`

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

## Real-device validation result
The user explicitly reported that all scoped P76 validation passed on a real device.

Validated coverage includes:

1. Normal already-authorized startup.
2. Existing ad-speed authorization path and `秒过广告激活中` route.
3. Existing software-source authorization path and `软件源激活中` route.
4. Fresh/cleared authorization state entering `首次激活` and authorization-method chooser.
5. Existing UDID acquisition path when DZUDID is absent or invalid.
6. Network-failure retry behavior for authorization modes.
7. Activation-code reuse and activation-code prompt behavior.
8. Authorization reset and relaunch activation flow.
9. Menu, local-files, backup, local restore, remote ZIP and cloud-save basic regression.
10. No false authorization success, route inversion, crash or unexpected early exit observed.

## Promotion
P76 is promoted as the current device-verified runtime baseline.

- Promoted runtime SHA: `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`
- Previous device-verified rollback baseline: `v1_p74` / `47840ad17fb4780dff4294adf162cb08a02bb6dc`

Later documentation-only commits on this branch must not be confused with the real-device-validated runtime SHA above.
