import SwiftLintFramework
import XCTest

final class SwiftVersionTests: XCTestCase {
    // swiftlint:disable:next function_body_length
    func testDetectSwiftVersion() {
        #if compiler(>=5.4.1)
            let version = "5.4.1"
        #elseif compiler(>=5.4.0)
            let version = "5.4.0"
        #elseif compiler(>=5.3.4)
            let version = "5.3.4"
        #elseif compiler(>=5.3.3)
            let version = "5.3.3"
        #elseif compiler(>=5.3.2)
            let version = "5.3.2"
        #elseif compiler(>=5.3.1)
            let version = "5.3.1"
        #elseif compiler(>=5.3.0)
            let version = "5.3.0"
        #elseif compiler(>=5.2.5)
            let version = "5.2.5"
        #elseif compiler(>=5.2.4)
            let version = "5.2.4"
        #elseif compiler(>=5.2.3)
            let version = "5.2.3"
        #elseif compiler(>=5.2.2)
            let version = "5.2.2"
        #elseif compiler(>=5.2.1)
            let version = "5.2.1"
        #elseif compiler(>=5.2.0)
            let version = "5.2.0"
        #elseif compiler(>=5.1.5)
            let version = "5.1.5"
        #elseif compiler(>=5.1.4)
            let version = "5.1.4"
        #elseif compiler(>=5.1.3)
            let version = "5.1.3"
        #elseif compiler(>=5.1.2)
            let version = "5.1.2"
        #elseif compiler(>=5.1.1)
            let version = "5.1.1"
        #elseif compiler(>=5.1.0)
            let version = "5.1.0"
        #elseif compiler(>=5.0.0)
            let version = "5.0.0"
        #elseif swift(>=4.2.0)
            let version = "4.2.0"
        #elseif swift(>=4.1.50)
            let version = "4.2.0" // Since we can't pass SWIFT_VERSION=4 to sourcekit, it returns 4.2.0
        #elseif swift(>=4.1.2)
            let version = "4.1.2"
        #elseif swift(>=4.1.1)
            let version = "4.1.1"
        #elseif swift(>=4.1.0)
            let version = "4.1.0"
        #elseif swift(>=4.0.3)
            let version = "4.0.3"
        #elseif swift(>=4.0.2)
            let version = "4.0.2"
        #elseif swift(>=4.0.1)
            let version = "4.0.1"
        #elseif swift(>=4.0.0)
            let version = "4.0.0"
        #elseif swift(>=3.4.0)
            let version = "4.2.0" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.2.0
        #elseif swift(>=3.3.2)
            let version = "4.1.2" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.1.2
        #elseif swift(>=3.3.1)
            let version = "4.1.1" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.1.1
        #elseif swift(>=3.3.0)
            let version = "4.1.0" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.1.0
        #elseif swift(>=3.2.3)
            let version = "4.0.3" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.0.3
        #elseif swift(>=3.2.2)
            let version = "4.0.2" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.0.2
        #elseif swift(>=3.2.1)
            let version = "4.0.1" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.0.1
        #else // if swift(>=3.2.0)
            let version = "4.0.0" // Since we can't pass SWIFT_VERSION=3 to sourcekit, it returns 4.0.0
        #endif
        XCTAssertEqual(SwiftVersion.current.rawValue, version)
    }
}
