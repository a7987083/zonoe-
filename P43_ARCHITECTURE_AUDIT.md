# P43 ARCHITECTURE STATE REFRESH & OWNERSHIP AUDIT

## Baseline
- Promoted/device baseline: `v1_p42`.
- Product runtime/source commit: `e87b683a9c868e00d13582c8145bb9368878fee3`.
- Audit branch: `work/zonoemenu-v1-p43-architecture-audit`.
- P42 active PBX Sources: 77.
- P43 is an audit-only phase. Product runtime must remain unchanged.

## Current startup/auth ownership
`testmod/Bsphp/main.m` currently owns five distinct responsibilities:
1. authorization-reset compatibility interception for `WX_NongShiFu123 -deletekm`;
2. clearing `DZUDID` plus Zonoe bridge defaults on authorization reset;
3. customer status-bar presentation helper;
4. customer authorization orchestration (`DZUDID` keychain -> bridge cache -> Zonoe request -> `loada` continuation);
5. process startup host (`+load`), framework preflight and A_customer/B_debug variant entry.

The startup host itself should remain in `main.m` for now because `+load` timing, preflight ordering and variant entry are protected behavior. The authorization orchestration block is the smallest coherent ownership unit that can be isolated without changing the legacy authorization implementation.

## P44 selected extraction target
P44 should extract the authorization orchestration/reset glue from `main.m` into a narrow service/coordinator boundary, provisionally named:
- `testmod/ZONServices/ZONAuthorizationCoordinator.h`
- `testmod/ZONServices/ZONAuthorizationCoordinator.m`

### Candidate moved responsibilities
- authorization-reset compatibility install function and original IMP storage;
- reset-time clearing of `DZUDID` and Zonoe bridge defaults;
- customer authorization status helper;
- customer authorization continuation after UDID acquisition;
- customer authorization start decision tree.

### `main.m` responsibilities that must stay in place in P44
- `NSObject (mian)` category ownership;
- `+load` entry point;
- AppLovinSDK / UnityFramework preflight helpers;
- exact call order: reset-extension install -> `ZONBootstrapStart(preflight, ready)`;
- A_customer/B_debug compile-time branch;
- debug floating-entry call;
- customer status-host creation / existing startup presentation behavior unless an exact-equivalence contract proves a narrower handoff.

## Protected P44 behavior
P44 must preserve byte-for-byte or mechanically equivalent logic for:
- `DZUDID` keychain read/write/remove semantics;
- bridge defaults keys `zonoe.udid.bridge.value`, `.scheme`, `.requestTimestamp`, `.requestNonce`;
- `WX_NongShiFu123 -deletekm` method replacement ordering and original IMP call-through;
- existing-UDID fast path directly to `[auth loada]`;
- bridge-cache path via `ZonoeCurrentUDID()`;
- first-acquisition order: status -> `ZonoeSetUDIDCallback` -> `ZonoeRequestUDIDIfNeeded`;
- `ZONContinueCustomerAuthorization` validation (`length >= 5`), write-back verification and `loada` continuation;
- all current main-queue dispatch behavior and status durations/text;
- `+load` and Bootstrap timing/order.

## Legacy unit audit

### `WX_NongShiFu123.mm`
Status: ACTIVE / HIGH-RISK / DO NOT SPLIT IN P44.

Observed responsibilities include:
- `loada` customer authorization entry;
- keychain-backed authorization state;
- delayed authorization mode selection UI;
- network reachability and server/session flows;
- UDID/IDFV acquisition branches;
- activation-code UI and validation;
- multiple status/UI dependencies;
- direct imports of `PubgLoad`, `NSObject+UI`, `fuzhu`, JDStatusBarNotification and other legacy utilities.

Conclusion: too broad for the first post-P42 ownership extraction. Keep as an implementation dependency behind the P44 coordinator boundary.

### `PubgLoad.mm`
Status: ACTIVE / BROAD MENU-FILE-DOWNLOAD LEGACY SURFACE.

Observed direct dependencies include `WX_NongShiFu123`, SSZipArchive, MBProgressHUD, JHDragView, Config, JHPP, JDStatusBarNotification, YYYPicker, PreferenceManager and SVProgressHUD. It mixes server/config parsing, file/download/package operations and UI state. Not selected for P44.

### `JiangHuHook.m`
Status: ACTIVE / RUNTIME HOOK SURFACE / PROTECTED.

Contains CaptainHook definitions for menu lifecycle, StoreKit/payment state, AVPlayer/ad speed and multiple ad SDK classes. It directly mutates `ImgTool` runtime state. Do not touch during auth boundary work.

### `daochucd.m`, `YYYPicker.m`, `fuhzu.m`
Status: ACTIVE legacy file/import/export/helper candidates. Their exact split target remains deferred to P48 and must be chosen from call-chain evidence, not file size alone.

## Active target conclusions
- Canonical runtime surface remains `testmod/` + `testmod.xcodeproj`.
- `WX_NongShiFu123.mm`, `PubgLoad.mm`, `JiangHuHook.m`, `daochucd.m`, `YYYPicker.m` and `fuhzu.m` remain candidate/active legacy units and must not be deleted based on superficial search.
- P42 service boundaries `ZONUDIDBridge.m` and `ZonoeUDIDAPI.m` remain the stable UDID ownership chain.

## P43 exit decision
P44 target is fixed as **Authorization Orchestration Boundary** centered on the static authorization/reset helper block in `testmod/Bsphp/main.m`.

P44 must not rewrite `WX_NongShiFu123.mm`. It should only move proven orchestration/reset glue into an explicit translation unit and leave `main.m +load` as the startup host.

## P43 verification requirements
- Assert P42 baseline runtime files are not modified during P43.
- Assert PBX still contains exactly 77 active Sources and the known high-risk units remain active.
- Assert the selected P44 authorization markers still exist in `main.m` before P44 begins.
- CI audit must pass before ROADMAP is advanced to P44 implementation.
- No real-device test is required for P43 if the runtime tree is unchanged.
