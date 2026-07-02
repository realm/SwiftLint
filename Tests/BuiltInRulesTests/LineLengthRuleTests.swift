import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct LineLengthRuleTests {
    private static let longString = String(repeating: "a", count: 121)

    private let longFunctionDeclarations = #examples([
        """
        public func superDuperLongFunctionDeclaration(a: String, b: String, \
        c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
        j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
        q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
        x: String, y: String, z: String) {}

        """,
        """
        func superDuperLongFunctionDeclaration(a: String, b: String, \
        c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
        j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
        q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
        x: String, y: String, z: String) {}

        """,
        """
        struct S {
            public init(a: String, b: String, c: String, d: String, e: String, f: String, \
                        g: String, h: String, i: String, j: String, k: String, l: String, \
                        m: String, n: String, o: String, p: String, q: String, r: String, \
                        s: String, t: String, u: String, v: String, w: String, x: String, \
                        y: String, z: String) throws {
                // ...
            }
        }
        """,
        """
        struct S {
            subscript(a: String, b: String, c: String, d: String, e: String, f: String, \
                      g: String, h: String, i: String, j: String, k: String, l: String, \
                      m: String, n: String, o: String, p: String, q: String, r: String, \
                      s: String, t: String, u: String, v: String, w: String, x: String, \
                      y: String, z: String) -> Int {
                // ...
                return 0
            }
        }
        """,
    ])
    private let longFunctionCalls = #examples([
        """
        superDuperLongFunctionCall(a: "A", b: "B", c: "C", d: "D", e: "E", f: "F", \
        g: "G", h: "H", i: "I", j: "J", k: "K", l: "L", m: "M", n: "N", o: "O", p: "P", \
        q: "Q", r: "R", s: "S", t: "T", u: "U", v: "V", w: "W", x: "X", y: "Y", z: "Z")
        """,
        """
        func test() {
            let _ = superDuperLongFunctionCall(a: "A", b: "B", c: "C", d: "D", e: "E", f: "F", \
            g: "G", h: "H", i: "I", j: "J", k: "K", l: "L", m: "M", n: "N", o: "O", p: "P", \
            q: "Q", r: "R", s: "S", t: "T", u: "U", v: "V", w: "W", x: "X", y: "Y", z: "Z")
        }
        """,
    ])

    private let longMacroDeclarations = #examples([
        """
        @freestanding(expression)
        public macro obfuscate(_ value: String) -> String \
        = #externalMacro(module: \"ObfuscatedStringMacros\", type: \"ObfuscationMacro\")
        """,
    ])

    private let longComment = Example(String(repeating: "/", count: 121) + "\n")
    private let longBlockComment = Example("/*" + String(repeating: " ", count: 121) + "*/\n")
    private let longRealBlockComment = Example("""
        /*
        \(Self.longString)
        */

        """)
    private let declarationWithTrailingLongComment = Example("let foo = 1 " + String(repeating: "/", count: 121) + "\n")
    private let interpolatedString = Example("print(\"\\(value)" + String(repeating: "A", count: 113) + "\" )\n")
    private let plainString = Example("print(\"" + Self.longString + ")\"\n")

    private let multilineString = Example("""
        let multilineString = \"\"\"
        \(Self.longString)
        \"\"\"

        """)
    private let tripleStringSingleLine = Example(
        "let tripleString = \"\"\"\(Self.longString)\"\"\"\n"
    )
    private let poundStringSingleLine = Example("let poundString = #\"\(Self.longString)\"#\n")
    private let multilineStringWithExpression = Example("""
        let multilineString = \"\"\"
        \(Self.longString)

        \"\"\"; let a = 1
        """)
    private let multilineStringWithNewlineExpression = Example("""
        let multilineString = \"\"\"
        \(Self.longString)

        \"\"\"
        ; let a = 1
        """)
    private let multilineStringFail = Example("""
        let multilineString = "A" +
        "\(Self.longString)"

        """)
    private let multilineStringWithFunction = Example("""
        let multilineString = \"\"\"
        \(Self.longString)
        \"\"\".functionCall()
        """)

    // Regex literal examples
    // swiftlint:disable line_length
    private let regexLiteral = Example("""
        let emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^\(Self.longString)$/

        """)
    private let regexLiteralWithCapture = Example("""
        let urlRegex = /^(https?:\\/\\/)?(www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})(\\/\(Self.longString))?$/

        """)
    private let regexLiteralMultiline = Example("""
        let complexRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^very\\.long\\.regex\\.pattern\\.here\\.with\\.many\\.dots\\.and\\.extra\\.text$/

        """)
    // swiftlint:enable line_length
    private let regexLiteralFail = Example("""
        let longRegexString = "\(Self.longString)"

        """)

    @Test
    func lineLength() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false, stringDoesntViolate: false)
    }

    @Test
    func lineLengthWithIgnoreFunctionDeclarationsEnabled() {
        let baseDescription = LineLengthRule.description
        let description = baseDescription.with(
            nonTriggeringExamples:
                baseDescription.nonTriggeringExamples +
                longFunctionDeclarations +
                longMacroDeclarations,
            triggeringExamples: longFunctionCalls
        )

        verifyRule(
            description,
            ruleConfiguration: ["ignores_function_declarations": true],
            commentDoesntViolate: false,
            stringDoesntViolate: false
        )
    }

    @Test
    func lineLengthWithIgnoreCommentsEnabled() {
        let baseDescription = LineLengthRule.description
        let triggeringExamples = longFunctionDeclarations + [declarationWithTrailingLongComment] + longMacroDeclarations
        let nonTriggeringExamples = [longComment, longBlockComment, longRealBlockComment]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(
            description,
            ruleConfiguration: ["ignores_comments": true],
            commentDoesntViolate: false,
            stringDoesntViolate: false,
            skipCommentTests: true
        )
    }

    @Test
    func lineLengthWithIgnoreURLsEnabled() {
        let url = "https://github.com/realm/SwiftLint"
        let triggeringLines = #examples([String(repeating: "/", count: 121) + "\(url)\n"])
        let nonTriggeringLines = #examples([
            "\(url) " + String(repeating: "/", count: 118) + " \(url)\n",
            "\(url)/" + String(repeating: "a", count: 120),
        ])

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_urls": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    @Test
    func lineLengthWithIgnoreInterpolatedStringsTrue() {
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

    @Test
    func lineLengthWithIgnoreMultilineStringsTrue() {
        let triggeringLines = [
            multilineStringFail,
            tripleStringSingleLine,
            poundStringSingleLine,
        ]
        let nonTriggeringLines = [
            multilineString,
            multilineStringWithExpression,
            multilineStringWithNewlineExpression,
            multilineStringWithFunction,
        ]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_multiline_strings": true],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    @Test
    func lineLengthWithIgnoreInterpolatedStringsFalse() {
        let triggeringLines = [plainString, interpolatedString]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignores_interpolated_strings": false],
                   commentDoesntViolate: false, stringDoesntViolate: false)
    }

    @Test
    func lineLengthWithExcludedLinesPatterns() {
        let nonTriggeringLines = [plainString, interpolatedString]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples

        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(
            description,
            ruleConfiguration: ["excluded_lines_patterns": ["^print"]],
            commentDoesntViolate: false,
            stringDoesntViolate: false
        )
    }

    @Test
    func lineLengthWithEmptyExcludedLinesPatterns() {
        let triggeringLines = [plainString, interpolatedString]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(
            description,
            ruleConfiguration: ["excluded_lines_patterns": []],
            commentDoesntViolate: false,
            stringDoesntViolate: false
        )
    }

    @Test
    func lineLengthWithIgnoreRegexLiteralsTrue() {
        let triggeringLines = [
            regexLiteralFail,
            plainString,
        ]
        let nonTriggeringLines = [
            regexLiteral,
            regexLiteralWithCapture,
            regexLiteralMultiline,
        ]

        let baseDescription = LineLengthRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringLines
        let triggeringExamples = baseDescription.triggeringExamples + triggeringLines

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description,
                   ruleConfiguration: ["ignores_regex_literals": true],
                   commentDoesntViolate: false,
                   stringDoesntViolate: false)
    }
}
