@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import TestHelpers
import XCTest

final class MultilineParametersConfigurationTests: SwiftLintTestCase {
    func testInvalidMaxNumberOfSingleLineParameters() async throws {
        for maxNumberOfSingleLineParameters in [0, -1] {
            let console = try await Issue.captureConsole {
                var config = MultilineParametersConfiguration()
                try config.apply(
                    configuration: ["max_number_of_single_line_parameters": maxNumberOfSingleLineParameters]
                )
            }
            XCTAssertEqual(
                console,
                """
                warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
                'max_number_of_single_line_parameters' should be >= 1.
                """
            )
        }
    }

    func testInvalidMaxNumberOfSingleLineParametersWithSingleLineEnabled() async throws {
        let console = try await Issue.captureConsole {
            var config = MultilineParametersConfiguration()
            try config.apply(
                configuration: ["max_number_of_single_line_parameters": 2, "allows_single_line": false]
            )
        }
        XCTAssertEqual(
            console,
            """
            warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
            'max_number_of_single_line_parameters' has no effect when 'allows_single_line' is false.
            """
        )
    }
}
