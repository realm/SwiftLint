import SwiftLintFramework
import XCTest

final class SwiftVersionTests: XCTestCase {
    func testDetectSwiftVersion() {
#if compiler(>=6.0.0)
        let version = "6.0.0"
#elseif compiler(>=5.7.2)
        let version = "5.7.2"
#elseif compiler(>=5.7.1)
        let version = "5.7.1"
#elseif compiler(>=5.7.0)
        let version = "5.7.0"
#elseif compiler(>=5.6.3)
        let version = "5.6.3"
#elseif compiler(>=5.6.2)
        let version = "5.6.2"
#elseif compiler(>=5.6.1)
        let version = "5.6.1"
#elseif compiler(>=5.6.0)
        let version = "5.6.0"
#elseif compiler(>=5.5.4)
        let version = "5.5.4"
#elseif compiler(>=5.5.3)
        let version = "5.5.3"
#elseif compiler(>=5.5.2)
        let version = "5.5.2"
#elseif compiler(>=5.5.1)
        let version = "5.5.1"
#elseif compiler(>=5.5.0)
        let version = "5.5.0"
#else
        #error("Unsupported Swift version")
#endif
        XCTAssertEqual(SwiftVersion.current.rawValue, version)
    }
}
