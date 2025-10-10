"""Public API for FSManifestInfo provider."""

load(":fsmanifestinfo.bzl", "fsmanifest")
load(":remap.bzl", _fsmanifest_remap = "fsmanifest_remap")

# Re-export the provider
FSManifestInfo = fsmanifest.FSManifestInfo

# Re-export the remap rule
fsmanifest_remap = _fsmanifest_remap

def manifest_from_files(
        files,
        prefix = "",
        category = "app",
        strip_prefix = None,
        mode = None,
        uid = None,
        gid = None):
    """Create a manifest from a list of files.

    Args:
        files: List or depset of File objects
        prefix: Path prefix to add to all entries
        category: Category for all files ("runtime", "third_party", or "app")
        strip_prefix: Optional prefix to remove from file paths
        mode: Default Unix mode for files
        uid: Default user ID
        gid: Default group ID

    Returns:
        FSManifestInfo provider
    """
    entries = {}

    # Convert to list if it's a depset
    file_list = files.to_list() if hasattr(files, "to_list") else files

    for f in file_list:
        path = f.short_path
        if strip_prefix and path.startswith(strip_prefix):
            path = path[len(strip_prefix):].lstrip("/")

        if prefix:
            path = prefix.rstrip("/") + "/" + path

        # Normalize path
        if not path.startswith("/"):
            path = "/" + path

        entries[path] = fsmanifest.make_entry(
            src = f,
            kind = "dir" if f.is_directory else "file",
            category = category,
            mode = mode,
            uid = uid,
            gid = gid,
        )

    return fsmanifest.create_manifest(entries)

def manifest_from_runfiles(
        runfiles,
        prefix = "/app",
        categorize_fn = None,
        default_category = "app",
        mode = None):
    """Create a manifest from runfiles.

    Args:
        runfiles: Runfiles object
        prefix: Path prefix for all entries
        categorize_fn: Optional function(file) -> category
        default_category: Default category if categorize_fn returns None
        mode: Default Unix mode

    Returns:
        FSManifestInfo provider
    """
    entries = {}

    # Process runfiles
    for f in runfiles.files.to_list():
        # Get the runfiles path
        path = f.short_path

        # Determine category
        category = default_category
        if categorize_fn:
            cat = categorize_fn(f)
            if cat:
                category = cat

        # Build destination path
        dest_path = prefix.rstrip("/") + "/" + path
        if not dest_path.startswith("/"):
            dest_path = "/" + dest_path

        entries[dest_path] = fsmanifest.make_entry(
            src = f,
            kind = "file",
            category = category,
            mode = mode,
        )

    # Add symlinks from runfiles
    for symlink in runfiles.symlinks.to_list():
        dest_path = prefix.rstrip("/") + "/" + symlink.path
        if not dest_path.startswith("/"):
            dest_path = "/" + dest_path

        entries[dest_path] = fsmanifest.make_entry(
            src = None,
            kind = "symlink",
            category = default_category,
            symlink_target = symlink.target_file.path if symlink.target_file else symlink.target_path,
        )

    return fsmanifest.create_manifest(entries)

def categorize_by_repository(file):
    """Categorization function that separates files by repository.

    Args:
        file: File object

    Returns:
        "third_party" for external repository files, None otherwise
    """
    # Check if it's from an external repository
    if file.owner and file.owner.workspace_name and file.owner.workspace_name != "":
        return "third_party"

    # Also check path heuristics
    if file.short_path.startswith("external/"):
        return "third_party"

    return None

def merge_manifests(manifests, allow_duplicates = False):
    """Merge multiple FSManifestInfo providers.

    Args:
        manifests: List of FSManifestInfo providers
        allow_duplicates: If False, fail on duplicate paths

    Returns:
        Merged FSManifestInfo provider
    """
    return fsmanifest.merge_manifests(manifests, allow_duplicates)

def split_by_category(manifest):
    """Split a manifest into separate manifests by category.

    Args:
        manifest: FSManifestInfo provider

    Returns:
        Dictionary mapping category to FSManifestInfo provider
    """
    layers = fsmanifest.categorize_by_layer(manifest)
    result = {}

    for category, entries in layers.items():
        if entries:  # Only create manifest if there are entries
            result[category] = fsmanifest.create_manifest(
                entries = entries,
                labels = {"layer": category},
            )

    return result