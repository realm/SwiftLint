@testable import SwiftLintFramework
import XCTest

final class ParserDiagnosticsTests: XCTestCase {
    func testFileWithParserDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNotNil(SwiftLintFile(contents: "importz Foundation").parserDiagnostics)
    }

    func testFileWithoutParserDiagnostics() {
        parserDiagnosticsDisabledForTests = false
        XCTAssertNil(SwiftLintFile(contents: "import Foundation").parserDiagnostics)
    }
}
