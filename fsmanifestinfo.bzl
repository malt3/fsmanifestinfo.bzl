"""Public API for FSManifestInfo."""

load("//private/providers:fsmanifestinfo.bzl", _FSManifestInfo = "FSManifestInfo")

# Re-export
FSManifestInfo = _FSManifestInfo
