FSManifestInfo Java Example
===========================

This application demonstrates proper layer separation in container images:

- Runtime layer: JVM runtime files
- Third-party layer: External dependencies (Guava, Gson, SLF4J, Commons CLI)
- Application layer: Your application code and resources

The FSManifestInfo provider enables automatic categorization and
layer creation based on file sources.