import Foundation

extension ProcessInfo {
    var isLikelyXcodeCloudEnvironment: Bool {
        // https://developer.apple.com/documentation/xcode/environment-variable-reference
        let requiredKeys: Set = [
            "CI",
            "CI_BUILD_ID",
            "CI_BUILD_NUMBER",
            "CI_BUNDLE_ID",
            "CI_COMMIT",
            "CI_DERIVED_DATA_PATH",
            "CI_PRODUCT",
            "CI_PRODUCT_ID",
            "CI_PRODUCT_PLATFORM",
            "CI_PROJECT_FILE_PATH",
            "CI_START_CONDITION",
            "CI_TEAM_ID",
            "CI_WORKFLOW",
            "CI_WORKSPACE",
            "CI_XCODE_PROJECT",
            "CI_XCODE_SCHEME",
            "CI_XCODEBUILD_ACTION",
        ]

        return requiredKeys.isSubset(of: environment.keys)
    }
}
