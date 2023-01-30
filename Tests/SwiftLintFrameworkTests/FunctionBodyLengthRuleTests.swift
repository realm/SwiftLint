@testable import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String,
                          violates: Bool = false,
                          file: StaticString = #file,
                          line: UInt = #line) -> Example {
    let marker = violates ? "↓" : ""
    return Example("func \(marker)abc() {\n\(body)}\n", file: file, line: line)
}

private func violatingFuncWithBody(_ body: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return funcWithBody(body, violates: true, file: file, line: line)
}

class FunctionBodyLengthRuleTests: XCTestCase {
    func testFunctionBodyLengths() async throws {
        do {
            let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 49).joined())
            let violations = try await self.violations(longFunctionBody)
            XCTAssertEqual(violations, [])
        }

        do {
            let longerFunctionBody = violatingFuncWithBody(repeatElement("x = 0\n", count: 51).joined())
            let violations = try await self.violations(longerFunctionBody)
            XCTAssertEqual(violations, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 6),
                reason: "Function body should span 50 lines or less excluding comments and " +
                "whitespace: currently spans 51 lines")])
        }

        do {
            let longerFunctionBodyWithEmptyLines = funcWithBody(
                repeatElement("\n", count: 100).joined()
            )
            let violations = try await self.violations(longerFunctionBodyWithEmptyLines)
            XCTAssertEqual(violations, [])
        }
    }

    func testFunctionBodyLengthsWithComments() async throws {
        do {
            let longFunctionBodyWithComments = funcWithBody(
                repeatElement("x = 0\n", count: 49).joined() +
                "// comment only line should be ignored.\n"
            )
            let violations = try await violations(longFunctionBodyWithComments)
            XCTAssertEqual(violations, [])
        }

        do {
            let longerFunctionBodyWithComments = violatingFuncWithBody(
                repeatElement("x = 0\n", count: 51).joined() +
                "// comment only line should be ignored.\n"
            )
            let violations = try await self.violations(longerFunctionBodyWithComments)
            XCTAssertEqual(violations, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 6),
                reason: "Function body should span 50 lines or less excluding comments and " +
                "whitespace: currently spans 51 lines")])
        }
    }

    func testFunctionBodyLengthsWithMultilineComments() async throws {
        do {
            let longFunctionBodyWithMultilineComments = funcWithBody(
                repeatElement("x = 0\n", count: 49).joined() +
                "/* multi line comment only line should be ignored.\n*/\n"
            )
            let violations = try await self.violations(longFunctionBodyWithMultilineComments)
            XCTAssertEqual(violations, [])
        }

        do {
            let longerFunctionBodyWithMultilineComments = violatingFuncWithBody(
                repeatElement("x = 0\n", count: 51).joined() +
                "/* multi line comment only line should be ignored.\n*/\n"
            )
            let violations = try await self.violations(longerFunctionBodyWithMultilineComments)
            XCTAssertEqual(violations, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 6),
                reason: "Function body should span 50 lines or less excluding comments and " +
                "whitespace: currently spans 51 lines")])
        }
    }

    func testConfiguration() async throws {
        let function = violatingFuncWithBody(repeatElement("x = 0\n", count: 10).joined())

        do {
            let violations = try await self.violations(function, configuration: ["warning": 12])
            XCTAssertEqual(violations, [])
        }

        do {
            let violations = try await self.violations(function, configuration: ["warning": 12, "error": 14])
            XCTAssertEqual(violations, [])
        }

        do {
            let violations = try await self.violations(function, configuration: ["warning": 8])
            XCTAssertEqual(
                violations.map(\.reason),
                [
                    """
                    Function body should span 8 lines or less excluding comments and whitespace: \
                    currently spans 10 lines
                    """
                ]
            )
        }
        do {
            let violations = try await self.violations(function, configuration: ["warning": 12, "error": 8])
            XCTAssertEqual(
                violations.map(\.reason),
                [
                    """
                    Function body should span 8 lines or less excluding comments and whitespace: \
                    currently spans 10 lines
                    """
                ]
            )
        }
    }

    private func violations(_ example: Example, configuration: Any? = nil) async throws -> [StyleViolation] {
        let config = makeConfig(configuration, FunctionBodyLengthRule.description.identifier)!
        return try await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
