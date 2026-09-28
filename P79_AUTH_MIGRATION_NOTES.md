# P79 Server-Driven Auth Isolation V1

Base runtime: P76 `9e4d0a0f34a4019fc26521fafdc864e9fd0f9afd`.

## Boundary

- Keep `testmod/Bsphp/WX_NongShiFu123.mm/.h` and the entire Bsphp tree as reference code.
- Do not delete or rewrite legacy BSPHP/BSPHPy in phase 1.
- New authorization must use the server-driven API/state model.
- Preserve existing UDID acquisition/menu timing from the P76 runtime.
- Do not change cloud-save entitlement, save/restore, runtime hook, or ordinary menu behavior in phase 1.

## Server-driven endpoints

- `GET /appstore?udid=<UDID>&code=<CARD>`
- `GET /index/index/apiface?udid=<UDID>`
- `GET /index/dylib_verify/config?dylib_key=zonoe.main`
- `POST /index/dylib_verify/verify`

## Security constraint

The integration guide does not specify the exact Protocol v2 canonical payload construction / HMAC field ordering. Do not invent it. Repository source must keep the Verify secret as a placeholder and must not log or commit a production secret.

## Phase 1 target

Existing floating/menu entry -> existing P76 UDID acquisition -> new card prompt -> server-driven activation/status/runtime-config/Verify v2 -> success/failure UI -> persisted V2 auth state.
