load("@rules_python//python:defs.bzl", "PyInfo")
load("@rules_python//python:py_executable_info.bzl", "PyExecutableInfo")

def main_path(ctx, file):
    return ctx.attr.prefix + "/src/" + file.short_path

def _py_image_config_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "_image_config.json")
    py_info = ctx.attr.binary[PyInfo]
    py_executable_info = ctx.attr.binary[PyExecutableInfo]
    paths = [
        ctx.attr.prefix + "/src",
        ctx.attr.prefix + "/site-packages",
    ]
    for p in py_info.imports.to_list():
        # skip anything that ends with "/site-packages"
        if p.endswith("/site-packages"):
            continue
        # skip anything up to the first slash
        if "/" in p:
            p = p.split("/", 1)[1]
        paths.append(ctx.attr.prefix + "/src/" + p)
    pythonpath = ":".join(paths)
    config = {
        "config": {
            "EntryPoint": [
                ctx.attr.interpreter,
                main_path(ctx, py_executable_info.main),
            ],
            "WorkingDir": ctx.attr.prefix + ".runfiles/_main",
            "Env": [
                "PYTHONPATH=" + pythonpath,
                "PYTHONUSERBASE=" + ctx.attr.prefix,
                "RUNFILES_DIR=" + ctx.attr.prefix + ".runfiles",
            ],
        },
    }
    ctx.actions.write(
        output = out,
        content = json.encode(config),
    )
    return [DefaultInfo(files = depset([out]))]

py_image_config = rule(
    implementation = _py_image_config_impl,
    attrs = {
        "binary": attr.label(mandatory = True, providers = [PyExecutableInfo, PyInfo], doc = "The py_binary target to package into the image."),
        "interpreter": attr.string(default = "/usr/bin/python3", doc = "Path to the Python interpreter inside the image."),
        "prefix": attr.string(default = "/app", doc = "The prefix path inside the image where files are placed."),
    },
)
