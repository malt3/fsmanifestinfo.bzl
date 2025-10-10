"""FSManifestInfo provider for describing file placement in archives and container images."""

# FSManifestInfo is a provider that describes how files should be placed
# in deliverables like container images, archives, or deployment targets.
FSManifestInfo = provider(
    doc = """Provider for describing file placement in archives and container images.

    This provider uses a dictionary mapping approach where paths in the deliverable
    are mapped to file entries containing source files and metadata.
    """,
    fields = {
        "entries": "Dictionary mapping destination paths (string) to entry structs",
        "defaults": "Optional struct with default values for metadata",
        "labels": "Optional dictionary of string labels for this manifest",
    },
)

def _make_entry(
        src,
        kind = "file",
        category = "app",
        mode = None,
        uid = None,
        gid = None,
        owner = None,
        group = None,
        mtime = None,
        xattrs = None,
        symlink_target = None):
    """Create an FSManifest entry.

    Args:
        src: Source File object or None for special entries
        kind: Entry kind - "file", "dir", "symlink", or "empty_dir"
        category: Category for layering - "runtime", "third_party", or "app"
        mode: Unix file mode (e.g., "0755")
        uid: User ID (integer)
        gid: Group ID (integer)
        owner: Owner name (string)
        group: Group name (string)
        mtime: Modification time (integer timestamp)
        xattrs: Dictionary of extended attributes
        symlink_target: Target path for symlinks

    Returns:
        Struct representing a manifest entry
    """
    return struct(
        src = src,
        kind = kind,
        category = category,
        mode = mode,
        uid = uid,
        gid = gid,
        owner = owner,
        group = group,
        mtime = mtime,
        xattrs = xattrs or {},
        symlink_target = symlink_target,
    )

def _validate_entry(entry, path):
    """Validate a manifest entry.

    Args:
        entry: Entry struct to validate
        path: Destination path for error messages
    """
    if entry.kind not in ["file", "dir", "symlink", "empty_dir"]:
        fail("Invalid entry kind '{}' for path '{}'".format(entry.kind, path))

    if entry.category not in ["runtime", "third_party", "app"]:
        fail("Invalid category '{}' for path '{}'. Must be 'runtime', 'third_party', or 'app'".format(
            entry.category, path))

    if entry.kind == "symlink" and not entry.symlink_target:
        fail("Symlink at '{}' must have symlink_target".format(path))

    if entry.kind in ["file", "dir"] and not entry.src:
        if entry.kind != "empty_dir":
            fail("{} at '{}' must have src".format(entry.kind.capitalize(), path))

def _merge_entries(entries1, entries2, allow_duplicates = False):
    """Merge two entry dictionaries.

    Args:
        entries1: First dictionary of entries
        entries2: Second dictionary of entries
        allow_duplicates: If False, fail on duplicate paths

    Returns:
        Merged dictionary of entries
    """
    result = dict(entries1)

    for path, entry in entries2.items():
        if path in result and not allow_duplicates:
            fail("Duplicate path '{}' in manifest merge".format(path))
        result[path] = entry

    return result

def _create_manifest(entries, defaults = None, labels = None):
    """Create an FSManifestInfo provider.

    Args:
        entries: Dictionary mapping paths to entry structs
        defaults: Optional struct with default metadata values
        labels: Optional dictionary of labels

    Returns:
        FSManifestInfo provider
    """
    # Validate all entries
    for path, entry in entries.items():
        _validate_entry(entry, path)

    return FSManifestInfo(
        entries = entries,
        defaults = defaults,
        labels = labels or {},
    )

def _merge_manifests(manifests, allow_duplicates = False):
    """Merge multiple FSManifestInfo providers.

    Args:
        manifests: List of FSManifestInfo providers
        allow_duplicates: If False, fail on duplicate paths

    Returns:
        Merged FSManifestInfo provider
    """
    merged_entries = {}
    merged_labels = {}

    for manifest in manifests:
        merged_entries = _merge_entries(merged_entries, manifest.entries, allow_duplicates)
        # Merge labels, later manifests override
        for key, value in manifest.labels.items():
            merged_labels[key] = value

    return FSManifestInfo(
        entries = merged_entries,
        defaults = None,  # Don't merge defaults
        labels = merged_labels,
    )

def _categorize_by_layer(manifest):
    """Split manifest entries by category for layering.

    Args:
        manifest: FSManifestInfo provider

    Returns:
        Dictionary mapping category names to dictionaries of entries
    """
    layers = {
        "runtime": {},
        "third_party": {},
        "app": {},
    }

    for path, entry in manifest.entries.items():
        layers[entry.category][path] = entry

    return layers

# Export public API
fsmanifest = struct(
    FSManifestInfo = FSManifestInfo,
    make_entry = _make_entry,
    validate_entry = _validate_entry,
    create_manifest = _create_manifest,
    merge_manifests = _merge_manifests,
    merge_entries = _merge_entries,
    categorize_by_layer = _categorize_by_layer,
)