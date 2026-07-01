import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.parserDiagnosticsEnabled(true), .rulesRegistered)
struct ParserDiagnosticsTests {
    @Test
    func fileWithParserErrorDiagnostics() {
        #expect(SwiftLintFile(contents: "importz Foundation").parserDiagnostics.isNotEmpty)
    }

    @Test
    func fileWithParserErrorDiagnosticsDoesntAutocorrect() throws {
        let contents = """
			print(CGPointZero))
			"""
        #expect(SwiftLintFile(contents: contents).parserDiagnostics == ["unexpected code \')\' in source file"])

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: #corrections([contents: contents]))

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
            .with(corrections: #corrections([original: corrected]))

        verifyCorrections(
            ruleDescription,
            config: try #require(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true)),
            disableCommands: [],
            testMultiByteOffsets: false,
            parserDiagnosticsDisabledForTests: false
        )
    }

    @Test
    func fileWithoutParserDiagnostics() {
        #expect(SwiftLintFile(contents: "import Foundation").parserDiagnostics.isEmpty)
    }
}
