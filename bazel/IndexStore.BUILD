load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary", "swift_library")

cc_library(
    name = "CIndexStore",
    hdrs = ["Sources/CIndexStore/include/indexstore.h"],
    linkstatic = True,
    tags = ["swift_module"],
)

swift_library(
    name = "IndexStore",
    srcs = glob([
        "Sources/IndexStore/*.swift",
    ]),
    linkopts = select({
        "@platforms//os:linux": ["-lIndexStore"],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
    deps = [
        "CIndexStore",
    ] + select({
        "@platforms//os:linux": [],
        "//conditions:default": [
            "@com_github_keith_static_index_store//:libIndexStore",
        ],
    }),
)
