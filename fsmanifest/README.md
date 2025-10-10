# FSManifestInfo Provider

The FSManifestInfo provider is a Bazel provider that describes how files should be placed in deliverables like container images, archives, or deployment targets. It implements Proposal 2 (Dictionary Mapping) from the "What-Goes-Where" provider design.

## Overview

FSManifestInfo uses a dictionary mapping approach where destination paths are mapped to file entries containing source files and metadata. This allows language rulesets (like `rules_java`) to describe file placement without depending on specific packaging implementations.

## Key Features

- **Category-based layering**: Files are categorized as `runtime`, `third_party`, or `app` for automatic layer splitting
- **Metadata preservation**: Supports file modes, ownership (uid/gid), timestamps, and extended attributes
- **Special file support**: Handles symlinks and empty directories
- **Provider merging**: Multiple FSManifestInfo providers can be merged with conflict detection

## API Reference

### FSManifestInfo Provider

The core provider with the following fields:

- `entries`: Dictionary mapping destination paths (string) to entry structs
- `defaults`: Optional struct with default values for metadata
- `labels`: Optional dictionary of string labels for this manifest

### Entry Structure

Each entry in the manifest has:

- `src`: Source File object or None for special entries
- `kind`: Entry kind - "file", "dir", "symlink", or "empty_dir"
- `category`: Category for layering - "runtime", "third_party", or "app"
- `mode`: Unix file mode (e.g., "0755")
- `uid`/`gid`: User/Group ID (integer)
- `owner`/`group`: Owner/Group name (string)
- `mtime`: Modification time (integer timestamp)
- `xattrs`: Dictionary of extended attributes
- `symlink_target`: Target path for symlinks

### Helper Functions

#### `fsmanifest.make_entry()`
Creates an FSManifest entry with proper validation.

```python
entry = fsmanifest.make_entry(
    src = file,
    kind = "file",
    category = "app",
    mode = "0644",
)
```

#### `fsmanifest.create_manifest()`
Creates an FSManifestInfo provider from entries.

```python
manifest = fsmanifest.create_manifest(
    entries = {
        "/app/bin/server": entry1,
        "/deps/lib.jar": entry2,
    },
    labels = {"type": "java_binary"},
)
```

#### `fsmanifest.merge_manifests()`
Merges multiple FSManifestInfo providers.

```python
merged = fsmanifest.merge_manifests(
    [manifest1, manifest2],
    allow_duplicates = False,
)
```

#### `fsmanifest.categorize_by_layer()`
Splits manifest entries by category for layering.

```python
layers = fsmanifest.categorize_by_layer(manifest)
# Returns: {"runtime": {...}, "third_party": {...}, "app": {...}}
```

## Integration Examples

### Producing FSManifestInfo (rules_java)

The modified `java_binary` rule provides FSManifestInfo:

```python
load("@rules_java//java:fsmanifest_defs.bzl", "java_binary")

java_binary(
    name = "my_java_app",
    srcs = ["Main.java"],
    deps = ["@maven//:guava"],
)
```

This automatically categorizes files:
- JRE/JDK files → `runtime`
- Maven/external dependencies → `third_party`
- Application code → `app`

### Consuming FSManifestInfo (rules_img)

The modified `image_manifest` rule consumes FSManifestInfo:

```python
load("@rules_img//img:fsmanifest_image.bzl", "image_manifest")

image_manifest(
    name = "my_image",
    fs_manifests = [":my_java_app"],  # Consumes FSManifestInfo
)
```

This automatically creates separate layers for runtime, third-party deps, and app code.

## Design Rationale

FSManifestInfo uses dictionary mapping (Proposal 2) because:

1. **Pure and inspectable**: Can be produced without actions and inspected during analysis
2. **Direct file access**: Contains actual File structs, no indirection
3. **Flexible metadata**: Supports arbitrary metadata through structured entries
4. **Composable**: Multiple manifests can be merged systematically

The main limitation is lack of visibility into TreeArtifacts during analysis phase, which may require special handling for directory outputs.

## Future Enhancements

- Support for custom categories beyond runtime/third_party/app
- Configurable layer ordering and naming
- Advanced metadata like capabilities and security attributes
- Integration with more language rulesets
- Native support in upstream rules without wrappers
