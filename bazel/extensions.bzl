"""bzlmod module_extension for providing extra rule sources that should be loaded by swiftlint"""

load(":deps.bzl", "extra_swift_sources")

def _extra_rules(module_ctx):
    root_modules = [m for m in module_ctx.modules if m.is_root]
    if len(root_modules) > 1:
        fail("Expected at most one root module, found {}".format(", ".join([x.name for x in root_modules])))

    if root_modules:
        root_module = root_modules[0]
    else:
        root_module = module_ctx.modules[0]

    kwargs = {}
    if root_module.tags.setup:
        kwargs["srcs"] = root_module.tags.setup[0].srcs

    extra_swift_sources(
        name = "swiftlint_extra_rules",
        **kwargs
    )

extra_rules = module_extension(
    implementation = _extra_rules,
    tag_classes = {
        "setup": tag_class(attrs = {
            "srcs": attr.label(allow_files = [".swift"]),
        }),
    },
)
