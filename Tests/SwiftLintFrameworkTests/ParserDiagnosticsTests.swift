@testable import SwiftLintFramework
import XCTest

final class ParserDiagnosticsTests: XCTestCase {
    func testFileWithParserErrorDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNotNil(SwiftLintFile(contents: "importz Foundation").parserDiagnostics)
    }

    func testFileWithParserErrorDiagnosticsDoesntAutocorrect() throws {
        let contents = """
        importz Foundation
        print(CGPointZero)
        """
        XCTAssertNotNil(SwiftLintFile(contents: contents).parserDiagnostics)

        let ruleDescription = LegacyConstantRule.description
            .with(corrections: [Example(contents): Example(contents)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    func testFileWithParserWarningDiagnostics() throws {
        parserDiagnosticsDisabledForTests = false
        let original = """
        @_functionBuilder // @_functionBuilder' has been renamed to '@resultBuilder'
        struct StringCharacterCounterBuilder {
          static func buildBlock(_ strings: String...) ->  [Int] {
            return strings.map { $0.count }
          }
        }
        """

        let corrected = """
        @_functionBuilder // @_functionBuilder' has been renamed to '@resultBuilder'
        struct StringCharacterCounterBuilder {
          static func buildBlock(_ strings: String...) -> [Int] {
            return strings.map { $0.count }
          }
        }
        """

        XCTAssertNotNil(SwiftLintFile(contents: original).parserDiagnostics)

        let ruleDescription = ReturnArrowWhitespaceRule.description
            .with(corrections: [Example(original): Example(corrected)])

        let config = try XCTUnwrap(makeConfig(nil, ruleDescription.identifier, skipDisableCommandTests: true))
        verifyCorrections(ruleDescription, config: config, disableCommands: [],
                          testMultiByteOffsets: false, parserDiagnosticsDisabledForTests: false)
    }

    func testFileWithoutParserDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNil(SwiftLintFile(contents: "import Foundation").parserDiagnostics)
    }
}
