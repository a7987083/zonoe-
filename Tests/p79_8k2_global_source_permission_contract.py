from pathlib import Path

root = Path(__file__).resolve().parents[1]
storage_h = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.h").read_text(encoding="utf-8")
storage_m = (root / "testmod/ZONAuthV2/ZONAuthV2Storage.m").read_text(encoding="utf-8")
api = (root / "testmod/ZONAuthV2/ZONAuthV2API.m").read_text(encoding="utf-8")
provider_h = (root / "testmod/ZONServices/ZONFeatureAccessProvider.h").read_text(encoding="utf-8")
provider_m = (root / "testmod/ZONServices/ZONFeatureAccessProvider.m").read_text(encoding="utf-8")
cloud = (root / "testmod/ZONServices/ZONSaveTransferCoordinator.m").read_text(encoding="utf-8")
verify = (root / "testmod/ZONAuthV2/ZONAuthV2Verify.m").read_text(encoding="utf-8")

# /apiface projection is kept session-only and travels with the short-lived proof.
assert "+ (nullable NSDictionary *)lastLicense;" in storage_h
assert "gZONAuthV2SessionLastLicense" in storage_m
assert "setLastLicense:json" in api
assert '@"/index/index/apiface"' in api
assert 'json[@"auth_proof"]' in api

# One centralized permission boundary owns the compatibility projection.
assert "effectivePermissionsForVerifyResponse" in provider_h
assert 'authorization[@"type"]' in provider_m
assert '@"全软件源"' in provider_m
assert 'effective[@"extra_menu"] = @YES' in provider_m
assert 'effective[@"extra_features"] = @YES' in provider_m
assert 'explicitlyDenied' in provider_m
assert 'currentServerPermissions' in provider_m

# Cloud must use the same permission projection, never a separate hard-coded rule.
assert '#import "ZONFeatureAccessProvider.h"' in cloud
assert "effectivePermissionsForVerifyResponse:response" in cloud

# v3.1 proof is one-shot: cloud refreshes /apiface before the sensitive fresh Verify.
assert '#import "../ZONAuthV2/ZONAuthV2API.h"' in cloud
assert "fetchLicenseForUDID:deviceIdentifier" in cloud
assert cloud.index("fetchLicenseForUDID:deviceIdentifier") < cloud.index("verifyUDID:deviceIdentifier")
assert "ZONCloudLicenseIsActive" in cloud
assert 'setAuthProof:nil' in verify
assert 'auth_proof_unavailable' in verify

print("P79.8k2 global-source/cloud permission contract passed")
