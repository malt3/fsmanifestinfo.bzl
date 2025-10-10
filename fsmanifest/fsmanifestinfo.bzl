"""FSManifestInfo provider for describing file placement in archives, container images, or other deployment targets."""

# Well-known categories
CATEGORY_PLATFORM = "platform"       # Language runtime, interpreter, standard library
CATEGORY_OTHER_PARTY = "external"    # Third-party/external dependencies
CATEGORY_FIRST_PARTY = "application" # First-party application code

# FSManifestInfo is a provider that describes how files should be placed
# in deliverables like container images, archives, or deployment targets.
FSManifestInfo = provider(
    doc = """Provider for describing file placement in archives and container images.

    This provider uses a dictionary mapping approach where paths in the deliverable
    are mapped to file entries containing source files and metadata.
    """,
    fields = {
        "entries": "Dictionary mapping destination paths (string) to entry structs with (kind, category, target)",
        "metadata": "Dictionary mapping destination paths (string) to metadata structs (mode, uid, gid, etc)",
        "defaults": "Optional struct with default values for metadata",
    },
)

def _make_file(src, category):
    """Create a file entry for FSManifest.

    Args:
        src: Source File object (required)
        category: Category - well-known category or custom string

    Returns:
        Struct with (kind, category, target) for a file entry
    """
    if not src:
        fail("make_file requires a src File object")

    return struct(
        kind = "file",
        category = category,
        target = src,
    )

def _make_symlink(symlink_target, category):
    """Create a symlink entry for FSManifest.

    Args:
        symlink_target: Target path for the symlink (required)
        category: Category - well-known category or custom string

    Returns:
        Struct with (kind, category, target) for a symlink entry
    """
    if not symlink_target:
        fail("make_symlink requires a symlink_target")

    return struct(
        kind = "symlink",
        category = category,
        target = symlink_target,
    )

def _make_empty_dir(category):
    """Create an empty directory entry for FSManifest.

    Args:
        category: Category - well-known category or custom string

    Returns:
        Struct with (kind, category, target) for an empty directory entry
    """
    return struct(
        kind = "empty_dir",
        category = category,
        target = None,
    )

def _make_metadata(
        mode = None,
        uid = None,
        gid = None,
        owner = None,
        group = None,
        mtime = None,
        xattrs = None):
    """Create metadata for a manifest entry.

    Args:
        mode: Unix file mode (e.g., "0755" for executables/directories, "0644" for regular files)
        uid: User ID (integer)
        gid: Group ID (integer)
        owner: Owner name (string)
        group: Group name (string)
        mtime: Modification time (integer timestamp)
        xattrs: Dictionary of extended attributes

    Returns:
        Struct with metadata fields (only non-None values included)
    """
    md = {}
    if mode != None:
        md["mode"] = mode
    if uid != None:
        md["uid"] = uid
    if gid != None:
        md["gid"] = gid
    if owner != None:
        md["owner"] = owner
    if group != None:
        md["group"] = group
    if mtime != None:
        md["mtime"] = mtime
    if xattrs != None:
        md["xattrs"] = xattrs
    return struct(**md) if md else None

def _validate_entry(entry, path):
    """Validate a manifest entry.

    Args:
        entry: Entry struct to validate (with kind, category, target)
        path: Destination path for error messages
    """
    # Valid kinds are: file (includes directories with File.is_directory), symlink, empty_dir
    if entry.kind not in ["file", "symlink", "empty_dir"]:
        fail("Invalid entry kind '{}' for path '{}'".format(entry.kind, path))

    # Validate based on kind
    if entry.kind == "file":
        if not entry.target or type(entry.target) != "File":
            fail("File at '{}' must have a File object as target".format(path))
    elif entry.kind == "symlink":
        if not entry.target or type(entry.target) != "string":
            fail("Symlink at '{}' must have a string target path".format(path))
    elif entry.kind == "empty_dir":
        if entry.target != None:
            fail("Empty directory at '{}' should have None as target".format(path))

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

def _create_manifest(entries, metadata = None, defaults = None):
    """Create an FSManifestInfo provider.

    Args:
        entries: Dictionary mapping paths to entry structs (kind, category, target)
        metadata: Optional dictionary mapping paths to metadata structs
        defaults: Optional struct with default metadata values

    Returns:
        FSManifestInfo provider
    """
    # Validate all entries
    for path, entry in entries.items():
        _validate_entry(entry, path)

    return FSManifestInfo(
        entries = entries,
        metadata = metadata or {},
        defaults = defaults,
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
    merged_metadata = {}

    for manifest in manifests:
        merged_entries = _merge_entries(merged_entries, manifest.entries, allow_duplicates)

        # Merge metadata dicts
        for path, md in manifest.metadata.items():
            if path in merged_metadata and not allow_duplicates:
                fail("Duplicate metadata for path '{}' in manifest merge".format(path))
            merged_metadata[path] = md

    last_defaults = None
    for manifest in manifests:
        if manifest.defaults != None:
            last_defaults = manifest.defaults

    return FSManifestInfo(
        entries = merged_entries,
        metadata = merged_metadata,
        defaults = last_defaults,
    )

def _categorize(manifest):
    """Split manifest entries by category.

    Args:
        manifest: FSManifestInfo provider

    Returns:
        Dictionary mapping category names to dictionaries of entries
    """
    categories = {}

    for path, entry in manifest.entries.items():
        if entry.category in categories:
            categories[entry.category][path] = entry
        else:
            categories[entry.category] = {path: entry}

    return categories

fsmanifest = struct(
    FSManifestInfo = FSManifestInfo,
    CATEGORY_PLATFORM = CATEGORY_PLATFORM,
    CATEGORY_OTHER_PARTY = CATEGORY_OTHER_PARTY,
    CATEGORY_FIRST_PARTY = CATEGORY_FIRST_PARTY,
    make_file = _make_file,
    make_symlink = _make_symlink,
    make_empty_dir = _make_empty_dir,
    make_metadata = _make_metadata,
    create_manifest = _create_manifest,
    merge_manifests = _merge_manifests,
    merge_entries = _merge_entries,
    categorize = _categorize,
)
