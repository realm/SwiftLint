@testable import SwiftLintBuiltInRules

class IdentifierNameRuleTests: SwiftLintTestCase {
    func testIdentifierNameWithExcluded() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let Apple = 0"),
            Example("let some_apple = 0"),
            Example("let Test123 = 0")
        ]
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("let ap_ple = 0"),
            Example("let AppleJuice = 0")
        ]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
    }

    func testIdentifierNameWithAllowedSymbols() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let myLet$ = 0"),
            Example("let myLet% = 0"),
            Example("let myLet$% = 0"),
            Example("let _myLet = 0")
        ]
        let triggeringExamples = baseDescription.triggeringExamples.filter { !$0.code.contains("_") }
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%", "_"]])
    }

    func testIdentifierNameWithAllowedSymbolsAndViolation() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("↓let my_Let$ = 0")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testIdentifierNameWithIgnoreStartWithLowercase() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamplesToRemove = [
            Example("↓let MyLet = 0"),
            Example("enum Foo { case ↓MyEnum }"),
            Example("↓func IsOperator(name: String) -> Bool")
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
    }

    func testStartsWithLowercaseCheck() {
        let triggeringExamples = [
            Example("↓let MyLet = 0"),
            Example("enum Foo { case ↓MyCase }"),
            Example("↓func IsOperator(name: String) -> Bool { true }")
        ]
        let nonTriggeringExamples = [
            Example("let myLet = 0"),
            Example("enum Foo { case myCase }"),
            Example("func isOperator(name: String) -> Bool { true }")
        ]

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: triggeringExamples)
                .with(nonTriggeringExamples: nonTriggeringExamples),
            ruleConfiguration: ["validates_start_with_lowercase": "error"]
        )

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: [])
                .with(nonTriggeringExamples: nonTriggeringExamples + triggeringExamples.removingViolationMarkers()),
            ruleConfiguration: ["validates_start_with_lowercase": false]
        )
    }

    func testStartsWithLowercaseCheckInCombinationWithAllowedSymbols() {
        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: [
                    Example("↓let OneLet = 0")
                ])
                .with(nonTriggeringExamples: [
                    Example("let MyLet = 0"),
                    Example("enum Foo { case myCase }")
                ]),
            ruleConfiguration: [
                "validates_start_with_lowercase": true,
                "allowed_symbols": ["M"]
            ] as [String: Any]
        )
    }

    func testLinuxCrashOnEmojiNames() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("let 👦🏼 = \"👦🏼\"")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }
}
