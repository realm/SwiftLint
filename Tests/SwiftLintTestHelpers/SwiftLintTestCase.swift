import SwiftLintFramework
import XCTest

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable test_case_accessibility

// swiftlint:disable:next balanced_xctest_lifecycle
open class SwiftLintTestCase: XCTestCase {
    override open class func setUp() {
        super.setUp()
        RuleRegistry.registerAllRulesOnce()
    }

    // swiftlint:disable:next identifier_name
    public func AsyncAssertFalse(_ condition: @autoclosure () async -> Bool,
                                 _ message: @autoclosure () -> String = "",
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async {
        let condition = await condition()
        XCTAssertFalse(condition, message(), file: file, line: line)
    }

    // swiftlint:disable:next identifier_name
    public func AsyncAssertTrue(_ condition: @autoclosure () async throws -> Bool,
                                _ message: @autoclosure () -> String = "",
                                file: StaticString = #filePath,
                                line: UInt = #line) async rethrows {
        let condition = try await condition()
        XCTAssertTrue(condition, message(), file: file, line: line)
    }

    // swiftlint:disable:next identifier_name
    public func AsyncAssertEqual<T: Equatable>(_ expression1: @autoclosure () async throws -> T,
                                               _ expression2: @autoclosure () async throws -> T,
                                               _ message: @autoclosure () -> String = "",
                                               file: StaticString = #filePath,
                                               line: UInt = #line) async rethrows {
        let value1 = try await expression1()
        let value2 = try await expression2()
        XCTAssertEqual(value1, value2, message(), file: file, line: line)
    }

    // swiftlint:disable:next identifier_name
    public func AsyncAssertNotEqual<T: Equatable>(_ expression1: @autoclosure () async -> T,
                                                  _ expression2: @autoclosure () async -> T,
                                                  _ message: @autoclosure () -> String = "",
                                                  file: StaticString = #filePath,
                                                  line: UInt = #line) async {
        let value1 = await expression1()
        let value2 = await expression2()
        XCTAssertNotEqual(value1, value2, message(), file: file, line: line)
    }

    // swiftlint:disable:next identifier_name
    public func AsyncAssertNil<T>(_ expression: @autoclosure () async -> T?,
                                  _ message: @autoclosure () -> String = "",
                                  file: StaticString = #filePath,
                                  line: UInt = #line) async {
        let value = await expression()
        XCTAssertNil(value, message(), file: file, line: line)
    }
}
