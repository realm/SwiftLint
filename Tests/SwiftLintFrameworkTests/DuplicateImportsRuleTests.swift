@testable import SwiftLintBuiltInRules
import XCTest

final class DuplicateImportsRuleTests: XCTestCase {
    func testDisableCommand() {
        let content = """
            import InspireAPI
            // swiftlint:disable:next duplicate_imports
            import class InspireAPI.Response
            """
        let file = SwiftLintFile(contents: content)

        _ = DuplicateImportsRule().correct(file: file)

        XCTAssertEqual(file.contents, content)
    }
}
