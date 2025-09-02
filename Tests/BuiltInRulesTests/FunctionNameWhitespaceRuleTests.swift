@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class FunctionNameWhitespaceRuleTests: SwiftLintTestCase {
    private typealias GenericSpacingType = FunctionNameWhitespaceConfiguration.GenericSpacingType

    private static let operatorWhitespaceViolationReason =
        "Operators should be surrounded by a single whitespace when defining them"
    private static let funcKeywordSpacingViolationReason =
        "Too many spaces between 'func' and function name"

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

    // MARK: - func keyword spacing

    func testSpaceBetweenFuncKeywordAndName_ShouldReportReason() {
        assertReason(
            "func  abc(lhs: Int, rhs: Int) -> Int {}",
            expected: Self.funcKeywordSpacingViolationReason
        )
    }

    // MARK: - operator functions

    func testOperatorFunctionSpacing_WhenNoSpaceAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|(lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    func testOperatorFunctionSpacing_WhenTooManySpacesAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|  (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    func testOperatorFunctionWithGenerics_WhenNoSpaceAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|<<A>(lhs: A, rhs: A) -> A {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    func testOperatorFunctionSpacing_WhenMultipleViolations_ShouldReportOperatorMessage() {
        assertReason(
            "func  <| (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    func testOperatorFunctionSpacing_WhenTooManySpacesBeforeAndAfter_ShouldReportOperatorMessage() {
        assertReason(
            "func  <|  (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    // MARK: - generic_spacing = no_space

    func testSpaceAfterFuncName_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_spacing": "no_space"],
            expected: GenericSpacingType.noSpace.beforeGenericViolationReason
        )
    }

    func testSpaceAfterGeneric_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T> (lhs: Int) {}",
            configuration: ["generic_spacing": "no_space"],
            expected: GenericSpacingType.noSpace.afterGenericViolationReason
        )
    }

    // MARK: - generic_spacing = leading_space

    func testSpaceAfterFuncName_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_space"],
            expected: GenericSpacingType.leadingSpace.beforeGenericViolationReason
        )
    }

    func testSpaceBeforeGeneric_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_space"],
            expected: GenericSpacingType.leadingSpace.beforeGenericViolationReason
        )
    }

    // MARK: - generic_spacing = trailing_space

    func testSpaceAfterFuncName_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_spacing": "trailing_space"],
            expected: GenericSpacingType.trailingSpace.beforeGenericViolationReason
        )
    }

    func testSpaceAfterGeneric_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "trailing_space"],
            expected: GenericSpacingType.trailingSpace.afterGenericViolationReason
        )
    }

    // MARK: - generic_spacing = leading_trailing_space

    func testSpaceAfterFuncName_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.beforeGenericViolationReason
        )
    }

    func testSpaceBeforeGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.beforeGenericViolationReason
        )
    }

    func testSpaceAfterGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc <T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.afterGenericViolationReason
        )
    }
}
