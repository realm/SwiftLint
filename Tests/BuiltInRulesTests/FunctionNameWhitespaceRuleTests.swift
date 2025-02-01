import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct FunctionNameWhitespaceRuleTests {
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
        file: String = #filePath,
        line: UInt = #line
    ) {
        let example = configuration == nil
            ? Example(source)
            : Example(source, configuration: configuration!)

        let violations = ruleViolations(example)
        #expect(
            violations.first?.reason == expected,
            sourceLocation: SourceLocation(fileID: #fileID, filePath: file, line: Int(line), column: 1)
        )
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

    @Test
    func spaceBetweenFuncKeywordAndName_ShouldReportReason() {
        assertReason(
            "func  abc(lhs: Int, rhs: Int) -> Int {}",
            expected: Self.funcKeywordSpacingViolationReason
        )
    }

    // MARK: - operator functions

    @Test
    func operatorFunctionSpacing_WhenNoSpaceAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|(lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    @Test
    func operatorFunctionSpacing_WhenTooManySpacesAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|  (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    @Test
    func operatorFunctionWithGenerics_WhenNoSpaceAfterOperator_ShouldReportOperatorMessage() {
        assertReason(
            "func <|<<A>(lhs: A, rhs: A) -> A {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    @Test
    func operatorFunctionSpacing_WhenMultipleViolations_ShouldReportOperatorMessage() {
        assertReason(
            "func  <| (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    @Test
    func operatorFunctionSpacing_WhenTooManySpacesBeforeAndAfter_ShouldReportOperatorMessage() {
        assertReason(
            "func  <|  (lhs: Int, rhs: Int) -> Int {}",
            expected: Self.operatorWhitespaceViolationReason
        )
    }

    // MARK: - generic_spacing = no_space

    @Test
    func spaceAfterFuncName_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_spacing": "no_space"],
            expected: GenericSpacingType.noSpace.beforeGenericViolationReason
        )
    }

    @Test
    func spaceAfterGeneric_WhenNoSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T> (lhs: Int) {}",
            configuration: ["generic_spacing": "no_space"],
            expected: GenericSpacingType.noSpace.afterGenericViolationReason
        )
    }

    // MARK: - generic_spacing = leading_space

    @Test
    func spaceAfterFuncName_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_space"],
            expected: GenericSpacingType.leadingSpace.beforeGenericViolationReason
        )
    }

    @Test
    func spaceBeforeGeneric_WhenLeadingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_space"],
            expected: GenericSpacingType.leadingSpace.beforeGenericViolationReason
        )
    }

    // MARK: - generic_spacing = trailing_space

    @Test
    func spaceAfterFuncName_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc (lhs: Int) {}",
            configuration: ["generic_spacing": "trailing_space"],
            expected: GenericSpacingType.trailingSpace.beforeGenericViolationReason
        )
    }

    @Test
    func spaceAfterGeneric_WhenTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "trailing_space"],
            expected: GenericSpacingType.trailingSpace.afterGenericViolationReason
        )
    }

    // MARK: - generic_spacing = leading_trailing_space

    @Test
    func spaceAfterFuncName_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.beforeGenericViolationReason
        )
    }

    @Test
    func spaceBeforeGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc<T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.beforeGenericViolationReason
        )
    }

    @Test
    func spaceAfterGeneric_WhenLeadingTrailingSpaceConfigured_ShouldReport() {
        assertReason(
            "func abc <T>(lhs: Int) {}",
            configuration: ["generic_spacing": "leading_trailing_space"],
            expected: GenericSpacingType.leadingTrailingSpace.afterGenericViolationReason
        )
    }
}
