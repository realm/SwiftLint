@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

final class ParserDiagnosticsTests: SwiftLintTestCase {
    @MainActor
    func testFileWithParserErrorDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNotNil(SwiftLintFile(contents: "importz Foundation").parserDiagnostics)
    }

    func testFileWithParserErrorDiagnosticsDoesntAutocorrect() async throws {
        let contents = """
        print(CGPointZero))
        """
        await MainActor.run {
            XCTAssertEqual(SwiftLintFile(contents: contents).parserDiagnostics, ["extraneous code \')\' at top level"])
        }

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: [Example(contents): Example(contents)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        await verifyCorrections(
            ruleDescription,
            config: config,
            disableCommands: [],
            testMultiByteOffsets: false,
            parserDiagnosticsDisabledForTests: false
        )
    }

    func testFileWithParserWarningDiagnostics() async throws {
        await MainActor.run {
            parserDiagnosticsDisabledForTests = false
        }
        // extraneous duplicate parameter name; 'bar' already has an argument label
        let original = """
        func foo(bar bar: String) ->   Int { 0 }
        """

        let corrected = """
        func foo(bar bar: String) -> Int { 0 }
        """

        await MainActor.run {
            XCTAssertEqual(SwiftLintFile(contents: original).parserDiagnostics, [])
        }

        let ruleDescription = ReturnArrowWhitespaceRule.description
            .with(corrections: [Example(original): Example(corrected)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        await verifyCorrections(
            ruleDescription,
            config: config,
            disableCommands: [],
            testMultiByteOffsets: false,
            parserDiagnosticsDisabledForTests: false
        )
    }

    @MainActor
    func testFileWithoutParserDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertEqual(SwiftLintFile(contents: "import Foundation").parserDiagnostics, [])
    }
}
