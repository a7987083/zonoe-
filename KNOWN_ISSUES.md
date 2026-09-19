# KNOWN_ISSUES

## Current state
- Promoted/device baseline: `v1_p62` / `a11160e70ff1163b2c462bb3ef5d539da1f489eb`.
- P62 CI Run `35410564486`: success.
- P62 real-device validation: passed, explicitly reported by user.
- Current candidate: `v1_p65` on `work/zonoemenu-v1-p65-p62-maintainability-refactor`.
- P65 CI Run `35424279529`: success; real-device validation pending.
- Active Sources: **78**.
- Architectures: `arm64 + arm64e`.
- Canonical runtime surface: `testmod/` + `testmod.xcodeproj`.

## Open risks

### P0 — `WX_NongShiFu123.mm` remains a high-risk authorization god object
It still owns/coordinates legacy authorization modes, network reachability, HTTP initialization, configuration parsing, activation UI, keychain-driven branching and retry presentation.

Risk:
- broad edits can alter callback order, retry mode, UI lifecycle or server state.

Next validation/refactor:
- P66 should extract only P62 retry ownership/presentation while preserving exact UX/timing/targets.

### P1 — authorization server response parsing trusts array shape
`getXinxi:` splits server-controlled strings and indexes expected fields without first proving element counts.

Risk:
- malformed or truncated data can produce range exceptions.

Next validation/refactor:
- P67 parsing-safety fixtures and guarded assignment. Valid-response semantics must remain unchanged.

### P1 — reachability helper lacks explicit NULL creation guard
`getNet` uses `SCNetworkReachabilityCreateWithName` and proceeds to flags/release without an explicit NULL branch.

Risk:
- creation failure can become a crash rather than clean offline handling.

Next validation/refactor:
- P68 network-boundary stage; preserve P62 retry UX.

### P1 — destructive clear-data exit ordering is not deterministic
`ZONClearGameDataPreservingTmp` schedules deletion work at +5 seconds and independently schedules `exit(0)` for the same +5-second deadline.

Risk:
- process termination may race remaining deletion work.

Next validation/refactor:
- P69 should chain exit only after deletion completion, with filesystem tests and device validation.

### P1 — global startup side effects remain order-sensitive
`main.m +load`, framework preflight, Bootstrap, authorization, module loading and floating-entry lifecycle remain order-sensitive.

Risk:
- async/queue cleanup can change launch behavior.

Rule:
- no timing/threading changes without dedicated measurement and behavior gates.

### P2 — `ZONLaunchTrace.h` remains implementation-heavy
Event-name mapping, uptime sampling, os_log singleton and signpost emission live as static inline implementation in the header.

Risk:
- compile-time coupling and duplicated inline implementation; no proven runtime regression currently.

### P2 — feature dispatcher remains coupled to legacy implementations
Registry/Dispatcher correctly centralizes feature routing, but Dispatcher still imports legacy backup/restore/cloud/auth handlers directly.

Risk:
- service replacement remains expensive even though UI routing is stable.

## Candidate-specific status

### P65 real-device gate — OPEN
- CI/contract/build/ABI/load-library gates passed.
- Only runtime file changed vs P62: `testmod/ZONServices/ZONAuthorizationCoordinator.m`.
- Must test A_customer startup with:
  - existing valid DZUDID;
  - first activation / UDID acquisition;
  - authorization continuation into `loada`;
  - clear authorization then relaunch.
- Do not promote before device validation.

## Closed / corrected

### P63/P64 offline authorization direction — ABANDONED
- P63 device behavior did not meet the intended offline-authorized requirement.
- P64 was abandoned before promotion.
- P62 remains the verified behavior baseline; do not reuse those paths accidentally.

### P62 unified authorization network retry — CLOSED / PROMOTED
- CI Run `35410564486`: success.
- Real-device validation: passed.
- Reachability and actual HTTP-failure paths now converge on the visible `重新检查` retry UI.

### Authorization orchestration mixed into main.m — CLOSED BY P44
- Selected authorization/reset ownership moved into `ZONAuthorizationCoordinator`.

### ZonoeUDIDAPI ownership mixed with UI — CLOSED BY P42
- Public UDID API has explicit service ownership.

### ZONUDIDBridge implementation-heavy header — CLOSED BY P41
- Implementation moved to `.m` and later device baselines covered it.

### Canonical product-source ambiguity — CORRECTED
- `testmod/` + `testmod.xcodeproj` are canonical; PBX membership remains authoritative.

## Tracking rule
Move a runtime risk to closed only after its scoped CI gate and, where behavior can change, required real-device validation pass. CI success alone does not equal promotion.
