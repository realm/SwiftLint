import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.parserDiagnosticsEnabled(true))
struct ParserDiagnosticsTests {
    @Test
    func fileWithParserErrorDiagnostics() {
        #expect(SwiftLintFile(contents: "importz Foundation").parserDiagnostics.isNotEmpty)
    }

    @Test
    func fileWithParserErrorDiagnosticsDoesntAutocorrect() throws {
        let contents = "print(CGPointZero))"
        #expect(SwiftLintFile(contents: contents).parserDiagnostics == ["extraneous code \')\' at top level"])

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: [Example(contents): Example(contents)])

        verifyCorrections(
            ruleDescription,
            config: try #require(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true)),
            disableCommands: [],
            testMultiByteOffsets: false,
            parserDiagnosticsDisabledForTests: false
        )
    }

    @Test
    func fileWithParserWarningDiagnostics() throws {
        // extraneous duplicate parameter name; 'bar' already has an argument label
        let original = "func foo(bar bar: String) ->   Int { 0 }"
        let corrected = "func foo(bar bar: String) -> Int { 0 }"

        #expect(SwiftLintFile(contents: original).parserDiagnostics.isEmpty)

        let ruleDescription = ReturnArrowWhitespaceRule.description
            .with(corrections: [Example(original): Example(corrected)])

        verifyCorrections(
            ruleDescription,
            config: try #require(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true)),
            disableCommands: [],
            testMultiByteOffsets: false,
            parserDiagnosticsDisabledForTests: false
        )
    }

    @Test
    func fileWithoutParserDiagnostics() throws {
        #expect(SwiftLintFile(contents: "import Foundation").parserDiagnostics.isEmpty)
    }
}
