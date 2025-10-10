# FSManifestInfo Provider

The FSManifestInfo provider is a Bazel provider that describes how files should be placed in deliverables like container images, archives, or deployment targets. It implements Proposal 2 (Dictionary Mapping) from the "What-Goes-Where" provider design.

## Overview

FSManifestInfo uses a dictionary mapping approach where destination paths are mapped to file entries containing source files and metadata. This allows language rulesets (like `rules_java`) to describe file placement without depending on specific packaging implementations.

## Key Features

- **Category-based output splitting**: Files are categorized as `platform`, `external`, or `application` for automatic splitting into subdeliverables (like container image layers)
- **Metadata preservation**: Supports file modes, ownership (uid/gid), timestamps, and extended attributes
- **Special file support**: Handles symlinks and empty directories
- **Provider merging**: Multiple FSManifestInfo providers can be merged with conflict detection

## Categories

FSManifestInfo uses language-agnostic file categories that work across all programming languages:

- **`CATEGORY_PLATFORM`**: Language runtime, interpreter, and standard library
  - Java: JVM/JDK
  - Python: Python interpreter and standard library
  - JavaScript: Node.js runtime
  - C++: libc, libstdc++

- **`CATEGORY_OTHER_PARTY`**: Third-party/external dependencies
  - Java: Maven dependencies
  - Python: pip packages
  - JavaScript: npm packages
  - C++: External libraries

- **`CATEGORY_FIRST_PARTY`**: First-party application code
  - Your application's compiled code
  - Configuration files
  - Resources and assets
  - data runfiles

The `CATEGORY_PLATFORM` may be excluded in a container image where the platform support is provided by the container base image.

## API Reference

### FSManifestInfo Provider

The core provider with the following fields:

- `entries`: Dictionary mapping destination paths (string) to entry structs with (kind, category, target)
- `metadata`: Dictionary mapping destination paths (string) to metadata structs (mode, uid, gid, etc)
- `defaults`: Optional struct with default values for metadata

### Entry Structure

Each entry in the manifest has:

- `kind`: Entry kind - "file" (includes directories), "symlink", or "empty_dir"
- `category`: Category for separation - `CATEGORY_PLATFORM`, `CATEGORY_OTHER_PARTY`, `CATEGORY_FIRST_PARTY`, or custom
- `target`: The source File for files, symlink target path for symlinks, None for empty directories

### Metadata Structure

Metadata is stored separately and can include:

- `mode`: Unix file mode (e.g., "0755" for directories/executables, "0644" for regular files)
- `uid`/`gid`: User/Group ID (integer)
- `owner`/`group`: Owner/Group name (string)
- `mtime`: Modification time (integer timestamp)
- `xattrs`: Dictionary of extended attributes

### Helper Functions

#### `fsmanifest.make_file()`
Creates a file entry (handles both regular files and directories).

```python
# Regular file
entry = fsmanifest.make_file(
    src = file,
    category = CATEGORY_FIRST_PARTY,
)

# Directory (detected via src.is_directory)
dir_entry = fsmanifest.make_file(
    src = directory,
    category = CATEGORY_FIRST_PARTY,
)
```

#### `fsmanifest.make_symlink()`
Creates a symbolic link entry.

```python
entry = fsmanifest.make_symlink(
    symlink_target = "/usr/bin/app",
    category = CATEGORY_FIRST_PARTY,
)
```

#### `fsmanifest.make_empty_dir()`
Creates an empty directory entry (no source file).

```python
entry = fsmanifest.make_empty_dir(
    category = CATEGORY_FIRST_PARTY,
)
```

#### `fsmanifest.make_metadata()`
Creates metadata for manifest entries.

```python
metadata = fsmanifest.make_metadata(
    mode = "0755",
    uid = 0,
    gid = 0,
    owner = "root",
    group = "root",
)
```

#### `fsmanifest.create_manifest()`
Creates an FSManifestInfo provider from entries and optional metadata.

```python
manifest = fsmanifest.create_manifest(
    entries = {
        "/app/bin/server": fsmanifest.make_file(src = server_file, category = CATEGORY_FIRST_PARTY),
        "/deps/lib.jar": fsmanifest.make_file(src = lib_jar, category = CATEGORY_OTHER_PARTY),
    },
    metadata = {
        "/app/bin/server": fsmanifest.make_metadata(mode = "0755"),
        "/deps/lib.jar": fsmanifest.make_metadata(mode = "0644"),
    },
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

#### `fsmanifest.categorize()`
Splits manifest entries by category for splitting.

```python
categories = fsmanifest.categorize(manifest)
# Returns: {"platform": {...}, "external": {...}, "application": {...}}
```
