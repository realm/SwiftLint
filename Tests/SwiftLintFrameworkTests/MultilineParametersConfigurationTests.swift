@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

final class MultilineParametersConfigurationTests: SwiftLintTestCase {
    func testInvalidMaxNumberOfSingleLineParameters() throws {
        for maxNumberOfSingleLineParameters in [0, -1] {
            var config = MultilineParametersConfiguration()

            XCTAssertEqual(
                try Issue.captureConsole {
                    try config.apply(
                        configuration: ["max_number_of_single_line_parameters": maxNumberOfSingleLineParameters]
                    )
                },
                """
                warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
                'max_number_of_single_line_parameters' should be >= 1.
                """
            )
        }
    }

    func testInvalidMaxNumberOfSingleLineParametersWithSingleLineEnabled() throws {
        var config = MultilineParametersConfiguration()

        XCTAssertEqual(
            try Issue.captureConsole {
                try config.apply(
                    configuration: ["max_number_of_single_line_parameters": 2, "allows_single_line": false]
                )
            },
            """
            warning: Inconsistent configuration for 'multiline_parameters' rule: Option \
            'max_number_of_single_line_parameters' has no effect when 'allows_single_line' is false.
            """
        )
    }
}
