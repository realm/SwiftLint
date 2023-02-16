load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@SwiftLint//bazel:opt_wrapper.bzl", "opt_wrapper")

swift_library(
    name = "SwiftSyntax",
    srcs = glob(
        ["Sources/SwiftSyntax/**/*.swift"],
        exclude = ["Sources/SwiftSyntax/Documentation.docc/**"],
    ),
    module_name = "SwiftSyntax",
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
    name = "SwiftSyntaxParser",
    srcs = glob(["Sources/SwiftSyntaxParser/**/*.swift"]),
    module_name = "SwiftSyntaxParser",
    deps = [
        ":SwiftParser",
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
    name = "SwiftRefactor",
    srcs = glob(["Sources/SwiftRefactor/**/*.swift"]),
    module_name = "SwiftRefactor",
    deps = [
        ":SwiftParser",
        ":SwiftSyntax",
    ],
)

swift_library(
    name = "_SwiftSyntaxMacros",
    srcs = glob(["Sources/_SwiftSyntaxMacros/**/*.swift"]),
    module_name = "_SwiftSyntaxMacros",
    deps = [
        ":SwiftDiagnostics",
        ":SwiftParser",
        ":SwiftSyntax",
        ":SwiftSyntaxBuilder",
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
