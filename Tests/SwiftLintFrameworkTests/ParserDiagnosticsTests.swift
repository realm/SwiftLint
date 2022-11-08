@testable import SwiftLintFramework
import XCTest

final class ParserDiagnosticsTests: SwiftLintTestCase {
    func testFileWithParserErrorDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNotNil(SwiftLintFile(contents: "importz Foundation").parserDiagnostics)
    }

    func testFileWithParserErrorDiagnosticsDoesntAutocorrect() throws {
        let contents = """
        print(CGPointZero))
        """
        XCTAssertEqual(SwiftLintFile(contents: contents).parserDiagnostics, ["extraneous code \')\' at top level"])

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: [Example(contents): Example(contents)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    func testFileWithParserWarningDiagnostics() throws {
        parserDiagnosticsDisabledForTests = false
        // extraneous duplicate parameter name; 'bar' already has an argument label
        let original = """
        func foo(bar bar: String) ->   Int { 0 }
        """

        let corrected = """
        func foo(bar bar: String) -> Int { 0 }
        """

        XCTAssertEqual(SwiftLintFile(contents: original).parserDiagnostics, [])

        let ruleDescription = ReturnArrowWhitespaceRule.description
            .with(corrections: [Example(original): Example(corrected)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    func testFileWithoutParserDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertEqual(SwiftLintFile(contents: "import Foundation").parserDiagnostics, [])
    }
}
