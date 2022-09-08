filegroup(
    name = "release_files",
    srcs = glob(["*"]),
    visibility = ["//visibility:public"],
)

xcode_version(
    name = "version14_0_0_14A309",
    aliases = [
        "14.0.0.14A309",
        "14A309",
    ],
    default_ios_sdk_version = "16.0",
    default_macos_sdk_version = "12.3",
    default_tvos_sdk_version = "16.0",
    default_watchos_sdk_version = "9.0",
    version = "14.0.0.14A309",
)

available_xcodes(
    name = "local_xcodes",
    default = ":version14_0_0_14A309",
    versions = [
        ":version14_0_0_14A309",
    ],
)

available_xcodes(
    name = "remote_xcodes",
    default = ":version14_0_0_14A309",
    versions = [
        ":version14_0_0_14A309",
    ],
)

xcode_config(
    name = "xcode_config",
    local_versions = ":local_xcodes",
    remote_versions = ":remote_xcodes",
)
