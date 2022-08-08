import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String,
                          violates: Bool = false,
                          file: StaticString = #file,
                          line: UInt = #line) -> Example {
    let marker = violates ? "↓" : ""
    return Example("func \(marker)abc() async {\nvar x = 0\n\(body)}\n", file: file, line: line)
}

private func violatingFuncWithBody(_ body: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return funcWithBody(body, violates: true, file: file, line: line)
}

class FunctionBodyLengthRuleTests: XCTestCase {
    func testWithDefaultConfiguration() async {
        await verifyRule(FunctionBodyLengthRule.description)
    }

    func testFunctionBodyLengths() async {
        do {
            let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 39).joined())
            let results = await self.violations(longFunctionBody)
            XCTAssertEqual(results, [])
        }

        do {
            let longerFunctionBody = violatingFuncWithBody(repeatElement("x = 0\n", count: 40).joined())
            let results = await self.violations(longerFunctionBody)
            XCTAssertEqual(results, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Function body should span 40 lines or less excluding comments and " +
                "whitespace: currently spans 41 lines")])
        }

        do {
            let longerFunctionBodyWithEmptyLines = funcWithBody(
                repeatElement("\n", count: 100).joined()
            )
            let results = await self.violations(longerFunctionBodyWithEmptyLines)
            XCTAssertEqual(results, [])
        }
    }

    func testFunctionBodyLengthsWithComments() async {
        do {
            let longFunctionBodyWithComments = funcWithBody(
                repeatElement("x = 0\n", count: 39).joined() +
                "// comment only line should be ignored.\n"
            )
            let results = await violations(longFunctionBodyWithComments)
            XCTAssertEqual(results, [])
        }

        do {
            let longerFunctionBodyWithComments = violatingFuncWithBody(
                repeatElement("x = 0\n", count: 40).joined() +
                "// comment only line should be ignored.\n"
            )
            let results = await violations(longerFunctionBodyWithComments)
            XCTAssertEqual(results, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Function body should span 40 lines or less excluding comments and " +
                "whitespace: currently spans 41 lines")])
        }
    }

    func testFunctionBodyLengthsWithMultilineComments() async {
        do {
            let longFunctionBodyWithMultilineComments = funcWithBody(
                repeatElement("x = 0\n", count: 39).joined() +
                "/* multi line comment only line should be ignored.\n*/\n"
            )
            let results = await violations(longFunctionBodyWithMultilineComments)
            XCTAssertEqual(results, [])
        }

        do {
            let longerFunctionBodyWithMultilineComments = violatingFuncWithBody(
                repeatElement("x = 0\n", count: 40).joined() +
                "/* multi line comment only line should be ignored.\n*/\n"
            )
            let results = await violations(longerFunctionBodyWithMultilineComments)
            XCTAssertEqual(results, [StyleViolation(
                ruleDescription: FunctionBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Function body should span 40 lines or less excluding comments and " +
                "whitespace: currently spans 41 lines")])
        }
    }

    private func violations(_ example: Example) async -> [StyleViolation] {
        let config = makeConfig(nil, FunctionBodyLengthRule.description.identifier)!
        return await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
