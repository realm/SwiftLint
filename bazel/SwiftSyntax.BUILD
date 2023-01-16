load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@SwiftLint//bazel:opt_wrapper.bzl", "opt_wrapper")

cc_library(
    name = "_CSwiftSyntax",
    srcs = glob(["Sources/_CSwiftSyntax/src/*.c"]),
    hdrs = glob(["Sources/_CSwiftSyntax/include/*.h"]),
    linkstatic = True,
    tags = ["swift_module"],
)

swift_library(
    name = "SwiftSyntax",
    srcs = glob(
        ["Sources/SwiftSyntax/**/*.swift"],
        exclude = ["Sources/SwiftSyntax/Documentation.docc/**"],
    ),
    module_name = "SwiftSyntax",
    private_deps = ["_CSwiftSyntax"],
)

swift_library(
    name = "SwiftBasicFormat",
    srcs = glob(["Sources/SwiftBasicFormat/**/*.swift"]),
    module_name = "SwiftBasicFormat",
    deps = [":SwiftSyntax"],
)

swift_library(
    name = "SwiftDiagnostics",
    srcs = glob(["Sources/SwiftDiagnostics/**/*.swift"]),
    module_name = "SwiftDiagnostics",
    deps = [":SwiftSyntax"],
)

swift_library(
    name = "SwiftParser",
    srcs = glob(["Sources/SwiftParser/**/*.swift"]),
    module_name = "SwiftParser",
    deps = [
        ":SwiftBasicFormat",
        ":SwiftDiagnostics",
        ":SwiftSyntax",
    ],
)

swift_library(
    name = "SwiftSyntaxBuilder",
    srcs = glob(["Sources/SwiftSyntaxBuilder/**/*.swift"]),
    module_name = "SwiftSyntaxBuilder",
    deps = [
        ":SwiftBasicFormat",
        ":SwiftParser",
        ":SwiftParserDiagnostics",
        ":SwiftSyntax",
    ],
)

swift_library(
    name = "SwiftOperators",
    srcs = glob(["Sources/SwiftOperators/**/*.swift"]),
    module_name = "SwiftOperators",
    deps = [
        ":SwiftDiagnostics",
        ":SwiftParser",
        ":SwiftSyntax",
    ],
)

swift_library(
    name = "SwiftParserDiagnostics",
    srcs = glob(["Sources/SwiftParserDiagnostics/**/*.swift"]),
    module_name = "SwiftParserDiagnostics",
    deps = [
        ":SwiftBasicFormat",
        ":SwiftDiagnostics",
        ":SwiftParser",
        ":SwiftSyntax",
    ],
)

swift_library(
    name = "IDEUtils",
    srcs = glob(["Sources/IDEUtils/**/*.swift"]),
    module_name = "IDEUtils",
    deps = [":SwiftSyntax"],
)

opt_wrapper(
    name = "optlibs",
    visibility = ["//visibility:public"],
    deps = [
        ":IDEUtils",
        ":SwiftOperators",
        ":SwiftParser",
        ":SwiftParserDiagnostics",
        ":SwiftSyntax",
        ":SwiftSyntaxBuilder",
    ],
)
