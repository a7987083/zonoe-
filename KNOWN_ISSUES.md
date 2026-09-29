# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_6`.
- Main work branch: `work/p79-server-driven-auth-isolation-v1`.
- Build commit: `ac948369ceba488ece11deb8730d8a9510687f44`.
- CI Run `36523256192`: success.
- Architectures: `arm64 + arm64e`.
- Real-device validation: pending.
- Last promoted/device rollback baseline remains `v1_p64a` / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### P79.6 still requires real-device validation
- CI compile/package success does not prove the activation and Verify behavior on-device.
- Required device paths: invalid card, used/mismatched card, valid new card, saved valid card, revoked/expired saved card, and transient network/server failure.
- Promotion is blocked until the scoped P79.6 regression passes.

### Raw CI P79.6 artifact does not contain Verify Secret
- CI Run `36523256192` reported `verify_secret_configured=0`.
- The raw CI dylib must not be used as the final Verify acceptance artifact.
- Controlled final test artifact uses equal-length post-build injection of the user-provided test Verify Secret into both architecture slices.
- Final controlled dylib SHA256: `9192a214bc7a23a0fb18aadccd72529c9404e415e3c20faab3ddb36b67974080`.
- Public source must retain only the placeholder. Do not commit the real/test Secret or print it in CI logs.

### Valid authorization may still expose an App Identity mismatch
- P79.6 now prevents invalid/unchanged activation state from falling through into Verify.
- If a genuinely valid authorization passes the activation gate but Verify still returns `Authorization does not apply to this App`, inspect server-side `app_identity` / bundle mapping and the submitted `bundle_id`, executable, Mach-O UUID, app version/build and dylib identity.
- Do not work around this by bypassing or weakening Verify.

### Presentation continuation remains device-sensitive
- Notice/update/message presentation is serialized by `ZONPresentationCoordinator`.
- Several call sites depend on presentation completion to continue to the icon.
- CI cannot prove that a modal presentation retry/failure always reaches the business continuation path; device regression must verify success → notice → update → icon.

### Historical backup/restore refactor work remains incomplete
- `daochucd` still mixes UI, filesystem traversal, archive work and sharing.
- Backup format compatibility must be preserved in any future P65 work.
- `YYYPicker` still mixes picker UI and restore engine.
- `PubgLoad` remains a multi-responsibility class for remote download/cloud-save work.

## Closed / corrected

### P79 activation fall-through into Verify — CORRECTED IN P79.6 / DEVICE PENDING
- Previous P79 code could call Verify after `/appstore` + `/apiface` without confirming that authorization became valid and changed.
- This caused unrelated card failures to reach Verify and be collapsed into `Authorization does not apply to this App` / `当前卡密不适用于此应用`.
- P79.6 restored `ZONLicenseIsAuthorized`, authorization fingerprinting and the `stateChanged` gate from the successful standalone auth implementation.
- Saved-card HTTP-200 but invalid authorization content is now also rejected before Verify.
- Activation-gate commit: `ad7fc577bb52b02a1c5cecaa74ef263c1f19a6a9`.

### P64a runtime-directory model — CLOSED / DEVICE PASSED
- P64a distinguishes game/user payload from runtime directory skeletons and volatile cache/temp residue.
- CI Run `35524126925`: success.
- User explicitly reported P64a fully normal on device.

### Version naming drift — CORRECTED IN PROJECT RECORDS
- New stages increment numeric phase.
- Same-stage fixes use suffix letters.
- Historical commits/artifacts remain preserved.

## Tracking rule
- CI success alone does not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
- Verify acceptance testing must use a Secret-configured controlled artifact, not a placeholder build.
