@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class FunctionNameWhitespaceRuleTests: SwiftLintTestCase {
    private typealias GenericSpaceType = FunctionNameWhitespaceConfiguration.GenericSpaceType

    // MARK: - Helper

    private func assertReason(
        _ source: String,
        configuration: [String: String]? = nil,
        expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let example = configuration == nil
            ? Example(source)
            : Example(source, configuration: configuration!)

        let violations = ruleViolations(example)
        XCTAssertEqual(violations.first?.reason, expected, file: file, line: line)
    }

    private func ruleViolations(
        _ example: Example,
        ruleConfiguration: Any? = nil
    ) -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, FunctionNameWhitespaceRule.identifier) else {
            return []
        }
        return violations(example, config: config)
    }

    ////
    // MARK: - func keyword spacing

    func test_SpaceBetweenFuncKeywordAndName_ShouldReportReason() {
        assertReason(
            "func  abc(lhs: Int, rhs: Int) -> Int {}",
            expected: "There should be no space before the function name"
        )
    }

    // MARK: - generic_space = no_space

    func test_SpaceAfterFuncName_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_space": "no_space"],
            expected: GenericSpaceType.noSpace.reasonForName
        )
    }

    func test_SpaceAfterGeneric_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T> (lhs: Int) {}",
            configuration: ["generic_space": "no_space"],
            expected: GenericSpaceType.noSpace.reasonForGenericAngleBracket
        )
    }

    // MARK: - generic_space = leading_space

    func test_SpaceAfterFuncName_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_space": "leading_space"],
            expected: GenericSpaceType.leadingSpace.reasonForName
        )
    }

    func test_SpaceBeforeGeneric_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_space": "leading_space"],
            expected: GenericSpaceType.leadingSpace.reasonForName
        )
    }

    // MARK: - generic_space = trailing_space

    func test_SpaceAfterFuncName_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_space": "trailing_space"],
            expected: GenericSpaceType.trailingSpace.reasonForName
        )
    }

    func test_SpaceAfterGeneric_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_space": "trailing_space"],
            expected: GenericSpaceType.trailingSpace.reasonForGenericAngleBracket
        )
    }

    // MARK: - generic_space = leading_trailing_space

    func test_SpaceAfterFuncName_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_space": "leading_trailing_space"],
            expected: GenericSpaceType.leadingTrailingSpace.reasonForName
        )
    }

    func test_SpaceBeforeGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_space": "leading_trailing_space"],
            expected: GenericSpaceType.leadingTrailingSpace.reasonForName
        )
    }

    func test_SpaceAfterGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc <T>(lhs: Int) {}",
            configuration: ["generic_space": "leading_trailing_space"],
            expected: GenericSpaceType.leadingTrailingSpace.reasonForGenericAngleBracket
        )
    }
}
