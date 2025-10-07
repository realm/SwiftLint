"""Shared compiler options for SwiftLint Bazel build."""

# Shared compiler options
COPTS = [
    "-warnings-as-errors",
    "-enable-upcoming-feature",
    "ConciseMagicFile",
    "-enable-upcoming-feature",
    "ExistentialAny",
    "-enable-upcoming-feature",
    "ForwardTrailingClosures",
    "-enable-upcoming-feature",
    "GlobalActorIsolatedTypesUsability",
    "-enable-upcoming-feature",
    "ImplicitOpenExistentials",
    "-enable-upcoming-feature",
    "ImportObjcForwardDeclarations",
    "-enable-upcoming-feature",
    "InferIsolatedConformances",
    "-enable-upcoming-feature",
    "InferSendableFromCaptures",
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
