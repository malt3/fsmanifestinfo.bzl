"""Rule for remapping and merging FSManifestInfo providers."""

load(":fsmanifestinfo.bzl", "FSManifestInfo", "fsmanifest")

def _fsmanifest_remap_impl(ctx):
    """Implementation for fsmanifest_remap rule."""

    # Collect all entries from input manifests
    merged_entries = {}

    for manifest_target in ctx.attr.manifests:
        if FSManifestInfo not in manifest_target:
            fail("Target {} does not provide FSManifestInfo".format(manifest_target.label))

        manifest_info = manifest_target[FSManifestInfo]

        for path, entry in manifest_info.entries.items():
            # Apply path remapping
            new_path = path

            # Remove bin directory prefix if requested
            if ctx.attr.strip_prefix == "auto":
                # Use Bazel's bin directory path
                bin_dir = ctx.bin_dir.path + "/"
                if new_path.startswith(bin_dir):
                    new_path = new_path[len(bin_dir):]
                # Also handle cases where path doesn't have full bin_dir prefix
                # but has bazel-out/k8-fastbuild/bin/ or similar
                elif new_path.startswith("bazel-out/"):
                    # Find the /bin/ part and strip everything before and including it
                    parts = new_path.split("/")
                    if "bin" in parts:
                        bin_idx = parts.index("bin")
                        new_path = "/".join(parts[bin_idx + 1:])
            elif ctx.attr.strip_prefix:
                # Strip custom prefix
                if new_path.startswith(ctx.attr.strip_prefix):
                    new_path = new_path[len(ctx.attr.strip_prefix):]

            # Add new prefix if specified
            if ctx.attr.add_prefix:
                # Ensure prefix ends with / if it's not empty
                prefix = ctx.attr.add_prefix
                if prefix and not prefix.endswith("/"):
                    prefix += "/"
                # Ensure new_path doesn't start with /
                if new_path.startswith("/"):
                    new_path = new_path[1:]
                new_path = prefix + new_path

            # Ensure path starts with /
            if not new_path.startswith("/"):
                new_path = "/" + new_path

            # Create new entry with remapped path
            merged_entries[new_path] = entry

    # Create new FSManifestInfo with merged and remapped entries
    manifest_info = fsmanifest.create_manifest(
        entries = merged_entries,
        labels = ctx.attr.labels,
        defaults = ctx.attr.defaults_struct,
    )

    return [manifest_info]

fsmanifest_remap = rule(
    implementation = _fsmanifest_remap_impl,
    attrs = {
        "manifests": attr.label_list(
            mandatory = True,
            providers = [FSManifestInfo],
            doc = "List of FSManifestInfo providers to merge and remap",
        ),
        "strip_prefix": attr.string(
            default = "auto",
            doc = """Prefix to strip from paths.
            'auto' (default) strips the Bazel bin directory automatically.
            Empty string means no stripping.
            Any other value strips that exact prefix.""",
        ),
        "add_prefix": attr.string(
            default = "",
            doc = "Prefix to add to all paths after stripping (e.g., '/app')",
        ),
        "labels": attr.string_dict(
            default = {},
            doc = "Labels to add to the merged manifest",
        ),
        "defaults_struct": attr.string(
            default = "",
            doc = "JSON string of default values for the manifest",
        ),
    },
    doc = """Merges and remaps paths in FSManifestInfo providers.

    This rule is useful for:
    - Making container paths predictable regardless of build configuration
    - Merging multiple FSManifestInfo providers
    - Relocating files to standard locations (e.g., /app/lib/)

    Example:
        fsmanifest_remap(
            name = "app_remapped",
            manifests = [":my_java_app"],
            strip_prefix = "auto",  # Remove bazel-out/k8-fastbuild/bin/
            add_prefix = "/app",     # Add /app prefix
        )
    """,
)