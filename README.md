# FSManifestInfo provider

> This Bazel module contains a (work-in-progress) implementation of the `FSManifestInfo` provider. It allows for fine control over the placement and metadata attached to individual `File` objects in a deliverable.

[See this proposal for more information](https://docs.google.com/document/d/1BOheluS2OOPfXyOMtbjnWvMivQo6CDjEB-_C-z3hBCg/edit).

It defines a dictionary mapping paths to `File` objects, empty directories, and symlinks, along with file metadata.

Rules returning this provider are free to define custom metadata.
The well-defined metadata fields in [metadata.bzl](./private/metadata.bzl) have special meaning that should be respected by producers and consumers.
