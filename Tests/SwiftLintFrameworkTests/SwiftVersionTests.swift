import SwiftLintFramework
import XCTest

final class SwiftVersionTests: SwiftLintTestCase {
    func testDetectSwiftVersion() {
#if compiler(>=6.0.3)
        let version = "6.0.3"
#elseif compiler(>=6.0.2)
        let version = "6.0.2"
#elseif compiler(>=6.0.1)
        let version = "6.0.1"
#elseif compiler(>=6.0.0)
        let version = "6.0.0"
#elseif compiler(>=5.10.1)
        let version = "5.10.1"
#elseif compiler(>=5.10.0)
        let version = "5.10.0"
#elseif compiler(>=5.9.2)
        let version = "5.9.2"
#elseif compiler(>=5.9.1)
        let version = "5.9.1"
#elseif compiler(>=5.9.0)
        let version = "5.9.0"
#elseif compiler(>=5.8.1)
        let version = "5.8.1"
#elseif compiler(>=5.8.0)
        let version = "5.8.0"
#elseif compiler(>=5.7.3)
        let version = "5.7.3"
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

    func testCompareBalancedSwiftVersion() {
        XCTAssertNotEqual(SwiftVersion(rawValue: "5"), SwiftVersion(rawValue: "6"))
        XCTAssertTrue(SwiftVersion(rawValue: "5") < SwiftVersion(rawValue: "6"))
        XCTAssertFalse(SwiftVersion(rawValue: "5") > SwiftVersion(rawValue: "6"))
        XCTAssertFalse(SwiftVersion(rawValue: "6") < SwiftVersion(rawValue: "5"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "5.1"), SwiftVersion(rawValue: "5.2"))
        XCTAssertTrue(SwiftVersion(rawValue: "5.1") < SwiftVersion(rawValue: "5.2"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.1") > SwiftVersion(rawValue: "5.2"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.2") < SwiftVersion(rawValue: "5.1"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "5.1.1"), SwiftVersion(rawValue: "5.1.2"))
        XCTAssertTrue(SwiftVersion(rawValue: "5.1.1") < SwiftVersion(rawValue: "5.1.2"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.1.1") > SwiftVersion(rawValue: "5.1.2"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.1.2") < SwiftVersion(rawValue: "5.1.1"))
    }

    func testCompareUnbalancedSwiftVersion() {
        XCTAssertEqual(SwiftVersion(rawValue: "5"), SwiftVersion(rawValue: "5.0"))
        XCTAssertFalse(SwiftVersion(rawValue: "5") < SwiftVersion(rawValue: "5.0"))
        XCTAssertFalse(SwiftVersion(rawValue: "5") > SwiftVersion(rawValue: "5.0"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "5.9"), SwiftVersion(rawValue: "6"))
        XCTAssertTrue(SwiftVersion(rawValue: "5.9") < SwiftVersion(rawValue: "6"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.9") > SwiftVersion(rawValue: "6"))
        XCTAssertFalse(SwiftVersion(rawValue: "6") < SwiftVersion(rawValue: "5.9"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "5.2"), SwiftVersion(rawValue: "5.10.3"))
        XCTAssertTrue(SwiftVersion(rawValue: "5.2") < SwiftVersion(rawValue: "5.10.3"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.2") > SwiftVersion(rawValue: "5.10.3"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.10.3") < SwiftVersion(rawValue: "5.2"))
    }

    func testCompareProblematicSwiftVersion() {
        XCTAssertEqual(SwiftVersion(rawValue: "5.010"), SwiftVersion(rawValue: "5.10"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.010") < SwiftVersion(rawValue: "5.10"))
        XCTAssertFalse(SwiftVersion(rawValue: "5.010") > SwiftVersion(rawValue: "5.10"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "-10"), SwiftVersion(rawValue: "-1"))
        XCTAssertTrue(SwiftVersion(rawValue: "-10") < SwiftVersion(rawValue: "-1"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "0"), SwiftVersion(rawValue: "10"))
        XCTAssertTrue(SwiftVersion(rawValue: "0") < SwiftVersion(rawValue: "10"))

        XCTAssertNotEqual(SwiftVersion(rawValue: "alpha"), SwiftVersion(rawValue: "beta"))
        XCTAssertTrue(SwiftVersion(rawValue: "alpha") < SwiftVersion(rawValue: "beta"))
    }
}
