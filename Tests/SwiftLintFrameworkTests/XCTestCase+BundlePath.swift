import Foundation
import XCTest

extension XCTestCase {
    var bundlePath: String {
        #if SWIFT_PACKAGE
            return "Tests/SwiftLintFrameworkTests/Resources".bridge().absolutePathRepresentation()
        #else
            return Bundle(for: type(of: self)).resourcePath!
        #endif
    }
}
