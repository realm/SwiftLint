import Foundation
import XCTest

enum TestResources {
    static var path: String {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .path
            .absolutePathStandardized()
    }
}

extension XCTestCase {
    var testResourcesPath: String { TestResources.path }
}
