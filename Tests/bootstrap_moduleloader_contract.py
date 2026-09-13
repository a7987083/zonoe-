#!/usr/bin/env python3
from pathlib import Path
import subprocess

BASELINE = "84f8b3898bee9d95ed4034d12842879cc56280d3"


def git_show(path: str) -> str:
    return subprocess.check_output(["git", "show", f"{BASELINE}:{path}"], text=True)


def function_body(text: str, name: str) -> str:
    marker = f"{name}("
    start = text.find(marker)
    if start < 0:
        raise AssertionError(f"missing function: {name}")
    brace = text.find("{", start)
    if brace < 0:
        raise AssertionError(f"missing body for: {name}")
    depth = 0
    for index in range(brace, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace:index + 1].strip()
    raise AssertionError(f"unterminated body for: {name}")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"missing {label}: {needle}")


bootstrap_header = Path("testmod/ZONBootstrap/ZONBootstrap.h").read_text()
bootstrap_impl = Path("testmod/ZONBootstrap/ZONBootstrap.m").read_text()
loader_header = Path("testmod/ZONCore/ZONModuleLoader.h").read_text()
loader_impl = Path("testmod/ZONCore/ZONModuleLoader.m").read_text()
main_impl = Path("testmod/Bsphp/main.m").read_text()

# Public headers must be declarations-only after p33.
assert "static inline" not in bootstrap_header
assert "dispatch_once(" not in bootstrap_header
assert "ZONLoadBundledModules();" not in bootstrap_header
assert "static inline" not in loader_header
assert "dlopen(" not in loader_header
assert "dlsym(" not in loader_header
require(bootstrap_header, "FOUNDATION_EXPORT void ZONBootstrapStart", "bootstrap declaration")
require(loader_header, "FOUNDATION_EXPORT void ZONCoreLog", "log declaration")
require(loader_header, "FOUNDATION_EXPORT const ZONHostAPI *ZONGetHostAPI", "host API declaration")
require(loader_header, "FOUNDATION_EXPORT void ZONLoadBundledModules", "module load declaration")

# The runtime call chain must remain explicit and unchanged at the boundary.
require(main_impl, '#import "../ZONBootstrap/ZONBootstrap.h"', "main -> bootstrap import")
require(main_impl, "ZONBootstrapStart(^{", "main -> bootstrap call")
require(bootstrap_impl, '#import "../ZONCore/ZONModuleLoader.h"', "bootstrap -> loader import")
require(bootstrap_impl, "ZONLoadBundledModules();", "bootstrap -> loader call")

# Compare every moved function body against the device-verified p32 baseline.
p32_bootstrap = git_show("testmod/ZONBootstrap/ZONBootstrap.h")
p32_loader = git_show("testmod/ZONCore/ZONModuleLoader.h")

for name in ["ZONBootstrapStart"]:
    expected = function_body(p32_bootstrap, name)
    actual = function_body(bootstrap_impl, name)
    if expected != actual:
        raise AssertionError(f"behavior body drift: {name}")

for name in [
    "ZONCoreLog",
    "ZONGetHostAPI",
    "ZONBundledModuleDirectories",
    "ZONPathIsInsideDirectory",
    "ZONLoadModuleAtPath",
    "ZONLoadBundledModules",
]:
    expected = function_body(p32_loader, name)
    actual = function_body(loader_impl, name)
    if expected != actual:
        raise AssertionError(f"behavior body drift: {name}")

# Lock module-loader safety/ABI invariants that must survive later refactors.
for needle, label in [
    ('@"ZONModules"', "module directory name"),
    ('@"dylib"', "dylib extension filter"),
    ("stringByResolvingSymlinksInPath", "symlink resolution"),
    ("RTLD_NOW | RTLD_LOCAL", "dlopen mode"),
    ('dlsym(handle, "zonoe_module_abi_version")', "ABI version export"),
    ('dlsym(handle, "zonoe_module_identifier")', "module identifier export"),
    ('dlsym(handle, "zonoe_module_initialize")', "module initializer export"),
    ("abiFn() != ZON_MODULE_ABI_VERSION", "ABI version guard"),
    ("[loadedIdentifiers containsObject:identifier]", "duplicate identifier guard"),
    ("initializeFn(ZONGetHostAPI())", "host API initialization"),
    ("dlclose(handle);", "failure cleanup"),
]:
    require(loader_impl, needle, label)

print("p33 bootstrap/module-loader contract: PASS")
