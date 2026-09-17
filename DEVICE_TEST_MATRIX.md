# DEVICE TEST MATRIX

## Rule
Every runtime-affecting development version must define its required real-device regression scope before promotion. CI success alone never changes `last_device_verified_*`.

## Common device smoke test
- App launches normally; floating entry appears normally.
- Menu opens/closes normally; outside-tap close works.
- Section fold/unfold and relayout work.
- Card/grid buttons, switches, ad switch and speed slider remain usable.
- No obvious freeze/crash while opening, closing, folding, or operating controls.

## Historical promoted baselines
- `v1_p41`: passed; superseded.
- `v1_p42`: passed; superseded.
- `v1_p44`: passed; superseded by later promoted baselines.
- P45/P46/P47 intermediate CI-verified behavior is covered by later real-device-passed baselines.
- `v1_p48_1`: passed; superseded by P49.

## v1_p49 — Active Target / Dead Code / Dependency Audit
Source: `4cebe094ad7a4dd554e8266af34dcf3abe04902a`  
CI head: `592aa64cd35307e358716d3f1517a75a41e986f3`  
CI Run: `35195152912` / **success**  
Status: **passed / current promoted device baseline**.

CI evidence:
- `Network.framework` proven to have zero source consumers before removal.
- `Network.framework` removed from PBX.
- Active PBX Sources remain **78**.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbol surface is identical to P48.1.
- Load-library delta versus P48.1 is exactly the removal of `Network.framework`; all other libraries are unchanged.
- A_customer artifact `10485344383`; digest `sha256:33ae7fda25128e9d0bd6a167a82aedaf3a1272a8ceb13111bef23c58ff270c5d`.
- A_customer dylib SHA256 `4d19c0368b8c599ff59635aa0e36a75a2ba67e797d14e91a48fef3b494e66bac`.
- B_debug artifact `10485622521`; digest `sha256:9156b57fd832461274f3c8d1625c8b8213d556c9862b32d1d461294783a23e27`.

Real-device result:
- User explicitly reported P49 normal on device.
- Startup, authorization, menu, storage operations and networking showed no reported regression.
- P49 is therefore promoted and becomes the rollback baseline.

## Promotion rule
P49 has satisfied both CI and real-device gates. P50 must start from this promoted baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
