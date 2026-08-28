import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.rulesRegistered)
struct MultilineParametersConfigurationTests {
    @Test
    func invalidMaxNumberOfSingleLineParameters() {
        #expect(throws: Issue.self) {
            _ = try MultilineParametersRule(configuration: ["max_number_of_single_line_parameters": 0])
        }
        #expect(throws: Issue.self) {
            _ = try MultilineParametersRule(configuration: ["max_number_of_single_line_parameters": -1])
        }
    }

    @Test
    func invalidMaxNumberOfSingleLineParametersWithSingleLineEnabled() {
        #expect(throws: Issue.self) {
            _ = try MultilineParametersRule(configuration: [
                "max_number_of_single_line_parameters": 2,
                "allows_single_line": false,
            ])
        }
    }
}
