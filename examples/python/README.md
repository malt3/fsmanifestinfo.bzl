# FSManifestInfo Python Example

This example demonstrates how to use FSManifestInfo with Python applications built using `rules_python`.

## Overview

This example shows:
- Integration of FSManifestInfo directly into `py_binary` rule
- Automatic categorization of Python dependencies (first-party vs third-party)
- Proper layer separation for optimized container images
- Support for data files and resources

## Structure

- `application.py` - Main Python application
- `json_processor.py` - Local library demonstrating internal dependencies
- `string_utils.py` - Utility library
- `config/app.config` - Configuration data file
- `resources/README.txt` - Resource data file
- `BUILD.bazel` - Build configuration
- `MODULE.bazel` - Module configuration with local overrides

## Key Features

### Modified rules_python

The `py_binary` rule in `rules_python` has been modified to automatically generate FSManifestInfo:
- Collects Python sources, dependencies, and data files
- Categorizes them as first-party or third-party based on repository
- Creates appropriate config fragment with Python entrypoint
- Provides FSManifestInfo for use with container image rules

### Layer Separation

When built as a container image, the files are automatically separated into layers:
- **external**: Third-party dependencies from PyPI (numpy, click, requests, etc.)
- **application**: Application code and first-party libraries

## Building

```bash
# Build the Python application
bazel build :application

# Run the application
bazel run :application -- --message "Hello FSManifest"

# Build the container image
bazel build :application_image

# Push to registry (requires authentication)
bazel run :push
```
