#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
IMPL = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.m").read_text()


def fail(message: str) -> None:
    print(f"p79.8d-passive-contract: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(needle: str, label: str) -> None:
    if needle not in IMPL:
        fail(f"missing {label}: {needle}")


def forbid(needle: str, label: str) -> None:
    if needle in IMPL:
        fail(f"unexpected {label}: {needle}")


# Exact externally injected image identities accepted by the device-tested candidate.
for name in [
    '"1_passive.dylib"',
    '"1_passive_zh.dylib"',
    '"SatellaJailed_passive.dylib"',
]:
    require(name, "accepted passive image name")

# Exact binary compatibility guards must not drift accidentally.
require("kZONPassiveSatellaCtorRVA = 0x847C", "passive constructor RVA")
require("kZONPassiveSatellaInitRVA = 0x888C", "init RVA")
for byte in ["0xC0, 0x03, 0x5F, 0xD6", "0xFC, 0x6F, 0xBA, 0xA9", "0xFA, 0x67, 0x01, 0xA9", "0xF8, 0x5F, 0x02, 0xA9", "0xF6, 0x57, 0x03, 0xA9"]:
    require(byte, "binary signature")
require("header->magic != MH_MAGIC_64", "Mach-O 64-bit guard")
require("memcmp((const void *)(base + kZONPassiveSatellaCtorRVA)", "constructor signature check")
require("memcmp((const void *)(base + kZONPassiveSatellaInitRVA)", "init signature check")

# Host must only consume a pre-injected image. It must never load/unload this module itself.
forbid("dlopen(", "passive module dlopen")
forbid("dlclose(", "passive module dlclose")
require("_dyld_image_count()", "dyld loaded-image enumeration")
require("_dyld_get_image_name(index)", "dyld image-name lookup")
require("_dyld_get_image_header(index)", "dyld Mach-O header lookup")

# arm64e call target authentication and main-thread invocation are protected behavior.
require("__has_feature(ptrauth_calls)", "arm64e PAC compile guard")
require("ptrauth_sign_unauthenticated", "function-pointer PAC")
require("ptrauth_key_function_pointer", "function-pointer PAC key")
require("[NSThread isMainThread]", "main-thread check")
require("dispatch_sync(dispatch_get_main_queue()", "main-thread handoff")

# One-shot per-process semantics and toggle behavior.
require("static BOOL gZONPassiveSatellaStarted = NO;", "one-shot process state")
require("if (gZONPassiveSatellaStarted)", "already-started guard")
require("gZONPassiveSatellaStarted = YES;", "success latch")
require('@"runtime.iap-noads": ^BOOL(BOOL on)', "IAP/no-ads route")
require("if (on) {", "ON-only passive initialization")
require("BOOL started = ZONStartInjectedPassiveSatella();", "passive start call")
require('@"NNGG", @"NNGGNNGG", on', "existing IAP/no-ads preference contract")
require("[ImgTool share].NeiGou = enabled;", "existing runtime side effect")

# Failure to find the injected module must not become a toggle failure/rollback.
require("image_not_loaded_or_invalid", "missing/invalid target log")
require("return YES;", "route remains handled")
forbid("setOn:NO", "UI rollback")

print("p79.8d-passive-contract: PASS")
