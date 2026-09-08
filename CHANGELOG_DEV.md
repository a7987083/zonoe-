# CHANGELOG_DEV

## 2026-09-09 — production-v1 bootstrap
- Created production development branch from stable baseline `68329ee5844f3899d369a778073e5586d8bc4e1f`.
- Locked runtime priority: IPA injection first, jailbreak injection second.
- Locked deployment target: iOS 12.0+; architectures arm64 + arm64e.
- Locked BS/PHP strategy: compatibility first, backend replacement later.
- Locked product role: universal core menu with future external dylib modules loaded via dlopen().
- Existing feature behavior is a regression-protected baseline.
- No runtime source behavior changed yet.
