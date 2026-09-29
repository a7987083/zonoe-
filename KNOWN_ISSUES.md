# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_7`.
- Development branch: `work/p79.7-auth-semantics-reset-scope`.
- Main P79 work branch: `work/p79-server-driven-auth-isolation-v1`.
- Source/build commit: `20cc0dc14e3157060d738ec8b66ef184284597bf`.
- CI Run `36531465809`: success.
- Architectures: `arm64 + arm64e`.
- Controlled final test dylib SHA256: `4ea75bea7c8a1929483d9f404aa9c47ab3be6e50cf7cafca5679740b926c23b8`.
- Real-device validation: pending.
- Last promoted/device rollback baseline remains `v1_p64a` / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### Same-card/same-UDID binding semantics require device confirmation
- P79.7 queries the compatibility `/authorization` endpoint before re-activating an already-authorized UDID.
- Only a structured bound result skips `/appstore`; unknown/not-bound keeps the strict P79.6 activation path.
- Device regression must verify that the actual production response marks the same card + same UDID correctly and that a different used card is not accepted.

### App mismatch prompt routing requires device confirmation
- P79.7 routes `app_not_authorized` / `Authorization does not apply to this App` back into the existing card prompt.
- Verify on-device that no separate terminal alert remains and that a replacement card can be entered immediately.

### Cross-App authorization clearing is limited by Keychain visibility
- P79.7 deletes complete authorization-related Generic Password services visible to the current process.
- iOS Keychain access-group isolation still applies. If App A and App B use separate/default access groups, App A cannot remove App B's isolated records.
- True cross-App local clearing requires a shared access group available to both signed Apps; server-side records require an explicit server reset/revoke contract if such behavior is desired.
- The current integration surface should not assume `/unbind` is equivalent to global authorization removal.

### Raw CI artifact still has no Verify Secret
- CI Run `36531465809` reported `verify_secret_configured=0`.
- Raw CI dylib SHA256: `d6c74b0cb3a7f9f9318c1f1ed805690aaecda2ef01be915b718deb9f5dc707f9`.
- Controlled final test artifact uses equal-length post-build injection into both architecture slices; placeholder remaining `0`, Secret occurrences `2`.
- Public source must retain only the placeholder.

### Presentation continuation remains device-sensitive
- Notice/update/message presentation is serialized by `ZONPresentationCoordinator`.
- Device regression must still verify success → notice → update → icon.

## Closed / corrected

### P79 activation fall-through into Verify — corrected in P79.6
- P79.6 restored authorization-state validation and `stateChanged` gating before Verify.
- P79.7 retains that gate and layers same-binding reuse on top.

### P64a runtime-directory model — device passed
- CI Run `35524126925`: success.
- User reported P64a fully normal on device.

## Tracking rule
- CI success alone does not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
- Verify acceptance testing must use a Secret-configured controlled artifact, not a placeholder build.
