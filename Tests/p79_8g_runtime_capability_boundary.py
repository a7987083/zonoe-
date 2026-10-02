#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DISPATCHER = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.m").read_text()
HEADER = (ROOT / "testmod/ZONServices/ZONRuntimeCapabilityService.h").read_text()
IMPL = (ROOT / "testmod/ZONServices/ZONRuntimeCapabilityService.m").read_text()


def fail(message: str) -> None:
    print(f"p79.8g-runtime-capability: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"unexpected {label}: {needle}")


for needle, label in [
    ("ZONRuntimeCapabilityPassiveSatella", "passive capability identifier"),
    ("ZONRuntimeCapabilityZonoePatch", "ZonoePatch capability identifier"),
    ("+ (BOOL)isCapabilityAvailable:(NSString *)identifier;", "availability API"),
    ("+ (BOOL)activateCapability:(NSString *)identifier;", "activation API"),
]:
    require(HEADER, needle, label)

require(IMPL, '@"passive.satella"', "stable passive capability key")
require(IMPL, '@"external.zonoepatch"', "stable ZonoePatch capability key")
require(IMPL, 'dlsym(RTLD_DEFAULT, "ZonoePatchActivate")', "cross-dylib ABI resolver")
require(IMPL, "ZONActivateExternalPatch()", "cross-dylib activation delegate")
require(IMPL, "+ (BOOL)isCapabilityAvailable:(NSString *)identifier", "availability implementation")
require(IMPL, "+ (BOOL)activateCapability:(NSString *)identifier", "activation implementation")
require(IMPL, "ZONFindInjectedPassiveSatellaBase() != 0", "availability probe")
require(IMPL, "return ZONStartInjectedPassiveSatella();", "activation delegate")

require(DISPATCHER, '#import "../ZONServices/ZONRuntimeCapabilityService.h"', "service import")
require(DISPATCHER, "[ZONRuntimeCapabilityService activateCapability:ZONRuntimeCapabilityPassiveSatella]", "dispatcher capability call")

# Dispatcher must remain a feature router and must not regain low-level image logic.
for needle, label in [
    ("_dyld_image_count", "dyld scanning"),
    ("LC_SEGMENT_64", "Mach-O segment parsing"),
    ("ptrauth_sign_unauthenticated", "PAC implementation"),
    ("kZONPassiveSatellaCtorRVA", "passive constructor RVA"),
    ("kZONPassiveSatellaInitRVA", "passive init RVA"),
    ("ZONFindInjectedPassiveSatellaBase", "passive image resolver"),
    ("ZONStartInjectedPassiveSatella", "passive start implementation"),
]:
    forbid(DISPATCHER, needle, label)

# Runtime capability service consumes only already-loaded images; loading remains external.
forbid(IMPL, "dlopen(", "runtime capability dlopen")
forbid(IMPL, "dlclose(", "runtime capability dlclose")
require(IMPL, "_dyld_image_count()", "loaded image enumeration")

print("p79.8g-runtime-capability: PASS")
