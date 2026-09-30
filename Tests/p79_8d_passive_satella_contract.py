#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DISPATCHER = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.m").read_text()
CAPABILITY = (ROOT / "testmod/ZONServices/ZONRuntimeCapabilityService.m").read_text()


def fail(message: str) -> None:
    print(f"p79.8d-passive-contract: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"unexpected {label}: {needle}")


for name in [
    '"1_passive.dylib"',
    '"1_passive_zh.dylib"',
    '"SatellaJailed_passive.dylib"',
]:
    require(CAPABILITY, name, "accepted passive image name")

require(CAPABILITY, "kZONPassiveSatellaCtorRVA = 0x847C", "passive constructor RVA")
require(CAPABILITY, "kZONPassiveSatellaInitRVA = 0x888C", "init RVA")
for byte in ["0xC0, 0x03, 0x5F, 0xD6", "0xFC, 0x6F, 0xBA, 0xA9", "0xFA, 0x67, 0x01, 0xA9", "0xF8, 0x5F, 0x02, 0xA9", "0xF6, 0x57, 0x03, 0xA9"]:
    require(CAPABILITY, byte, "binary signature")
require(CAPABILITY, "header->magic != MH_MAGIC_64", "Mach-O 64-bit guard")
require(CAPABILITY, "memcmp((const void *)(base + kZONPassiveSatellaCtorRVA)", "constructor signature check")
require(CAPABILITY, "memcmp((const void *)(base + kZONPassiveSatellaInitRVA)", "init signature check")

forbid(CAPABILITY, "dlopen(", "passive module dlopen")
forbid(CAPABILITY, "dlclose(", "passive module dlclose")
require(CAPABILITY, "_dyld_image_count()", "dyld loaded-image enumeration")
require(CAPABILITY, "_dyld_get_image_name(index)", "dyld image-name lookup")
require(CAPABILITY, "_dyld_get_image_header(index)", "dyld Mach-O header lookup")

require(CAPABILITY, "__has_feature(ptrauth_calls)", "arm64e PAC compile guard")
require(CAPABILITY, "ptrauth_sign_unauthenticated", "function-pointer PAC")
require(CAPABILITY, "ptrauth_key_function_pointer", "function-pointer PAC key")
require(CAPABILITY, "[NSThread isMainThread]", "main-thread check")
require(CAPABILITY, "dispatch_sync(dispatch_get_main_queue()", "main-thread handoff")

require(CAPABILITY, "static BOOL gZONPassiveSatellaStarted = NO;", "one-shot process state")
require(CAPABILITY, "if (gZONPassiveSatellaStarted)", "already-started guard")
require(CAPABILITY, "gZONPassiveSatellaStarted = YES;", "success latch")
require(DISPATCHER, '@"runtime.iap-noads": ^BOOL(BOOL on)', "IAP/no-ads route")
require(DISPATCHER, "if (on) {", "ON-only passive initialization")
require(DISPATCHER, "[ZONRuntimeCapabilityService activateCapability:ZONRuntimeCapabilityPassiveSatella]", "capability activation call")
require(DISPATCHER, '@"NNGG", @"NNGGNNGG", on', "existing IAP/no-ads preference contract")
require(DISPATCHER, "[ImgTool share].NeiGou = enabled;", "existing runtime side effect")

require(CAPABILITY, "image_not_loaded_or_invalid", "missing/invalid target log")
require(DISPATCHER, "return YES;", "route remains handled")
forbid(DISPATCHER, "setOn:NO", "UI rollback")

print("p79.8d-passive-contract: PASS")
