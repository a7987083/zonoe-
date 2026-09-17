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

## v1_p48_1 — StoreKit Residual Cleanup
Source: `71eddfa0600112aa56a8bef45013d73f4673794a`  
CI head: `efabe050194b87518c1442b4fe078ed7283db846`  
CI Run: `35180342515` / **success**  
Status: **passed / current promoted device baseline**.

CI evidence:
- `YYYPicker` StoreKit/App Store residual surface removed.
- Restore-save public behavior retained.
- Active PBX Sources: **78**.
- PBX unchanged versus P48.
- A_customer and B_debug builds passed for `arm64 + arm64e`.
- Exported symbol surface is identical to P48.
- Load-library delta versus P48 is exactly the removal of `StoreKit.framework`; all other libraries are unchanged.
- A_customer artifact `10480455519`; digest `sha256:beb2e1dd9b0b6ad913b5dc00911a890fd33293f9f33204196266474909b47dfe`.
- A_customer dylib SHA256 `36bbe4c32882d98b274fb7cfb40bf62f727502b4867765bee1f747c0e5fbe90d`.
- B_debug artifact `10480331340`; digest `sha256:fb21abd689eee241ae9331e24558756a342fd50a766fd8d4740bab5fde615e8e`.

Real-device result:
- User explicitly reported P48.1 normal on device.
- Restore-save path and menu smoke showed no reported regression.
- P48.1 is therefore promoted and becomes the rollback baseline.

## Promotion rule
P48.1 has satisfied both CI and real-device gates. Any P49 deletion or dependency removal must be validated against this baseline.

## P39-B — JDStatusBarNotification dependency audit
Status: audit only; KEEP_LIVE_DEPENDENCY.
