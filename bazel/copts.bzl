"""Shared compiler options for SwiftLint Bazel build."""

# Shared compiler options
COPTS = [
    "-warnings-as-errors",
    "-enable-upcoming-feature",
    "ExistentialAny",
    "-enable-upcoming-feature",
    "ConciseMagicFile",
    "-enable-upcoming-feature",
    "ImportObjcForwardDeclarations",
    "-enable-upcoming-feature",
    "ForwardTrailingClosures",
    "-enable-upcoming-feature",
    "ImplicitOpenExistentials",
    "-Xfrontend",
    "-warn-implicit-overrides",
]

STRICT_CONCURRENCY_COPTS = [
    "-Xfrontend",
    "-strict-concurrency=complete",
]

TARGETED_CONCURRENCY_COPTS = [
    "-Xfrontend",
    "-strict-concurrency=targeted",
]

# Combined options for convenience
STRICT_COPTS = COPTS + STRICT_CONCURRENCY_COPTS
TARGETED_COPTS = COPTS + TARGETED_CONCURRENCY_COPTS
