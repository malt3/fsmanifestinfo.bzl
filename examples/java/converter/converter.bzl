load("@rules_java//java:defs.bzl", "JavaInfo")
load("@fsmanifestinfo//fsmanifest:fsmanifestinfo.bzl", "fsmanifest")
load("@fsmanifestinfo//fsmanifest:defs.bzl", "CATEGORY_FIRST_PARTY", "CATEGORY_OTHER_PARTY")

# Provider to carry collected runfiles through the aspect
RunfilesInfo = provider(
    doc = "Provider to carry collected runfiles from Java targets",
    fields = {
        "runfiles": "depset of files collected from data attributes",
    },
)

# runfiles_aspect collects runfiles from java targets.
def _runfiles_aspect_impl(_target, ctx):# Collect direct runfiles from this target's data attribute
    direct_runfiles = []
    if hasattr(ctx.rule.attr, "data"):
        for data_target in ctx.rule.attr.data:
            # Collect files from each data dependency
            if DefaultInfo in data_target:
                direct_runfiles.extend(data_target[DefaultInfo].files.to_list())
                # Also collect from data_runfiles if available
                if data_target[DefaultInfo].data_runfiles:
                    direct_runfiles.extend(data_target[DefaultInfo].data_runfiles.files.to_list())

    # Collect transitive runfiles from deps and runtime_deps
    transitive_runfiles = []
    for attr_name in ["deps", "runtime_deps"]:
        if hasattr(ctx.rule.attr, attr_name):
            for dep in getattr(ctx.rule.attr, attr_name):
                if RunfilesInfo in dep:
                    transitive_runfiles.append(dep[RunfilesInfo].runfiles)

    # Create depset of all collected runfiles
    all_runfiles = depset(
        direct = direct_runfiles,
        transitive = transitive_runfiles,
    )

    # Return providers
    providers = []
    providers.append(RunfilesInfo(runfiles = all_runfiles))

    return providers


_runfiles_aspect = aspect(
    implementation = _runfiles_aspect_impl,
    attr_aspects = ["deps", "runtime_deps", "data"],
    provides = [RunfilesInfo],
)

def _runfiles_path(file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return "_main/" + file.short_path

def _converter_impl(ctx):
    java_info = ctx.attr.binary[JavaInfo]
    sameparty_repo = ctx.attr.binary.label.repo_name
    entries = {}
    metadata = {}
    classpath = ""

    # This may be ineffiecient
    # oh well... :(
    for jar in java_info.compilation_info.runtime_classpath.to_list():
        owner = jar.owner if hasattr(jar, "owner") else None
        if owner:
            category = CATEGORY_FIRST_PARTY if owner.repo_name == sameparty_repo else CATEGORY_OTHER_PARTY
        else:
            category = CATEGORY_FIRST_PARTY
        rpath = _runfiles_path(jar)
        entry_path = ctx.attr.prefix + rpath if ctx.attr.prefix.endswith("/") else ctx.attr.prefix + "/" + rpath
        entries[entry_path] = fsmanifest.make_file(
            src = jar,
            category = category,
        )
        classpath += (":" if classpath else "") + entry_path

    # Add data runfiles collected by the aspect
    if RunfilesInfo in ctx.attr.binary:
        for data_file in ctx.attr.binary[RunfilesInfo].runfiles.to_list():
            rpath = _runfiles_path(data_file)
            entry_path = ctx.attr.prefix + rpath if ctx.attr.prefix.endswith("/") else ctx.attr.prefix + "/" + rpath
            entries[entry_path] = fsmanifest.make_file(
                src = data_file,
                category = CATEGORY_FIRST_PARTY,
            )
    out = ctx.actions.declare_file(ctx.label.name + ".config_fragment")
    entrypoint = [
        ctx.attr.interpreter,
        "-cp",
        classpath,
    ]
    if ctx.attr.main_class:
        entrypoint.append(ctx.attr.main_class)
    working_dir = ctx.attr.prefix + "/_main"
    config_fragment = json.encode({
        "config": {
            "Entrypoint": entrypoint,
            "WorkingDir": working_dir,
            "Env": [
                "JAVA_RUNFILES=" + ctx.attr.prefix,
            ],
        },
    })
    ctx.actions.write(
        output = out,
        content = config_fragment,
    )
    return [
        DefaultInfo(files = depset([out])),
        fsmanifest.create_manifest(entries, metadata),
    ]

converter = rule(
    implementation = _converter_impl,
    attrs = {
        "main_class": attr.string(),
        "binary": attr.label(providers = [JavaInfo], aspects = [_runfiles_aspect], mandatory = True),
        "interpreter": attr.string(default = "/usr/bin/java"),
        "prefix": attr.string(default = "/app"),
    },
)
