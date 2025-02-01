import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.rulesRegistered)
struct MultilineParametersConfigurationTests {
    @Test
    func invalidMaxNumberOfSingleLineParameters() async throws {
        for maxNumberOfSingleLineParameters in [0, -1] {
            let console = try await Issue.captureConsole {
                var config = MultilineParametersConfiguration()
                try config.apply(
                    configuration: ["max_number_of_single_line_parameters": maxNumberOfSingleLineParameters]
                )
            }
            #expect(
                console == """
                    warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
                    'max_number_of_single_line_parameters' should be >= 1.
                    """
            )
        }
    }

    @Test
    func invalidMaxNumberOfSingleLineParametersWithSingleLineEnabled() async throws {
        let console = try await Issue.captureConsole {
            var config = MultilineParametersConfiguration()
            try config.apply(
                configuration: ["max_number_of_single_line_parameters": 2, "allows_single_line": false]
            )
        }
        #expect(
            console == """
                warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
                'max_number_of_single_line_parameters' has no effect when 'allows_single_line' is false.
                """
        )
    }
}
