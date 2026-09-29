# ROADMAP

> Canonical refactor plan for `zonoemenu`. New functional stages increment the numeric phase. Same-stage fixes use `a/b/c/d` suffixes.

## Current active stage — P79.8a Clean UDID-First Rebuild — CI PASSED / DEVICE PENDING
- VERSION: `v1_p79_8a`.
- Branch: `work/p79.8-udid-first-rebuild`.
- Rebuilt directly from P79.8 commit `702f7011bda568dffbe57c1ad3ca6d7d0feebc40`.
- Flow commit: `fdd83d6eeb562d6ba6f6d5a4afae6d09f2234a4c`.
- BindingProbe removal commit: `dce8c905960256d6e73dcdb62d42060f56660558`.
- VERSION commit: `bbebc59b4fb113d0bcfccdd201d889fe1bdb3442`.
- CI enable/build HEAD: `3ab9fc3879930b7d89770ca95f6e7636dc0119d3`.
- CI Run `36572203902` / run #32: success.
- Artifact ID `11036215202`, digest `sha256:639403f138acece3089e3460e7606752d55364115b3e1e8c404cdb8f941033b2`.
- Raw CI dylib SHA256: `188e25b8c8d76653baffb01e01cd8931302d2ca6d0e67a07d18fee1bd80a894a`.
- Controlled final test dylib SHA256: `1601c8aaf55643918d4d7d6f4ea16d45c552e6fdf1ad9c8c7a2cd9152c03fbb0`.
- Raw CI reports `verify_secret_configured=0`; controlled final artifact has placeholder `0` and Secret occurrences `2`.

### P79.8a startup contract
1. Acquire UDID first and persist it as the device identity.
2. Before reading any locally saved card, call `/index/index/apiface?udid=<UDID>` through the Bootstrap-provided business API base.
3. Preserve the legacy BSPHPy success contract: `code == 1`, `msg == ok`, `expire > now` means this UDID already has an active card authorization.
4. Active UDID authorization never opens the card prompt; it proceeds directly to Runtime Config + Verify.
5. Verify, not `/apiface`, owns current-App authorization level and permissions (`access_level`, `permissions`).
6. Explicit no-record or expired authorization opens the card prompt.
7. Network/server errors or unknown payloads do not open the card prompt because they are not proof of an unactivated UDID.
8. First activation keeps the strict before-state → `/appstore` → after-state → state-change gate before Verify.

### Removed from the runtime path
- P79.8 `ZONAuthV2BindingProbe` swizzle is no longer compiled into the target.
- `P79.8_BINDING_GATE` and `P79.8_LICENSE_PROBE` markers are absent from the final binary.
- Startup no longer uses `savedCard` as the decision for whether a new App needs activation.

### Device gates
- Freshly installed App + already-activated UDID: no card prompt; direct Verify.
- Verify response supplies the server-authoritative card level/permissions and continues accordingly.
- UDID with no activation record: card prompt.
- Expired authorization: replacement-card prompt.
- New card: activation must create a real state change before Verify.
- App mismatch: return to the same card prompt.

## Protocol baseline
- Bootstrap: `https://raw.githubusercontent.com/a7987083/zonoemenu-config/main/bootstrap/zonoe.main.json`
- Business API base: `https://app3.zonoeios.xyz`
- UDID authorization path: `/index/index/apiface`
- Verify endpoint: `https://app3.zonoeios.xyz/index/dylib_verify/verify`
- `dylib_key=zonoe.main`, `dylib_version=1`, empty build, protocol v2.

## Last promoted/device baseline — P64a
- Version: `v1_p64a`.
- Source: `010f383da7f1429c4db93bfda559431e3c4080f9`.
- CI Run `35524126925`: success.
- Real-device validation: PASS.
- P64a remains the rollback baseline until P79.8a passes device regression.

## Frozen operating rules
1. `testmod/` + `testmod.xcodeproj` are canonical.
2. Preserve commit history; do not force-update normal development branches.
3. CI success does not equal device promotion.
4. Keep ROADMAP, CHANGELOG_DEV, HANDOFF, PROJECT_STATE and KNOWN_ISSUES synchronized.
5. Never commit or print the real/test Verify Secret.

# Next Task
Install controlled `v1_p79_8a` and first verify a freshly installed App on an already-activated UDID. It must skip card input and proceed to Verify.
