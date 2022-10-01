load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

cc_library(
    name = "_CSwiftSyntax",
    srcs = glob(["Sources/_CSwiftSyntax/src/*.c"]),
    hdrs = glob(["Sources/_CSwiftSyntax/include/*.h"]),
    linkstatic = True,
    tags = ["swift_module"],
)

swift_library(
    name = "SwiftSyntax",
    srcs = glob(["Sources/SwiftSyntax/**/*.swift"]),
    module_name = "SwiftSyntax",
    private_deps = ["_CSwiftSyntax"],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "SwiftBasicFormat",
    srcs = glob(["Sources/SwiftBasicFormat/**/*.swift"]),
    module_name = "SwiftBasicFormat",
    visibility = ["//visibility:public"],
    deps = [":SwiftSyntax"],
)

swift_library(
    name = "SwiftDiagnostics",
    srcs = glob(["Sources/SwiftDiagnostics/**/*.swift"]),
    module_name = "SwiftDiagnostics",
    visibility = ["//visibility:public"],
    deps = [":SwiftSyntax"],
)

swift_library(
    name = "SwiftParser",
    srcs = glob(["Sources/SwiftParser/**/*.swift"]),
    module_name = "SwiftParser",
    visibility = ["//visibility:public"],
    deps = [":SwiftSyntax", ":SwiftDiagnostics", ":SwiftBasicFormat"],
)

swift_library(
    name = "SwiftSyntaxBuilder",
    srcs = glob(["Sources/SwiftSyntaxBuilder/**/*.swift"]),
    module_name = "SwiftSyntaxBuilder",
    visibility = ["//visibility:public"],
    deps = [":SwiftSyntax", ":SwiftBasicFormat", ":SwiftParser"],
)
