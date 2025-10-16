"""FSManifestInfo provider for describing file placement in archives, container images, or other deployment targets."""

_DOC = """\
Provider for describing file placement in archives and container images.

This provider uses a dictionary mapping approach where paths in the deliverable
are mapped to file entries containing source files and metadata.
"""

_FIELDS = {
    "entries": "Dictionary mapping destination paths (string) to entry structs with (kind, target)",
    "metadata": "Dictionary mapping destination paths (string) to metadata structs (mode, uid, gid, etc)",
    "defaults": "Optional struct with default values for metadata",
}

def _make_fsmanifestinfo(*, entries, metadata = None, defaults = None):
    typeof_dict = type({})
    if type(entries) != typeof_dict:
        fail("FSManifestInfo 'entries' field must be a dictionary mapping paths to entry structs.")

    for k, v in entries.items():
        if type(k) != type(""):
            fail("FSManifestInfo 'entries' keys must be strings (paths), but found {}.".format(type(k)))
        if not hasattr(v, "kind"):
            fail("FSManifestInfo 'entries' values must be structs with a 'kind' field.")
        if v.kind not in ["file", "symlink", "empty_dir"]:
            fail("FSManifestInfo 'entries' values 'kind' field must be one of 'file', 'symlink', or 'empty_dir'.")
        if v.kind in ["file", "symlink"] and not hasattr(v, "target"):
            fail("FSManifestInfo 'entries' values with kind 'file' or 'symlink' must have a 'target' field.")

    if metadata != None:
        for k, v in metadata.items():
            if type(k) != type(""):
                fail("FSManifestInfo 'metadata' keys must be strings (paths).")
            # We could do more validation on the metadata struct here if desired.
            # For now, we don't want to restrict what metadata can be provided.
    return {
        "entries": entries,
        "metadata": metadata,
        "defaults": defaults,
    }

FSManifestInfo, _ = provider(
    doc = _DOC,
    fields = _FIELDS,
    init = _make_fsmanifestinfo,
)
