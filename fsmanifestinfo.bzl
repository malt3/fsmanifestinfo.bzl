"""Public API for fsmanifestinfo"""

load("//fsmanifest/private:fsmanifestinfo.bzl", _fsmanifest = "fsmanifest")

# Re-export
FSManifestInfo = _fsmanifest.FSManifestInfo
CATEGORY_PLATFORM = _fsmanifest.CATEGORY_PLATFORM
CATEGORY_OTHER_PARTY = _fsmanifest.CATEGORY_OTHER_PARTY
CATEGORY_FIRST_PARTY = _fsmanifest.CATEGORY_FIRST_PARTY
fsmanifest = _fsmanifest
