#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
PROVIDER_H = (ROOT / "testmod/ZONServices/ZONFeatureAccessProvider.h").read_text()
PROVIDER_M = (ROOT / "testmod/ZONServices/ZONFeatureAccessProvider.m").read_text()
REGISTRY_H = (ROOT / "testmod/ZONCore/ZONFeatureRegistry.h").read_text()
REGISTRY_M = (ROOT / "testmod/ZONCore/ZONFeatureRegistry.m").read_text()
RENDERER = (ROOT / "testmod/ZONCore/ZONSectionRenderer.m").read_text()
DISPATCHER = (ROOT / "testmod/ZONCore/ZONFeatureDispatcher.m").read_text()


def fail(message: str) -> None:
    print(f"p79.8h-feature-access: FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"missing {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"unexpected {label}: {needle}")


# Public R3 boundary.
for needle in [
    "+ (NSDictionary<NSString *, id> *)currentServerPermissions;",
    "+ (NSString *)currentAccessLevel;",
    "+ (BOOL)isFeatureVisible:(NSDictionary<NSString *, id> *)feature;",
    "+ (BOOL)isFeatureActionAllowed:(NSDictionary<NSString *, id> *)feature;",
]:
    require(PROVIDER_H, needle, "feature access provider API")

# The provider is the only layer in this path that understands AuthV2 session schema.
for needle in [
    '#import "../ZONAuthV2/ZONAuthV2Storage.h"',
    '[ZONAuthV2Storage lastVerify]',
    'verify[@"permissions"]',
    'verify[@"access_level"]',
    'ZONFeatureIsVisibleWithPermissions(feature, [self currentServerPermissions])',
    'ZONFeatureIsActionAllowedWithPermissions(feature, [self currentServerPermissions])',
    '[ZONRuntimeCapabilityService isCapabilityAvailable:requiredCapability]',
]:
    require(PROVIDER_M, needle, "centralized access decision")

# Registry gains optional runtime capability metadata without assigning it to any
# existing feature in P79.8h, preserving current visibility/action behavior.
require(REGISTRY_H, "ZONFeatureRequiredRuntimeCapabilityKey", "runtime capability metadata declaration")
require(REGISTRY_M, 'ZONFeatureRequiredRuntimeCapabilityKey = @"requiredRuntimeCapability"', "runtime capability metadata definition")
feature_table = REGISTRY_M.split("features = @[", 1)[1].split("];", 1)[0]
forbid(feature_table, "ZONFeatureRequiredRuntimeCapabilityKey", "runtime capability requirement on existing feature")

# Existing cloud permission semantics remain unchanged.
require(feature_table, 'ZONFeatureIdentifierKey:@"base.cloud-save"', "cloud-save feature")
require(feature_table, 'ZONFeatureRequiredMenuPermissionKey:@"extra_menu"', "cloud menu permission")
require(feature_table, 'ZONFeatureRequiredActionPermissionKey:@"extra_features"', "cloud action permission")

# Renderer and Dispatcher must consume the provider instead of parsing raw AuthV2.
require(RENDERER, '#import "../ZONServices/ZONFeatureAccessProvider.h"', "renderer provider import")
require(RENDERER, '[ZONFeatureAccessProvider isFeatureVisible:feature]', "renderer visibility decision")
require(RENDERER, '[ZONFeatureAccessProvider currentServerPermissions]', "renderer permission diagnostics")
require(RENDERER, '[ZONFeatureAccessProvider currentAccessLevel]', "renderer access-level diagnostics")
forbid(RENDERER, "ZONAuthV2Storage", "renderer raw AuthV2 dependency")

require(DISPATCHER, '#import "../ZONServices/ZONFeatureAccessProvider.h"', "dispatcher provider import")
require(DISPATCHER, '[ZONFeatureAccessProvider isFeatureActionAllowed:feature]', "dispatcher action decision")
forbid(DISPATCHER, "ZONAuthV2Storage", "dispatcher raw AuthV2 dependency")
forbid(DISPATCHER, "ZONCurrentServerPermissions", "dispatcher duplicate permission parser")

# R2 capability activation remains separate from R3 access evaluation.
require(DISPATCHER, '[ZONRuntimeCapabilityService activateCapability:ZONRuntimeCapabilityPassiveSatella]', "existing passive activation")

print("p79.8h-feature-access: PASS")
