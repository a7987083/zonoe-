# KNOWN_ISSUES

## Current state
- Active test version: `v1_p79_8`.
- Main P79 work branch: `work/p79-server-driven-auth-isolation-v1`.
- Logic commit: `608a5bbb1c584e551efe6bffbce088bcf99280b2`.
- Build/version commit: `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- CI Run `36560746520` / run #27: success.
- Architectures: `arm64 + arm64e`.
- Controlled final test dylib SHA256: `12cac6f3a9b7ce9da1ad5f27f9364606c42f52eb3311dd36e2308c5cd8a8f723`.
- Real-device validation: pending.
- Last promoted/device rollback baseline remains `v1_p64a` / `010f383da7f1429c4db93bfda559431e3c4080f9`.

## Open risks

### P79.8 same-card/same-UDID requires device confirmation
- P79.8 probes `/index/index/license` with exact `code + udid` after confirming the UDID already has active authorization.
- The server path uses `AuthorizationLicense::query(code, udid)`, which requires exact `kami + udid + jh=1`; only an active result may skip `/appstore`.
- Device regression must confirm that the currently deployed server renders the expected active-license response and that the flow reaches Verify.
- A different used card must remain rejected and must never borrow the current UDID's authorization.

### P79.7 `/authorization` binding probe is retired
- P79.7 device test failed because same card + same UDID still showed `解锁码已使用`.
- The legacy `/authorization` compatibility surface did not supply the structured Bound result expected by P79.7, so the client fell back to `/appstore`.
- Current `/appstore` treats `jh=1` cards as one-time activation credentials and returns `解锁码已使用`; this is not sufficient evidence of same-device ownership.
- Do not reintroduce the old `/authorization` probe or convert a generic used-card message into success.

### App mismatch prompt routing requires device confirmation
- P79.7/P79.8 route `app_not_authorized` / `Authorization does not apply to this App` back into the existing card prompt.
- Verify on-device that no separate terminal alert remains and that a replacement card can be entered immediately.

### Cross-App authorization clearing is limited by Keychain visibility
- Authorization reset deletes complete authorization-related Generic Password services visible to the current process.
- iOS Keychain access-group isolation still applies. If App A and App B use separate/default access groups, App A cannot remove App B's isolated records.
- True cross-App local clearing requires a shared access group available to both signed Apps; server-side records require an explicit server reset/revoke contract if such behavior is desired.
- `/unbind` is a transfer operation and must not be treated as a global revoke API.

### Raw CI artifact still has no Verify Secret
- CI Run `36560746520` reported `verify_secret_configured=0`.
- Raw CI dylib SHA256: `590f6a67e5e4faf9d6c9a2c6f6910884cbff4a15e5cf6c205fe3536be20fb9cc`.
- Controlled final test artifact uses equal-length post-build injection into both architecture slices; placeholder remaining `0`, Secret occurrences `2`, size unchanged, 128 bytes differ.
- Public source must retain only the placeholder.

### Presentation continuation remains device-sensitive
- Notice/update/message presentation is serialized by `ZONPresentationCoordinator`.
- Device regression must still verify success → notice → update → icon.

## Closed / corrected

### P79.7 binding decision source — corrected in P79.8 / DEVICE PENDING
- Replaced retired `/authorization` compatibility probe with the existing exact server license query.
- Same-card reuse no longer depends on interpreting `解锁码已使用`.

### P79 activation fall-through into Verify — corrected in P79.6
- P79.6 restored authorization-state validation and `stateChanged` gating before Verify.
- P79.8 retains that gate for new activations.

### P64a runtime-directory model — device passed
- CI Run `35524126925`: success.
- User reported P64a fully normal on device.

## Tracking rule
- CI success alone does not equal promotion.
- Every stage transition must update `ROADMAP.md`, `CHANGELOG_DEV.md`, `HANDOFF.md`, `PROJECT_STATE.json` and `KNOWN_ISSUES.md` together.
- Verify acceptance testing must use a Secret-configured controlled artifact, not a placeholder build.
