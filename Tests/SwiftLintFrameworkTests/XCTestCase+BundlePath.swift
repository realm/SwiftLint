import Foundation
import XCTest

extension XCTestCase {
    var testResourcesPath: String {
        return URL(fileURLWithPath: #file).deletingLastPathComponent()
            .appendingPathComponent("Resources").path.absolutePathStandardized()
    }
}
