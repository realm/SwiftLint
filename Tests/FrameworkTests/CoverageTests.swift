@testable import SwiftLintFramework
@testable import SwiftLintBuiltInRules
import XCTest

final class CoverageTests: SwiftLintTestCase {
    func testCoverage() {
        let rules: [any Rule] = [
            ArrayInitRule(),
            BlockBasedKVORule(),
            ClosingBraceRule(),
            DirectReturnRule(),
        ]
        var coverage = Coverage(numberOfEnabledRules: 4, totalNumberOfRules: 10)
        XCTAssertEqual(coverage.enabledRulesCoverage, 0)
        XCTAssertEqual(coverage.allRulesCoverage, 0)
        let file = SwiftLintFile(contents: "\n")
        coverage.addCoverage(for: file, rules: rules)
        XCTAssertEqual(coverage.enabledRulesCoverage, 1.0)
        XCTAssertEqual(coverage.allRulesCoverage, 0.4)
        XCTAssertEqual(coverage.report, "Enabled rules coverage: 1.001\n    All rules coverage: 0.401")
    }
}
