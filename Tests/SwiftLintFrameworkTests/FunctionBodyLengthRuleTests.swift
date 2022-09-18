import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String,
                          violates: Bool = false,
                          file: StaticString = #file,
                          line: UInt = #line) -> Example {
    let marker = violates ? "↓" : ""
    return Example("func \(marker)abc() {\nvar x = 0\n\(body)}\n", file: file, line: line)
}

private func complexFuncWithBody(_ body: String, file: StaticString = #file, line: UInt = #line) -> Example {
    Example(
      "func example(text: String, testIntArgument: Int, testArgument withLabel: String," +
      " _ lastAgrumentWithoutLabel: String) {\n" +
      "var a = 5\n\(body)}\n",
      file: file,
      line: line)
}

private func uiKitFuncWithBody(_ body: String, file: StaticString = #file, line: UInt = #line) -> Example {
    Example(
      "func tableView(_ tableView: UITableView," +
      " cellForRowAt indexPath: IndexPath) -> UITableViewCell {\n" +
      "var cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: \"identifier\", for: indexPath)\n" +
      "\(body) \n}\n",
      file: file,
      line: line)
}

private func violatingFuncWithBody(_ body: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return funcWithBody(body, violates: true, file: file, line: line)
}

class FunctionBodyLengthRuleTests: XCTestCase {
    func testFunctionBodyLengths() {
        let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 39).joined())
        XCTAssertEqual(self.violations(longFunctionBody, ruleConfigurations: nil), [])

        let longerFunctionBody = violatingFuncWithBody(repeatElement("x = 0\n", count: 40).joined())
        XCTAssertEqual(self.violations(longerFunctionBody, ruleConfigurations: nil), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])

        let longerFunctionBodyWithEmptyLines = funcWithBody(
            repeatElement("\n", count: 100).joined()
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithEmptyLines, ruleConfigurations: nil), [])
    }

    func testFunctionBodyLengthsWithComments() {
        let longFunctionBodyWithComments = funcWithBody(
            repeatElement("x = 0\n", count: 39).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithComments, ruleConfigurations: nil), [])

        let longerFunctionBodyWithComments = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 40).joined() +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithComments, ruleConfigurations: nil), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }

    func testFunctionBodyLengthsWithMultilineComments() {
        let longFunctionBodyWithMultilineComments = funcWithBody(
            repeatElement("x = 0\n", count: 39).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longFunctionBodyWithMultilineComments, ruleConfigurations: nil), [])

        let longerFunctionBodyWithMultilineComments = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 40).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longerFunctionBodyWithMultilineComments, ruleConfigurations: nil),
                       [StyleViolation(
                        ruleDescription: FunctionBodyLengthRule.description,
                        location: Location(file: nil, line: 1, character: 1),
                        reason: "Function body should span 40 lines or less excluding comments and " +
                        "whitespace: currently spans 41 lines")]
        )
    }

    func testFunctionBodyLengthWithExcludedName() {
        let longFunctionWithExcludedName = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 41).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longFunctionWithExcludedName,
                                       ruleConfigurations: ["excludedByName": "abc"]), [])

        let longerFunctionWithExcludedName = violatingFuncWithBody(
            repeatElement("x = 0\n", count: 101).joined() +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(self.violations(longerFunctionWithExcludedName,
                                       ruleConfigurations: ["excludedByName": ["abc"]]), [])
    }

    func testFunctionBodyLengthWithExcludedNameBySignature() {
        let longFunctionWithExcludedNameSignature = uiKitFuncWithBody(
            repeatElement("cell = UITableViewCell()\n", count: 40).joined()
        )
        let additionalRuleConfigurations = ["excludedBySignature": "tableView(_:cellForRowAt:)"]
        XCTAssertEqual(self.violations(longFunctionWithExcludedNameSignature,
                                       ruleConfigurations: additionalRuleConfigurations), [])
    }

    func testFunctionBodyLengthComplexFunctionExcludedBySignature() {
        let longComplexFunction = complexFuncWithBody(
            repeatElement("a = 5\n", count: 40).joined()
        )
        XCTAssertEqual(self.violations(longComplexFunction, ruleConfigurations: nil),
                       [StyleViolation(
                        ruleDescription: FunctionBodyLengthRule.description,
                        location: Location(file: nil, line: 1, character: 1),
                        reason: "Function body should span 40 lines or less excluding comments and " +
                        "whitespace: currently spans 41 lines")]
        )

        let complexFuncWarnWithExcludedBySignature = complexFuncWithBody(
            repeatElement("a = 5\n", count: 41).joined()
        )
        let violationsStyleWithWarning = self.violations(
            complexFuncWarnWithExcludedBySignature,
            ruleConfigurations: ["excludedBySignature": "example(text:testIntArgument:testArgument:_:)"]
        )
        XCTAssertEqual(violationsStyleWithWarning, [])

        let complexFuncErrWithExcludedBySignature = complexFuncWithBody(
            repeatElement("a = 5\n", count: 101).joined()
        )
        let violationsStyleWithError = self.violations(
            complexFuncErrWithExcludedBySignature,
            ruleConfigurations: ["excludedBySignature": ["example(text:testIntArgument:testArgument:_:)"]]
        )
        XCTAssertEqual(violationsStyleWithError, [])
    }

    private func violations(_ example: Example, ruleConfigurations: Any?) -> [StyleViolation] {
        let config = makeConfig(ruleConfigurations, FunctionBodyLengthRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(example, config: config)
    }
}
