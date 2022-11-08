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

class FunctionBodyLengthRuleTests: SwiftLintTestCase {
    func testFunctionBodyLengths() {
        let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 49).joined())
        XCTAssertEqual(self.violations(longFunctionBody), [])

        let longerFunctionBody = violatingFuncWithBody(repeatElement("x = 0\n", count: 51).joined())
        XCTAssertEqual(self.violations(longerFunctionBody), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 6),
            reason: "Function body should span 50 lines or less excluding comments and " +
            "whitespace: currently spans 51 lines")])

        let longerFunctionBodyWithEmptyLines = funcWithBody(
            repeatElement("\n", count: 100).joined()
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithEmptyLines), [])
    }

    func testFunctionBodyLengthsWithComments() {
        let longFunctionBodyWithComments = funcWithBody(
            repeatElement("x = 0\n", count: 49).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithComments), [])

        let longerFunctionBodyWithComments = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 51).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 6),
            reason: "Function body should span 50 lines or less excluding comments and " +
            "whitespace: currently spans 51 lines")])
    }

    func testFunctionBodyLengthsWithMultilineComments() {
        let longFunctionBodyWithMultilineComments = funcWithBody(
            repeatElement("x = 0\n", count: 49).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longFunctionBodyWithMultilineComments), [])

        let longerFunctionBodyWithMultilineComments = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 51).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithMultilineComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 6),
            reason: "Function body should span 50 lines or less excluding comments and " +
            "whitespace: currently spans 51 lines")])
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        let config = makeConfig(nil, FunctionBodyLengthRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(example, config: config)
    }
}
