@testable import SwiftLintFramework
import XCTest

class CompilerProtocolInitRuleTests: XCTestCase {
    private let ruleID = CompilerProtocolInitRule.description.identifier

    func testWithDefaultConfiguration() {
        verifyRule(CompilerProtocolInitRule.description)
    }

    func testViolationMessageForExpressibleByIntegerLiteral() throws {
        let config = try XCTUnwrap(makeConfig(nil, ruleID))
        let allViolations = violations(Example("let a = NSNumber(integerLiteral: 1)"), config: config)

        let compilerProtocolInitViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        let violation = try XCTUnwrap(
            compilerProtocolInitViolation,
            "A compiler protocol init violation should have been triggered!"
        )
        XCTAssertEqual(
            violation.reason,
            "The initializers declared in compiler protocol ExpressibleByIntegerLiteral shouldn't be called directly."
        )
    }
}

// https://bugs.swift.org/browse/SR-11501
#if compiler(<5.1) || (SWIFT_PACKAGE && os(macOS))
private enum UnwrapError: Error {
    case missingValue
}

private func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?,
                          _ message: @autoclosure () -> String = "") throws -> T {
    if let value = try expression() {
        return value
    } else {
        throw UnwrapError.missingValue
    }
}
#endif
