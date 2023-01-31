import Foundation
import XCTest

enum TestResources {
    static var path: String {
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return "\(rootProjectDirectory)/Tests/SwiftLintFrameworkTests/Resources"
        }

        return URL(fileURLWithPath: #file, isDirectory: false)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .path
            .absolutePathStandardized()
    }
}

extension XCTestCase {
    var testResourcesPath: String { TestResources.path }
}
