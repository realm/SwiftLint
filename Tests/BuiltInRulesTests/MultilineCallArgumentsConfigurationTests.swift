@testable import SwiftLintBuiltInRules
import SwiftLintCore
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct MultilineCallArgumentsConfigurationTests {
    @Test
    func configurationInvalidValuesThrow() {
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": 0])
        }
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": -1])
        }
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 2,
            ])
        }
    }

    @Test
    func configurationAllowsSingleLineFalseWithMaxParametersOneIsValid() {
        #expect(throws: Never.self) {
            _ = try MultilineCallArgumentsRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ])
        }
    }
}
