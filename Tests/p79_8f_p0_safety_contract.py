#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
CAPABILITY = (ROOT / "testmod/ZONServices/ZONRuntimeCapabilityService.m").read_text()
AUTH_RESET = (ROOT / "testmod/ZONServices/ZONAuthorizationResetService.m").read_text()
GAME_RESET = (ROOT / "testmod/ZONServices/ZONGameDataResetService.m").read_text()
AUTH_FLOW = (ROOT / "testmod/ZONAuthV2/ZONAuthV2Flow.m").read_text()


def fail(message: str) -> None:
    print(f"p79.8f-p0-safety: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"unexpected {label}: {needle}")


for needle, label in [
    ("ZONPassiveSatellaTextCoversRange", "mapped-range validator"),
    ("LC_SEGMENT_64", "64-bit segment parsing"),
    ('"__TEXT"', "__TEXT segment identity"),
    ("segment->vmaddr != 0", "vmaddr zero contract"),
    ("VM_PROT_READ", "readable mapping guard"),
    ("VM_PROT_EXECUTE", "executable mapping guard"),
    ("kZONPassiveSatellaCtorRVA = 0x847C", "constructor RVA"),
    ("kZONPassiveSatellaInitRVA = 0x888C", "init RVA"),
    ("BOOL ctorMapped = ZONPassiveSatellaTextCoversRange", "constructor bounds check"),
    ("BOOL initMapped = ZONPassiveSatellaTextCoversRange", "init bounds check"),
    ("if (!ctorMapped || !initMapped)", "fail-closed range gate"),
    ("text_range_mismatch", "diagnostic range failure marker"),
]:
    require(CAPABILITY, needle, label)

range_gate = CAPABILITY.find("if (!ctorMapped || !initMapped)")
ctor_memcmp = CAPABILITY.find("memcmp((const void *)(base + kZONPassiveSatellaCtorRVA)")
init_memcmp = CAPABILITY.find("memcmp((const void *)(base + kZONPassiveSatellaInitRVA)")
if range_gate < 0 or ctor_memcmp < 0 or init_memcmp < 0 or not (range_gate < ctor_memcmp < init_memcmp):
    fail("mapped-range gate must execute before both signature dereferences")

protected_keys = [
    '"fold_base"', '"fold_draw"', '"fold_role"',
    '"NNGG"', '"NNGGNNGG"', '"AADD"', '"AADDAADD"', '"AADDssppeedd"',
]
for key in protected_keys:
    require(AUTH_RESET, key, "protected menu/runtime preference")
for needle, label in [
    ("ZONAuthorizationResetPreferenceSnapshot", "pre-reset preference snapshot"),
    ("ZONAuthorizationResetPreferenceSnapshotMatches", "post-reset boundary verification"),
    ("ZONAuthorizationResetRestorePreferenceSnapshot", "fail-closed preference restoration"),
    ("protected menu/runtime preferences changed during authorization reset; restored snapshot", "boundary violation log"),
    ("authorization reset completed; protected menu/runtime preferences unchanged", "successful reset boundary log"),
]:
    require(AUTH_RESET, needle, label)

for needle, label in [
    ("NSString *home = NSHomeDirectory();", "container home root"),
    ('stringByAppendingPathComponent:@"Documents"', "Documents root"),
    ('stringByAppendingPathComponent:@"Library"', "Library root"),
    ('stringByAppendingPathComponent:@"tmp"', "tmp root"),
    ("removePersistentDomainForName:bundleIdentifier", "current-app defaults reset"),
]:
    require(GAME_RESET, needle, label)
forbid(GAME_RESET, "removeItemAtPath:NSHomeDirectory()", "whole-container deletion")

for needle, label in [
    ('[self showMessage:ZONStartupLookupErrorMessage(error) title:@"验证失败" completion:nil];', "startup transport failure UI"),
    ('NSLog(@"[zonoemenu][auth-v2][P79.8A_UDID_GATE] unknown payload; card prompt suppressed")', "unknown-payload suppression marker"),
    ('[self showMessage:@"授权服务器返回格式异常，请稍后重试。" title:@"验证失败" completion:nil];', "unknown-payload failure UI"),
]:
    require(AUTH_FLOW, needle, label)

error_branch = AUTH_FLOW.find("if (error) {")
missing_branch = AUTH_FLOW.find("if (state == ZONUDIDAuthorizationStateMissing)")
if error_branch < 0 or missing_branch < 0 or error_branch >= missing_branch:
    fail("startup transport failure must be handled before missing-activation/card-prompt routing")

print("p79.8f-p0-safety: PASS")
