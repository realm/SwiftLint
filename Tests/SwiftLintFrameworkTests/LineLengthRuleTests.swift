@testable import SwiftLintFramework

class LineLengthRuleTests: SwiftLintTestCase {
    private let longFunctionDeclarations = [
        Example("public func superDuperLongFunctionDeclaration(a: String, b: String, " +
            "c: String, d: String, e: String, f: String, g: String, h: String, i: String, " +
            "j: String, k: String, l: String, m: String, n: String, o: String, p: String, " +
            "q: String, r: String, s: String, t: String, u: String, v: String, w: String, " +
            "x: String, y: String, z: String) {\n"),
        Example("func superDuperLongFunctionDeclaration(a: String, b: String, " +
            "c: String, d: String, e: String, f: String, g: String, h: String, i: String, " +
            "j: String, k: String, l: String, m: String, n: String, o: String, p: String, " +
            "q: String, r: String, s: String, t: String, u: String, v: String, w: String, " +
            "x: String, y: String, z: String) {\n")
    ]

    private let longComment = Example(String(repeating: "/", count: 121) + "\n")
    private let longBlockComment = Example("/*" + String(repeating: " ", count: 121) + "*/\n")
    private let declarationWithTrailingLongComment = Example("let foo = 1 " + String(repeating: "/", count: 121) + "\n")
    private let interpolatedString = Example("print(\"\\(value)" + String(repeating: "A", count: 113) + "\" )\n")
    private let plainString = Example("print(\"" + String(repeating: "A", count: 121) + ")\"\n")

    func testLineLength() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testLineLengthWithIgnoreFunctionDeclarationsEnabled() {
        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + longFunctionDeclarations
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_function_declarations": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testLineLengthWithIgnoreCommentsEnabled() {
        let baseDescription = LineLengthRule.description
        let triggeringExamples = longFunctionDeclarations + [declarationWithTrailingLongComment]
        let nonTriggeringExamples = [longComment, longBlockComment]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_comments": true],
                   commentDoesntViolate: false, stringDoesntViolate: false, skipCommentTests: true)
    }

    func testLineLengthWithIgnoreURLsEnabled() {
        let url = "https://github.com/realm/SwiftLint"
        let triggeringLines = [Example(String(repeating: "/", count: 121) + "\(url)\n")]
        let nonTriggeringLines = [
            Example("\(url) " + String(repeating: "/", count: 118) + " \(url)\n"),
            Example("\(url)/" + String(repeating: "a", count: 120))
        ]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_urls": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testLineLengthWithIgnoreInterpolatedStringsTrue() {
        let triggeringLines = [plainString]
        let nonTriggeringLines = [interpolatedString]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_interpolated_strings": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }
    func testLineLengthWithIgnoreInterpolatedStringsFalse() {
        let triggeringLines = [plainString, interpolatedString]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_interpolated_strings": false],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }
}
