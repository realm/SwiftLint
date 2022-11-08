import SwiftLintFramework
import XCTest

class AccessControlLevelTests: SwiftLintTestCase {
    func testDescription() {
        XCTAssertEqual(AccessControlLevel.private.description, "private")
        XCTAssertEqual(AccessControlLevel.fileprivate.description, "fileprivate")
        XCTAssertEqual(AccessControlLevel.internal.description, "internal")
        XCTAssertEqual(AccessControlLevel.public.description, "public")
        XCTAssertEqual(AccessControlLevel.open.description, "open")
    }

    func testPriority() {
        XCTAssertLessThan(AccessControlLevel.private, .fileprivate)
        XCTAssertLessThan(AccessControlLevel.fileprivate, .internal)
        XCTAssertLessThan(AccessControlLevel.internal, .public)
        XCTAssertLessThan(AccessControlLevel.public, .open)
    }
}
